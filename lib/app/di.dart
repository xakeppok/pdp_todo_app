import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/router/app_router.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_data_source.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_pigeon_data_source.dart';
import 'package:pdp_todo_app/features/battery/data/repositories/battery_repository_impl.dart';
import 'package:pdp_todo_app/features/battery/domain/repositories/battery_repository.dart';
import 'package:pdp_todo_app/features/battery/domain/usecases/get_battery_level.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_cubit.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_data_source.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_pigeon_data_source.dart';
import 'package:pdp_todo_app/features/connectivity/data/repositories/connectivity_repository_impl.dart';
import 'package:pdp_todo_app/features/connectivity/domain/repositories/connectivity_repository.dart';
import 'package:pdp_todo_app/features/connectivity/domain/usecases/watch_connectivity.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_cubit.dart';
import 'package:pdp_todo_app/features/messages/data/datasources/messages_data_source.dart';
import 'package:pdp_todo_app/features/messages/data/datasources/messages_pigeon_data_source.dart';
import 'package:pdp_todo_app/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:pdp_todo_app/features/messages/domain/repositories/messages_repository.dart';
import 'package:pdp_todo_app/features/messages/domain/usecases/send_ping.dart';
import 'package:pdp_todo_app/features/messages/presentation/bloc/messages_cubit.dart';
import 'package:pdp_todo_app/features/native_map/data/datasources/map_data_source.dart';
import 'package:pdp_todo_app/features/native_map/data/datasources/map_pigeon_data_source.dart';
import 'package:pdp_todo_app/features/native_map/data/repositories/map_repository_impl.dart';
import 'package:pdp_todo_app/features/native_map/domain/repositories/map_repository.dart';
import 'package:pdp_todo_app/features/native_map/domain/usecases/watch_map_clicks.dart';
import 'package:pdp_todo_app/features/native_map/presentation/bloc/map_cubit.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/home_widget_todo_data_source.dart';
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
      HomeWidgetTodoDataSource(
        seed: seed,
        failureMode: failureMode,
      );

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
    ..registerLazySingleton<BatteryDataSource>(
      BatteryPigeonDataSource.new,
      // BatteryPlatformDataSource.new,
    )
    ..registerLazySingleton<BatteryRepository>(
      () => BatteryRepositoryImpl(getIt<BatteryDataSource>()),
    )
    ..registerLazySingleton(() => GetBatteryLevel(getIt<BatteryRepository>()))
    ..registerLazySingleton(() => BatteryCubit(getIt()))
    ..registerLazySingleton<ConnectivityDataSource>(
      ConnectivityPigeonDataSource.new,
      // ConnectivityPlatformDataSource.new,
    )
    ..registerLazySingleton<ConnectivityRepository>(
      () => ConnectivityRepositoryImpl(getIt<ConnectivityDataSource>()),
    )
    ..registerLazySingleton(
      () => WatchConnectivity(getIt<ConnectivityRepository>()),
    )
    ..registerLazySingleton(
      () => ConnectivityCubit(getIt<WatchConnectivity>()),
    )
    ..registerLazySingleton<MessagesDataSource>(
      MessagesPigeonDataSource.new,
      // MessagesPlatformDataSource.new,
    )
    ..registerLazySingleton<MessagesRepository>(
      () => MessagesRepositoryImpl(getIt<MessagesDataSource>()),
    )
    ..registerLazySingleton(() => SendPing(getIt<MessagesRepository>()))
    ..registerLazySingleton(
      () => MessagesCubit(sendPing: getIt()),
    )
    ..registerLazySingleton<MapDataSource>(MapPigeonDataSource.new)
    ..registerLazySingleton<MapRepository>(
      () => MapRepositoryImpl(getIt<MapDataSource>()),
    )
    ..registerLazySingleton(
      () => WatchMapClicks(getIt<MapRepository>()),
    )
    ..registerFactory(
      () => MapCubit(getIt<WatchMapClicks>()),
    );
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

MapCubit createMapCubit() {
  return getIt<MapCubit>()..watch();
}

GoRouter createConfiguredRouter({String initialLocation = AppRoutes.todos}) {
  return createAppRouter(
    clock: getIt<Clock>(),
    createFormCubit: createTodoFormCubit,
    createDetailsCubit: createTodoDetailsCubit,
    createMapCubit: createMapCubit,
    initialLocation: initialLocation,
  );
}

void setDataSourceFailureMode(FailureMode mode) {
  getIt<TodoDataSource>().failureMode = mode;
}

FailureMode getDataSourceFailureMode() {
  return getIt<TodoDataSource>().failureMode;
}
