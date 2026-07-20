---
name: go-review-optimize
description: Scrutinize Go code for measurable, quantifiable performance wins — even when they sacrifice idiom or legibility. Use when the user asks to "optimize", "ultra-optimize", "make faster", "performance tune", "reduce allocations", "benchmark and improve", or "squeeze cycles" in Go code, or when they want a platform-specific fast path in Go. Requires a checked-in BenchmarkX and benchstat evidence for every recommendation; rejects speculative micro-opts. Mandates the `ultra-opt:` comment template, follows the `magus/cache/reflink/` build-tag pattern, and carries explicit precedence rules versus go-review-style and go-review-legibility. Invoke explicitly only — do not auto-invoke during normal review.
---

This skill is the deliberate counterweight to `go-review-style` and `go-review-legibility`. It only fires when an optimization is measured. Without numbers, defer to legibility.

## 1. Triage — should this code be ultra-optimized?

Three gates. Any "no" sends you back to `go-review-style`.

1. **Is it hot?** The target function must appear in a `go test -bench` profile, a `pprof` top-10 listing, or be on a documented inner loop called millions of times per second. "It might be slow" is not hot.
2. **Is the algorithmic level already optimal?** No point shaving allocations off an O(n²) sort that could be O(n log n). Fix the algorithm first; micro-optimize the constant second.
3. **Is there a `BenchmarkX` already, or will the author write one?** The benchmark must live in the same package as the change, alongside the change itself. Verbal commitments don't count.

If all three gates pass, proceed. Otherwise, stop here.

## 2. Evidence requirements

Every recommendation requires:

- **A checked-in `BenchmarkX`** in the same package as the change. This is non-negotiable. Future maintainers must be able to re-run `go test -bench=BenchmarkX -benchmem -count=10 > new.txt` and compare.
- **`benchstat` output in the PR description.** Run `benchstat old.txt new.txt`. Paste the result. The delta on `ns/op` and `allocs/op` is the claim.
- **The right tool for the claim:**
  - Allocation claims: `-benchmem` (`allocs/op`, `B/op`).
  - CPU claims: `go test -bench=. -cpuprofile=cpu.prof` then `go tool pprof`.
  - Escape claims: `go build -gcflags=-m 2>&1 | grep <func>`.
  - Bounds-check claims: `go build -gcflags=-d=ssa/check_bce/debug=1`.
- **Platform/syscall opts:** the kernel or OS minimum version must be stated in the code comment. "Works on Linux" is not sufficient; "Linux ≥ 4.5 (copy_file_range)" is.

Reject any recommendation that cannot be backed by a measurement.

## 3. Categories of ultra-optimization

Each category below follows: **rule → before/after snippet → measurement type → legibility cost**.

### 3.1 Allocation reduction

Allocations are the most common hot-path cost. Reduce them with: `sync.Pool` for large, frequently reused objects; `make([]T, 0, n)` with a known upper bound; `bytes.Buffer.Reset()` over re-construction; avoiding interface boxing of concrete types in tight loops.

```go
// before
func Render(w io.Writer, data []byte) {
    buf := &bytes.Buffer{}  // heap alloc every call
    process(buf, data)
    w.Write(buf.Bytes())
}

// after
var bufPool = sync.Pool{New: func() any { return new(bytes.Buffer) }}

// ultra-opt: reuse buf via sync.Pool to avoid 4 KiB alloc/op.
//   measured: BenchmarkRender -38% ns/op, -92% allocs/op (benchstat, n=10).
//   trade-off: caller must not retain references to buf after Render returns.
//   assumes:  Go 1.13+ (Pool is not cleared between GCs in 1.13+).
func Render(w io.Writer, data []byte) {
    buf := bufPool.Get().(*bytes.Buffer)
    buf.Reset()
    defer bufPool.Put(buf)
    process(buf, data)
    w.Write(buf.Bytes())
}
```

Measurement type: `-benchmem` `allocs/op` delta.

**Legibility cost:** non-local ownership; callers must respect the "don't retain" contract.

**Premature-pool warning:** if the objects are < ~64 B or the call site is rarely reached, pool overhead exceeds saved alloc. Measure first.

### 3.2 Escape-analysis tuning

Returning a value instead of a pointer can keep a struct on the stack when it's small (≲ 64 B) and short-lived. Closures captured in hot loops frequently force variables to heap; hoisting them out can eliminate the alloc.

