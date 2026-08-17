import 'package:equatable/equatable.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';

class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.completed,
    required this.tags,
  });

  final String id;
  final String title;
  final String description;
  final TodoPriority priority;
  final DateTime dueDate;
  final bool completed;
  final List<String> tags;

  bool isOverdue(Clock clock) {
    if (completed) return false;
    final today = _dateOnly(clock.now());
    final due = _dateOnly(dueDate);
    return due.isBefore(today);
  }

  Todo complete() {
    if (completed) {
      throw const DomainFailure('Todo is already completed');
    }
    return copyWith(completed: true);
  }

  Todo uncomplete() => copyWith(completed: false);

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    TodoPriority? priority,
    DateTime? dueDate,
    bool? completed,
    List<String>? tags,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      tags: List<String>.from(tags ?? this.tags),
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    dueDate,
    completed,
    tags,
  ];
}
