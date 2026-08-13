import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/app/theme_cubit.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/features/messages/presentation/messages_keys.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_filter.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_sort.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_validator.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/create_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/update_todo.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_form_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:pdp_todo_app/features/todos/presentation/pages/create_todo_page.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todo_list_item.dart';

import '../fixtures/todo_fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  late MockGetTodos getTodos;
  late MockDeleteTodo deleteTodo;
  late MockToggleTodoCompletion toggleTodoCompletion;
  final clock = FixedClock(DateTime(2026, 8, 12, 15));

  setUpAll(registerFallbackValues);

  setUp(() {
    getTodos = MockGetTodos();
    deleteTodo = MockDeleteTodo();
    toggleTodoCompletion = MockToggleTodoCompletion();
  });

  TodosBloc createBloc() => buildTodosBloc(
    getTodos: getTodos,
    deleteTodo: deleteTodo,
    toggleTodoCompletion: toggleTodoCompletion,
    clock: clock,
  );

  testWidgets('shows loading view', (tester) async {
    when(() => getTodos()).thenAnswer(
      (_) => Future<List<Todo>>.delayed(
        const Duration(milliseconds: 50),
        buildTodoList,
      ),
    );
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(tester, bloc: bloc, clock: clock);
    expect(find.byKey(TodosKeys.loadingView), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('shows empty view', (tester) async {
    when(() => getTodos()).thenAnswer((_) async => []);
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(tester, bloc: bloc, clock: clock);
    await tester.pumpAndSettle();
    expect(find.byKey(TodosKeys.emptyView), findsOneWidget);
  });

  testWidgets('shows error view with retry', (tester) async {
    when(() => getTodos()).thenThrow(const ServerFailure('network down'));
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(tester, bloc: bloc, clock: clock);
    await tester.pumpAndSettle();
    expect(find.byKey(TodosKeys.errorView), findsOneWidget);
    expect(find.byKey(TodosKeys.retryButton), findsOneWidget);
  });

  testWidgets('loaded list renders titles', (tester) async {
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(tester, bloc: bloc, clock: clock);
    await tester.pumpAndSettle();
    expect(find.text('Write unit tests'), findsOneWidget);
    expect(find.text('Add widget tests'), findsOneWidget);
  });

  testWidgets(
    'todo item shows priority and overdue affordance',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoListItem(
              todo: buildTodo(
                id: 'overdue',
                title: 'Overdue item',
                dueDate: DateTime(2026, 8, 10),
              ),
              clock: clock,
            ),
          ),
        ),
      );
      expect(find.text('Medium'), findsOneWidget);
      expect(find.byKey(TodosKeys.overdue('overdue')), findsOneWidget);
    },
  );

  testWidgets('filter chip changes visible items', (tester) async {
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(tester, bloc: bloc, clock: clock);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.filter(TodoFilter.completed)));
    await tester.pumpAndSettle();

    expect(find.text('Document CI'), findsOneWidget);
    expect(find.text('Write unit tests'), findsNothing);
  });

  testWidgets('sort changes order', (tester) async {
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(tester, bloc: bloc, clock: clock);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.sortMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TodosKeys.sort(TodoSort.priority)));
    await tester.pumpAndSettle();

    final titles = tester.widgetList<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == 'Write unit tests' ||
                widget.data == 'Add widget tests' ||
                widget.data == 'Document CI'),
      ),
    );
    expect(titles.first.data, 'Write unit tests');
  });

  testWidgets('create form shows title validation error', (tester) async {
    final repository = MockTodoRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TodoFormCubit(
            createTodo: CreateTodo(repository, const TodoValidator()),
            updateTodo: UpdateTodo(repository, const TodoValidator()),
          ),
          child: const TodoFormPage(title: 'Create Todo'),
        ),
      ),
    );

    await tester.tap(find.byKey(TodosKeys.submitButton));
    await tester.pumpAndSettle();
    expect(find.text('Title cannot be empty'), findsOneWidget);
  });

  testWidgets('create form shows invalid due-date validation error', (
    tester,
  ) async {
    final repository = MockTodoRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TodoFormCubit(
            createTodo: CreateTodo(repository, const TodoValidator()),
            updateTodo: UpdateTodo(repository, const TodoValidator()),
          ),
          child: const TodoFormPage(title: 'Create Todo'),
        ),
      ),
    );

    await tester.enterText(find.byKey(TodosKeys.titleField), 'Valid');
    await tester.enterText(
      find.byKey(TodosKeys.dueDateField),
      '2026-02-30',
    );
    await tester.tap(find.byKey(TodosKeys.submitButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('valid calendar date'), findsOneWidget);
  });

  testWidgets('toggle complete from list item', (tester) async {
    final todos = buildTodoList();
    when(() => getTodos()).thenAnswer((_) async => todos);
    when(() => toggleTodoCompletion(any())).thenAnswer((invocation) async {
      final todo = invocation.positionalArguments.first as Todo;
      return todo.complete();
    });
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(tester, bloc: bloc, clock: clock);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.toggle('todo-2')));
    await tester.pumpAndSettle();
    verify(() => toggleTodoCompletion(any())).called(1);
  });

  testWidgets('delete removes item from list UI', (tester) async {
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    when(() => deleteTodo(any())).thenAnswer((_) async {});
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(tester, bloc: bloc, clock: clock);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.delete('todo-1')));
    await tester.pumpAndSettle();
    expect(find.text('Write unit tests'), findsNothing);
  });

  testWidgets('tap item navigates to details', (tester) async {
    String? navigated;
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(
      tester,
      bloc: bloc,
      clock: clock,
      onNavigate: (location) => navigated = location,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.item('todo-1')));
    await tester.pumpAndSettle();
    expect(navigated, AppRoutes.details('todo-1'));
    expect(find.byKey(TodosKeys.detailsRouteStub('todo-1')), findsOneWidget);
  });

  testWidgets('FAB opens create route', (tester) async {
    String? navigated;
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(
      tester,
      bloc: bloc,
      clock: clock,
      onNavigate: (location) => navigated = location,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodosKeys.createFab));
    await tester.pumpAndSettle();
    expect(navigated, AppRoutes.create);
  });

  testWidgets('messages button opens messages route', (tester) async {
    String? navigated;
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(
      tester,
      bloc: bloc,
      clock: clock,
      onNavigate: (location) => navigated = location,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(MessagesKeys.openButton));
    await tester.pumpAndSettle();
    expect(navigated, AppRoutes.messages);
    expect(find.byKey(MessagesKeys.page), findsOneWidget);
  });

  testWidgets('dark theme smoke on list', (tester) async {
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(
      tester,
      bloc: bloc,
      clock: clock,
      themeMode: ThemeMode.dark,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(TodosKeys.list), findsOneWidget);
  });

  testWidgets('theme toggle cycles mode', (tester) async {
    when(() => getTodos()).thenAnswer((_) async => buildTodoList());
    final themeCubit = ThemeCubit(ThemeMode.light);
    final bloc = createBloc()..add(const TodosLoadRequested());
    await pumpTodosPage(
      tester,
      bloc: bloc,
      clock: clock,
      themeCubit: themeCubit,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(TodosKeys.themeToggle), findsOneWidget);
    expect(themeCubit.state, ThemeMode.light);

    await tester.tap(find.byKey(TodosKeys.themeToggle));
    await tester.pump();
    expect(themeCubit.state, ThemeMode.dark);

    await tester.tap(find.byKey(TodosKeys.themeToggle));
    await tester.pump();
    expect(themeCubit.state, ThemeMode.system);
  });
}
