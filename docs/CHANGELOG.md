# Changelog
Format: Keep a Changelog. Versioning: SemVer; pre-1.0 tags are `v0.<n>.x-mvp<n>`.

## [0.3.0-mvp3] - 2026-11-03
### Added
- Favorites with optimistic heart and a Saved list
- Agent names on listings through a narrow `visible_names` window
- Inquiry threads (client and agent) with inbox and close
- Viewing requests with agent confirm/decline, cancel and completed
- `ConflictFailure`; new permissions for favorites, inquiries and viewings
- Supabase migration 0004 (favorites, inquiries, messages, viewings, rules)

## [0.2.1-mvp2.1] - 2026-11-02
### Added
- Property photos: upload, cover, remove, gallery, card thumbnails
- Supabase migration 0003 (property_photos, storage bucket and policies)
- Photo rules and use cases; `DeleteProperty` removes a draft's files

## [0.2.0-mvp2] - 2026-11-01
### Added
- Property listings with approval workflow, browse/search/filter/sort/paging
- Agent "My listings", admin review queue and all-listings management
- Admin-configurable approval rule (platform settings)
- Permissions: browseProperties, manageOwnProperties, manageAllProperties, manageSettings
- Supabase migration 0002 (properties, app_settings, workflow guard) and dev seed

## [0.1.0-mvp1] - 2026-10-31
### Added
- Supabase email/password auth with secure session persistence
- Roles and permissions; permission-based router guards
- Admin/Agent/Client home shells; admin user role management
- Supabase migration (profiles, RLS, guard trigger)
- Fake backend, `runCatching`, `InvalidCredentialsFailure`, shared `ErrorView`

## [0.0.1-mvp0] - 2026-10-31
### Added
- Project scaffold, strict lints, GitHub Actions CI
- Android flavors (dev/staging/prod) and config injection
- Core: Result, Failure, logger, secure store
- Material 3 light/dark theme and design tokens
- Localization (English)
- go_router skeleton, `app_info` vertical slice, tests
