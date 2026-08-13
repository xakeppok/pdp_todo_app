import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/router/app_router.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_platform_data_source.dart';
import 'package:pdp_todo_app/features/battery/data/repositories/battery_repository_impl.dart';
import 'package:pdp_todo_app/features/battery/domain/repositories/battery_repository.dart';
import 'package:pdp_todo_app/features/battery/domain/usecases/get_battery_level.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_cubit.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/in_memory_todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/data/repositories/todo_repository_impl.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_query.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_validator.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/create_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/delete_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/get_todo_by_id.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/get_todos.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/toggle_todo_completion.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/update_todo.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_details_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_form_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({
  Clock? clock,
  TodoDataSource? dataSource,
  List<TodoModel>? seed,
  FailureMode failureMode = FailureMode.none,
  bool reset = false,
}) async {
  if (reset) {
    await getIt.reset();
  }

  final resolvedClock = clock ?? const SystemClock();
  final resolvedDataSource =
      dataSource ??
      InMemoryTodoDataSource(seed: seed, failureMode: failureMode);

  getIt
    ..registerSingleton<Clock>(resolvedClock)
    ..registerSingleton<TodoDataSource>(resolvedDataSource)
    ..registerLazySingleton<TodoRepository>(
      () => TodoRepositoryImpl(getIt<TodoDataSource>()),
    )
    ..registerLazySingleton(() => GetTodos(getIt()))
    ..registerLazySingleton(() => GetTodoById(getIt()))
    ..registerLazySingleton(
      () => CreateTodo(getIt(), const TodoValidator()),
    )
    ..registerLazySingleton(
      () => UpdateTodo(getIt(), const TodoValidator()),
    )
    ..registerLazySingleton(() => DeleteTodo(getIt()))
    ..registerLazySingleton(() => ToggleTodoCompletion(getIt()))
    ..registerLazySingleton(BatteryPlatformDataSource.new)
    ..registerLazySingleton<BatteryRepository>(
      () => BatteryRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetBatteryLevel(getIt<BatteryRepository>()))
    ..registerLazySingleton(() => BatteryCubit(getIt()));
}

TodosBloc createTodosBloc() {
  return TodosBloc(
    getTodos: getIt(),
    deleteTodo: getIt(),
    toggleTodoCompletion: getIt(),
    todoQuery: const TodoQuery(),
    clock: getIt(),
  );
}

TodoFormCubit createTodoFormCubit({Todo? initialTodo}) {
  return TodoFormCubit(
    createTodo: getIt(),
    updateTodo: getIt(),
    initialTodo: initialTodo,
  );
}

TodoDetailsCubit createTodoDetailsCubit(String todoId) {
  final cubit = TodoDetailsCubit(
    todoId: todoId,
    getTodoById: getIt(),
    toggleTodoCompletion: getIt(),
    deleteTodo: getIt(),
  );
  unawaited(cubit.load());
  return cubit;
}

GoRouter createConfiguredRouter({String initialLocation = AppRoutes.todos}) {
  return createAppRouter(
    clock: getIt<Clock>(),
    createFormCubit: createTodoFormCubit,
    createDetailsCubit: createTodoDetailsCubit,
    initialLocation: initialLocation,
  );
}

void setDataSourceFailureMode(FailureMode mode) {
  getIt<TodoDataSource>().failureMode = mode;
}

FailureMode getDataSourceFailureMode() {
  return getIt<TodoDataSource>().failureMode;
}