```go
// before — escapes to heap on every call
func newPoint(x, y float64) *Point { return &Point{x, y} }

// after
// ultra-opt: return value, not pointer; keeps Point on caller's stack.
//   measured: BenchmarkNewPoint -100% allocs/op (go build -gcflags=-m confirms no escape).
//   trade-off: callers taking the address of the return value will re-escape it; don't.
func newPoint(x, y float64) Point { return Point{x, y} }
```

Use `go build -gcflags=-m 2>&1 | grep <funcname>` to confirm before and after. Don't guess — the compiler surprises you.

Measurement type: `-gcflags=-m` diff + `-benchmem` `allocs/op`.

**Legibility cost:** value semantics preclude mutation via the returned value; not always correct.

### 3.3 Unsafe string ↔ []byte conversions

`unsafe.String` (Go 1.20+) and `unsafe.Slice` let you reinterpret a `[]byte` as a `string` without a copy — zero allocation. This is safe only when the `[]byte` is not modified for the duration of the string's use, and the string does not escape to a goroutine or storage outliving the slice.

```go
// ultra-opt: avoid string(b) copy in read-only hot path.
//   measured: BenchmarkLookup -45% ns/op, -1 allocs/op (benchstat, n=10).
//   trade-off: if b is mutated or escapes (goroutine, map key, channel send), data races result.
//   assumes:  Go 1.20+; b is stack-local and not captured by any closure.
key := unsafe.String(unsafe.SliceData(b), len(b))
```

Gate this with a build constraint if your minimum Go version is below 1.20. Document the lifetime guarantee at the call site and in the function comment. If you cannot write the lifetime guarantee in one sentence, don't do this.

Measurement type: `-benchmem` `allocs/op` + `-gcflags=-m`.

**Legibility cost:** data-race risk if the invariant is violated later; the `unsafe` import is a loud signal to reviewers.

### 3.4 Struct field ordering

Reorder fields widest-first to eliminate padding. Group `sync/atomic` fields at the top of the struct, 8-byte aligned. Use a `[64]byte` cache-line pad between per-goroutine counters to prevent false sharing on multi-core.

```go
// before — 4 bytes padding between id and flag
type Node struct {
    flag  bool     // 1 B
    id    uint64   // 8 B (4 B padding before this)
    count int32    // 4 B
}

// after
// ultra-opt: widest-first field ordering eliminates 4 B of padding.
//   measured: unsafe.Sizeof(Node{}) 24→16 bytes; BenchmarkNodeScan -11% ns/op.
//   trade-off: field order no longer matches the domain model's conceptual grouping.
type Node struct {
    id    uint64  // 8 B
    count int32   // 4 B
    flag  bool    // 1 B
    _     [3]byte // explicit pad to keep the struct self-documenting
}
```

Measurement type: `unsafe.Sizeof` before/after + a cache-thrashing bench.

**Legibility cost:** field order no longer reflects semantics; requires a comment to justify.

### 3.5 Bounds-check elimination (BCE)

The compiler can eliminate array/slice bounds checks if it can prove `i < len(s)` at the access site. Hoist a single `_ = s[n-1]` before a loop to prove the length once and let the compiler skip per-iteration checks.

```go
// ultra-opt: hoist bounds check out of the loop; compiler eliminates per-iteration checks.
//   measured: BenchmarkScan -18% ns/op (-gcflags=-d=ssa/check_bce/debug=1 confirms 0 checks inside loop).
//   trade-off: panics at the hoist line rather than at the first bad access; stack trace differs.
_ = s[len(s)-1]           // prove len(s) >= 1 before the loop
for i := range s {
    process(s[i])
}
```

Measurement type: `go build -gcflags=-d=ssa/check_bce/debug=1` diff + `-bench` ns/op.

**Legibility cost:** the `_ = s[...]` line looks like dead code; the `// ultra-opt:` comment is load-bearing.

### 3.6 Builder and buffer reuse

`strings.Builder.Grow(n)` before writing avoids internal doublings. `bytes.Buffer.Reset()` on a pooled buffer avoids re-allocation. Measure the `B/op` delta to confirm the win.

```go
// ultra-opt: pre-grow builder to avoid 3 internal reallocations at median input size.
//   measured: BenchmarkFormat -29% ns/op, -3 allocs/op (benchstat, n=10 at p50 input).
//   trade-off: growth hint is wrong for inputs much smaller or larger than median.
var b strings.Builder
b.Grow(estimatedLen)
```

