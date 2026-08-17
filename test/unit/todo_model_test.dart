import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/data/services/home_widget_todo_service.dart';

void main() {
  const todo = TodoModel(
    id: 'todo-1',
    title: 'Write unit tests',
    description: 'Cover domain rules and use cases',
    priority: 'high',
    dueDate: '2026-08-10',
    completed: false,
    tags: ['testing', 'domain'],
  );

  test('round-trips full todo json', () {
    final decoded = TodoModel.listFromJsonString(
      TodoModel.listToJsonString([todo]),
    ).single;

    expect(decoded.id, todo.id);
    expect(decoded.title, todo.title);
    expect(decoded.description, todo.description);
    expect(decoded.priority, todo.priority);
    expect(decoded.dueDate, todo.dueDate);
    expect(decoded.completed, todo.completed);
    expect(decoded.tags, todo.tags);
  });

  test('widget json keeps only id, title, and completed', () {
    final decoded =
        jsonDecode(
              TodoModel.widgetListToJsonString(
                [todo],
                limit: HomeWidgetTodoService.widgetLimit,
              ),
            )
            as List<dynamic>;

    expect(decoded, hasLength(1));
    expect(
      (decoded.single as Map).keys,
      unorderedEquals(['id', 'title', 'completed']),
    );
  });

  test('copyWith clones tags so later mutation is isolated', () {
    final original = todo.copyWith();
    original.tags.add('mutated');

    expect(todo.tags, ['testing', 'domain']);
    expect(original.tags, ['testing', 'domain', 'mutated']);
  });

  test('reads completed flags written by native widgets', () {
    const raw = '''
[
  {
    "id": "todo-1",
    "title": "Write unit tests",
    "completed": 1,
    "description": "Cover domain rules and use cases",
    "priority": "high",
    "dueDate": "2026-08-10",
    "tags": ["testing"]
  }
]
''';

    expect(TodoModel.listFromJsonString(raw).single.completed, isTrue);
  });
}
