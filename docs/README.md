# Property Manager

Flutter property-management app (roles: Admin, Agent, Client). Clean Architecture,
Riverpod, go_router. Backend: Supabase (wired from MVP 1).

## Prerequisites
- Flutter stable (>= 3.27), Xcode (iOS builds, macOS only), Android Studio / SDK

## Setup
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cp config/example.json config/dev.json      # fill in values (never commit)
```

## Run (always pass --flavor and the matching entry point)
```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=config/staging.json
flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json
```

## Quality
```bash
dart format . && flutter analyze && flutter test
```
Generated files (`*.g.dart`, `*.freezed.dart`, l10n) are not committed.
After changing providers, freezed classes or ARB files, re-run build_runner (or `flutter pub get` for ARB).

## Add a language
Copy `lib/l10n/app_en.arb` to `app_<code>.arb`, set `@@locale`, translate. No code changes.
RTL (ur, ar) is handled by Flutter automatically.

## Add a feature
Create `lib/features/<name>/{domain,data,presentation}`, add one `GoRoute` in
`lib/app/router/app_router.dart`, add strings to the ARB. See docs/ARCHITECTURE.md.

## Docs
`docs/ARCHITECTURE.md`, `docs/MVP-00.md`, `docs/CHANGELOG.md`, `docs/INTERVIEW_QA.md`

## Backend (Supabase)
1. Create a project; run `supabase/migrations/0001_profiles_and_roles.sql` in the SQL editor.
2. Put the project URL and the public anon/publishable key in `config/<flavor>.json`.
   Never use the service-role key in this app.
3. Dev project: email confirmation off. Staging/prod: on, with separate projects.
4. Create the first admin: sign up, then
   `update public.profiles set role = 'admin' where email = '...';`

Without config, dev uses a seeded fake: admin@/agent@/client@example.com,
password `Password1`.

## Windows notes
Use PowerShell syntax. If Gradle reports "Timeout waiting to lock build logic
queue", run `cd android; .\gradlew --stop`.

## Release process
Feature branch → PR into `develop` (CI green) → PR `develop` into `main` →
then tag on `main`: `git switch main; git pull; git tag -a vX.Y.Z-mvpN -m "..."`.
Never tag before the merge, and never move a tag once pushed.