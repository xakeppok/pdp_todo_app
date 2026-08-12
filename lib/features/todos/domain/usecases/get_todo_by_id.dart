import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/repositories/todo_repository.dart';

class GetTodoById {
  const GetTodoById(this._repository);

  final TodoRepository _repository;

  Future<Todo> call(String id) => _repository.getTodoById(id);
}
