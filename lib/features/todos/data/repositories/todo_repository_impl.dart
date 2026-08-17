import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/repositories/todo_repository.dart';

class TodoRepositoryImpl implements TodoRepository {
  const TodoRepositoryImpl(this._dataSource);

  final TodoDataSource _dataSource;

  @override
  Future<List<Todo>> getTodos() => _mapList(_dataSource.getTodos);

  @override
  Future<Todo> getTodoById(String id) async {
    try {
      final model = await _dataSource.getTodoById(id);
      return model.toEntity();
    } on DataSourceException catch (error) {
      if (error.message.contains('not found')) {
        throw NotFoundFailure(error.message);
      }
      throw ServerFailure(error.message);
    } catch (error) {
      throw ServerFailure(error.toString());
    }
  }

  @override
  Future<Todo> createTodo(Todo todo) =>
      _mapOne(() => _dataSource.createTodo(TodoModel.fromEntity(todo)));

  @override
  Future<Todo> updateTodo(Todo todo) =>
      _mapOne(() => _dataSource.updateTodo(TodoModel.fromEntity(todo)));

  @override
  Future<void> deleteTodo(String id) async {
    try {
      await _dataSource.deleteTodo(id);
    } on DataSourceException catch (error) {
      if (error.message.contains('not found')) {
        throw NotFoundFailure(error.message);
      }
      throw ServerFailure(error.message);
    } catch (error) {
      throw ServerFailure(error.toString());
    }
  }

  Future<List<Todo>> _mapList(Future<List<TodoModel>> Function() action) async {
    try {
      final models = await action();
      return models.map((model) => model.toEntity()).toList(growable: false);
    } on DataSourceException catch (error) {
      throw ServerFailure(error.message);
    } catch (error) {
      throw ServerFailure(error.toString());
    }
  }

  Future<Todo> _mapOne(Future<TodoModel> Function() action) async {
    try {
      final model = await action();
      return model.toEntity();
    } on DataSourceException catch (error) {
      if (error.message.contains('not found')) {
        throw NotFoundFailure(error.message);
      }
      throw ServerFailure(error.message);
    } catch (error) {
      throw ServerFailure(error.toString());
    }
  }
}
