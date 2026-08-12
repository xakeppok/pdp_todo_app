import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';
import 'package:pdp_todo_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_validator.dart';

class CreateTodo {
  const CreateTodo(this._repository, this._validator);

  final TodoRepository _repository;
  final TodoValidator _validator;

  Future<Todo> call({
    required String id,
    required TodoInput input,
  }) async {
    final validated = _validator.validate(input);
    final todo = Todo(
      id: id,
      title: validated.title,
      description: validated.description,
      priority: _priorityFrom(validated.priority),
      dueDate: validated.dueDate,
      completed: false,
      tags: validated.tags,
    );
    return _repository.createTodo(todo);
  }

  TodoPriority _priorityFrom(String value) => switch (value) {
        'low' => TodoPriority.low,
        'high' => TodoPriority.high,
        _ => TodoPriority.medium,
      };
}
