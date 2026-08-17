import 'package:flutter/material.dart';
import 'package:pdp_todo_app/app/app.dart';
import 'package:pdp_todo_app/app/di.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/home_widget_todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';

import '../test/helpers/fake_home_widget_todo_service.dart';

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
      dataSource: HomeWidgetTodoDataSource(
        service: FakeHomeWidgetTodoService(),
        seed: seed,
        failureMode: failureMode,
      ),
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
