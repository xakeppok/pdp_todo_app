import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_validator.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/create_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/delete_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/get_todo_by_id.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/get_todos.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/toggle_todo_completion.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/update_todo.dart';

import '../fixtures/todo_fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  late MockTodoRepository repository;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockTodoRepository();
  });

  group('GetTodos', () {
    test('returns repository list', () async {
      final todos = buildTodoList();
      when(() => repository.getTodos()).thenAnswer((_) async => todos);

      final result = await GetTodos(repository)();

      expect(result, todos);
      verify(() => repository.getTodos()).called(1);
    });
  });

  group('GetTodoById', () {
    test('returns todo when found', () async {
      final todo = buildTodo();
      when(() => repository.getTodoById('todo-1'))
          .thenAnswer((_) async => todo);

      final result = await GetTodoById(repository)('todo-1');

      expect(result, todo);
    });

    test('propagates not-found failure from repository', () async {
      when(() => repository.getTodoById('missing')).thenThrow(
        const NotFoundFailure('Todo missing not found'),
      );

      expect(
        () => GetTodoById(repository)('missing'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('CreateTodo', () {
    const validator = TodoValidator();

    test('validation failure does not call repository', () async {
      final useCase = CreateTodo(repository, validator);

      expect(
        () => useCase(
          id: 'todo-x',
          input: const TodoInput(
            title: '',
            description: '',
            priority: 'medium',
            dueDateInput: '2026-08-12',
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(() => repository.createTodo(any()));
    });

    test('success delegates to repository', () async {
      when(() => repository.createTodo(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as Todo,
      );

      final created = await CreateTodo(repository, validator)(
        id: 'todo-x',
        input: const TodoInput(
          title: 'New todo',
          description: 'Body',
          priority: 'high',
          dueDateInput: '2026-08-15',
          tags: ['new'],
        ),
      );

      expect(created.title, 'New todo');
      verify(() => repository.createTodo(any())).called(1);
    });
  });

  group('UpdateTodo', () {
    const validator = TodoValidator();

    test('validation failure does not call repository; success delegates',
        () async {
      final existing = buildTodo();
      final useCase = UpdateTodo(repository, validator);

      expect(
        () => useCase(
          existing: existing,
          input: const TodoInput(
            title: '',
            description: '',
            priority: 'medium',
            dueDateInput: '2026-08-12',
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(() => repository.updateTodo(any()));

      when(() => repository.updateTodo(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as Todo,
      );

      final updated = await useCase(
        existing: existing,
        input: const TodoInput(
          title: 'Updated',
          description: 'Body',
          priority: 'low',
          dueDateInput: '2026-08-18',
        ),
      );

      expect(updated.title, 'Updated');
      verify(() => repository.updateTodo(any())).called(1);
    });
  });

  group('DeleteTodo', () {
    test('delegates to repository', () async {
      when(() => repository.deleteTodo('todo-1')).thenAnswer((_) async {});

      await DeleteTodo(repository)('todo-1');

      verify(() => repository.deleteTodo('todo-1')).called(1);
    });
  });

  group('ToggleTodoCompletion', () {
    test('already-completed complete request fails without write', () async {
      final todo = buildTodo(completed: true);

      expect(
        () => ToggleTodoCompletion(repository)(todo, completed: true),
        throwsA(isA<DomainFailure>()),
      );
      verifyNever(() => repository.updateTodo(any()));
    });

    test('active todo completes via repository', () async {
      final todo = buildTodo();
      when(() => repository.updateTodo(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as Todo,
      );

      final updated = await ToggleTodoCompletion(repository)(todo);

      expect(updated.completed, isTrue);
      verify(() => repository.updateTodo(any())).called(1);
    });
  });
}
