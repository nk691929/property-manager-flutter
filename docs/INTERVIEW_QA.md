# Interview Q&A

## Architecture

**[Easy] What is Clean Architecture?**
A way to organize code in layers so business rules don't depend on frameworks.
Domain (entities, use cases, repository interfaces) sits at the center; data
and presentation depend on it, never the reverse.

**[Medium] Why define a repository interface in domain but implement it in data?**
Dependency inversion. Use cases depend on an abstraction they own, so the
backend (Supabase, REST, a fake) can change without touching business logic, and
tests can inject a mock.

**[Medium] Feature-first vs layer-first structure?**
Layer-first groups by technical type and scatters one feature across many folders.
Feature-first keeps everything for a feature together: easier ownership,
deletion, and scaling. Shared code goes in `core/`.

**[Hard] Is a use case that just forwards to a repository worth it?**
Debatable. Costs a file; buys a consistent seam where permission checks,
validation and orchestration land as the app grows. In a tiny app, skip it. In an
app with roles and multi-repo operations, it pays for itself.

## Error handling

**[Medium] Why return `Result<T>` instead of throwing?**
Failures become part of the function signature, and sealed classes make handling
exhaustive at compile time. Exceptions are invisible in signatures and easy to
forget. Trade-off: some ceremony; mixed styles if used inconsistently.

**[Hard] Where should exceptions be caught?**
At layer boundaries, usually the repository implementation. It translates
SDK/network exceptions into domain `Failure`s so upper layers never see backend
types. Truly unexpected errors go to global handlers (`FlutterError.onError`,
`PlatformDispatcher.onError`) and the logger.

**[Medium] Why not store user-facing messages inside Failure?**
Failures live below the UI and can't know the locale. They carry type/code; the
presentation layer maps them to localized strings (an exhaustive `switch`).

## Riverpod

**[Easy] `ref.watch` vs `ref.read`?**
`watch` subscribes and rebuilds on change (use in `build`). `read` gets the
current value once (use in callbacks like `onPressed`).

**[Medium] How does Riverpod help testing and DI?**
Providers form the dependency graph, and any provider can be overridden in a
`ProviderScope`, so tests swap a repository for a fake without changing code.

**[Hard] Why does `appConfigProvider` throw until overridden?**
Fail-fast: the config is created in `bootstrap` from the entry point's flavor.
If someone forgets the override, the app crashes at startup instead of running
with silently wrong values.

**[Hard] Why disable automatic retry?**
Riverpod 3 retries failing providers with backoff. For user-facing flows that
hides failures and complicates tests; we want retry to be an explicit decision.

## Navigation

**[Medium] Why go_router over Navigator 1.0?**
Declarative, URL-based routing, deep links, a central `redirect` for guards, and
nested navigation. Navigator 1.0 is imperative and hard to guard centrally.

**[Hard] Where do role-based guards belong?**
In the router's `redirect` (UX: send users to the right place) and again in
the domain layer (security: use cases enforce permissions). UI-only guards are
cosmetic, since they can be bypassed and don't protect data. Real enforcement
also needs server-side rules (Supabase RLS).

## Config, i18n, tooling

**[Medium] Flavors vs `--dart-define`?**
Flavors change native identity (app ID, name, icons) so environments install
side by side. Dart-defines inject compile-time values. We use both.

**[Hard] Are `--dart-define` values secret?**
No. They're compiled into the binary and extractable. Only public-by-design
values (e.g. Supabase anon key with RLS) belong in the app. Server secrets stay
on the server.

**[Easy] How do you add a language with gen_l10n?**
Add an ARB file with the translations; generated delegates and
`supportedLocales` update. Use placeholders instead of string concatenation,
and `EdgeInsetsDirectional` for RTL.

**[Medium] Why not commit generated code?**
Avoids noisy diffs and merge conflicts; CI proves it generates cleanly.
Downside: extra setup step, documented in the README.

## Testing

**[Medium] What did you test at each layer?**
Domain: use case delegation with a mocked repository. Data: mapping and
exception→Failure translation with a mocked data source. Presentation: widget
tests with provider overrides for loaded/error/retry states. Core: Result and config.

**[Hard] Why override providers in widget tests instead of mocking the repository?**
Overriding the leaf provider (`appInfoProvider`) isolates the widget from the
whole chain and keeps the test about UI behavior. Lower-layer behavior is already
covered by its own tests, which keeps the pyramid cheap.

## Auth, authorization and security

**[Easy] Authentication vs authorization?**
Authentication proves who you are (sign-in). Authorization decides what you may
do (roles/permissions). They fail differently: unauthenticated → login;
unauthorized → "forbidden".

**[Medium] Why permissions instead of `if (role == admin)`?**
Roles change more often than capabilities. Code asks `can(permission)` and one
mapping defines each role's permissions, so adding a role touches one place.

**[Hard] Is a router guard security?**
No, it's UX. The client runs on a device the user controls, and the API can be
called directly. Real enforcement is server-side (RLS, triggers). Domain checks
add defense in depth and clean failures.

**[Hard] How do you stop privilege escalation at sign-up?**
The profile-creating trigger hardcodes `client` and ignores user metadata, and a
`BEFORE UPDATE` trigger rejects role changes unless the caller is an admin.

**[Medium] Why is the Supabase anon key safe in the app?**
It's public by design: it only identifies the project. RLS limits what it can
do. The service-role key bypasses RLS and must never ship.

**[Medium] How does the router react to login/logout?**
`refreshListenable` bumps on every auth-state change; `redirect` runs again.
The router listens (not watches) to auth state so it isn't rebuilt.

**[Medium] Why a pure `resolveRedirect` function?**
Guard logic becomes a table of inputs and outputs, tested without widgets.

**[Hard] What does `ref.mounted` protect against?**
After `await`, an autoDispose notifier may already be disposed (the page left
after a successful redirect). Setting state then throws; check `ref.mounted`.

**[Medium] Where do SDK exceptions get translated, and why there?**
In the backend-specific data source. The repository stays SDK-free, so swapping
backends means writing a new data source.

**[Medium] Why a fake data source in `lib/`, not just tests?**
It lets the app run without a backend in dev, and tests share it. Production
refuses to start without real config so fake data can't leak into release.

**[Medium] Why store the session in secure storage?**
The default SharedPreferences is unencrypted. Keychain/Keystore protect tokens.

**[Hard] Why did adding `InvalidCredentialsFailure` force a UI edit?**
`Failure` is sealed and `FailureMessage` uses an exhaustive `switch`; the
compiler refuses to build until the new case has a message.

**[Hard] A stream should emit the current value, then changes. What's the pitfall?**
If you read the current value and subscribe in two separate steps, an event in
between is lost. Do both synchronously (`Stream.multi`), as the fake auth source
does after a test caught exactly this.

**[Medium] A mocktail test fails with "registerFallbackValue was not called".**
`any()` on a non-primitive type needs a dummy value registered once in
`setUpAll`. The failure can poison the next test (dangling matcher), so fix the
first error before chasing the second.

**[Medium] Why can a test that can't fail be worse than no test?**
It gives false confidence. Our first sign-out test passed even with the stream
bug, because `null` was the last event anyway.