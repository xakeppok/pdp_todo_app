import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';

class TodoModel {
  const TodoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.completed,
    required this.tags,
  });

  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      priority: todo.priority.name,
      dueDate: _formatDate(todo.dueDate),
      completed: todo.completed,
      tags: List<String>.from(todo.tags),
    );
  }

  final String id;
  final String title;
  final String description;
  final String priority;
  final String dueDate;
  final bool completed;
  final List<String> tags;

  Todo toEntity() {
    final parts = dueDate.split('-');
    return Todo(
      id: id,
      title: title,
      description: description,
      priority: TodoPriority.values.byName(priority),
      dueDate: DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ),
      completed: completed,
      tags: List<String>.from(tags),
    );
  }

  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? dueDate,
    bool? completed,
    List<String>? tags,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      tags: tags ?? this.tags,
    );
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