Measurement type: `-benchmem` `allocs/op` + `B/op`.

**Legibility cost:** `Grow` hint becomes a maintenance liability when input size distribution shifts.

### 3.7 Avoiding `defer` in tight loops

Modern Go (1.14+) defer is ~1–2 ns per call, cheap for most use. In loops called millions of times per second, that's measurable. Replace `defer` with explicit cleanup only when the bench shows the gain and the cleanup path is not error-branch-only.

```go
// ultra-opt: explicit Close replaces defer in 10M-iter loop; defer overhead measurable at scale.
//   measured: BenchmarkProcess -7% ns/op (benchstat, n=10, 1e7 iterations/op).
//   trade-off: must duplicate cleanup on every return path; audit carefully on error branches.
f, err := os.Open(name)
if err != nil { return err }
err = process(f)
f.Close()    // ultra-opt: intentional; see comment above
return err
```

Measurement type: `-bench` ns/op; only worth it when the loop body is otherwise very cheap.

**Legibility cost:** silent resource-leak risk if a return path is added later without the explicit close.

### 3.8 Map vs slice for small N

Hash-map lookup has a fixed overhead that dominates for very small N. Linear scan over a slice beats a map when N ≲ 8 and keys are comparable with `==`.

```go
// ultra-opt: linear scan over []pair beats map[string]T at N≤8 keys.
//   measured: BenchmarkLookup4 map: 45 ns/op, slice: 12 ns/op (benchstat, n=10).
//   trade-off: O(N) not O(1); correct only while the set stays small. Add a size assertion.
type pair struct{ k string; v int }
var table = []pair{{"a", 1}, {"b", 2}, ...}  // N ≤ 8
```

Measurement type: `-bench` ns/op at the actual N used in production.

**Legibility cost:** O(N) is surprising to maintainers who expect O(1) map lookup; the comment is non-optional.

### 3.9 SIMD via plan9 assembly

Almost never worth authoring. Consider only when the measured CPU win is ≥ 5× over the pure-Go version and a pure-Go `_generic.go` fallback exists. Requires a build-tagged `_amd64.s` + `_arm64.s` pair and a correctness test that runs on both paths.

If you reach this point, the measurement bar justifies the complexity, but plan to maintain two implementations indefinitely.

Measurement type: `-bench` ns/op + `perf stat` instruction-count comparison.

**Legibility cost:** assembly is opaque to most Go contributors; plan9 syntax adds another barrier.

### 3.10 cgo as a last resort

cgo is permitted when: (a) a pure-Go implementation was written, benchmarked, and lost to a well-tuned C library by a margin that matters to production SLOs; and (b) both benchmark results are cited in the PR. Cite the pure-Go numbers, the cgo numbers, and which C library is used. Document the build-dependency in the package comment.

Measurement type: `-bench` ns/op with and without cgo.

**Legibility cost:** cgo breaks cross-compilation, adds a C toolchain dependency, and complicates profiling.

## 4. The `ultra-opt:` comment template (mandatory)

Every ultra-optimization that bends a convention the sibling skills would otherwise enforce **must** carry this comment:

```go
// ultra-opt: <one-line what>.
//   measured: <BenchmarkName> <delta> (<tool>, n=<count>).
//   trade-off: <legibility / portability / contract cost>.
//   assumes:  <platform / kernel / Go version, if applicable>.
```

The literal string `ultra-opt:` is the grep contract. Reviewers audit with:

```sh
grep -rn "ultra-opt:" .
```

No `ultra-opt:` prefix, no merge. A comment that omits `measured:` is rejected — it's not an ultra-opt, it's a hunch.

## 5. Platform-specific fast paths via build tags

The canonical example in this repo is `magus/cache/reflink/`. Study it before authoring a new platform-specific fast path.

**File naming convention** — four-file pattern:

```
feature/
├── feature_linux.go         //go:build linux && (amd64 || arm64)
├── feature_linux_other.go   //go:build linux && !amd64 && !arm64
├── feature_darwin.go        (no explicit tag — filename suffix `_darwin` is the constraint)
├── feature_other.go         //go:build !linux && !darwin
└── feature_test.go          (no tag — platform-agnostic contract test)
```

Rules:

