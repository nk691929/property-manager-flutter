# Interview Q&A

## Architecture

**[Easy] What is Clean Architecture?**
A way to organize code in layers so business rules don't depend on frameworks.
Domain (entities, use cases, repository interfaces) sits at the center; data and
presentation depend on it, never the reverse.

**[Medium] Why define a repository interface in domain but implement it in data?**
Dependency inversion. Use cases depend on an abstraction they own, so the backend
(Supabase, REST, a fake) can change without touching business logic, and tests
can inject a mock.

**[Medium] Feature-first vs layer-first structure?**
Layer-first scatters one feature across many folders. Feature-first keeps
everything for a feature together: easier ownership, deletion and scaling. Shared
code goes in `core/`.

**[Hard] Is a use case that just forwards to a repository worth it?**
Debatable. It costs a file and buys a consistent seam where permission checks,
validation and orchestration land as the app grows. In a tiny app, skip it. In an
app with roles and multi-repository operations, it pays for itself.

## Error handling

**[Medium] Why return `Result<T>` instead of throwing?**
Failures become part of the signature, and sealed classes make handling
exhaustive at compile time. Exceptions are invisible in signatures and easy to
forget. Trade-off: some ceremony.

**[Hard] Where should exceptions be caught?**
At layer boundaries. Backend data sources translate SDK exceptions into typed
`Failure`s; repositories wrap calls in `runCatching`. Truly unexpected errors go
to global handlers (`FlutterError.onError`, `PlatformDispatcher.onError`).

**[Medium] Why not store user-facing messages inside `Failure`?**
Failures live below the UI and can't know the locale. They carry a type; the
presentation layer maps it to localized text with an exhaustive `switch`.

**[Hard] Why did adding `InvalidCredentialsFailure` force a UI edit?**
`Failure` is sealed and `FailureMessage` uses an exhaustive `switch`, so the
compiler refuses to build until the new case has a message.

**[Medium] Why override `name` instead of using `runtimeType.toString()`?**
Under `--obfuscate`, runtime type names are mangled. An explicit (abstract) `name`
is stable, and making it abstract forces every subclass to provide one.

## Riverpod

**[Easy] `ref.watch` vs `ref.read`?**
`watch` subscribes and rebuilds on change (use in `build`). `read` gets the
current value once (use in callbacks like `onPressed`).

**[Medium] How does Riverpod help testing and DI?**
Providers form the dependency graph and any provider can be overridden in a
`ProviderScope`, so tests swap a repository for a fake without changing code.

**[Hard] Why does `appConfigProvider` throw until overridden?**
Fail-fast: the config is created in `bootstrap` from the entry point's flavor.
A forgotten override crashes at startup instead of running with silently wrong
values.

**[Hard] Why disable automatic retry?**
Riverpod 3 retries failing providers with backoff. For user-facing flows that
hides failures and complicates tests; retry should be an explicit decision.

**[Hard] What does `ref.mounted` protect against?**
After an `await`, an autoDispose notifier may already be disposed (the page left
after a successful redirect). Setting state then throws; check `ref.mounted`.

## Navigation

**[Medium] Why go_router over Navigator 1.0?**
Declarative, URL-based routing, deep links, a central `redirect` for guards, and
nested navigation. Navigator 1.0 is imperative and hard to guard centrally.

**[Medium] How does the router react to login/logout?**
`refreshListenable` is bumped on every auth-state change and `redirect` runs
again. The router *listens* to auth state (not watches) so it isn't rebuilt,
which would reset navigation state.

**[Medium] Why a pure `resolveRedirect` function?**
Guard logic becomes a table of inputs and outputs, tested without widgets.

## Auth, authorization and security

**[Easy] Authentication vs authorization?**
Authentication proves who you are (sign-in). Authorization decides what you may
do (roles/permissions). Unauthenticated → login; unauthorized → "forbidden".

**[Medium] Why permissions instead of `if (role == admin)`?**
Roles change more often than capabilities. Code asks `can(permission)` and one
mapping defines each role's permissions, so adding a role touches one place.

**[Hard] Is a router guard security?**
No, it's UX. The client runs on a device the user controls and the API can be
called directly. Real enforcement is server-side (RLS, triggers). Domain checks
add defense in depth and clean failures.

**[Hard] How do you stop privilege escalation at sign-up?**
The profile-creating trigger hardcodes `client` and ignores user metadata, and a
`BEFORE UPDATE` trigger rejects role changes unless the caller is an admin.

