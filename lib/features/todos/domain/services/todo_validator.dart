import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';

class TodoInput {
  const TodoInput({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDateInput,
    this.tags = const [],
  });

  final String title;
  final String description;
  final String priority;
  final String dueDateInput;
  final List<String> tags;
}

class ValidatedTodoInput {
  const ValidatedTodoInput({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.tags,
  });

  final String title;
  final String description;
  final String priority;
  final DateTime dueDate;
  final List<String> tags;
}

class TodoValidator {
  const TodoValidator();

  static const maxTitleLength = 100;

  ValidatedTodoInput validate(TodoInput input) {
    final title = input.title.trim();
    if (title.isEmpty) {
      throw const ValidationFailure('Title cannot be empty');
    }
    if (title.length > maxTitleLength) {
      throw const ValidationFailure(
        'Title cannot exceed $maxTitleLength characters',
      );
    }

    final dueDate = parseDateOnly(input.dueDateInput);
    final priority = input.priority.trim().toLowerCase();
    if (TodoPriority.tryParse(priority) == null) {
      throw const ValidationFailure('Priority must be low, medium, or high');
    }

    return ValidatedTodoInput(
      title: title,
      description: input.description.trim(),
      priority: priority,
      dueDate: dueDate,
      tags: input.tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
    );
  }

  DateTime parseDateOnly(String raw) {
    final value = raw.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const ValidationFailure(
        'Due date must be a valid date in YYYY-MM-DD format',
      );
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    if (month < 1 || month > 12) {
      throw const ValidationFailure('Due date month is invalid');
    }

    final daysInMonth = _daysInMonth(year, month);
    if (day < 1 || day > daysInMonth) {
      throw const ValidationFailure('Due date is not a valid calendar date');
    }

    return DateTime(year, month, day);
  }

  int _daysInMonth(int year, int month) {
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isLeapYear(year)) return 29;
    return lengths[month - 1];
  }

  bool _isLeapYear(int year) =>
      (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
}
