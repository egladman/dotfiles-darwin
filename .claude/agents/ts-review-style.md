---
name: ts-review-style
description: Use when reviewing or writing TypeScript and you need guidance on constructor naming vs factory functions, JSDoc comment intent (WHY not WHAT), module stutter, error messages and Error subclasses, options-object pattern, when to extract helpers, Promise concurrency primitives, when interfaces and generics earn their keep, native Array/Map/Object vs lodash, nullability conventions, any vs unknown, type assertion avoidance, non-null assertion avoidance, discriminated unions for state, readonly defaults, enum vs const-union, or the satisfies operator.
model: sonnet
tools: Read, Grep, Glob, Bash
---

Apply these conventions when reviewing or writing TypeScript. They are checks a reviewer should run; not all need to fire on every change.

## 1. Constructor naming

`new ClassName()` is fine when the class name alone disambiguates what is being constructed. Factory functions (`createThing()`, `openConnection()`) earn their keep when:

- Construction is async (you can't `await new X()` in most contexts).
- The concrete class should be hidden behind an interface return type.
- The factory branches on input to return different subtypes.

`create` prefix is the idiomatic factory name. `open` works for file-or-connection-style resources because it carries lifecycle meaning the class name doesn't.

Anti-patterns to flag:
- `new UserFactory()`: "Factory" in a class name usually means a factory function would be cleaner.
- A constructor that does async work via a `.init()` method callers must remember to call. Hoist it into a `createX()` factory.

## 2. Comments convey WHY, not WHAT

Default to no comment. Add one only when the reason isn't obvious from the code: a hidden constraint, a non-obvious invariant, a workaround for a specific bug, surprising behavior.

Things that earn a comment:
- A correctness-relevant invariant (`// intentionally idempotent`).
- A call-site obligation (`// must be called after the transaction commits`).
- A workaround for a known bug, with a link.
- An explicit non-goal ("this does *not* validate X; the caller already did").
- A `// eslint-disable-next-line` **must** explain WHY the suppression is needed; a bare disable is a smell.

Things that don't earn a comment:
- Restating the identifier (`/** Gets the user. */` on `getUser()`).
- Marking removed code (`// removed in v2`).
- Crediting a refactor or a ticket number.

JSDoc on exported functions: include a description only when name + types leave genuine ambiguity. Don't write `@param` tags that restate the parameter name.

## 3. Type names and module stutter

Most TypeScript imports are named (`import { AuthService } from '@app/auth'`) so the file path doesn't appear at the call site. Stutter is less load-bearing than in Go.

Flag stutter when a namespace import or barrel forces the qualifier into the call site:

```ts
// stutter: auth.AuthService
import * as auth from '@app/auth';
const svc = new auth.AuthService();

// clean
const svc = new auth.Service();
```

With named imports (`import { Service } from '@app/auth'`), `AuthService` vs `Service` is a style choice. Prefer the shorter unqualified name when the module already qualifies it.

## 4. Error messages: lowercase, no trailing period

Keep error messages lowercase, no trailing period. Prefix with the subsystem, then wrap the cause.

```ts
// good
throw new Error(`worker: join: ${cause.message}`);

// better: preserve the cause chain (Node 16.9+, TS 4.6+)
throw new Error('worker: join', { cause });

// sentinel error
export class TokenExpiredError extends Error {
  constructor() { super('token expired'); this.name = 'TokenExpiredError'; }
}
```

Prefer `Error` subclasses over raw `new Error(string)` for errors callers need to distinguish. `instanceof` is more reliable than string matching. Always set `this.name` in the constructor.

Source: *Effective TypeScript* Item 58; Node.js `Error` docs.

## 5. Options object for optional config

The TypeScript idiom for optional parameters is an options object, not variadic closures.

```ts
// good
function createClient(baseUrl: string, opts: ClientOptions = {}): Client

// bad: positional optional params become order-sensitive
function createClient(baseUrl: string, timeout?: number, retries?: number, logger?: Logger)
```

Name the type `<Thing>Options`; export it so callers can construct it. Use `Partial<Options>` when all fields are optional.

Anti-patterns to flag:
- A `boolean` flag as a positional argument: `send(msg, true)`. Use a named option: `send(msg, { retry: true })`.
- More than three positional parameters on a public function. Introduce an options object.

## 6. Copy a few lines before extracting a helper

Premature abstraction is a real cost. Leave duplicated lines until a third or fourth real caller actually appears.

Three similar lines in two files beats a one-call abstraction with a `boolean` flag.

TypeScript-specific smells:
- Extracting a one-liner to avoid a `?.` chain. `getUser()?.profile?.name` doesn't need a helper.
- A helper whose name describes exactly what the single caller does. That's indirection, not reuse.

## 7. Promise concurrency primitives

**`Promise.all`**: fail-fast fan-out. All N operations must succeed; cancel on first failure.

```ts
const [users, orders] = await Promise.all([fetchUsers(), fetchOrders()]);
```

**`Promise.allSettled`**: collect all outcomes before continuing. The `errors.Join` analog for async. Use for teardowns, validators that should report every problem, or operations where you want all results regardless of individual failures.

```ts
const results = await Promise.allSettled(items.map(process));
const errors = results.filter(r => r.status === 'rejected');
```

**`AggregateError`**: thrown by `Promise.any` when all promises reject. Inspect `err.errors[]` for individual causes.

Default to sequential `await` for 1-2 operations. It reads clearly and errors stay at their source. Reach for `Promise.all` when N > 2 or when latency matters.

Anti-pattern: floating `Promise.all` in a `void` function with no `.catch`. Attach an error handler or `await` it.

## 8. Interfaces: when they earn their keep

Default to concrete types. Introduce an interface when at least one of:

1. **Two or more real production implementations exist or are imminent.** A test double is not a second implementation. `vitest-mock-extended` generates doubles from concrete classes without requiring an interface.
2. **The consumer needs a narrower view than the producer offers.** Declare a small interface at the *consumer* with only the methods it calls; let the concrete class satisfy it implicitly via structural typing.
3. **A true plugin contract**: a boundary that external code must satisfy.

`type` alias vs `interface`: use `interface` for object shapes that may be extended; use `type` for unions, intersections, and computed shapes.

Anti-patterns:
- `IService` / `ServiceImpl`: `I` prefix and `Impl` suffix signal a single-implementation interface. Remove the interface; pass the concrete class.
- Interface created solely "so we can mock it". `vitest-mock-extended` mocks concrete classes directly.
- Interface declared at the producer exporting every method. Prefer narrow consumer-declared interfaces.

Source: TypeScript handbook "Interfaces vs Type Aliases"; *Effective TypeScript* Item 13.

## 9. Generics: when they earn their keep

Default to concrete types. Reach for generics when:

1. **The same function is called with ≥ 2 concrete type arguments in production code.**
2. **Writing a true container or algorithm.** `Cache<K, V>`, `Result<T, E>`, `paginate<T>`: the type parameter does real work.
3. **The alternative is `any` plus a type assertion at every call site.**

TypeScript-specific:
- Mapped types (`Partial<T>`, `Pick<T, K>`) earn their keep when they solve a real distribution problem. Don't write a mapped type for one call site; write the concrete shape.
- Conditional types (`T extends U ? A : B`) are powerful but surprise readers. Only reach for them when a simpler overload or union won't work.
- `type Nullable<T> = T | null` called once is just `T | null` inline. Don't add an alias.

Source: TypeScript handbook "Generics"; *Effective TypeScript* Items 14-16.

## 10. Native first; library for what's missing

Native `Array`, `Map`, `Set`, and `Object` methods cover most operations. Use them first.

**Reach for lodash / remeda when native is missing:** `groupBy`, `partition`, `chunk`, `zip`, `uniq`, `uniqBy`, deep clone, deep equal, `debounce`, `throttle`.

**Flag lodash where native works:**
- `_.get(obj, 'a.b.c')` → `obj.a?.b?.c` (optional chaining).
- `_.isNil(x)` → `x == null`.
- `_.isEmpty(arr)` → `arr.length === 0`.
- `_.cloneDeep` → `structuredClone` (Node 17+).

Lodash/fp and Ramda implicit currying surprises readers unfamiliar with point-free style. Prefer explicit arrow functions unless the team is fluent.

## 11. Optionality and nullability: KISS

**`x?: T`**: property may be absent entirely. Prefer for optional config fields.

**`x: T | undefined`**: property is present in the shape but value may be `undefined`. Use when the distinction matters (serialization, `Object.keys`).

**`T | null`**: explicit sentinel. Use when the distinction from `undefined` is meaningful (DB rows, JSON payloads).

Pick one convention per project for "no value." Don't mix `null` and `undefined` for the same role in the same module.

Anti-patterns:
- `x: T | null | undefined`: double-optional. Pick one.
- `x?: string | null` on an internal type where `x?: string` suffices.

## 12. `any` vs `unknown`

`any` disables type checking entirely and infects callers. `unknown` defers checking: you must narrow before use.

```ts
// bad: JSON.parse returns any — infection spreads
const data = JSON.parse(raw);
data.user.name; // no error, may blow up at runtime

// good: narrow at the boundary
const data: unknown = JSON.parse(raw);
const result = UserSchema.parse(data); // throws on invalid shape
```

When you must use `any` (third-party library with poor types): contain it in a single adapter function; don't let it spread.

Enable `useUnknownInCatchVariables` (TypeScript 4.4+) so `catch (e)` variables are `unknown` by default.

Source: TypeScript handbook "Unknown"; typescript-eslint `no-explicit-any`.

## 13. Type assertions (`as`) avoidance

Every `as X` is a claim the type checker cannot verify.

Replace with:
- Type predicates: `function isUser(x: unknown): x is User { ... }`
- Schema validation: `UserSchema.parse(data)` (Zod) throws on mismatch.
- `instanceof`: `if (err instanceof TokenExpiredError)`

`as const` is the canonical exception. It narrows to literal types; it does not widen.

`as unknown as T` double-assertion always compiles and is almost always wrong. It signals the types are fighting you; fix the types.

When you genuinely must assert, add a comment explaining WHY it's safe:

```ts
// The #root element is always a div — guaranteed by the HTML template
const root = document.getElementById('root') as HTMLDivElement;
```

Source: *Effective TypeScript* Item 9; typescript-eslint `no-unsafe-type-assertion`.

## 14. Non-null assertion (`!`) avoidance

`x!` tells the compiler "not null/undefined at runtime." No runtime check occurs.

```ts
// bad: TypeError if getUser() returns undefined
const name = getUser()!.profile.name;

// good: explicit guard
const user = getUser();
if (!user) throw new Error('user not found');
const name = user.profile.name;
```

Replace `!` with explicit guards, early returns, or branded types that encode "non-null" in the type itself.

Acceptable in test setup after explicit fixture construction (`const el = document.getElementById('root')!`).

Source: *Effective TypeScript* Item 9; typescript-eslint `no-non-null-assertion`.

## 15. Discriminated unions for state

Model mutually exclusive states as a union with a literal discriminant field, not a flag-bag struct.

```ts
// bad: which combinations are legal?
type State = { loading: boolean; data?: User; error?: Error };

// good: each state is explicit; TypeScript narrows correctly
type State =
  | { status: 'loading' }
  | { status: 'ready'; data: User }
  | { status: 'error'; error: Error };
```

The discriminant enables exhaustive `switch` with compile-time exhaustiveness checking.

Apply to: async loading state, step-machine state, API response shapes, multi-variant command results.

Source: TypeScript handbook "Discriminated Unions"; *Effective TypeScript* Item 28.

## 16. `readonly` and immutability defaults

Mark function parameters `readonly T[]` when the function doesn't mutate:

```ts
function sum(values: readonly number[]): number {
  return values.reduce((a, b) => a + b, 0);
}
```

Use `as const` for literal config objects to preserve literal types:

```ts
const ROLES = ['admin', 'viewer', 'auditor'] as const;
type Role = typeof ROLES[number]; // 'admin' | 'viewer' | 'auditor'
```

Apply `Readonly<T>` on shared state passed across module boundaries.

Don't apply `readonly` everywhere. On internal implementation details it adds noise. Apply at public APIs and module boundaries.

Source: TypeScript handbook "Readonly"; *Effective TypeScript* Item 17.

## 17. Enum vs const-union vs `as const` object

Native `enum` compiles to a runtime object and produces reverse mappings that surprise callers.

```ts
// avoid: runtime cost; reverse mapping is unexpected
enum Status { Pending = 'pending', Active = 'active' }

// prefer: zero runtime cost; works with exhaustive switch
type Status = 'pending' | 'active' | 'closed';

// use when you need runtime iteration over the values
const Status = { Pending: 'pending', Active: 'active', Closed: 'closed' } as const;
type Status = typeof Status[keyof typeof Status];
```

Prefer const-union for simple sets. Use `as const` object when you need runtime iteration. Avoid numeric enums; they allow any number at the call site.

Source: *Effective TypeScript* Item 40; TypeScript handbook "Enums".

## 18. `satisfies` for config

`satisfies` validates a literal against a type WITHOUT widening it. You keep precise literal types.

```ts
// annotation widens: cfg.theme is string, not 'dark'
const cfg: Config = { theme: 'dark', retries: 3 };

// satisfies: cfg.theme is still 'dark'; Config shape is validated
const cfg = { theme: 'dark', retries: 3 } satisfies Config;
```

Use when you need the narrow literal types (e.g., as a discriminant or for mapped-type inference). Don't use when a plain type annotation gives you everything you need.

Source: TypeScript 4.9 release notes ("The `satisfies` operator").

## 19. Exhaustive branching on unions

When branching on a union type where correctness depends on handling every variant, prefer exhaustive matching over manual `if`/`in` checks. The goal: the compiler fails when a new variant is added without a branch.

`ts-pattern` with `.exhaustive()` is one way. A `switch` on a discriminant with a `never` default is another. The point is compile-time exhaustiveness, not a specific library.

```ts
// bad: adding a variant silently falls through
if ('accessKeyId' in config) { ... }
else { ... }

// good: compiler catches missing variants
match(config)
    .with({ accessKeyId: P.string }, (c) => /* ... */)
    .with({ roleArn: P.string }, (c) => /* ... */)
    .exhaustive();
```

Don't reach for exhaustive matching on simple boolean checks or single-branch guards.

## 20. Parse at trust boundaries, not assert

Use schema validation (Zod `parse`, class-validator, etc.) when data crosses a trust boundary: external API responses, workflow inputs, queue messages, config files. Type assertions (`as`) compile away and trust the runtime blindly.

```ts
// bad: upstream schema change is invisible
const config = response.data as unknown as ExportConfig;

// good: fails fast with a clear error
const config = ExportConfigSchema.parse(response.data);
```

Derive the TypeScript type from the schema (`z.infer<typeof Schema>`) so the type and validation stay in sync. Use `.default()` on schema fields to push fallback logic into the parse step and out of the function body.

## 21. Test mocking: `vitest-mock-extended` over `vi.fn()`

Prefer `mock<ClassName>()` from `vitest-mock-extended` over manually declaring `vi.fn()` variables. The mock signatures are type-checked, and the setup is a single object literal instead of decomposed function stubs.

```ts
// bad: untyped, verbose
let getConfig: ReturnType<typeof vi.fn>;
let copyReport: ReturnType<typeof vi.fn>;
beforeEach(() => {
    getConfig = vi.fn();
    copyReport = vi.fn().mockResolvedValue('key');
});

// good: typed, compact
let activities: MockProxy<ExportActivities>;
beforeEach(() => {
    activities = mock<ExportActivities>({
        getConfig: vi.fn(),
        copyReport: vi.fn().mockResolvedValue('key'),
    });
});
```

When passing mocks to a framework that expects plain functions (e.g., Temporal `Worker.create({ activities })`), destructure: `{ copyReport: activities.copyReport }`.

## See also

Project-specific conventions in `CLAUDE.md` and `AGENTS.md` take precedence over this skill.

- **ts-review-skeptic**: bug hunt (Promise hazards, type escapes, memory leaks) and deletion sweep.
- **ts-review-nit**: nit the exported API surface (naming, missing `AbortSignal`, return shapes).
- **ts-review-legibility**: turn false-positive findings into structural refactors.
- **ts-review-ultra**: fan-out; runs style + nit + skeptic in parallel and merges the findings.
- **ts-review-optimize**: measured performance wins (V8 hot paths); invoke explicitly only.
