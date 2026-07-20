---
name: ts-review-optimize
description: Use when you want to scrutinize TypeScript or Node.js code for measurable, quantifiable performance wins. Triggers on "optimize", "make faster", "reduce allocations", "benchmark and improve", "squeeze cycles", "V8 hot path" in TypeScript/Node code. Requires a checked-in benchmark and measured evidence for every recommendation. Invoke explicitly only — do not auto-invoke during normal review.
---

This skill is the deliberate counterweight to `ts-review-style` and `ts-review-legibility`. It only fires when an optimization is measured. Without numbers, defer to legibility.

## 1. Triage — should this code be ultra-optimized?

Three gates. Any "no" sends you back to `ts-review-style`.

1. **Is it hot?** The target function must appear in a `--prof` profile (`node --prof`), a `clinic.js` flamegraph, a `0x` profile, or be on a documented inner loop called millions of times per second. "It might be slow" is not hot.
2. **Is the algorithmic level already optimal?** No point shaving allocations off an O(n²) sort that could be O(n log n). Fix the algorithm first; micro-optimize the constant second.
3. **Is there a benchmark already checked in, or will the author write one?** The benchmark must live alongside the change (same package or `__benchmarks__/` sibling). Verbal commitments don't count.

If all three gates pass, proceed. Otherwise, stop here.

## 2. Evidence requirements

Every recommendation requires:

- **A checked-in benchmark** using `tinybench`, `mitata`, or `benchmark.js`. Future maintainers must be able to re-run and compare. Include baseline and optimized numbers in the PR description.
- **The right tool for the claim:**
  - Allocation claims: `--inspect` heap snapshot diff, or `--expose-gc` + `process.memoryUsage()` before/after.
  - CPU claims: `node --prof` → `node --prof-process` or `clinic doctor` flamegraph.
  - Deopt claims: `node --trace-deopt` or `deopt-explorer` on the V8 log.
  - Escape / inline claims: `node --print-opt-code` or `--trace-opt` on the hot function.
- **Platform version stated** in the code comment: "Node ≥ 18 (V8 10.2)" when the optimization relies on a specific V8 behavior.

Reject any recommendation that cannot be backed by a measurement.

## 3. Categories of ultra-optimization

### 3.1 Allocation reduction

Object allocation in hot paths drives GC pressure. Reduce with:
- Pre-allocate arrays: `new Array(n)` or `new Array(n).fill(0)` when the length is known.
- Reuse buffers: `Buffer.allocUnsafe(size)` + manual reset rather than `Buffer.alloc` per call.
- Avoid spreading in loops: `{ ...defaults, ...overrides }` allocates a new object each iteration — mutate a pre-allocated config object instead.
- Avoid closure allocation in hot loops: a closure created inside a loop allocates a new function per iteration. Hoist the function and pass closed-over state as arguments.

```ts
// before: new closure per item
items.forEach(item => process(item, context));

// ultra-opt: hoist closure; one function allocation instead of items.length
function processItem(item: Item, ctx: Context) { ... }
for (const item of items) processItem(item, context);
```

Measurement type: heap snapshot diff or `process.memoryUsage().heapUsed` before/after.

**Legibility cost:** less ergonomic; hoisted function adds indirection.

### 3.2 Hidden-class stability (monomorphism)

V8 assigns a "hidden class" (shape) to every object based on the order and types of its properties. Polymorphic call sites (objects with different shapes) deoptimize to the generic interpreter.

Rules:
- Add all properties in the constructor, in the same order, every time.
- Do not delete properties (`delete obj.x` invalidates the hidden class).
- Do not mix types into the same property slot across objects (e.g., `obj.value = 1` sometimes, `obj.value = 'a'` other times).

```ts
// bad: two shapes — one with name, one without
const a = { id: 1 };
const b = { id: 2, name: 'x' };

// good: consistent shape
const a = { id: 1, name: undefined };
const b = { id: 2, name: 'x' };
```

Measurement type: `--trace-deopt` or deopt-explorer confirming deopts are eliminated.

**Legibility cost:** explicit `undefined` fields are surprising to readers.

### 3.3 Avoiding deopt triggers

V8's TurboFan compiler optimizes hot functions. Several patterns cause it to bail out to unoptimized code:

