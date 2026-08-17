import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/app/theme_cubit.dart';
import 'package:pdp_todo_app/core/router/app_router.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/get_todo_by_id.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_details_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

import '../fixtures/todo_fixtures.dart';
import '../helpers/pump_app.dart';

class MockGetTodoById extends Mock implements GetTodoById {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerFallbackValues);

  testWidgets('going to another details todo rebuilds the page', (
    tester,
  ) async {
    final getTodoById = MockGetTodoById();
    when(() => getTodoById('todo-1')).thenAnswer(
      (_) async => buildTodo(title: 'First todo'),
    );
    when(() => getTodoById('todo-2')).thenAnswer(
      (_) async => buildTodo(id: 'todo-2', title: 'Second todo'),
    );

    final router = createAppRouter(
      clock: testClock,
      createFormCubit: ({initialTodo}) {
        throw UnimplementedError();
      },
      createDetailsCubit: (id) {
        final cubit = TodoDetailsCubit(
          todoId: id,
          getTodoById: getTodoById,
          toggleTodoCompletion: MockToggleTodoCompletion(),
          deleteTodo: MockDeleteTodo(),
        );
        unawaited(cubit.load());
        return cubit;
      },
      createMapCubit: () {
        throw UnimplementedError();
      },
      initialLocation: AppRoutes.details('todo-1'),
    );

    final getTodos = MockGetTodos();
    when(getTodos.call).thenAnswer((_) async => const []);
    final todosBloc = buildTodosBloc(getTodos: getTodos);
    final themeCubit = ThemeCubit(ThemeMode.light);
    final batteryCubit = await buildLoadedBatteryCubit();
    final connectivityCubit = await buildLoadedConnectivityCubit();
    addTearDown(todosBloc.close);
    addTearDown(themeCubit.close);
    addTearDown(batteryCubit.close);
    addTearDown(connectivityCubit.close);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: todosBloc),
          BlocProvider.value(value: themeCubit),
          BlocProvider.value(value: batteryCubit),
          BlocProvider.value(value: connectivityCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(_detailsTitle(tester), 'First todo');

    router.go(AppRoutes.details('todo-2'));
    await tester.pumpAndSettle();

    expect(_detailsTitle(tester), 'Second todo');
  });
}

String _detailsTitle(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(TodosKeys.detailsTitle)).data!;
}
