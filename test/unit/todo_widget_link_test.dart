import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/features/todos/presentation/todo_widget_link.dart';

void main() {
  test('parses list and details widget links', () {
    expect(
      TodoWidgetLink.tryParse(Uri.parse('todowidget:///todos/todo-2')),
      isA<TodoWidgetLink>().having((link) => link.id, 'id', 'todo-2'),
    );
    expect(
      TodoWidgetLink.tryParse(Uri.parse('todowidget://todos/todo-2')),
      isA<TodoWidgetLink>().having((link) => link.id, 'id', 'todo-2'),
    );
    expect(
      TodoWidgetLink.tryParse(Uri.parse('todowidget://app/todos/todo-2')),
      isA<TodoWidgetLink>().having((link) => link.id, 'id', 'todo-2'),
    );
    expect(
      TodoWidgetLink.tryParse(Uri.parse('todowidget:///todos')),
      isA<TodoWidgetLink>().having((link) => link.id, 'id', isNull),
    );
    expect(
      TodoWidgetLink.tryParse(
        Uri.parse('todowidget://app/todos/todo-2'),
      )?.location,
      AppRoutes.details('todo-2'),
    );
    expect(
      TodoWidgetLink.tryParse(Uri.parse('todowidget://app/todos'))?.location,
      AppRoutes.todos,
    );
    expect(
      TodoWidgetLink.tryParse(
        Uri.parse('todowidget://app/todos/todo-2?homeWidget'),
      )?.location,
      AppRoutes.details('todo-2'),
    );
  });

  test('ignores unknown widget links', () {
    expect(TodoWidgetLink.tryParse(null), isNull);
    expect(TodoWidgetLink.tryParse(Uri.parse('https://example.com')), isNull);
    expect(
      TodoWidgetLink.tryParse(Uri.parse('todowidget://complete?id=todo-2')),
      isNull,
    );
  });
}
