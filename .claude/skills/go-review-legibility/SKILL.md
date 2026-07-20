---
name: go-review-legibility
description: Convert false-positive Go review findings into structural refactors that lift hidden invariants into the call site's view. Use when the user provides a list of code-review findings already inspected and judged false positives, and wants recommendations for how to restructure the code so future reviewers (human or AI) don't misread it. Produces a per-finding refactor sketch plus cross-cutting moves and a priority table.
---

Turn a list of inspected-and-rejected review findings into a punch list of structural refactors that make the underlying invariants visible at the call site.

## Principle

A false-positive review finding is signal, not noise. The code is correct, but its correctness depends on a hidden invariant — a precondition the caller must satisfy, an ordering between calls, a non-obvious type guarantee, an implicit lifetime — that the reviewer (human or LLM) couldn't see from the line they were reading. When that happens, the bug isn't in the reviewer; it's in the code's legibility. Fix the code so the next reviewer doesn't have to chase the same ghost.

The output of this skill is a set of *refactor proposals* — not bug fixes. Every proposal must preserve current behavior while making intent visible at the point a reviewer first encounters it.

## Input

Expect the user to provide:

1. A list of review findings. Each finding has:
   - A file path and line range.
   - A short description of what the reviewer thought was wrong.
   - A confirmation that this was inspected and is actually fine ("false positive").
2. Optionally, the user's own one-line guess at *why* the reviewer was confused.

If any of these are missing, ask for them before producing recommendations. Do not invent findings; do not re-review the code looking for new issues. The skill's job is to take the list as given and propose structural moves.

## Output

For each finding, produce:

- **Why the reviewer was misled.** One or two sentences naming the hidden invariant.
- **Refactor sketch.** Concrete code-level move — a rename, a type introduction, a parameter reorder, a constructor split, a constant extraction. Show the smallest patch that makes the invariant visible. Reference the file path and line range.
- **What it costs.** Anything the move sacrifices (a small allocation, a wider API surface, a churned test fixture). Be honest.

After the per-finding section, surface:

- **Cross-cutting moves.** If two or more findings point at the same root cause (e.g. several `bool` parameters that should each become a typed option), collapse them into one shared refactor.
- **Priority table.** Rank the proposed refactors by `legibility-gain ÷ effort`. Use a small table with columns: *Refactor*, *Files touched*, *Reviewers helped (count of findings)*, *Effort (S/M/L)*, *Recommended order*.

## Refactor patterns to reach for

These are the moves that most often make a hidden invariant legible. Pick the one that fits; don't ladder through them.

1. **Rename to lift the precondition.** `Process(b []byte)` → `ProcessUTF8(b []byte)` when the function only accepts UTF-8. The type stays `[]byte`; the name now warns the caller.
2. **Introduce a typed wrapper for an opaque scalar.** `string` → `PatternID` (see `internal/pinboard/store.go:30`). Costs a conversion at the boundary; pays for itself when the call site shows `RemovePattern(pid)` instead of `RemovePattern(s)`.
3. **Split a multi-mode constructor.** One `New(mode int, …)` → `NewReadOnly(…)` + `NewReadWrite(…)`. Removes a runtime branch from the call site's mental model.
4. **Replace a `bool` parameter with a named option.** `Send(ctx, msg, true)` → `Send(ctx, msg, WithRetry())`. The call site reads as English; the reviewer doesn't have to remember which `bool` is which.
5. **Narrow the interface at the parameter.** A function that only `Read`s shouldn't take a `*Store`; it should take `interface { Get(id) … }`. Smaller types make the obligation visible.
6. **Hoist an invariant into a constructor.** If every caller has to `obj.SetX(); obj.Validate()` before use, move both into `New…()` and make the zero value unusable.
7. **Move the comment into the type system.** A `// must not be nil` doc on a parameter is a code smell — change the type to a non-nil-by-construction wrapper, or split into a method on a non-nil receiver.
8. **Extract a sentinel error.** Reviewers flag `errors.Is(err, somethingThatLooksWrong)`; promote the inline check to a named `var ErrThing = errors.New("thing")` and the call site says what it means.
9. **Order parameters by lifetime.** `ctx` first, dependencies next, request data last. Reviewers learn to scan in that order; deviations look suspicious even when they aren't.
10. **Make the receiver own the rule.** If two methods must be called in order, collapse them into one that runs both — or have the second take a token returned by the first, so the type system enforces the ordering.

## Quality bar

A proposal is good when:

- A reviewer reading only the *new* call site (not the implementation) would not flag the original finding.
- The refactor changes naming, types, or shape — not behavior. Tests should pass without modification (or with mechanical renames).
- The cost section names a real downside. If you can't think of one, the proposal is probably either trivial or not actually a refactor.

A proposal is suspect when:

- It adds a comment to fix a legibility problem. Comments rot; types don't.
- It introduces a new abstraction with one caller. Wait for the second.
- It "fixes" a finding that the user labelled as opinion (e.g. "reviewer prefers shorter names"). Style preferences aren't legibility bugs.

## Format for findings

When the user pastes findings, normalise each one into:

```
### F<n>: <one-line summary>
- file:    internal/foo/bar.go:120-128
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
