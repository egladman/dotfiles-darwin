---
name: go-review-style
description: Apply Go style and judgment conventions during code review or authoring. Use when reviewing or writing Go in this repo and you need guidance on naming (constructors, types), comment intent (WHY over WHAT), error message style, the variadic-options pattern, when to reach for `errgroup`/`errors.Join`, when interfaces or generics earn their keep, when to use stdlib `slices`/`maps` versus `samber/lo`, and when pointers are warranted versus values. Complements the interface-naming rules already in CLAUDE.md.
model: sonnet
tools: Read, Grep, Glob, Bash
---

Apply these conventions when reviewing or writing Go. They are checks a reviewer should run; not all need to fire on every change.

## 1. Constructor naming

Prefer descriptive constructor names over a bare `New` when the type name alone is ambiguous at the call site. `NewMigrator(db, ver, log)` reads better than `New(db, ver, log)` because a reader scanning unfamiliar code sees what is being constructed without jumping to the import path. `Open(path)` for file-or-DB-style resources is also good — it carries lifecycle meaning the type name doesn't.

Bare `New` is fine when the package name plus a singular primary type makes the call site unambiguous (e.g. `jobs.NewRegistry`, `queue.New`).

References:
- `internal/database/migrate.go:132` — `Open(path string) (*sql.DB, error)`
- `internal/database/migrate.go:158` — `NewMigrator(db, appVersion, logger)`
- `internal/storage/workspace_s3.go:27` — `NewS3Workspace(bucket, prefix, scratchRoot)`

## 2. Comments convey WHY, not WHAT

Default to no comment. Add one only when the reason isn't obvious from the code: a hidden constraint, a non-obvious invariant, a workaround for a specific bug, surprising behavior. Trust the reader. A comment that restates the function name in a sentence is noise — and noise rots faster than code.

Things that earn a comment:
- A correctness-relevant invariant (`// intentionally idempotent`).
- A call-site obligation (`// call this after committing the tx`).
- A workaround for a bug, with a link if there is one.
- An explicit non-goal ("this does *not* validate X — the caller already did").

Things that don't earn a comment:
- Restating the identifier (`// GetUser gets a user`).
- Marking removed code (`// removed in v2`).
- Crediting a refactor or a ticket number.

References:
- `internal/database/migrate.go:39-41` — explains the bootstrap is intentionally idempotent.
- `internal/jobs/queue.go:100-102` — explains the call-site obligation on `Notify`.

## 3. Type names should not repeat the package name

In package `search`, prefer `Query` / `Result` / `Engine` over `SearchQuery` / `SearchResult` / `SearchEngine` — the call site already says `search.Query`. In package `config`, `Cache` is better than `CacheConfig`. The package is the qualifier; doubling it is just stutter.

Exceptions exist when the unqualified name would collide with a standard-library or widely-used type at the call site. Treat these as the exception, not the default.

References:
- `internal/search/engine.go:15,77,89` — `Engine`, `Query`, `Result`.
- `internal/account/account.go:42,56` — `Account`, `Identity` (in package `account`).

## 4. Error messages: lowercase, minimal punctuation

No trailing period, no capitalized first word, no fancy punctuation or symbols. Prefix with the package or subsystem, then the action, then `%w` to wrap a cause. Sentinel errors follow the same shape (`"token expired"`, `"not found"`).

```go
return nil, fmt.Errorf("worker: join: %w", err)
return nil, fmt.Errorf("worker: mkdir certdir: %w", err)
var ErrTokenExpired = errors.New("token expired")
```

References:
- `internal/worker/client.go:78-100` — `worker: <verb>: %w` shape across a function.
- `internal/account/account.go:361-363` — sentinel error declarations.
- `internal/pinboard/store.go:20,24` — `ErrNotFound`, `ErrAlreadyExists`.

## 5. Variadic functional options for optional config

When a constructor or factory takes more than its required arguments, expose extras as `opts ...func(*fooOptions)` rather than ballooning the signature or introducing a public `Config` struct. The options struct stays unexported; each option helper is a small closure that mutates one field.