- **`try`/`catch` inside the hot function.** Move the try/catch to the caller; let the hot function be free of exception handling.
- **`arguments` object access.** Use rest parameters (`...args`) instead; `arguments` prevents optimization.
- **Mixing integer and float in the same variable.** `let x = 1; x = 1.5;` can cause a slot-type change. Use typed arrays or keep types consistent.
- **`eval` or `with`.** These block all optimization. Remove.

Measurement type: `--trace-deopt` confirming the function stays optimized after the change.

**Legibility cost:** restructuring try/catch to the caller makes error flow less local.

### 3.4 `Buffer` and `TypedArray` for binary-intensive paths

For binary-intensive operations (network protocol parsing, file I/O, crypto), `Buffer` and `TypedArrays` avoid the overhead of JavaScript string manipulation:

- Pre-size a `Buffer` and use `writeUInt32LE`, `writeUInt8`, etc. directly rather than `Buffer.concat` in a loop.
- `Uint8Array`, `Float64Array`, `Int32Array` for numeric arrays in hot paths — they are contiguous, unboxed in V8, and avoid the per-element object overhead of `number[]`.

```ts
// ultra-opt: pre-sized Buffer with direct writes; avoid Buffer.concat in tight loop
//   measured: BenchmarkSerialize -60% ns/op (mitata, n=10).
//   trade-off: manual offset tracking; must not exceed allocated size.
//   assumes: Node ≥ 16.
const buf = Buffer.allocUnsafe(FIXED_PAYLOAD_SIZE);
buf.writeUInt32LE(id, 0);
buf.writeUInt8(flags, 4);
```

Measurement type: `tinybench` ns/op + `process.memoryUsage()` diff.

**Legibility cost:** manual offset arithmetic; no bounds checking.

### 3.5 String concatenation in hot loops

`+` operator on strings is efficient for 1–2 concatenations. For N concatenations in a loop, push to an array and `join('')`:

```ts
// ultra-opt: array join avoids N intermediate string allocations.
//   measured: BenchmarkBuild -40% ns/op at N=1000 (tinybench, n=10).
//   trade-off: two-pass logic; array allocation up front.
const parts: string[] = [];
for (const item of items) parts.push(item.value);
return parts.join('');
```

Template literals (`\`${a}${b}\``) compile to a single concatenation — fine for 2–3 parts; prefer array-join for N > ~10.

Measurement type: `tinybench` ns/op at the actual N used in production.

**Legibility cost:** less readable than template literals for small N.

### 3.6 Microtask flooding

Every `await` yields to the microtask queue. In a tight loop, `await` per iteration serializes work and floods the queue:

```ts
// bad: N microtask yields for N items
for (const item of items) {
  await process(item);
}

// ultra-opt: batch with Promise.all in chunks; one yield per chunk.
//   measured: BenchmarkBatchProcess -70% elapsed at N=1000 (tinybench, n=10).
//   trade-off: partial failure in a chunk fails the whole chunk.
//   assumes: process() is CPU-bound or has independent I/O.
const CHUNK = 50;
for (let i = 0; i < items.length; i += CHUNK) {
  await Promise.all(items.slice(i, i + CHUNK).map(process));
}
```

Measurement type: wall-clock elapsed time + `tinybench` ns/op.

**Legibility cost:** chunking logic obscures the per-item intent; error handling is less granular.

### 3.7 `for` loops vs `forEach` / `map` in measured hot paths

V8 has narrowed the gap significantly. `forEach` and `map` are fine for most code. In a measured hot path where array iteration dominates:

- `for` and `for-of` over arrays produce fewer intermediate objects than `map` (no new array allocation for side-effect-only loops).
- `forEach` has a callback invocation per element; `for` does not.

Only switch after measurement confirms the gain. `for-of` is usually the best balance of readability and performance.

Measurement type: `tinybench` ns/op with a realistic input size.

**Legibility cost:** `for-of` is fine; bare `for` with index arithmetic is less clear.

### 3.8 `WeakRef` and `WeakMap` for memory-sensitive caches

Not a CPU win, but prevents leaks in caches keyed by object identity:

- `WeakMap<Key, Value>` — entry is automatically removed when `Key` is garbage-collected. No manual cleanup needed.
- `WeakRef<T>` — holds a weak reference to `T`; check `.deref()` before use; `undefined` means GC'd.

