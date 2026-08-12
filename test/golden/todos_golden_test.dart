import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/app/theme.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todo_list_item.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todos_empty_view.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todos_error_view.dart';

import '../fixtures/todo_fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 8, 12, 15));

  setUpAll(() async {
    await loadAppFonts();
    registerFallbackValues();
  });

  Widget wrap(Widget child, {ThemeMode mode = ThemeMode.light}) {
    return MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      home: Scaffold(body: child),
    );
  }

  testGoldens('todo list with data phone light', (tester) async {
    final getTodos = MockGetTodos();
    when(getTodos.call).thenAnswer((_) async => buildTodoList());
    final bloc = buildTodosBloc(getTodos: getTodos, clock: clock)
      ..add(const TodosLoadRequested());

    await pumpTodosPage(
      tester,
      bloc: bloc,
      clock: clock,
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'todos_list_phone_light');
  });

  testGoldens('empty state', (tester) async {
    await tester.pumpWidgetBuilder(
      wrap(const TodosEmptyView()),
      surfaceSize: const Size(390, 844),
    );
    await screenMatchesGolden(tester, 'todos_empty');
  });

  testGoldens('error state', (tester) async {
    await tester.pumpWidgetBuilder(
      wrap(
        const TodosErrorView(
          message: 'Simulated get failure',
          onRetry: _noop,
        ),
      ),
      surfaceSize: const Size(390, 844),
    );
    await screenMatchesGolden(tester, 'todos_error');
  });

  testGoldens('todo item', (tester) async {
    await tester.pumpWidgetBuilder(
      wrap(
        TodoListItem(
          todo: buildTodo(
            title: 'Write unit tests',
            dueDate: DateTime(2026, 8, 10),
          ),
          clock: clock,
          onToggleCompleted: _noop,
          onDelete: _noop,
        ),
      ),
      surfaceSize: const Size(390, 120),
    );
    await screenMatchesGolden(tester, 'todo_item');
  });

  testGoldens('dark theme list', (tester) async {
    final getTodos = MockGetTodos();
    when(getTodos.call).thenAnswer((_) async => buildTodoList());
    final bloc = buildTodosBloc(getTodos: getTodos, clock: clock)
      ..add(const TodosLoadRequested());

    await pumpTodosPage(
      tester,
      bloc: bloc,
      clock: clock,
      themeMode: ThemeMode.dark,
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'todos_list_phone_dark');
  });

  testGoldens('tablet wide list', (tester) async {
    final getTodos = MockGetTodos();
    when(getTodos.call).thenAnswer((_) async => buildTodoList());
    final bloc = buildTodosBloc(getTodos: getTodos, clock: clock)
      ..add(const TodosLoadRequested());

    await pumpTodosPage(
      tester,
      bloc: bloc,
      clock: clock,
      surfaceSize: const Size(1024, 768),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'todos_list_tablet');
  });
}

void _noop() {}
