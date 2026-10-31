# Property Manager

Flutter property-management app with three roles (Admin, Agent, Client).
Clean Architecture, Riverpod, go_router, Supabase backend.

**Status:** MVP 1 (auth and role-based navigation). See `docs/CHANGELOG.md`.

## Prerequisites
- Flutter stable (Dart SDK ^3.13), Android Studio / Android SDK
- Xcode is needed for iOS builds (macOS only). iOS is not configured yet; see
  `docs/MVP-00.md`.
- A Supabase project (see Backend below)

## Setup
```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
Copy-Item config\example.json config\dev.json    # fill in values; never commit
```
On macOS/Linux use `cp config/example.json config/dev.json`.

## Run
Always pass the flavor, the matching entry point, and the config file:
```powershell
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=config/staging.json
flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json
```
Plain `flutter run` fails by design (multiple flavors, no `lib/main.dart`).

## Backend (Supabase)
1. Create a project and run `supabase/migrations/0001_profiles_and_roles.sql`
   in the SQL editor.
2. Put the project URL and the public anon/publishable key in
   `config/<flavor>.json`. Never use the service-role key in this app.
3. Dev project: email confirmation off. Staging and prod: on, each with its own
   separate Supabase project.
4. Create the first admin: sign up in the app, then run
   `update public.profiles set role = 'admin' where email = '...';`

Without backend config, dev and staging run against a seeded in-memory fake:
`admin@example.com`, `agent@example.com`, `client@example.com`, password
`Password1`. Production refuses to start without real config.

## Quality
```powershell
dart format .
flutter analyze
flutter test
```
Generated files (`*.g.dart`, `*.freezed.dart`, l10n output) are not committed.
After changing providers, freezed classes or ARB files, re-run build_runner
(and `flutter gen-l10n` for ARB changes).

## Architecture
Feature-first Clean Architecture: `lib/features/<name>/{domain,data,presentation}`
plus a small shared kernel in `lib/core`. Dependencies point inward only
(presentation → domain ← data). Access control is permission-based, enforced in
the router, in use cases, and finally by Supabase RLS. Details and decision
records: `docs/ARCHITECTURE.md`.

## Add a language
Copy `lib/l10n/app_en.arb` to `app_<code>.arb`, set `@@locale`, and translate.
No code changes; RTL languages (ur, ar) are handled by Flutter.

## Add a feature
Create `lib/features/<name>/{domain,data,presentation}`, add its route to
`lib/app/router/routes.dart` and `app_router.dart`, and add its strings to the ARB.

## Add a role
Add the value to `Role`, map it in `permissionsFor`, give it a home route in
`AppRoutes.homeFor`, and extend the database enum. The compiler flags every
exhaustive `switch` that needs updating.

## Windows notes
Use PowerShell syntax. If Gradle reports "Timeout waiting to lock build logic
queue", run `cd android; .\gradlew --stop`.

## Release process
Feature branch → PR into `develop` (CI green) → PR `develop` into `main` → then
tag on `main`:
`git switch main; git pull; git tag -a vX.Y.Z-mvpN -m "..."`.
Never tag before the merge, and never move a tag once pushed.

## Docs
`docs/ARCHITECTURE.md`, `docs/MVP-00.md`, `docs/MVP-01.md`,
`docs/CHANGELOG.md`, `docs/INTERVIEW_QA.md`