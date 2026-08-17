import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/repositories/todo_repository.dart';

class TodoRepositoryImpl implements TodoRepository {
  const TodoRepositoryImpl(this._dataSource);

  final TodoDataSource _dataSource;

  @override
  Future<List<Todo>> getTodos() {
    return _run(() async {
      final models = await _dataSource.getTodos();
      return models.map((model) => model.toEntity()).toList(growable: false);
    });
  }

  @override
  Future<Todo> getTodoById(String id) {
    return _run(() async {
      final model = await _dataSource.getTodoById(id);
      return model.toEntity();
    });
  }

  @override
  Future<Todo> createTodo(Todo todo) {
    return _run(() async {
      final model = await _dataSource.createTodo(TodoModel.fromEntity(todo));
      return model.toEntity();
    });
  }

  @override
  Future<Todo> updateTodo(Todo todo) {
    return _run(() async {
      final model = await _dataSource.updateTodo(TodoModel.fromEntity(todo));
      return model.toEntity();
    });
  }

  @override
  Future<void> deleteTodo(String id) {
    return _run(() => _dataSource.deleteTodo(id));
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DataSourceException catch (error) {
      if (error.isNotFound) {
        throw NotFoundFailure(error.message);
      }
      throw ServerFailure(error.message);
    } catch (error) {
      throw ServerFailure(error.toString());
    }
  }
}
