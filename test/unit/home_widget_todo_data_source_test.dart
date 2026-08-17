import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/home_widget_todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/data/services/home_widget_todo_service.dart';

import '../helpers/fake_home_widget_todo_service.dart';

void main() {
  const extra = TodoModel(
    id: 'todo-5',
    title: 'Walk the dog',
    description: 'After dinner',
    priority: 'low',
    dueDate: '2026-08-14',
    completed: false,
    tags: ['home'],
  );

  HomeWidgetTodoDataSource buildSource(FakeHomeWidgetTodoService service) {
    return HomeWidgetTodoDataSource(service: service);
  }

  test('seeds default todos when the store is empty', () async {
    final service = FakeHomeWidgetTodoService();
    final source = buildSource(service);

    final todos = await source.getTodos();

    expect(
      todos.map((todo) => todo.id),
      defaultTodoSeed.map((todo) => todo.id),
    );
    expect(service.json, isNotNull);
    expect(service.saveCount, 1);
  });

  test('does not re-seed an explicitly empty list', () async {
    final service = FakeHomeWidgetTodoService('[]');
    final source = buildSource(service);

    expect(await source.getTodos(), isEmpty);
    expect(service.json, '[]');
  });

  test('re-reads widget toggles from the shared json store', () async {
    final service = FakeHomeWidgetTodoService();
    final source = buildSource(service);
    await source.getTodos();

    final current = TodoModel.listFromJsonString(service.json!);
    service.json = TodoModel.listToJsonString([
      for (final todo in current)
        if (todo.id == 'todo-1') todo.copyWith(completed: true) else todo,
    ]);

    final todos = await source.getTodos();
    expect(
      todos.firstWhere((todo) => todo.id == 'todo-1').completed,
      isTrue,
    );
    expect(
      todos.firstWhere((todo) => todo.id == 'todo-1').description,
      'Cover domain rules and use cases',
    );
  });

  test('keeps extra fields when updating a todo', () async {
    final service = FakeHomeWidgetTodoService();
    final source = buildSource(service);
    await source.createTodo(extra);

    await source.updateTodo(extra.copyWith(completed: true));

    final stored = TodoModel.listFromJsonString(service.json!);
    final dog = stored.firstWhere((todo) => todo.id == 'todo-5');
    expect(dog.completed, isTrue);
    expect(dog.description, 'After dinner');
    expect(dog.tags, ['home']);
  });

  test('writes a slim widget replica instead of the full list', () async {
    final service = FakeHomeWidgetTodoService();
    final source = HomeWidgetTodoDataSource(
      service: service,
      seed: [
        for (var i = 1; i <= 12; i++)
          TodoModel(
            id: 'todo-$i',
            title: 'Todo $i',
            description: 'Description $i',
            priority: 'medium',
            dueDate: '2026-08-12',
            completed: false,
            tags: const ['bulk'],
          ),
      ],
    );

    await source.getTodos();

    final decoded = jsonDecode(service.widgetJson!) as List<dynamic>;
    expect(decoded, hasLength(HomeWidgetTodoService.widgetLimit));
    expect(service.total, 12);
    expect(
      (decoded.first as Map).keys,
      unorderedEquals(['id', 'title', 'completed']),
    );
    expect(TodoModel.listFromJsonString(service.json!), hasLength(12));
  });

  test('honors write failure mode', () async {
    final source = HomeWidgetTodoDataSource(
      service: FakeHomeWidgetTodoService(),
      failureMode: FailureMode.throwOnWrite,
    );

    expect(
      () => source.deleteTodo('todo-1'),
      throwsA(isA<DataSourceException>()),
    );
  });
}
