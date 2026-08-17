import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/home_widget_todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/data/repositories/todo_repository_impl.dart';

import '../helpers/fake_home_widget_todo_service.dart';

class MockTodoDataSource extends Mock implements TodoDataSource {}

void main() {
  test('maps data source exceptions to ServerFailure', () async {
    final dataSource = MockTodoDataSource();
    when(dataSource.getTodos).thenThrow(
      const DataSourceException('Simulated get failure'),
    );

    final repository = TodoRepositoryImpl(dataSource);

    expect(
      repository.getTodos,
      throwsA(
        isA<ServerFailure>().having(
          (f) => f.message,
          'message',
          'Simulated get failure',
        ),
      ),
    );
  });

  test('maps not-found data source errors to NotFoundFailure', () async {
    final dataSource = MockTodoDataSource();
    when(() => dataSource.getTodoById('missing')).thenThrow(
      const DataSourceException('Todo missing not found'),
    );

    final repository = TodoRepositoryImpl(dataSource);

    expect(
      () => repository.getTodoById('missing'),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('json store persists created todos', () async {
    final source = HomeWidgetTodoDataSource(
      service: FakeHomeWidgetTodoService(),
      seed: const [],
    );
    final repository = TodoRepositoryImpl(source);

    await repository.createTodo(
      const TodoModel(
        id: 'new',
        title: 'Created',
        description: '',
        priority: 'medium',
        dueDate: '2026-08-12',
        completed: false,
        tags: [],
      ).toEntity(),
    );

    final todos = await repository.getTodos();
    expect(todos.single.title, 'Created');
  });
}
