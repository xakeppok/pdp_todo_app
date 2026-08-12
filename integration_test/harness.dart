import 'package:flutter/material.dart';
import 'package:pdp_todo_app/app/app.dart';
import 'package:pdp_todo_app/app/di.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';

/// Test-only bootstrap. Configures FailureMode without private DS fields.
class IntegrationHarness {
  IntegrationHarness._();

  static Future<Widget> createApp({
    List<TodoModel>? seed,
    FailureMode failureMode = FailureMode.none,
    DateTime? now,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await configureDependencies(
      reset: true,
      clock: FixedClock(now ?? DateTime(2026, 8, 12, 15)),
      seed: seed,
      failureMode: failureMode,
    );

    final bloc = createTodosBloc()..add(const TodosLoadRequested());
    return TodoApp(
      router: createConfiguredRouter(),
      todosBloc: bloc,
      themeMode: themeMode,
    );
  }

  static void setFailureMode(FailureMode mode) {
    setDataSourceFailureMode(mode);
  }
}
