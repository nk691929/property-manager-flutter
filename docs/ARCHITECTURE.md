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

### ADR-013: Workflow rules live twice, on purpose
Listing status transitions are a pure Dart function (`PropertyWorkflow`) for UX
and early failure, and a Postgres trigger (`guard_property_write`) for real
enforcement. They must be kept in sync; tests pin the Dart side and the SQL
checks in docs/MVP-02.md pin the database side.

### ADR-014: Admin-configurable platform rules
`app_settings` is a single-row table (boolean primary key = true). Admins change
`require_listing_approval` at runtime. Use cases always re-read the rule before
enforcing it; the cached copy in the UI only labels buttons.

### ADR-015: Paged lists as a family notifier
`PropertyList(PropertyListQuery)` serves browse, "my listings" and admin lists.
The query is a freezed value, so Riverpod caches one list per distinct query.
Offset pagination with an `id` tie-breaker; "Load more" is an explicit button.

### ADR-016: Cross-feature dependencies
`properties` domain imports `platform_settings` domain (approval rule); the
properties UI imports `adminUsersProvider` to list agents for reassignment.
Dependencies point at domain interfaces or public providers, never at another
feature's data layer.

### ADR-017: Photos are part of the Property aggregate
`Property` carries its `photos`; the properties feature owns photo use cases.
A separate feature would need properties and photos to import each other (a
cycle). One query embeds photos with the property (PostgREST resource
embedding), so lists need no per-card requests.

### ADR-018: Public bucket with unguessable paths
`property-photos` is public-read: URLs are plain strings, cacheable, and need no
signing request. Paths are `<propertyId>/<random uuid>.<ext>`. Write access is
RLS-protected through `can_manage_property_photos`. Trade-off: anyone holding a
URL can fetch the file, including photos of draft listings. A private bucket
with signed URLs is the stricter alternative (revisit in MVP 6).

### ADR-019: Compensating actions across Storage and Postgres
No transaction spans both systems. Add = upload file, then insert row (delete the
file if the row fails). Remove = delete row, then file (log if the file delete
fails). A failure always leaves an invisible orphan file, never a row pointing at
a missing image. Deleting a draft removes its photos first, because after the
property row is gone the storage policies can no longer prove ownership.

### ADR-020: Validate on the device, enforce on the server
The picker shrinks images (max 1600 px, quality 80). Domain rules check count,
size and type (type from magic bytes, not file names). The bucket limits, the
10-photo trigger and RLS are the real enforcement.

### ADR-021: Aggregates and agent derivation
Inquiries and viewings store the client and the property, not the agent. The
agent is read from the property's current owner at load time (resource
embedding), so reassigning a listing moves its conversations and viewings to
the new agent with no data fix. The old agent loses access automatically.

### ADR-022: Optimistic updates roll back only their own change
`FavoriteIds` flips the heart before the request finishes. On failure it undoes
just that property, never restoring a saved copy of the whole list, so taps made
meanwhile survive. A per-property in-flight set drops double taps. The provider
watches the current user so one person's hearts never leak to the next sign-in.

### ADR-023: Cross-feature composition lives in the app layer
Features never import each other's presentation code. The app layer plugs
widgets into slots (`cardTrailing`, `actions`, `bottomBar`), e.g.
`PropertyEngagementBar` places the inquiry and viewing buttons on the property
detail screen. Domain-level dependencies point only at interfaces
(`ListFavoriteProperties` uses `PropertiesRepository`).

### ADR-024: A narrow window into private data
`profiles` stays private. `visible_names(ids)` is a SECURITY DEFINER function
returning only id and name, and only for people the caller has a legitimate
relationship with (an agent with a published listing, or the other party in an
inquiry or viewing). A function, not a view, so RLS is not bypassed for everyone.
Email and phone are never exposed to other users.

### ADR-025: Multi-row writes go through a database function
`create_inquiry` creates the inquiry and its first message in one transaction
(PostgREST would issue two independent requests). Single-row writes (a viewing
request, a message) use plain inserts guarded by triggers. Column-level grants
(`grant update (status)`) freeze every other column of an inquiry or viewing.

### ADR-026: Business rules at the database edge, mirrored in Dart
The viewing state machine and time window exist as `ViewingWorkflow` /
`ViewingRules` (Dart, instant UX, unit-tested with an injected clock) and as
`guard_viewing_write` (SQL, authoritative). Partial unique indexes enforce "one
open inquiry" and "one active viewing" per client and listing even when two taps
race. A conflict on a stale screen refreshes the list instead of repeating the
error.