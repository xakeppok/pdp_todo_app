# PDP Todo App

Reference Flutter project to build a practical command of the testing stack — unit, widget, golden, and integration — and make it repeatable for the team through CI gates.

Not a product Todo app. Just enough Clean Architecture, Bloc, go_router, and business logic to exercise the full pyramid.

## Test layers

| Layer | Folder | Count (approx.) | Role |
|-------|--------|-----------------|------|
| Unit | `test/unit/` | 27 | Domain rules, use cases, repository |
| Bloc/Cubit | `test/bloc/` | 19 | Event → state without UI |
| Widget | `test/widget/` | 15 | UI states, taps, navigation |
| Golden | `test/golden/` + `goldens/*.png` | 6 | Visual regression (committed PNGs) |
| Integration | `integration_test/` | 6 | Multi-screen flows (CI: Android) |

Cheat sheet (pyramid, tools, **what to test where**, snippets): [docs/testing-strategy.md](docs/testing-strategy.md)

Goldens (generate / update / review): [docs/goldens.md](docs/goldens.md)

## Setup

```bash
flutter pub get

# one-time: install Lefthook, then wire git hooks for this clone
brew install lefthook   # https://lefthook.dev — other installers also fine
lefthook install
```

`lefthook install` writes into `.git/hooks/`. Without it, commits skip the local CI gates. Re-run after a fresh clone.

## Run the app

```bash
flutter run
```

In-memory fake with seeded todos. Clock fixed at `2026-08-12 15:00` so overdue stays deterministic.

## Run the suite

```bash
# unit + Bloc/Cubit + widget + golden
flutter test test/

# same + LCOV → coverage/lcov.info
flutter test --coverage test/

flutter test test/unit
flutter test test/bloc
flutter test test/widget
flutter test test/golden

# local macOS: skip goldens if pixels drift vs Linux CI images
flutter test --exclude-tags golden test/

# integration: CI uses Android emulator; desktop is smoke only
flutter test integration_test/
```

### Commit hooks (same as CI `test` job)

After `lefthook install`, every commit runs the CI `test` job gates from `lefthook.yml`:

1. `flutter analyze --fatal-infos`
2. `flutter test test/` (on macOS/Windows: `--exclude-tags golden`)

Android integration tests stay CI-only.

```bash
lefthook install          # required once per clone
lefthook run pre-commit   # run the gates without committing
LEFTHOOK=0 git commit ... # skip hooks once
```

Details: [docs/ci-and-flaky-tests.md](docs/ci-and-flaky-tests.md).

### Coverage

```bash
flutter test --coverage test/
# optional HTML: genhtml coverage/lcov.info -o coverage/html
```

CI uploads `coverage/lcov.info` as the `coverage-lcov` artifact.

Goldens: committed PNGs in `test/golden/goldens/` — see [docs/goldens.md](docs/goldens.md).

### Update goldens

```bash
flutter test --update-goldens test/golden   # prefer Linux
```

## Layout

```
lib/
  app/           # DI (get_it), themes, TodoApp
  core/          # failures, clock, router
  features/todos/
    data/        # fake data source, models, repository
    domain/      # entities, validator, query, use cases, repository port
    presentation/# blocs, pages, widgets
```

`get_it` only in `lib/app/di.dart` and the integration harness. Pages and `app_router.dart` don't call it — router comes from `createConfiguredRouter()`.

## Stack

- Flutter 3.44.9 / Dart 3.12.2
- flutter_bloc, go_router, get_it, equatable
- mocktail, bloc_test, golden_toolkit, integration_test
- very_good_analysis (`flutter analyze --fatal-infos` in CI)

## Docs

- [Testing cheat sheet](docs/testing-strategy.md) — pyramid, tools, decision guide, snippets
- [Goldens](docs/goldens.md) — generate, update, review
- [CI and flaky tests](docs/ci-and-flaky-tests.md)