Use when the cache key is an object whose lifetime you don't control. Don't use for primitive keys — use a regular `Map` with an explicit eviction policy.

Measurement type: heap snapshot before/after sustained load; confirm objects are collected.

**Legibility cost:** `deref()` check required before every access; subtle lifetime semantics.

### 3.9 Streaming vs buffering for large payloads

Buffering an entire large file or response into memory before processing doubles peak memory usage:

```ts
// ultra-opt: stream directly; peak memory = one chunk, not full payload.
//   measured: BenchmarkTransform -85% peak heap (heap snapshot, 100 MB input).
//   trade-off: streaming complicates error handling and partial-result logic.
//   assumes: Node ≥ 16 (stream.pipeline with async iterator support).
import { pipeline } from 'node:stream/promises';
await pipeline(readable, transform, writable);
```

Use `stream.pipeline` (not manual `pipe`) for automatic teardown on error.

Measurement type: heap snapshot at peak + wall-clock elapsed.

**Legibility cost:** streaming pipelines are significantly harder to reason about than buffered transforms.

### 3.10 Native addons and WASM as a last resort

Permitted only when: (a) a pure-JS implementation was written, benchmarked, and lost to a native alternative by a margin that matters to production SLOs; and (b) both benchmark results are cited in the PR. Cite the pure-JS numbers, the native numbers, and the specific library. Document the build dependency in the package `README`.

Measurement type: `tinybench` ns/op with and without the native addon.

**Legibility cost:** native addons break cross-compilation, require a platform-specific build toolchain, and complicate profiling. WASM adds a compilation step and a separate debugging workflow.

## 4. The `ultra-opt:` comment template (mandatory)

Every ultra-optimization that bends a convention `ts-review-style` or `ts-review-legibility` would otherwise enforce **must** carry this comment:

```ts
// ultra-opt: <one-line what>.
//   measured: <benchmarkName> <delta> (<tool>, n=<runs>).
//   trade-off: <legibility / portability / contract cost>.
//   assumes:  <Node version, V8 version, platform, if applicable>.
```

The literal string `ultra-opt:` is the grep contract. Reviewers audit with:

```sh
grep -rn "ultra-opt:" .
```

No `ultra-opt:` prefix, no merge. A comment that omits `measured:` is rejected — it's not an ultra-opt, it's a hunch.

## 5. Anti-patterns — reject on sight

- **Micro-opt without a checked-in benchmark.** No measurement, no change.
- **"I read that X is faster."** Benchmark it or drop it.
- **Removing `await` in non-hot functions.** The microtask overhead only matters at high iteration counts. Removing it elsewhere introduces fire-and-forget bugs.
- **Premature `WeakRef`.** Adds lifetime complexity; only justified when a measured leak is confirmed.
- **Optimizing cold code.** If the profiler says < 1% wall-clock, leave it readable.
- **Loop unrolling without measurement.** V8 already unrolls loops it can prove safe.
- **Switching from `forEach` to `for` without a benchmark.** The gap is small in modern V8; measure before changing.

## 6. Conflict resolution with sibling skills

When `ts-review-style` says "prefer X for legibility" and a measured ultra-opt says otherwise, the ultra-opt wins **iff**:

1. It carries the `ultra-opt:` comment with all four lines.
2. A benchmark is checked into the same package.
3. Benchmark output appears in the PR description.
4. The Node/V8 version assumption is stated.

If any condition is unmet, legibility wins. This is not negotiable.

The same rule applies to `ts-review-legibility`: a measured ultra-opt may introduce a legibility cost the legibility skill would otherwise flag, provided the comment fully covers it.

## 7. What this skill does not do

- Recommend rewriting in another language.
- Endorse native addons without documented evidence that a pure-JS alternative was written and benchmarked.
- Run benchmarks itself — the author must provide them.
- Fire on cold code, test helpers, one-off CLI commands, or anything outside a measured hot path.
- Auto-invoke during normal review — explicit user request only.

## See also

- `ts-review-style` — default style and idiom conventions; defer here when not in a measured hot path.
- `ts-review-legibility` — structural refactors to make correct code visibly correct.