**[Medium] Why is the Supabase publishable (anon) key safe in the app?**
It only identifies the project. RLS limits what it can do. The service-role key
bypasses RLS and must never ship.

**[Medium] Why store the session in secure storage?**
The default SharedPreferences is unencrypted. Keychain/Keystore protect tokens.

**[Medium] Why is there a fake data source in `lib/`, not just in tests?**
It lets the app run without a backend in dev, and tests share it. Production
refuses to start without real config so fake data can't leak into release.

## Config, i18n, tooling

**[Medium] Flavors vs `--dart-define`?**
Flavors change native identity (app ID, name, icons) so environments install side
by side. Dart-defines inject compile-time values. We use both.

**[Hard] Are `--dart-define` values secret?**
No. They're compiled into the binary and extractable. Only public-by-design values
belong in the app.

**[Easy] How do you add a language with gen_l10n?**
Add an ARB file; the generated delegates and `supportedLocales` update. Use
placeholders, not string concatenation, and `EdgeInsetsDirectional` for RTL.

**[Medium] Why not commit generated code?**
It avoids noisy diffs and merge conflicts, and CI proves it generates cleanly.
Downside: an extra setup step, documented in the README.

**[Medium] Gradle says "Timeout waiting to lock build logic queue". What now?**
A stale Gradle daemon or parallel build holds the lock. Run `gradlew --stop`, end
the stuck process, and avoid running Android Studio sync and `flutter run`
simultaneously.

**[Hard] When do you reach for a hand-written flavor config over a generator?**
When the generator is fragile for your toolchain. `flutter_flavorizr` left a
dangling Gradle reference on Windows; twenty hand-written lines are transparent
and easy to hand over.

## Testing

**[Medium] What did you test at each layer?**
Domain: use cases with a mocked repository (including forbidden paths). Data:
repository against the fake data source. Presentation: widget tests with provider
overrides. Core: Result and config. Router: the redirect table.

**[Hard] A stream should emit the current value, then changes. What's the pitfall?**
Reading the current value and subscribing in two separate steps can lose an event
in between. Do both synchronously (`Stream.multi`), as the fake auth source does
after a test caught exactly this.

**[Medium] A mocktail test fails with "registerFallbackValue was not called".**
`any()` on a non-primitive type needs a dummy value registered once in
`setUpAll`. The failure can poison the next test (a dangling matcher), so fix the
first error before chasing the second.

**[Medium] Why can a test that can't fail be worse than no test?**
It gives false confidence. Our first sign-out test passed even with the stream
bug, because `null` was the last event anyway.

## Git and release

**[Medium] Why tag only after merging to `main`?**
A tag marks a release commit. Tagging before the merge pointed `v0.1.0-mvp1` at
MVP 0 code. Never move a tag after it's pushed; delete it only if nobody has
consumed it.

## State machines, search and paging

**[Medium] How did you model the listing lifecycle?**
As a state machine: a status enum plus one pure function `canTransition`. The UI
derives its buttons from `nextStatuses`, so screens never hold their own rules.

**[Hard] Why enforce the same transitions in Dart and in a Postgres trigger?**
Dart gives instant feedback and clean failures; only the database stops a client
that calls the API directly. The cost is duplicated rules, mitigated by tests on
both sides.

**[Medium] How do admins change platform rules without a release?**
A single-row `app_settings` table with an admin-only update policy. Use cases
read it before enforcing, so a stale UI copy can't bypass the rule.

**[Medium] Offset vs keyset pagination?**
Offset is simple but can repeat or skip rows when data changes mid-scroll;
keyset (cursor) is stable but needs a sortable cursor and more code. We use offset
with an `id` tie-breaker and de-duplicate on the client.

**[Medium] Why debounce search input?**
Without it each keystroke fires a query. A 400 ms debounce sends one request when
typing pauses and cancels the pending timer on each change and on dispose.

**[Hard] Why does the filter object need value equality?**
Riverpod caches family providers by argument equality. A freezed `PropertyFilter`
inside `PropertyListQuery` means identical filters share one cached list and
different filters get their own.

**[Medium] Why is the mutation notifier `keepAlive`?**
A page often pops right after a save. An auto-dispose notifier could be disposed
mid-await, making `ref.invalidate` throw.

**[Medium] How do you keep user text out of a PostgREST filter string?**
Strip characters with meaning there (commas, parentheses, wildcards, quotes)
before interpolating it into `or(...)` or `ilike`.

**[Easy] Why `numeric` for prices in the database?**
Floating-point can't represent many decimal amounts exactly; `numeric` is exact.