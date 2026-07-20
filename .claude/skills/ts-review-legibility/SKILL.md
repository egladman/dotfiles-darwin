---
name: ts-review-legibility
description: Use when you have a list of TypeScript code-review findings already inspected and judged false positives, and want recommendations for how to restructure the code so future reviewers don't misread it. Produces a per-finding refactor sketch plus cross-cutting moves and a priority table. Does not write code or re-review for new bugs.
---

Turn a list of inspected-and-rejected review findings into a punch list of structural refactors that make the underlying invariants visible at the call site.

## Principle

A false-positive review finding is signal, not noise. The code is correct, but its correctness depends on a hidden invariant (a precondition the caller must satisfy, an ordering between calls, a non-obvious type guarantee, an implicit lifetime) that the reviewer couldn't see from the line they were reading. When that happens, the bug isn't in the reviewer; it's in the code's legibility. Fix the code so the next reviewer doesn't have to chase the same ghost.

The output of this skill is a set of *refactor proposals*, not bug fixes. Every proposal must preserve current behavior while making intent visible at the point a reviewer first encounters it.

## Input

Expect the user to provide:

1. A list of review findings. Each finding has:
   - A file path and line range.
   - A short description of what the reviewer thought was wrong.
   - A confirmation that this was inspected and is actually fine ("false positive").
2. Optionally, the user's own one-line guess at *why* the reviewer was confused.

If any of these are missing, ask for them before producing recommendations. Do not invent findings; do not re-review the code looking for new issues.

## Output

For each finding, produce:

- **Why the reviewer was misled.** One or two sentences naming the hidden invariant.
- **Refactor sketch.** Concrete code-level move: a rename, a type introduction, a parameter reorder, a constructor split, a branded type. Show the smallest patch that makes the invariant visible. Reference the file path and line range.
- **What it costs.** Anything the move sacrifices (a wider API surface, a churned test fixture, a small allocation). Be honest.

After the per-finding section, surface:

- **Cross-cutting moves.** If two or more findings point at the same root cause (e.g., several `boolean` parameters that should each become a named option), collapse them into one shared refactor.
- **Priority table.** Rank proposals by `legibility-gain ÷ effort`. Small table with columns: *Refactor*, *Files touched*, *Reviewers helped (count of findings)*, *Effort (S/M/L)*, *Recommended order*.

## Refactor patterns to reach for

Pick the one that fits; don't ladder through them.

1. **Rename to lift the precondition.** `process(b: Buffer)` → `processUtf8(b: Buffer)` when the function only accepts UTF-8. The type stays `Buffer`; the name now warns the caller.

2. **Introduce a branded type for an opaque scalar.** `string` → `type UserId = string & { readonly __brand: 'UserId' }`. Costs an explicit cast at the boundary; pays for itself when call sites read `removeUser(id)` instead of `removeUser(s)`.

   ```ts
   type UserId = string & { readonly __brand: 'UserId' };
   function toUserId(s: string): UserId { return s as UserId; }
   ```

3. **Split a multi-mode constructor / factory.** `new Store(mode: 'ro' | 'rw', …)` → `Store.readOnly(…)` and `Store.readWrite(…)`. Removes a runtime branch from the call site's mental model.

4. **Replace a `boolean` parameter with a named option.** `send(msg, true)` → `send(msg, { retry: true })` or `send(msg, { mode: 'retry' })`. The call site reads as English; the reviewer doesn't have to remember which `boolean` is which.

5. **Narrow the type at the parameter.** A function that only reads from a store shouldn't take the full `Store`; it should take `Pick<Store, 'get' | 'list'>` or a small interface declared at the consumer.

   ```ts
   // instead of: function render(store: UserStore)
   interface Readable { get(id: string): User | undefined }
   function render(store: Readable)
   ```

6. **Hoist an invariant into a constructor / factory.** If every caller has to `obj.setX(); obj.validate()` before use, move both into `createX(…)` and make the zero-value unusable.

7. **Move the comment into the type system.** `// must not be null` on a parameter → change the type to remove `null` from the union, or split into a method on a non-null receiver. Comments rot; types don't.

8. **Extract a sentinel `Error` subclass.** Reviewers flag `err.message === 'token expired'`; promote to `if (err instanceof TokenExpiredError)`. The call site says what it means.

   ```ts
   export class TokenExpiredError extends Error {
     constructor() { super('token expired'); this.name = 'TokenExpiredError'; }
   }
   ```

9. **Order parameters by lifetime.** `signal` last (idiomatic in most Node/Web APIs), required args first, optional args last. Reviewers learn to scan in that order; deviations look suspicious.

10. **Return a token type to encode ordering.** If two methods must be called in sequence, have the first return a token the second requires:

    ```ts
    type Connected = { readonly __brand: 'Connected' };
    function connect(): Promise<Connected>
    function query(conn: Connected, sql: string): Promise<Row[]>
    ```

    The type system enforces the ordering; reviewers can see it without reading the implementation.

## Quality bar

A proposal is good when:
- A reviewer reading only the *new* call site (not the implementation) would not flag the original finding.
- The refactor changes naming, types, or shape, not behavior. Tests should pass without modification (or with mechanical renames).
- The cost section names a real downside. If you can't think of one, the proposal is probably either trivial or not actually a refactor.

A proposal is suspect when:
- It adds a comment to fix a legibility problem. Comments rot; types don't.
- It introduces a new abstraction with one caller. Wait for the second.
- It "fixes" a finding the user labelled as opinion. Style preferences aren't legibility bugs.

## Format for findings

When the user pastes findings, normalise each one into:

```
### F<n>: <one-line summary>
- file:    src/foo/bar.ts:120-128
- thought: <reviewer's misreading, paraphrased>
- actual:  <why the code is correct>
- hidden:  <the invariant the reviewer couldn't see>
- move:    <refactor sketch with file references>
- cost:    <honest tradeoff>
```

Keep each finding under ten lines. Put the priority table at the end, after the per-finding entries and any cross-cutting moves.

## What this skill does not do

- Re-review code looking for new issues. The findings list is the input; treat it as closed.
- Argue with the user's "false positive" classification. If they say it was inspected and is fine, take that as given.
- Implement the refactors. Output is proposals; the user decides what to apply.
- Touch behavior. If a proposal would change runtime semantics, surface the conflict and stop.
