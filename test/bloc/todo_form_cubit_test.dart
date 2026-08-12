import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_validator.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/create_todo.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_form_cubit.dart';

import '../fixtures/todo_fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  late MockTodoRepository repository;
  late MockCreateTodo createTodo;
  late MockUpdateTodo updateTodo;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockTodoRepository();
    createTodo = MockCreateTodo();
    updateTodo = MockUpdateTodo();
  });

  blocTest<TodoFormCubit, TodoFormState>(
    'submit with invalid input emits validation failure',
    build: () => TodoFormCubit(
      createTodo: CreateTodo(repository, const TodoValidator()),
      updateTodo: updateTodo,
      idGenerator: () => 'generated-id',
    ),
    act: (cubit) async {
      cubit
        ..titleChanged('')
        ..dueDateChanged('2026-02-30');
      await cubit.submit();
    },
    expect: () => [
      isA<TodoFormState>().having((s) => s.title, 'title', ''),
      isA<TodoFormState>().having((s) => s.dueDateInput, 'due', '2026-02-30'),
      isA<TodoFormState>()
          .having((s) => s.status, 'status', TodoFormStatus.submitting),
      isA<TodoFormState>()
          .having((s) => s.status, 'status', TodoFormStatus.failure)
          .having((s) => s.fieldErrors.isNotEmpty, 'field errors', isTrue),
    ],
    verify: (_) {
      verifyNever(() => repository.createTodo(any()));
    },
  );

  blocTest<TodoFormCubit, TodoFormState>(
    'submit success emits success with saved todo',
    build: () => TodoFormCubit(
      createTodo: createTodo,
      updateTodo: updateTodo,
      idGenerator: () => 'generated-id',
    ),
    setUp: () {
      when(
        () => createTodo(
          id: any(named: 'id'),
          input: any(named: 'input'),
        ),
      ).thenAnswer((_) async => buildTodo(id: 'generated-id', title: 'New'));
    },
    act: (cubit) async {
      cubit
        ..titleChanged('New')
        ..dueDateChanged('2026-08-15');
      await cubit.submit();
    },
    expect: () => [
      isA<TodoFormState>(),
      isA<TodoFormState>(),
      isA<TodoFormState>()
          .having((s) => s.status, 'status', TodoFormStatus.submitting),
      isA<TodoFormState>()
          .having((s) => s.status, 'status', TodoFormStatus.success)
          .having((s) => s.savedTodo?.title, 'saved', 'New'),
    ],
  );

  blocTest<TodoFormCubit, TodoFormState>(
    'submit failure from use case emits failure',
    build: () => TodoFormCubit(
      createTodo: createTodo,
      updateTodo: updateTodo,
      idGenerator: () => 'generated-id',
    ),
    setUp: () {
      when(
        () => createTodo(
          id: any(named: 'id'),
          input: any(named: 'input'),
        ),
      ).thenThrow(const ServerFailure('write failed'));
    },
    act: (cubit) async {
      cubit
        ..titleChanged('New')
        ..dueDateChanged('2026-08-15');
      await cubit.submit();
    },
    expect: () => [
      isA<TodoFormState>(),
      isA<TodoFormState>(),
      isA<TodoFormState>()
          .having((s) => s.status, 'status', TodoFormStatus.submitting),
      isA<TodoFormState>()
          .having((s) => s.status, 'status', TodoFormStatus.failure)
          .having((s) => s.errorMessage, 'error', 'write failed'),
    ],
  );
}
