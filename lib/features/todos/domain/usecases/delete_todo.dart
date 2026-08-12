import 'package:pdp_todo_app/features/todos/domain/repositories/todo_repository.dart';

class DeleteTodo {
  const DeleteTodo(this._repository);

  final TodoRepository _repository;

  Future<void> call(String id) => _repository.deleteTodo(id);
}
