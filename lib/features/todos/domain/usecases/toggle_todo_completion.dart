import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/repositories/todo_repository.dart';

/// Toggles completion. Completing an already-completed todo is rejected
/// without writing (domain rule). Uncompleting a completed todo is allowed.
class ToggleTodoCompletion {
  const ToggleTodoCompletion(this._repository);

  final TodoRepository _repository;

  Future<Todo> call(Todo todo, {bool? completed}) async {
    final targetCompleted = completed ?? !todo.completed;

    if (targetCompleted) {
      if (todo.completed) {
        throw const DomainFailure('Todo is already completed');
      }
      return _repository.updateTodo(todo.complete());
    }

    if (!todo.completed) {
      return todo;
    }
    return _repository.updateTodo(todo.uncomplete());
  }
}
