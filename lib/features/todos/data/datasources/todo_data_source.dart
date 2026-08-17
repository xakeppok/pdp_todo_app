import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';

class DataSourceException implements Exception {
  const DataSourceException(this.message, {this.isNotFound = false});

  factory DataSourceException.notFound(String id) {
    return DataSourceException('Todo $id not found', isNotFound: true);
  }

  factory DataSourceException.alreadyExists(String id) {
    return DataSourceException('Todo $id already exists');
  }

  final String message;
  final bool isNotFound;

  @override
  String toString() => 'DataSourceException: $message';
}

enum FailureMode {
  none('off'),
  throwOnGet('reads'),
  throwOnWrite('writes');

  const FailureMode(this.label);

  final String label;

  FailureMode get next => switch (this) {
    FailureMode.none => FailureMode.throwOnWrite,
    FailureMode.throwOnWrite => FailureMode.throwOnGet,
    FailureMode.throwOnGet => FailureMode.none,
  };
}

abstract class TodoDataSource {
  FailureMode get failureMode;
  set failureMode(FailureMode value);

  Future<List<TodoModel>> getTodos();

  Future<TodoModel> getTodoById(String id);

  Future<TodoModel> createTodo(TodoModel todo);

  Future<TodoModel> updateTodo(TodoModel todo);

  Future<void> deleteTodo(String id);
}
