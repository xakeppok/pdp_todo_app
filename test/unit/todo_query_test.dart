import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_filter.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_sort.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_query.dart';

import '../fixtures/todo_fixtures.dart';

void main() {
  const query = TodoQuery();
  final clock = FixedClock(DateTime(2026, 8, 12, 15));
  final todos = buildTodoList();

  test('filters active todos', () {
    final result = query.filter(todos, TodoFilter.active, clock);
    expect(result.map((t) => t.id), ['todo-1', 'todo-2']);
  });

  test('filters completed todos', () {
    final result = query.filter(todos, TodoFilter.completed, clock);
    expect(result.map((t) => t.id), ['todo-3']);
  });

  test('filters overdue todos', () {
    final result = query.filter(todos, TodoFilter.overdue, clock);
    expect(result.map((t) => t.id), ['todo-1']);
  });

  test('sorts by priority high to low', () {
    final result = query.sort(todos, TodoSort.priority);
    expect(result.first.priority, TodoPriority.high);
    expect(result.last.priority, TodoPriority.low);
  });

  test('sorts by due date soonest first', () {
    final result = query.sort(todos, TodoSort.dueDate);
    expect(result.map((t) => t.id), ['todo-1', 'todo-2', 'todo-3']);
  });
}
