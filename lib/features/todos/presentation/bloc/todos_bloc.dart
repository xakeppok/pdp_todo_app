import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_filter.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_sort.dart';
import 'package:pdp_todo_app/features/todos/domain/services/todo_query.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/delete_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/get_todos.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/toggle_todo_completion.dart';

part 'todos_event.dart';
part 'todos_state.dart';

class TodosBloc extends Bloc<TodosEvent, TodosState> {
  TodosBloc({
    required this._getTodos,
    required this._deleteTodo,
    required this._toggleTodoCompletion,
    required this._todoQuery,
    required this._clock,
  }) : super(const TodosInitial()) {
    on<TodosLoadRequested>(_onLoad);
    on<TodosRetryRequested>(_onLoad);
    on<TodosFilterChanged>(_onFilterChanged);
    on<TodosSortChanged>(_onSortChanged);
    on<TodosToggleCompleted>(_onToggleCompleted);
    on<TodosDeleteRequested>(_onDeleteRequested);
    on<TodosItemUpserted>(_onItemUpserted);
    on<TodosItemRemoved>(_onItemRemoved);
  }

  final GetTodos _getTodos;
  final DeleteTodo _deleteTodo;
  final ToggleTodoCompletion _toggleTodoCompletion;
  final TodoQuery _todoQuery;
  final Clock _clock;

  Future<void> _onLoad(TodosEvent event, Emitter<TodosState> emit) async {
    final filter = state.filter;
    final sort = state.sort;
    final previousTodos = state.allTodos;

    emit(TodosLoading(filter: filter, sort: sort, allTodos: previousTodos));
    try {
      final allTodos = await _getTodos();
      emit(_buildVisibleState(
        allTodos: allTodos,
        filter: filter,
        sort: sort,
      ));
    } on Failure catch (failure) {
      emit(TodosError(
        message: failure.message,
        filter: filter,
        sort: sort,
        allTodos: previousTodos,
      ));
    } on Object catch (error) {
      emit(TodosError(
        message: error.toString(),
        filter: filter,
        sort: sort,
        allTodos: previousTodos,
      ));
    }
  }

  void _onFilterChanged(
    TodosFilterChanged event,
    Emitter<TodosState> emit,
  ) {
    emit(_rebuildWith(
      allTodos: state.allTodos,
      filter: event.filter,
      sort: state.sort,
    ));
  }

  void _onSortChanged(
    TodosSortChanged event,
    Emitter<TodosState> emit,
  ) {
    emit(_rebuildWith(
      allTodos: state.allTodos,
      filter: state.filter,
      sort: event.sort,
    ));
  }

  Future<void> _onToggleCompleted(
    TodosToggleCompleted event,
    Emitter<TodosState> emit,
  ) async {
    final filter = state.filter;
    final sort = state.sort;
    final currentTodos = state.allTodos;

    try {
      final updated = await _toggleTodoCompletion(event.todo);
      final allTodos = [
        for (final todo in currentTodos)
          if (todo.id == updated.id) updated else todo,
      ];
      emit(_buildVisibleState(
        allTodos: allTodos,
        filter: filter,
        sort: sort,
      ));
    } on Failure catch (failure) {
      emit(TodosError(
        message: failure.message,
        filter: filter,
        sort: sort,
        allTodos: currentTodos,
      ));
    }
  }

  Future<void> _onDeleteRequested(
    TodosDeleteRequested event,
    Emitter<TodosState> emit,
  ) async {
    final filter = state.filter;
    final sort = state.sort;
    final currentTodos = state.allTodos;

    try {
      await _deleteTodo(event.id);
      final allTodos =
          currentTodos.where((todo) => todo.id != event.id).toList();
      emit(_buildVisibleState(
        allTodos: allTodos,
        filter: filter,
        sort: sort,
      ));
    } on Failure catch (failure) {
      emit(TodosError(
        message: failure.message,
        filter: filter,
        sort: sort,
        allTodos: currentTodos,
      ));
    }
  }

  void _onItemUpserted(
    TodosItemUpserted event,
    Emitter<TodosState> emit,
  ) {
    final currentTodos = state.allTodos;
    final exists = currentTodos.any((todo) => todo.id == event.todo.id);
    final allTodos = exists
        ? [
            for (final todo in currentTodos)
              if (todo.id == event.todo.id) event.todo else todo,
          ]
        : [...currentTodos, event.todo];

    emit(_rebuildWith(
      allTodos: allTodos,
      filter: state.filter,
      sort: state.sort,
    ));
  }

  void _onItemRemoved(
    TodosItemRemoved event,
    Emitter<TodosState> emit,
  ) {
    final allTodos =
        state.allTodos.where((todo) => todo.id != event.id).toList();
    emit(_rebuildWith(
      allTodos: allTodos,
      filter: state.filter,
      sort: state.sort,
    ));
  }

  /// Keeps Loading / Error / Initial shape; rebuilds list for data states.
  TodosState _rebuildWith({
    required List<Todo> allTodos,
    required TodoFilter filter,
    required TodoSort sort,
  }) {
    final snapshot = List<Todo>.from(allTodos);
    return switch (state) {
      TodosInitial() => TodosInitial(
          filter: filter,
          sort: sort,
          allTodos: snapshot,
        ),
      TodosLoading() => TodosLoading(
          filter: filter,
          sort: sort,
          allTodos: snapshot,
        ),
      TodosError(:final message) => TodosError(
          message: message,
          filter: filter,
          sort: sort,
          allTodos: snapshot,
        ),
      TodosLoaded() || TodosEmpty() => _buildVisibleState(
          allTodos: snapshot,
          filter: filter,
          sort: sort,
        ),
    };
  }

  TodosState _buildVisibleState({
    required List<Todo> allTodos,
    required TodoFilter filter,
    required TodoSort sort,
  }) {
    final snapshot = List<Todo>.from(allTodos);
    final visible = _todoQuery.apply(
      todos: snapshot,
      filter: filter,
      sort: sort,
      clock: _clock,
    );
    if (visible.isEmpty) {
      return TodosEmpty(
        filter: filter,
        sort: sort,
        allTodos: snapshot,
      );
    }
    return TodosLoaded(
      todos: visible,
      filter: filter,
      sort: sort,
      allTodos: snapshot,
    );
  }
}
