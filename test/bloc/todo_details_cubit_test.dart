import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/delete_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/get_todo_by_id.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_details_cubit.dart';

import '../fixtures/todo_fixtures.dart';
import '../helpers/pump_app.dart';

class MockGetTodoById extends Mock implements GetTodoById {}

class MockDeleteTodoUseCase extends Mock implements DeleteTodo {}

void main() {
  late MockGetTodoById getTodoById;
  late MockToggleTodoCompletion toggleTodoCompletion;
  late MockDeleteTodoUseCase deleteTodo;

  setUpAll(registerFallbackValues);

  setUp(() {
    getTodoById = MockGetTodoById();
    toggleTodoCompletion = MockToggleTodoCompletion();
    deleteTodo = MockDeleteTodoUseCase();
  });

  TodoDetailsCubit buildCubit() => TodoDetailsCubit(
        todoId: 'todo-1',
        getTodoById: getTodoById,
        toggleTodoCompletion: toggleTodoCompletion,
        deleteTodo: deleteTodo,
      );

  blocTest<TodoDetailsCubit, TodoDetailsState>(
    'load emits loading then loaded',
    build: buildCubit,
    setUp: () {
      when(() => getTodoById('todo-1'))
          .thenAnswer((_) async => buildTodo());
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<TodoDetailsLoading>(),
      isA<TodoDetailsLoaded>(),
    ],
  );

  blocTest<TodoDetailsCubit, TodoDetailsState>(
    'load failure emits error',
    build: buildCubit,
    setUp: () {
      when(() => getTodoById('todo-1'))
          .thenThrow(const NotFoundFailure('missing'));
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<TodoDetailsLoading>(),
      isA<TodoDetailsError>().having((s) => s.message, 'message', 'missing'),
    ],
  );

  blocTest<TodoDetailsCubit, TodoDetailsState>(
    'toggle updates loaded todo',
    build: buildCubit,
    seed: () => TodoDetailsLoaded(todo: buildTodo()),
    setUp: () {
      when(() => toggleTodoCompletion(any())).thenAnswer((invocation) async {
        final todo = invocation.positionalArguments.first as Todo;
        return todo.complete();
      });
    },
    act: (cubit) => cubit.toggleCompleted(),
    expect: () => [
      isA<TodoDetailsLoaded>()
          .having((s) => s.todo.completed, 'completed', isTrue),
    ],
  );

  blocTest<TodoDetailsCubit, TodoDetailsState>(
    'delete emits deleted',
    build: buildCubit,
    seed: () => TodoDetailsLoaded(todo: buildTodo()),
    setUp: () {
      when(() => deleteTodo('todo-1')).thenAnswer((_) async {});
    },
    act: (cubit) => cubit.delete(),
    expect: () => [
      isA<TodoDetailsDeleted>().having((s) => s.id, 'id', 'todo-1'),
    ],
  );
}
