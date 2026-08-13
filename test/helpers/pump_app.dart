import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/app/theme.dart';
import 'package:pdp_todo_app/app/theme_cubit.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/features/battery/domain/usecases/get_battery_level.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_cubit.dart';
import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:pdp_todo_app/features/connectivity/domain/usecases/watch_connectivity.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_cubit.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_state.dart';
import 'package:pdp_todo_app/features/messages/domain/usecases/send_ping.dart';
import 'package:pdp_todo_app/features/messages/presentation/bloc/messages_cubit.dart';
import 'package:pdp_todo_app/features/messages/presentation/messages_keys.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_query.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_validator.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/create_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/delete_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/get_todos.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/toggle_todo_completion.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/update_todo.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:pdp_todo_app/features/todos/presentation/pages/todos_page.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

class MockGetTodos extends Mock implements GetTodos {}

class MockDeleteTodo extends Mock implements DeleteTodo {}

class MockToggleTodoCompletion extends Mock implements ToggleTodoCompletion {}

class MockCreateTodo extends Mock implements CreateTodo {}

class MockUpdateTodo extends Mock implements UpdateTodo {}

class MockGetBatteryLevel extends Mock implements GetBatteryLevel {}

class MockWatchConnectivity extends Mock implements WatchConnectivity {}

class MockSendPing extends Mock implements SendPing {}

class FakeTodo extends Fake implements Todo {}

class FakeTodoInput extends Fake implements TodoInput {}

void registerFallbackValues() {
  registerFallbackValue(FakeTodo());
  registerFallbackValue(FakeTodoInput());
}

TodosBloc buildTodosBloc({
  required GetTodos getTodos,
  DeleteTodo? deleteTodo,
  ToggleTodoCompletion? toggleTodoCompletion,
  Clock? clock,
}) {
  return TodosBloc(
    getTodos: getTodos,
    deleteTodo: deleteTodo ?? MockDeleteTodo(),
    toggleTodoCompletion: toggleTodoCompletion ?? MockToggleTodoCompletion(),
    todoQuery: const TodoQuery(),
    clock: clock ?? FixedClock(DateTime(2026, 8, 12, 15)),
  );
}

Future<BatteryCubit> buildLoadedBatteryCubit({int level = 85}) async {
  final getBatteryLevel = MockGetBatteryLevel();
  when(getBatteryLevel.call).thenAnswer((_) async => level);
  final cubit = BatteryCubit(getBatteryLevel);
  await cubit.getBatteryLevel();
  return cubit;
}

Future<ConnectivityCubit> buildLoadedConnectivityCubit({
  ConnectivityStatus status = ConnectivityStatus.wifi,
}) async {
  final watchConnectivity = MockWatchConnectivity();
  when(watchConnectivity.call).thenAnswer((_) => Stream.value(status));
  final cubit = ConnectivityCubit(watchConnectivity);
  final loaded = cubit.stream.firstWhere(
    (state) => state is ConnectivityLoaded,
  );
  cubit.watch();
  await loaded;
  return cubit;
}

MessagesCubit buildMessagesCubit() {
  final sendPing = MockSendPing();
  when(
    () => sendPing(
      id: any(named: 'id'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer(
    (invocation) async => throw StateError('sendPing not stubbed'),
  );
  return MessagesCubit(sendPing: sendPing);
}
Future<void> pumpTodosPage(
  WidgetTester tester, {
  required TodosBloc bloc,
  Clock? clock,
  ThemeCubit? themeCubit,
  BatteryCubit? batteryCubit,
  ConnectivityCubit? connectivityCubit,
  MessagesCubit? messagesCubit,
  ThemeMode themeMode = ThemeMode.light,
  Size surfaceSize = const Size(390, 844),
  void Function(String location)? onNavigate,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  final resolvedThemeCubit = themeCubit ?? ThemeCubit(themeMode);
  addTearDown(resolvedThemeCubit.close);

  final resolvedBatteryCubit = batteryCubit ?? await buildLoadedBatteryCubit();
  if (batteryCubit == null) {
    addTearDown(resolvedBatteryCubit.close);
  }

  final resolvedConnectivityCubit =
      connectivityCubit ?? await buildLoadedConnectivityCubit();
  if (connectivityCubit == null) {
    addTearDown(resolvedConnectivityCubit.close);
  }

  final resolvedMessagesCubit = messagesCubit ?? buildMessagesCubit();
  if (messagesCubit == null) {
    addTearDown(resolvedMessagesCubit.close);
  }

  final router = GoRouter(
    initialLocation: AppRoutes.todos,
    routes: [
      GoRoute(
        path: AppRoutes.todos,
        builder: (context, state) => TodosPage(
          clock: clock ?? FixedClock(DateTime(2026, 8, 12, 15)),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.createRelative,
            builder: (context, state) {
              onNavigate?.call(AppRoutes.create);
              return const Scaffold(
                key: TodosKeys.createRouteStub,
                body: Text('Create stub'),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.idRelative,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              onNavigate?.call(AppRoutes.details(id));
              return Scaffold(
                key: TodosKeys.detailsRouteStub(id),
                body: Text('Details $id'),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) {
          onNavigate?.call(AppRoutes.messages);
          return const Scaffold(
            key: MessagesKeys.page,
            body: Text('Messages stub'),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider.value(value: resolvedThemeCubit),
        BlocProvider.value(value: resolvedBatteryCubit),
        BlocProvider.value(value: resolvedConnectivityCubit),
        BlocProvider.value(value: resolvedMessagesCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return MaterialApp.router(
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: mode,
            routerConfig: router,
          );
        },
      ),
    ),
  );
}
