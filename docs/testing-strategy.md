# Testing cheat sheet

Short guide for this repo: pyramid, tools, **what goes where**, and annotated snippets from the suite.

## Pyramid

```
        Integration  — few real flows, full wiring
           Golden    — pixels for stable screens
           Widget    — UI states & interactions
           Bloc/Cubit— event → state (no pixels)
           Unit      — domain, use cases, repository
```

| Layer | Proves | Doubles | Folder |
|-------|--------|---------|--------|
| Unit | Rules & collaboration at the next boundary | mocktail on repo / data source | `test/unit/` |
| Bloc/Cubit | Event/state sequences without rendering | mocktail on use cases | `test/bloc/` |
| Widget | Loading/empty/error/loaded, taps, nav | mocked use cases + pumped router | `test/widget/` |
| Golden | Looks like this PNG | fixtures + fixed clock | `test/golden/` |
| Integration | Multi-screen flows with real wiring | in-memory fake + fixed `Clock` | `integration_test/` |

Bloc/Cubit tests are **not** widget tests. They use `bloc_test` and live under `test/bloc/`.

## Tool choices

| Tool | Why here |
|------|----------|
| `flutter_test` | Unit + widget baseline |
| `bloc_test` | Assert state sequences without pumping UI |
| `mocktail` | Lightweight mocks at collaboration boundaries |
| `golden_toolkit` | Fonts + `testGoldens` / `screenMatchesGolden` |
| `integration_test` | Device/emulator flows; CI on Android |
| `InMemoryTodoDataSource` | Stateful fake for app + integration |
| `FixedClock` | Deterministic overdue |

## Decision guide: what to test at which layer?

Ask what would make you trust the change — then pick the lowest layer that can prove it.

| If you care about… | Prefer | Skip / don't duplicate |
|--------------------|--------|-------------------------|
| Validation, overdue date-only, filter/sort, complete rules | **Unit** | Don't re-assert the same rule in every widget test |
| “CreateTodo does not hit repo when invalid” | **Unit** (mock repo + `verifyNever`) | |
| Loading → loaded / empty / error; filter updates list | **Bloc** | Don't pump widgets just to check states |
| Form submit success/failure, details load/toggle/delete | **Bloc/Cubit** | |
| Retry button visible; empty copy; list titles; FAB opens create | **Widget** | Don't re-test use-case validation messages in integration only |
| Light/dark list, empty/error chrome, phone vs tablet | **Golden** | Don't assert pixels in widget tests |
| Create → details → complete; filter → edit → delete | **Integration** (few) | Don't cover every validation path here |

**Quick rule:** unit for rules, bloc for transitions, widget for “on screen”, golden for “looks right”, integration for “wiring works end-to-end”.

### Mock vs fake

- **Fake** (`InMemoryTodoDataSource`) — needs multi-step state (create then list then delete). App + integration.
- **Mock** (mocktail) — assert one collaboration (called / not called, args). Unit / bloc / widget.

## Annotated snippets

### Unit — rule + collaboration

```dart
// test/unit/usecases_test.dart
test('validation failure does not call repository', () async {
  final useCase = CreateTodo(repository, validator);

  expect(
    () => useCase(
      id: 'todo-x',
      input: const TodoInput(
        title: '', // ← invalid: unit owns this rule
        description: '',
        priority: 'medium',
        dueDateInput: '2026-08-12',
      ),
    ),
    throwsA(isA<ValidationFailure>()),
  );
  verifyNever(() => repository.createTodo(any())); // ← mock checks the boundary
});
```

```dart
// test/unit/todo_validator_test.dart — pure, no doubles
test('rejects empty or whitespace title', () {
  expect(
    () => validator.validate(input(title: '   ')),
    throwsA(isA<ValidationFailure>()),
  );
});
```

### Bloc — event → state (no UI)

```dart
// test/bloc/todos_bloc_test.dart
blocTest<TodosBloc, TodosState>(
  'load emits loading then loaded',
  build: () {
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    return buildBloc();
  },
  act: (bloc) => bloc.add(const TodosLoadRequested()),
  expect: () => [
    isA<TodosLoading>(),
    isA<TodosLoaded>().having((s) => s.todos.length, 'count', 3),
  ],
);
```

### Widget — what's on screen

```dart
// test/widget/todos_page_test.dart
testWidgets('shows error view with retry', (tester) async {
  when(() => getTodos()).thenThrow(const ServerFailure('network down'));
  final bloc = createBloc()..add(const TodosLoadRequested());
  await pumpTodosPage(tester, bloc: bloc, clock: clock);
  await tester.pumpAndSettle();
  expect(find.byKey(TodosKeys.errorView), findsOneWidget);
  expect(find.byKey(TodosKeys.retryButton), findsOneWidget);
});
```

### Golden — pixels only

```dart
// test/golden/todos_golden_test.dart
testGoldens('empty state', (tester) async {
  await tester.pumpWidgetBuilder(
    wrap(const TodosEmptyView()),
    surfaceSize: const Size(390, 844),
  );
  await screenMatchesGolden(tester, 'todos_empty'); // ← PNG under test/golden/goldens/
});
```

### Integration — real wiring, fake DS

```dart
// integration_test/app_test.dart
testWidgets('create todo then open details and complete', (tester) async {
  final app = await IntegrationHarness.createApp(); // fake DS + fixed clock
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(TodosKeys.createFab));
  // … fill form, open details, toggle complete …
  expect(find.text('Mark as active'), findsOneWidget);
});
```

## pump vs pumpAndSettle

- **`pump`** — one frame (or a duration). Loading indicators, controlled async.
- **`pumpAndSettle`** — until idle. After nav / form submit when futures finish quickly.

Prefer mock-controlled futures over `Future.delayed` wall-clock sleeps.

## Determinism checklist

- Inject `Clock` (`FixedClock`) for overdue
- Seed todos with stable IDs/dates
- Complete futures via mocktail `thenAnswer`
- Set `FailureMode` only through the integration harness

## Architecture map

```
Widget / Integration → Pages
Bloc tests           → TodosBloc / TodoFormCubit / TodoDetailsCubit
Unit (use cases)     → domain/usecases
Unit (pure)          → entities, TodoValidator, TodoQuery
Unit (repo)          → TodoRepositoryImpl ↔ TodoDataSource
Fake                 → InMemoryTodoDataSource
```

Domain has no Flutter UI imports. Presentation depends inward via constructor-injected use cases. `get_it` stays in `lib/app/di.dart` + integration harness.
