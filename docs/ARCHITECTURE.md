# Architecture

## Layers and the dependency rule

```
presentation ──▶ domain ◀── data
 (widgets,       (entities, repo     (data sources,
  providers)      interfaces,         repo implementations,
                  use cases)          DTOs/mappers)
```

- `domain` imports nothing from Flutter, Riverpod or any backend SDK.
- `data` implements domain interfaces and converts exceptions into `Failure`s.
- `presentation` talks to use cases through providers; widgets hold no business logic.
- `core/` is a small shared kernel (config, Result, Failure, logging, storage, backend helpers).

## Data flow (read)

Widget → `ref.watch(provider)` → UseCase → Repository (interface) →
RepositoryImpl → DataSource → backend. Results come back as `Result<T>` and are
converted to `AsyncValue` at the provider boundary.

## Access control (three layers, only one is real security)

1. Router `resolveRedirect`: UX only, sends people to the right screen.
2. Use cases check `AppUser.can(permission)` via `CurrentUserReader`: business
   rules and clean `ForbiddenFailure`s.
3. Supabase RLS + triggers: the only layer that actually protects data.

## Decisions (ADR format)

### ADR-001: Feature-first Clean Architecture
Status: Accepted. Context: 8+ features and a swappable backend. Decision: one
folder per feature with domain/data/presentation. Exception: each feature's
`presentation/providers/*_providers.dart` is the composition root and may import
`data/`. Consequence: more files; features can be added or removed in isolation.

### ADR-002: Riverpod with code generation
`@riverpod` annotations. Requires build_runner; less boilerplate and
compile-time-checked provider types.

### ADR-003: `Result<T>` instead of throwing across layers
Repositories and use cases return `Result<T>`. `Failure` is a sealed hierarchy
mapped to localized text in presentation through an exhaustive switch.
**Amended (MVP 1):** backend-specific data sources throw typed `Failure`s (they
know their SDK). Repositories use `runCatching`, which turns a `Failure` into
`Err` and anything unexpected into `UnknownFailure`. Repositories therefore
contain no SDK types, so a REST data source can replace Supabase without
touching them.

### ADR-004: Flavors via entry points + `--dart-define-from-file`
Android flavors (dev/staging/prod) are written by hand in
`android/app/build.gradle.kts` (`productFlavors` plus `buildFeatures.resValues = true`).
`flutter_flavorizr` was tried and dropped: it was unreliable on Windows with
Kotlin-DSL Gradle files and left a dangling `apply` reference. iOS schemes and
bundle IDs will be configured on a Mac in MVP 6. Dart-defines are compiled into
the app and are not secret; the Supabase public key is public by design
(protected by RLS) and the service-role key never ships.

### ADR-005: Supabase as first backend, behind repository interfaces
Owner-confirmed. A REST or Firebase implementation can be added by implementing
the same interfaces. Supabase types must not appear in domain.

### ADR-006: Generated code is not committed
`*.g.dart`, `*.freezed.dart` and l10n output are gitignored; CI generates them.
Smaller diffs, no merge conflicts; the README documents the extra step.

### ADR-007: Disable Riverpod automatic retry
`ProviderScope(retry: disableAutoRetry)`. Retrying is an explicit UX decision
(a Retry button) or a data-layer policy, not a hidden global default.

### ADR-008: Permission-based access control
`permissionsFor(Role)` is an exhaustive switch and the only role-to-permission
map. Guards and use cases check permissions, never raw roles. Adding a role =
one mapping change (plus its home route).

### ADR-009: Shared identity types
`AppUser`, `Role`, `Permission` live in `features/auth/domain` and may be
imported by other features' domains. `ProfileModel` (auth/data) is reused by
admin_users/data as a pragmatic shared DTO for `public.profiles`.

### ADR-010: Sign-up policy
Everyone self-registers as `client`, enforced by a DB trigger and never by client
metadata. Admins promote users in the app. Creating privileged accounts directly
needs the service-role key, i.e. a server-side function (future work).

### ADR-011: Session storage
The Supabase session is persisted through `SecureLocalStorage`
(Keychain/Keystore), not the default SharedPreferences.

### ADR-012: No-backend fallback
Without SUPABASE_* config, dev/staging use a seeded in-memory fake; prod throws
at startup. Dev data is not persisted.
