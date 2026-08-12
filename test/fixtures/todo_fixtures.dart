import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';

final testClock = FixedClock(DateTime(2026, 8, 12, 15));

Todo buildTodo({
  String id = 'todo-1',
  String title = 'Sample todo',
  String description = 'Description',
  TodoPriority priority = TodoPriority.medium,
  DateTime? dueDate,
  bool completed = false,
  List<String> tags = const ['testing'],
}) {
  return Todo(
    id: id,
    title: title,
    description: description,
    priority: priority,
    dueDate: dueDate ?? DateTime(2026, 8, 12),
    completed: completed,
    tags: tags,
  );
}

List<Todo> buildTodoList() => [
  buildTodo(
    title: 'Write unit tests',
    priority: TodoPriority.high,
    dueDate: DateTime(2026, 8, 10),
    tags: const ['testing', 'domain'],
  ),
  buildTodo(
    id: 'todo-2',
    title: 'Add widget tests',
    dueDate: DateTime(2026, 8, 12),
    tags: const ['testing', 'ui'],
  ),
  buildTodo(
    id: 'todo-3',
    title: 'Document CI',
    priority: TodoPriority.low,
    dueDate: DateTime(2026, 8, 20),
    completed: true,
    tags: const ['docs'],
  ),
];
