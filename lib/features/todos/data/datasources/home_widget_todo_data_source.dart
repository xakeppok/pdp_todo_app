import 'package:pdp_todo_app/core/async/async_mutex.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/data/models/todo_model.dart';
import 'package:pdp_todo_app/features/todos/data/services/home_widget_todo_service.dart';

const List<TodoModel> defaultTodoSeed = [
  TodoModel(
    id: 'todo-1',
    title: 'Write unit tests',
    description: 'Cover domain rules and use cases',
    priority: 'high',
    dueDate: '2026-08-10',
    completed: false,
    tags: ['testing', 'domain'],
  ),
  TodoModel(
    id: 'todo-2',
    title: 'Add widget tests',
    description: 'Cover loading, empty, and error UI',
    priority: 'medium',
    dueDate: '2026-08-12',
    completed: false,
    tags: ['testing', 'ui'],
  ),
  TodoModel(
    id: 'todo-3',
    title: 'Document CI',
    description: 'Explain flaky tests and goldens',
    priority: 'low',
    dueDate: '2026-08-20',
    completed: true,
    tags: ['docs'],
  ),
  TodoModel(
    id: 'todo-4',
    title: 'Buy milk',
    description: 'Buy milk for the kids',
    priority: 'high',
    dueDate: '2026-08-13',
    completed: false,
    tags: ['shopping'],
  ),
];

class HomeWidgetTodoDataSource implements TodoDataSource {
  HomeWidgetTodoDataSource({
    HomeWidgetTodoService? service,
    List<TodoModel>? seed,
    this._failureMode = FailureMode.none,
  }) : _service = service ?? HomeWidgetTodoService(),
       _seed = List<TodoModel>.unmodifiable(seed ?? defaultTodoSeed);

  final HomeWidgetTodoService _service;
  final List<TodoModel> _seed;
  final AsyncMutex _mutex = AsyncMutex();
  FailureMode _failureMode;

  @override
  FailureMode get failureMode => _failureMode;

  @override
  set failureMode(FailureMode value) => _failureMode = value;

  @override
  Future<List<TodoModel>> getTodos() {
    return _mutex.run(() async {
      _maybeThrowGet();
      final todos = await _loadOrSeed();
      return [for (final todo in todos) todo.copyWith()];
    });
  }

  @override
  Future<TodoModel> getTodoById(String id) {
    return _mutex.run(() async {
      _maybeThrowGet();
      final todo = _byId(await _loadOrSeed())[id];
      if (todo == null) {
        throw DataSourceException.notFound(id);
      }
      return todo.copyWith();
    });
  }

  @override
  Future<TodoModel> createTodo(TodoModel todo) {
    return _mutex.run(() async {
      _maybeThrowWrite();
      final todos = await _loadOrSeed();
      if (_byId(todos).containsKey(todo.id)) {
        throw DataSourceException.alreadyExists(todo.id);
      }
      final created = todo.copyWith();
      await _persist([...todos, created]);
      return created.copyWith();
    });
  }

  @override
  Future<TodoModel> updateTodo(TodoModel todo) {
    return _mutex.run(() async {
      _maybeThrowWrite();
      final todos = await _loadOrSeed();
      if (!_byId(todos).containsKey(todo.id)) {
        throw DataSourceException.notFound(todo.id);
      }
      final updated = todo.copyWith();
      await _persist([
        for (final item in todos)
          if (item.id == updated.id) updated else item,
      ]);
      return updated.copyWith();
    });
  }

  @override
  Future<void> deleteTodo(String id) {
    return _mutex.run(() async {
      _maybeThrowWrite();
      final todos = await _loadOrSeed();
      if (!_byId(todos).containsKey(id)) {
        throw DataSourceException.notFound(id);
      }
      await _persist([
        for (final todo in todos)
          if (todo.id != id) todo,
      ]);
    });
  }

  Future<List<TodoModel>> _loadOrSeed() async {
    final raw = await _service.load();
    if (raw == null) {
      await _persist(_seed);
      return _seed;
    }
    if (raw.isEmpty) return const [];
    return TodoModel.listFromJsonString(raw);
  }

  Future<void> _persist(List<TodoModel> todos) => _service.save(todos);

  Map<String, TodoModel> _byId(List<TodoModel> todos) {
    return {for (final todo in todos) todo.id: todo};
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
}
