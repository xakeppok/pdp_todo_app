import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_filter.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_sort.dart';

class TodoQuery {
  const TodoQuery();

  List<Todo> apply({
    required List<Todo> todos,
    required TodoFilter filter,
    required TodoSort sort,
    required Clock clock,
  }) {
    final filtered = this.filter(todos, filter, clock);
    return this.sort(filtered, sort);
  }

  List<Todo> filter(List<Todo> todos, TodoFilter filter, Clock clock) {
    return switch (filter) {
      TodoFilter.all => List<Todo>.from(todos),
      TodoFilter.active =>
        todos.where((todo) => !todo.completed).toList(growable: false),
      TodoFilter.completed =>
        todos.where((todo) => todo.completed).toList(growable: false),
      TodoFilter.overdue =>
        todos.where((todo) => todo.isOverdue(clock)).toList(growable: false),
    };
  }

  List<Todo> sort(List<Todo> todos, TodoSort sort) {
    final copy = List<Todo>.from(todos)
      ..sort((a, b) {
        final primary = switch (sort) {
          TodoSort.priority => b.priority.rank.compareTo(a.priority.rank),
          TodoSort.dueDate => a.dueDate.compareTo(b.dueDate),
        };
        if (primary != 0) return primary;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return copy;
  }
}
