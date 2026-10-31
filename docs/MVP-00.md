# MVP 0: Foundation

## Built
Flavors, config, Result/Failure, logger, secure-store abstraction, Material 3
themes, gen_l10n (en), go_router skeleton, `app_info` vertical slice, tests, CI.

## How to use
See README. The home screen shows app name, version, environment and whether
backend config was injected: a quick sanity check for dart-defines.

## Test plan
- Unit: Result, AppConfig, use case, repository (mapping + failure translation)
- Widget: app_info page (loaded, error, retry)
- Integration (planned): `integration_test/` with the first real flow in MVP 1 (login → role home)

## Known limitations
- No real features yet; no auth, roles, or backend calls
- Secure-store wrapper has no automated test yet (needs a device); covered in MVP 1
- English only (Urdu/Arabic planned; structure is ready)
- App icons and splash are Flutter defaults
- Not executed on physical devices by the author at time of writing; verify per README