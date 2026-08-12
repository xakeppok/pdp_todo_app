import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodos();

  Future<Todo> getTodoById(String id);

  Future<Todo> createTodo(Todo todo);

  Future<Todo> updateTodo(Todo todo);

  Future<void> deleteTodo(String id);
}
