# CI and flaky tests

## How CI works

GitHub Actions workflow: `.github/workflows/ci.yml`

Flutter is pinned to **3.44.9**.

### Job `test`

1. `flutter pub get`
2. `flutter analyze --fatal-infos`
3. `flutter test --coverage test/` (unit, Bloc/Cubit, widget, golden → `coverage/lcov.info`)
4. Upload `coverage/lcov.info` as the `coverage-lcov` artifact

Fails the job on any non-zero exit. Does **not** pass `--update-goldens`.

### Job `integration`

Runs on an **Android emulator** via `android-emulator-runner`.

Local `flutter test integration_test/ -d macos` can smoke-test flows but is **not** CI parity (Android is the supported integration target).

## Goldens

Generate / update / review: [goldens.md](goldens.md).

Short version: update on **Linux** to match the `test` job; never pass `--update-goldens` in CI.

## Deterministic fixtures

- Fixed `Clock` (`2026-08-12 15:00`) so “due today” is never overdue
- Stable todo IDs and titles in seeds/fixtures
- Explicit surface sizes in golden/widget pumps

## Stable async handling

- Prefer mock-controlled futures and `blocTest`
- Use `pump` / `pumpAndSettle` with finite animations
- Integration failure/retry: set `FailureMode` via `IntegrationHarness.setFailureMode`, then tap Retry

## Avoid arbitrary `Future.delayed`

Sleeps hide race conditions and slow the suite. If you must wait, prefer:

- awaiting the future under test
- `tester.pump(duration)` with a known duration tied to a fake timer
- polling UI with a clear condition

## When retries are justified

Retries can mask real flakes. Prefer root-cause fixes (determinism, settling, unique keys).

Retries are only justified for:

- known infrastructure flakes (emulator boot), isolated in CI helpers
- never for asserting business logic or goldens

If a test is flaky, fix fixtures/async/goldens OS parity first.