**Name option helpers with a `With…` prefix.** `WithTapeWidth(15)`, `WithTimeout(5*time.Second)`, `WithLogger(l)`. The prefix reads naturally when callers chain several together and groups options visually at the call site. This mirrors the Dagger Go SDK convention (https://pkg.go.dev/dagger.io/dagger) — `Container().WithExec(...)`, `WithMountedDirectory(...)`, etc. — which is the canonical exemplar in the Go ecosystem.

The pattern keeps zero-config calls clean, lets callers add knobs without breaking signatures, and keeps defaults in one place.

Reference exemplar: `notion/zipper.go:47-86` — `Zipper(name, gauge, length, opts...)` with private `zipperOptions` and `WithTapeWidth`.

```go
type zipperOptions struct {
    tapeWidth float64
}

func WithTapeWidth(mm float64) func(*zipperOptions) {
    return func(o *zipperOptions) { o.tapeWidth = mm }
}

func Zipper(name string, gauge ZipperGauge, length float64, opts ...func(*zipperOptions)) project.Notion {
    o := &zipperOptions{}
    for _, opt := range opts { opt(o) }
    // ...
}
```

## 6. Copy a few lines before extracting a helper

Premature abstraction is a real cost. If two or three call sites share a handful of lines, leave them duplicated until a third or fourth real caller actually appears. Be honest about whether the helper would get reused, or whether you're designing for a hypothetical future. Speculative shared code accretes parameters, ages badly, and is harder to delete than a few duplicated lines. Three similar lines in two files beats a one-call abstraction with a `bool` flag.

When a refactor proposal adds a helper used in exactly one place "for clarity", push back. Inline it.

## 7. `errgroup` and `errors.Join`

Two distinct tools; reach for either when the parallelism (or independence) is the point, not as a default. Both have a real cost: stack traces and inline `if err != nil` are easier to read than centralized aggregation, and the error check moves away from the line that produced it.

**`errgroup`** is for parallel fan-out over N independent operations that all return errors. The win is centralized cancellation (`gctx`) and first-error propagation. The honest tradeoff: the error check moves from each goroutine's `func() error` body to the eventual `g.Wait()`, which can make a single failure harder to trace at the producing line. The tradeoff is worth it when N is variable or large; less so for two sequential operations where ordinary `if err != nil` is clearer.

References:
- `magus/cache/cache.go:435` — `errgroup.WithContext(ctx)` for rate-limited spec processing across N inputs.
- `magus/cache/hash.go:137` — `errgroup.WithContext(...)` for parallel hash computation.
- `internal/apiserver/serve.go:119` — graceful shutdown orchestration with `errgroup.WithContext(ctx)`.
- `magus/cache/cache.go:739` — hand-rolled `sync.WaitGroup`. A reasonable candidate to convert if the file is touched for other reasons; don't refactor it standalone.

**`errors.Join`** is for collecting independent errors from operations that should *not* short-circuit — typically validators that should report every problem at once, or teardowns that should attempt every cleanup before returning. Don't use it sequentially when the first error should abort: that's just `if err != nil { return err }`.

References:
- `api/config/v1alpha1/validate.go` — validation error aggregation.
- `magus/observability/provider_otel.go` — OTel provider teardown.
- `magus/register.go` — registration error aggregation.

## 8. Interfaces — when they earn their keep

Default to concrete types. Introduce an interface when at least one of:

1. **Two or more real implementations exist or are imminent.** "Two real" means in production code — tests-only fakes don't count. If only one implementation exists and you don't have a second on the near horizon, the interface is speculative and should wait.
2. **The consumer needs a narrower view than the producer offers.** Declare a small interface at the *consumer* with only the methods it actually calls; let the concrete type from elsewhere satisfy it implicitly. This is the canonical Go move and is documented in `CLAUDE.md`'s interface-naming section. Example: `internal/account/native/native.go:41-44` declares `credStore` with the two methods it needs, even though the source `account.Store` has many more.
3. **A true plugin contract.** Multi-method interfaces are justified when they describe a backend boundary — see `internal/search/engine.go:15-48` (`Engine` with 9 methods, postgres impl today, room for Typesense/Meilisearch).

Single-method interfaces (Go's `-er` convention) are the cheapest move and almost always pull their weight when used: `geometry/shape_iface.go:5-8` (`Shape`, six implementations).

Anti-patterns to flag in review:

- Interface with one implementation and a test fake. The test fake is not a justification; pass a concrete struct or use a constructor that takes the dependency directly.
- Interface declared at the *producer* package, exporting every method. Prefer narrow consumer-declared interfaces — they don't force the producer to be stable.
- Interface with no callers that route through it polymorphically — every call site already knows the concrete type. Inline it.

## 9. Generics — when they earn their keep

Default to concrete types or `any` with a typed wrapper. Reach for generics when:

1. **The same function is called with two or more concrete type arguments in production code.** Examples: `internal/apiserver/api/client/client.go` `decodeResp[T any]` and `internal/studio/server/dispatch.go` `decodeArg[T any]` — both unmarshal into many distinct response/arg types and would otherwise need per-type duplication or unsafe `any`.
2. **You're writing a true container or algorithm.** A generic `LRU[K comparable, V any]` or `Set[T comparable]` is fine — the type parameter does real work. A generic `Process[T any](x T)` that ignores `T` is ceremony.
3. **The alternative is `any` plus a type assertion at every call site.** Generics replace the assertions with compile-time checks; that's a real win.

Don't reach for generics when:

- The function has one caller with one concrete type. `project/registry_keys.go` `sortedKinds[V any]` is invoked with one concrete type — the generic adds no safety. Test helpers like `ptr[T any]` are fine but not exemplars to imitate.
- A typed wrapper would make the API safer at the same cost. The repo's `pinboard.PatternID`, `tenant.TenantID`, `tenant.AccountID` are good examples — typed `string`s, not `Generic[T]`s, that prevent ID-mixing at the type level without the cognitive overhead of type parameters.

Generics earn their keep when they remove duplication or runtime assertions; they don't earn their keep just by existing.

## 10. stdlib `slices`/`maps` first; `samber/lo` for what stdlib doesn't have

The repo already standardizes on stdlib `slices` (no `golang.org/x/exp/slices`). Maintain that — for `Sort`, `SortFunc`, `Contains`, `Equal`, `Index`, `BinarySearch`, `IsSorted`, `Reverse`, `Clone`, `Concat`, etc., use `slices.*`. Same for stdlib `maps` (`maps.Keys`, `maps.Values`, `maps.Clone`, `maps.Copy`).

Reach for `samber/lo` (already a dependency, ~8 imports across `geometry`, `nester`, `magus`, `exporter`, `pattern`, `document`, `handler`) when stdlib doesn't cover the operation:

- `lo.Filter`, `lo.Map`, `lo.Reduce`, `lo.GroupBy`, `lo.Partition` — stdlib `slices` has no `Map`/`Filter`/`Reduce`, so these are the right call. Example: `nester/bottomleft.go` uses `lo.Filter` to narrow patterns.
- `lo.Uniq`, `lo.UniqBy`, `lo.Chunk`, `lo.Flatten` — also missing from stdlib.

Don't use `lo` when stdlib has the equivalent:

- `lo.Contains` → `slices.Contains`
- `lo.IndexOf` → `slices.Index`
- `lo.Sort`, `lo.OrderBy` → `slices.Sort`, `slices.SortFunc`
- `lo.Reverse` → `slices.Reverse`
- `lo.Keys`/`lo.Values` (over a map) → `maps.Keys`/`maps.Values` (stdlib returns iterators in 1.23+; `slices.Collect` adapts).

Mixing both packages in one file is fine — pick stdlib first, fall back to `lo` only for what stdlib lacks.

## 11. Pointers — KISS by default

Default to values. Pointers are technically more complex than values: they introduce `nil` to the type, complicate ownership, and can hide aliasing bugs. Copying a small struct is cheap; the cost rarely shows up in a profile.

Reach for a pointer when one of these is true:

1. **You need to distinguish "absent" from "zero value."** A `*int` lets you tell apart "the user didn't set it" from "the user set it to 0"; a plain `int` cannot. Same for `*bool`, `*time.Time`, optional config fields decoded from JSON. If the zero value is a meaningful answer, don't use a pointer.
2. **The type is a long-lived handle or client.** HTTP/gRPC/DB clients, queues, registries usually carry connection state, mutexes, or background goroutines and must not be copied. A pointer receiver and pointer construction (`*Client`) is the right shape. References: `internal/apiserver/api/client/client.go` (`*Client`), `internal/jobs/queue.go` (`*Queue`), `internal/database/migrate.go` (`*Migrator`).
3. **Mutation needs to be visible to the caller.** A method that mutates the receiver (`*T`) or a function that fills out a passed-in struct needs a pointer. Pure transforms that return a new value can stay on a value receiver.
4. **Profiling says the copy hurts.** If a struct is large and copied on a hot path, switch to a pointer. Don't preempt this — let the profiler decide. The hyper-optimized loops in `magus/cache` are the rare place this matters in this repo; almost everywhere else, KISS wins.

Anti-patterns to flag in review:

- `*string`, `*int`, `*bool` on internal types where the zero value would be a perfectly fine sentinel. Adds nil-handling for no benefit.
- Pointer receiver on a small immutable value type for "consistency" — `image.Point` and `time.Time` are values for a reason.
- Inconsistent receiver kinds on the same type (some methods on `T`, some on `*T`). Pick one.
- Returning `*T` from a constructor "to make it cheap" when `T` is two ints. The escape-to-heap cost dwarfs the copy.

When in doubt, start with a value type. Switching to a pointer later is a mechanical change; switching from a pointer back to a value usually isn't.

## See also

`CLAUDE.md` covers the Go interface naming convention (`-er` for single-method, domain noun for multi-method aggregates) and the frontend ellipsis rule. This skill does not duplicate either; refer to `CLAUDE.md` directly for those.