1. **Filename suffix provides the base constraint.** Go recognizes `_GOOS.go` (e.g. `_linux`, `_darwin`) as an implicit build constraint. Use an explicit `//go:build` only when you need arch qualifiers or negations beyond what the filename already expresses.

2. **Arch-qualify fast paths.** If a fast path relies on `int` being 64-bit (or any other arch guarantee), qualify it with `&& (amd64 || arm64)` and provide a same-OS fallback variant (`feature_linux_other.go` with `//go:build linux && !amd64 && !arm64`). See `magus/cache/reflink/clone_linux.go:1` for the pattern and `clone_linux.go:3-6` for the rationale comment.

3. **The catch-all fallback uses explicit negation.** `_other.go` is not a recognized GOOS, so it always needs an explicit `//go:build !linux && !darwin` (enumerating every fast-path platform you handle). See `magus/cache/reflink/clone_other.go`.

4. **Identical public signature across all variants.** Every file in the family must expose the same function with the same signature. Callers never branch. See `func Clone(src, dst string) error` repeated verbatim in all four reflink files.

5. **Tests live in an untagged `_test.go`.** Tests validate the *contract* (does the function do what it promises?), not the syscall path. The same test suite runs on every platform and confirms all variants satisfy the promise. See `magus/cache/reflink/clone_test.go`.

6. **Document OS and kernel minimums** in the package or function doc comment. "Linux ≥ 4.5 (copy_file_range), ≥ 3.1 (io.Copy only)" is the right level of precision.

**Two-file variant** (simpler case — one fast path, one fallback):

```
feature_linux.go     (no explicit tag — filename is sufficient)
feature_other.go     //go:build !linux
```

See `magus/cache/hash_iouring_linux.go` + `magus/cache/hash_iouring_other.go` for a live example.

## 6. Anti-patterns — reject on sight

- **Micro-opt without a checked-in benchmark.** No measurement, no change.
- **"I read that X is faster."** Reject. Benchmark it or drop it.
- **`unsafe.Pointer` cast without a lifetime comment.** Reject. The comment is the proof the cast is safe.
- **Premature `sync.Pool`.** Pool overhead exceeds saved alloc for objects < ~64 B or rarely reused call sites. Measure first; pools are not universally beneficial.
- **Optimizing cold code.** If `pprof` says the function is < 1% of wall-clock CPU, leave it readable. Touching cold code for micro-gains introduces risk with no latency payoff.
- **Loop unrolling without measurement.** The compiler already unrolls loops it can prove safe. Manual unrolling without a profiler result showing the current form is a bottleneck is cargo-cult optimization.
- **Removing `defer` in non-hot functions.** The 1–2 ns `defer` overhead only matters at millions of calls per second. Removing it elsewhere just adds cleanup-path bugs.

## 7. Conflict resolution with sibling skills

When `go-review-style` says "prefer X for legibility" and a measured ultra-opt says otherwise, the ultra-opt wins **iff**:

1. It carries the `ultra-opt:` comment with all four lines.
2. A `BenchmarkX` is checked into the same package.
3. `benchstat` output appears in the PR description.
4. The platform or version assumption is stated.

If any condition is unmet, legibility wins. This is not negotiable.

The same rule applies to `go-review-legibility`: a measured ultra-opt may introduce a legibility cost the legibility skill would otherwise flag, provided the comment fully covers it.

## 8. What this skill does not do

- Doesn't recommend rewriting in another language.
- Doesn't endorse cgo without documented evidence that a pure-Go alternative was written and benchmarked.
- Doesn't run benchmarks itself — the author must provide them.
- Doesn't fire on cold code, test helpers, one-off CLI commands, or anything outside a measured hot path.
- Doesn't auto-invoke during normal review — explicit user request only.
- Doesn't propose platform-specific fast paths for platforms not already present in the repo (no Windows fast paths, no `.s` assembly files, until the repo establishes a pattern for them).

## See also

- `.claude/skills/go-review-style/SKILL.md` — default style and idiom conventions; defer here when not in a measured hot path.
- `.claude/skills/go-review-legibility/SKILL.md` — structural refactors to make correct code visibly correct.
- `magus/cache/reflink/` — canonical four-file build-tag pattern (clone_linux.go, clone_linux_other.go, clone_darwin.go, clone_other.go, clone_test.go).
- `magus/cache/hash_iouring_linux.go` + `hash_iouring_other.go` — canonical two-file build-tag pattern.
