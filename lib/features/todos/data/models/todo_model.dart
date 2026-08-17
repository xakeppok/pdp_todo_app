import 'dart:convert';

import 'package:pdp_todo_app/core/clock/iso_date.dart';
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
      dueDate: IsoDate.format(todo.dueDate),
      completed: todo.completed,
      tags: List<String>.from(todo.tags),
    );
  }

  factory TodoModel.fromJson(Map<dynamic, dynamic> json) {
    return TodoModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      dueDate: json['dueDate']?.toString() ?? '',
      completed: _readCompleted(json['completed']),
      tags: _readTags(json['tags']),
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
      tags: List<String>.from(tags ?? this.tags),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate,
      'completed': completed,
      'tags': List<String>.from(tags),
    };
  }

  static List<TodoModel> listFromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map && item['id'] != null && '${item['id']}'.isNotEmpty)
          TodoModel.fromJson(item),
    ];
  }

  static String listToJsonString(List<TodoModel> todos) {
    return jsonEncode([for (final todo in todos) todo.toJson()]);
  }

  static String widgetListToJsonString(
    List<TodoModel> todos, {
    required int limit,
  }) {
    return jsonEncode([
      for (final todo in todos.take(limit))
        {
          'id': todo.id,
          'title': todo.title,
          'completed': todo.completed,
        },
    ]);
  }

  static bool _readCompleted(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == 'true' || value == '1';
    }
    return false;
  }

  static List<String> _readTags(Object? value) {
    if (value is! List) return const [];
    return [for (final item in value) item.toString()];
  }
}
