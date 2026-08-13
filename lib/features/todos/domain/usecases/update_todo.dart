import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';
import 'package:pdp_todo_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_validator.dart';

class UpdateTodo {
  const UpdateTodo(this._repository, this._validator);

  final TodoRepository _repository;
  final TodoValidator _validator;

  Future<Todo> call({
    required Todo existing,
    required TodoInput input,
  }) async {
    final validated = _validator.validate(input);
    final updated = existing.copyWith(
      title: validated.title,
      description: validated.description,
      priority: _priorityFrom(validated.priority),
      dueDate: validated.dueDate,
      tags: validated.tags,
    );
    return _repository.updateTodo(updated);
  }

  TodoPriority _priorityFrom(String value) => switch (value) {
    'low' => TodoPriority.low,
    'high' => TodoPriority.high,
    _ => TodoPriority.medium,
  };
}
