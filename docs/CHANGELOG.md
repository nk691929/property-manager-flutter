# Changelog
Format: Keep a Changelog. Versioning: SemVer; pre-1.0 tags are `v0.<mvp>.x-mvp<n>`.

## [0.0.1-mvp0] - 2026-10-29
### Added
- Project scaffold, strict lints, GitHub Actions CI
- Flavors (dev/staging/prod) and config injection
- Core: Result, Failure, logger, secure store
- Material 3 light/dark theme, design tokens
- Localization (English)
- go_router skeleton, `app_info` vertical slice, tests

## [0.1.0-mvp1] - 2026-10-31
### Added
- Supabase email/password auth with secure session persistence
- Roles and permissions; permission-based router guards
- Admin/Agent/Client home shells; admin user role management
- Supabase migration (profiles, RLS, guard trigger)
- Fake backend, `runCatching`, `InvalidCredentialsFailure`, shared `ErrorView`