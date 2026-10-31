# MVP 0: Foundation

## Built
Android flavors, config injection, Result/Failure, logger, secure-store
abstraction, Material 3 light/dark themes, gen_l10n (en), go_router skeleton,
the `app_info` vertical slice, tests, and GitHub Actions CI.

## How to use
See the README. The info screen shows app name, version, environment, and whether
backend config was injected: a quick sanity check for dart-defines.

## Test plan
- Unit: Result, AppConfig, use case, repository (mapping + failure translation)
- Widget: app_info page (loaded, error, retry)
- Integration (planned): `integration_test/` with the first real flow

## Known limitations
- iOS is not configured or verified (Windows dev machine); iOS schemes and bundle
  IDs are planned for MVP 6 on a Mac or cloud Mac
- Android verified on a physical device (flavor `dev`); staging and prod are
  configured but not yet run
- The secure-store wrapper has no automated test (needs a device)
- English only; the structure is ready for Urdu/Arabic (RTL)
- App icons and splash are Flutter defaults
