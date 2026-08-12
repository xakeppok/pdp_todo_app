import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';

import '../fixtures/todo_fixtures.dart';

void main() {
  group('Todo.isOverdue', () {
    final clock = FixedClock(DateTime(2026, 8, 12, 15));

    test('is true when due date is a prior calendar day and not completed', () {
      final todo = buildTodo(dueDate: DateTime(2026, 8, 11));
      expect(todo.isOverdue(clock), isTrue);
    });

    test(
      'is false when due date is today even if clock has afternoon time',
      () {
        final todo = buildTodo(dueDate: DateTime(2026, 8, 12));
        expect(todo.isOverdue(clock), isFalse);
      },
    );

    test('is false when completed even if past due', () {
      final todo = buildTodo(
        dueDate: DateTime(2026, 8, 10),
        completed: true,
      );
      expect(todo.isOverdue(clock), isFalse);
    });
  });

  group('Todo.complete', () {
    test('rejects already-completed todos', () {
      final todo = buildTodo(completed: true);
      expect(todo.complete, throwsA(isA<DomainFailure>()));
    });

    test('marks active todo as completed', () {
      final todo = buildTodo(
        priority: TodoPriority.high,
      );
      expect(todo.complete().completed, isTrue);
    });
  });
}
