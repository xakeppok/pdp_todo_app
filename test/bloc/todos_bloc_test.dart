import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_filter.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_sort.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';

import '../fixtures/todo_fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  late MockGetTodos getTodos;
  late MockDeleteTodo deleteTodo;
  late MockToggleTodoCompletion toggleTodoCompletion;

  setUpAll(registerFallbackValues);

  setUp(() {
    getTodos = MockGetTodos();
    deleteTodo = MockDeleteTodo();
    toggleTodoCompletion = MockToggleTodoCompletion();
  });

  TodosBloc buildBloc() => buildTodosBloc(
        getTodos: getTodos,
        deleteTodo: deleteTodo,
        toggleTodoCompletion: toggleTodoCompletion,
      );

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

  blocTest<TodosBloc, TodosState>(
    'load with empty repo emits empty',
    build: () {
      when(() => getTodos()).thenAnswer((_) async => []);
      return buildBloc();
    },
    act: (bloc) => bloc.add(const TodosLoadRequested()),
    expect: () => [
      isA<TodosLoading>(),
      isA<TodosEmpty>(),
    ],
  );

  blocTest<TodosBloc, TodosState>(
    'load failure emits error',
    build: () {
      when(() => getTodos()).thenThrow(const ServerFailure('boom'));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const TodosLoadRequested()),
    expect: () => [
      isA<TodosLoading>(),
      isA<TodosError>().having((s) => s.message, 'message', 'boom'),
    ],
  );

  blocTest<TodosBloc, TodosState>(
    'retry after error emits loaded',
    build: () {
      var calls = 0;
      when(() => getTodos()).thenAnswer((_) async {
        calls += 1;
        if (calls == 1) {
          throw const ServerFailure('boom');
        }
        return buildTodoList();
      });
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const TodosLoadRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TodosRetryRequested());
    },
    expect: () => [
      isA<TodosLoading>(),
      isA<TodosError>(),
      isA<TodosLoading>(),
      isA<TodosLoaded>(),
    ],
  );

  blocTest<TodosBloc, TodosState>(
    'filter and sort update loaded list',
    build: () {
      when(() => getTodos()).thenAnswer((_) async => buildTodoList());
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const TodosLoadRequested());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(const TodosFilterChanged(TodoFilter.active))
        ..add(const TodosSortChanged(TodoSort.priority));
    },
    expect: () => [
      isA<TodosLoading>(),
      isA<TodosLoaded>(),
      isA<TodosLoaded>()
          .having((s) => s.filter, 'filter', TodoFilter.active)
          .having((s) => s.todos.length, 'active count', 2),
      isA<TodosLoaded>()
          .having((s) => s.sort, 'sort', TodoSort.priority)
          .having((s) => s.todos.first.priority.name, 'first', 'high'),
    ],
  );

  blocTest<TodosBloc, TodosState>(
    'toggle complete and delete update state',
    build: () {
      final todos = buildTodoList();
      when(() => getTodos()).thenAnswer((_) async => List<Todo>.from(todos));
      when(() => toggleTodoCompletion(any())).thenAnswer((invocation) async {
        final todo = invocation.positionalArguments.first as Todo;
        return todo.complete();
      });
      when(() => deleteTodo(any())).thenAnswer((_) async {});
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const TodosLoadRequested());
      await Future<void>.delayed(Duration.zero);
      final loaded = bloc.state as TodosLoaded;
      final target = loaded.todos.firstWhere((t) => t.id == 'todo-2');
      bloc.add(TodosToggleCompleted(target));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TodosDeleteRequested('todo-1'));
    },
    expect: () => [
      isA<TodosLoading>(),
      isA<TodosLoaded>(),
      isA<TodosLoaded>().having(
        (s) => s.allTodos.firstWhere((t) => t.id == 'todo-2').completed,
        'completed',
        isTrue,
      ),
      isA<TodosLoaded>().having(
        (s) => s.allTodos.any((t) => t.id == 'todo-1'),
        'deleted',
        isFalse,
      ),
    ],
  );

  blocTest<TodosBloc, TodosState>(
    'upsert and remove update list without reload',
    build: () {
      when(() => getTodos()).thenAnswer((_) async => buildTodoList());
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const TodosLoadRequested());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(
          TodosItemUpserted(
            buildTodo(id: 'todo-new', title: 'Brand new'),
          ),
        )
        ..add(const TodosItemRemoved('todo-1'));
    },
    expect: () => [
      isA<TodosLoading>(),
      isA<TodosLoaded>(),
      isA<TodosLoaded>().having(
        (s) => s.allTodos.any((t) => t.id == 'todo-new'),
        'upserted',
        isTrue,
      ),
      isA<TodosLoaded>().having(
        (s) => s.allTodos.any((t) => t.id == 'todo-1'),
        'removed',
        isFalse,
      ),
    ],
  );

  blocTest<TodosBloc, TodosState>(
    'filter during error updates state without leaving error',
    build: () {
      when(() => getTodos()).thenThrow(const ServerFailure('boom'));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const TodosLoadRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TodosFilterChanged(TodoFilter.active));
    },
    expect: () => [
      isA<TodosLoading>(),
      isA<TodosError>().having((s) => s.message, 'message', 'boom'),
      isA<TodosError>()
          .having((s) => s.message, 'message', 'boom')
          .having((s) => s.filter, 'filter', TodoFilter.active),
    ],
  );

  blocTest<TodosBloc, TodosState>(
    'delete failure keeps list and sets actionMessage',
    build: () {
      when(() => getTodos()).thenAnswer((_) async => buildTodoList());
      when(() => deleteTodo(any()))
          .thenThrow(const ServerFailure('delete failed'));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const TodosLoadRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TodosDeleteRequested('todo-1'));
    },
    expect: () => [
      isA<TodosLoading>(),
      isA<TodosLoaded>(),
      isA<TodosLoaded>().having(
        (s) => s.actionMessage,
        'actionMessage',
        'delete failed',
      ),
    ],
  );

  blocTest<TodosBloc, TodosState>(
    'clear action message resets snackbar payload',
    build: () {
      when(() => getTodos()).thenAnswer((_) async => buildTodoList());
      when(() => deleteTodo(any()))
          .thenThrow(const ServerFailure('delete failed'));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const TodosLoadRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TodosDeleteRequested('todo-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TodosActionMessageCleared());
    },
    expect: () => [
      isA<TodosLoading>(),
      isA<TodosLoaded>(),
      isA<TodosLoaded>().having(
        (s) => s.actionMessage,
        'actionMessage',
        'delete failed',
      ),
      isA<TodosLoaded>().having((s) => s.actionMessage, 'cleared', isNull),
    ],
  );
}
