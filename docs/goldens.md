# Goldens

Committed reference images live in `test/golden/goldens/`. Tests: `test/golden/todos_golden_test.dart` (tagged `golden`).

Current set:

| File | What it covers |
|------|----------------|
| `todos_list_phone_light.png` | List with data, phone, light |
| `todos_list_phone_dark.png` | Same list, dark |
| `todos_list_tablet.png` | Wide / tablet surface |
| `todos_empty.png` | Empty state |
| `todos_error.png` | Error + retry chrome |
| `todo_item.png` | Single row (priority / overdue) |

## Generate / update

Prefer **Linux** so PNGs match the GitHub Actions `test` job (macOS/Linux Skia + fonts can differ).

```bash
flutter test --update-goldens test/golden
```

Review the diffed PNGs under `test/golden/goldens/`, then commit them with the test change.

Do **not** pass `--update-goldens` in CI — CI only compares.

## Run (compare only)

```bash
flutter test test/golden
# or as part of the full suite:
flutter test test/
```

Local macOS smoke without fighting pixel drift:

```bash
flutter test --exclude-tags golden test/
```

## Review a failure

On mismatch Flutter writes under `test/golden/failures/` (gitignored if present — delete after reviewing):

1. Open the failure folder — master vs actual vs diff.
2. Decide: intentional UI change → update goldens on Linux and commit. Accidental → fix the widget/test.
3. Don't raise tolerance to “make CI green”; fix the image or the code.

## Keep them stable

- Fixed `Clock` + seeded fixtures
- Explicit `surfaceSize` in pumps
- `loadAppFonts()` in `setUpAll`
- Same Flutter pin as CI (`3.44.9`)

More on flakes / CI: [ci-and-flaky-tests.md](ci-and-flaky-tests.md).
