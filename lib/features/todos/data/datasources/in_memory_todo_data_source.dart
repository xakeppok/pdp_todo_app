import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';

class DataSourceException implements Exception {
  const DataSourceException(this.message);

  final String message;

  @override
  String toString() => 'DataSourceException: $message';
}

/// Stateful in-memory fake used by the app and integration tests.
class InMemoryTodoDataSource implements TodoDataSource {
  InMemoryTodoDataSource({
    List<TodoModel>? seed,
    this._failureMode = FailureMode.none,
  }) : _todos = {for (final todo in seed ?? _defaultSeed) todo.id: todo};

  final Map<String, TodoModel> _todos;
  FailureMode _failureMode;

  @override
  FailureMode get failureMode => _failureMode;

  @override
  set failureMode(FailureMode value) => _failureMode = value;

  @override
  Future<List<TodoModel>> getTodos() async {
    _maybeThrowGet();
    return _todos.values.map((todo) => todo.copyWith()).toList(growable: false);
  }

  @override
  Future<TodoModel> getTodoById(String id) async {
    _maybeThrowGet();
    final todo = _todos[id];
    if (todo == null) {
      throw DataSourceException('Todo $id not found');
    }
    return todo.copyWith();
  }

  @override
  Future<TodoModel> createTodo(TodoModel todo) async {
    _maybeThrowWrite();
    if (_todos.containsKey(todo.id)) {
      throw DataSourceException('Todo ${todo.id} already exists');
    }
    _todos[todo.id] = todo.copyWith();
    return todo.copyWith();
  }

  @override
  Future<TodoModel> updateTodo(TodoModel todo) async {
    _maybeThrowWrite();
    if (!_todos.containsKey(todo.id)) {
      throw DataSourceException('Todo ${todo.id} not found');
    }
    _todos[todo.id] = todo.copyWith();
    return todo.copyWith();
  }

  @override
  Future<void> deleteTodo(String id) async {
    _maybeThrowWrite();
    if (!_todos.containsKey(id)) {
      throw DataSourceException('Todo $id not found');
    }
    _todos.remove(id);
  }

  void clear() => _todos.clear();

  void resetToSeed([List<TodoModel>? seed]) {
    _todos
      ..clear()
      ..addEntries(
        (seed ?? _defaultSeed).map(
          (todo) => MapEntry(todo.id, todo.copyWith()),
        ),
      );
  }

  void _maybeThrowGet() {
    if (_failureMode == FailureMode.throwOnGet) {
      throw const DataSourceException('Simulated get failure');
    }
  }

  void _maybeThrowWrite() {
    if (_failureMode == FailureMode.throwOnWrite) {
      throw const DataSourceException('Simulated write failure');
    }
  }

  static final List<TodoModel> _defaultSeed = [
    const TodoModel(
      id: 'todo-1',
      title: 'Write unit tests',
      description: 'Cover domain rules and use cases',
      priority: 'high',
      dueDate: '2026-08-10',
      completed: false,
      tags: ['testing', 'domain'],
    ),
    const TodoModel(
      id: 'todo-2',
      title: 'Add widget tests',
      description: 'Cover loading, empty, and error UI',
      priority: 'medium',
      dueDate: '2026-08-12',
      completed: false,
      tags: ['testing', 'ui'],
    ),
    const TodoModel(
      id: 'todo-3',
      title: 'Document CI',
      description: 'Explain flaky tests and goldens',
      priority: 'low',
      dueDate: '2026-08-20',
      completed: true,
      tags: ['docs'],
    ),
    const TodoModel(
      id: 'todo-4',
      title: 'Buy milk',
      description: 'Buy milk for the kids',
      priority: 'high',
      dueDate: '2026-08-13',
      completed: false,
      tags: ['shopping'],
    ),
  ];
}
