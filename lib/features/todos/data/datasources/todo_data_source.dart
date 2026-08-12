import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';

enum FailureMode {
  none,
  throwOnGet,
  throwOnWrite,
}

/// Abstract data source. Implementations may be fakes or (in real apps) remote.
abstract class TodoDataSource {
  FailureMode get failureMode;
  set failureMode(FailureMode value);

  Future<List<TodoModel>> getTodos();

  Future<TodoModel> getTodoById(String id);

  Future<TodoModel> createTodo(TodoModel todo);

  Future<TodoModel> updateTodo(TodoModel todo);

  Future<void> deleteTodo(String id);
}
