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
- `presentation` talks to use cases through providers; widgets contain no business logic.
- `core/` is a small shared kernel (config, Result, Failure, logging, storage).

## Data flow (read)
Widget → `ref.watch(provider)` → UseCase → Repository (interface) →
RepositoryImpl → DataSource → backend. Results flow back as `Result<T>`,
converted to `AsyncValue` at the provider boundary.

## Decisions (ADR format)

### ADR-001: Feature-first Clean Architecture
Status: Accepted. Context: app will have 8+ features and a swap-able backend.
Decision: one folder per feature with domain/data/presentation. Exception: each
feature's `presentation/providers/*_providers.dart` is the composition root and
may import `data/`. Consequence: more files; features are removable/addable in isolation.

### ADR-002: Riverpod with code generation
Decision: `@riverpod` annotations. Consequence: requires build_runner; less
boilerplate and compile-time-checked provider types.

### ADR-003: `Result<T>` instead of throwing across layers
Decision: repositories/use cases return `Result<T>`; exceptions are caught at
the data boundary. `Failure` is a sealed hierarchy mapped to localized text
in presentation via an exhaustive switch.

### ADR-004: Flavors via entry points + `--dart-define-from-file`
Decision: native flavors (flutter_flavorizr) plus per-env JSON for values.
Consequence: never run without `--flavor`. Dart-defines are not secrets; the
Supabase anon key is public by design (protected by RLS); service keys never ship.

### ADR-005: Supabase as first backend, behind repository interfaces
Decision (owner-confirmed). Consequence: a REST/Firebase implementation can be
added by implementing the same interfaces. Supabase types must not appear in domain.

### ADR-006: Generated code is not committed
Decision: gitignore `*.g.dart`/`*.freezed.dart`/l10n output; CI generates them.
Consequence: smaller diffs and no merge conflicts; README documents the extra step.

### ADR-007: Disable Riverpod automatic retry
Decision: `ProviderScope(retry: disableAutoRetry)`. Retrying is an explicit UX
decision (Retry button) or a data-layer policy, not a hidden global default.

### ADR-008: Permission-based access control (implemented in MVP 1)
Decision: `Role -> Set<Permission>`; guards and use cases check permissions,
never raw roles. Adding a role = one mapping change.

### ADR-003 (amended): Who translates exceptions?
Backend-specific data sources throw typed `Failure`s (they know their SDK).
Repositories use `runCatching`, which turns `Failure` into `Err` and anything
unexpected into `UnknownFailure`. Result: repositories contain no SDK types, so
a REST data source can replace Supabase with no repository changes.

### ADR-008 (implemented): Permission-based access control
`permissionsFor(Role)` is an exhaustive switch (the only role→permission map).
Enforcement happens in three layers: (1) router `resolveRedirect` for UX,
(2) use cases via `CurrentUserReader` + `AppUser.can` for business rules,
(3) Supabase RLS + trigger for real security. Only (3) protects data.

### ADR-009: Shared identity types
`AppUser`, `Role`, `Permission` live in `features/auth/domain`. Other features'
domains may import them. `ProfileModel` (auth/data) is reused by admin_users/data
as a pragmatic shared DTO for `public.profiles`.

### ADR-010: Sign-up policy
Everyone self-registers as `client` (enforced by DB trigger, never by client
metadata). Admins promote users in-app. Creating privileged accounts directly
needs the service-role key, i.e. a server-side function (future work).

### ADR-011: Session storage
Supabase session is persisted via `SecureLocalStorage` (Keychain/Keystore),
not the default SharedPreferences.

### ADR-012: No-backend fallback
Without SUPABASE_* config, dev/staging use a seeded in-memory fake;
prod throws at startup. Dev data is not persisted.