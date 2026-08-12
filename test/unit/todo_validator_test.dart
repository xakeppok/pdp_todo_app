import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_validator.dart';

void main() {
  const validator = TodoValidator();

  TodoInput input({
    String title = 'Valid title',
    String dueDateInput = '2026-08-12',
    String priority = 'medium',
  }) {
    return TodoInput(
      title: title,
      description: 'desc',
      priority: priority,
      dueDateInput: dueDateInput,
    );
  }

  test('rejects empty or whitespace title', () {
    expect(
      () => validator.validate(input(title: '   ')),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('rejects title longer than 100 characters', () {
    expect(
      () => validator.validate(input(title: 'a' * 101)),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('accepts a valid title', () {
    final result = validator.validate(input(title: ' Ship tests '));
    expect(result.title, 'Ship tests');
  });

  test('rejects invalid calendar date components before DateTime construction',
      () {
    expect(
      () => validator.parseDateOnly('2026-02-30'),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('accepts a valid date-only input', () {
    final date = validator.parseDateOnly('2026-02-28');
    expect(date, DateTime(2026, 2, 28));
  });
}
