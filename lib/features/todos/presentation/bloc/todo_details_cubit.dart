import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/delete_todo.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/get_todo_by_id.dart';
import 'package:pdp_todo_app/features/todos/domain/usecases/toggle_todo_completion.dart';

sealed class TodoDetailsState extends Equatable {
  const TodoDetailsState();

  @override
  List<Object?> get props => [];
}

final class TodoDetailsInitial extends TodoDetailsState {
  const TodoDetailsInitial();
}

final class TodoDetailsLoading extends TodoDetailsState {
  const TodoDetailsLoading();
}

final class TodoDetailsLoaded extends TodoDetailsState {
  const TodoDetailsLoaded({
    required this.todo,
    this.actionMessage,
  });

  final Todo todo;
  final String? actionMessage;

  TodoDetailsLoaded copyWith({
    Todo? todo,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return TodoDetailsLoaded(
      todo: todo ?? this.todo,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [todo, actionMessage];
}

final class TodoDetailsError extends TodoDetailsState {
  const TodoDetailsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class TodoDetailsDeleted extends TodoDetailsState {
  const TodoDetailsDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class TodoDetailsCubit extends Cubit<TodoDetailsState> {
  TodoDetailsCubit({
    required this.todoId,
    required this.getTodoById,
    required this.toggleTodoCompletion,
    required this.deleteTodo,
  }) : super(const TodoDetailsInitial());

  final String todoId;
  final GetTodoById getTodoById;
  final ToggleTodoCompletion toggleTodoCompletion;
  final DeleteTodo deleteTodo;

  Future<void> load() async {
    emit(const TodoDetailsLoading());
    try {
      final todo = await getTodoById(todoId);
      if (isClosed) {
        return;
      }
      emit(TodoDetailsLoaded(todo: todo));
    } on Failure catch (failure) {
      if (isClosed) {
        return;
      }
      emit(TodoDetailsError(failure.message));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }
      emit(TodoDetailsError(error.toString()));
    }
  }

  Future<void> toggleCompleted() async {
    final current = state;
    if (current is! TodoDetailsLoaded) return;

    try {
      final updated = await toggleTodoCompletion(current.todo);
      if (isClosed) {
        return;
      }
      emit(TodoDetailsLoaded(todo: updated));
    } on Failure catch (failure) {
      if (isClosed) {
        return;
      }
      emit(current.copyWith(actionMessage: failure.message));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }
      emit(current.copyWith(actionMessage: error.toString()));
    }
  }

  Future<void> delete() async {
    final current = state;
    if (current is! TodoDetailsLoaded) return;

    try {
      await deleteTodo(current.todo.id);
      if (isClosed) {
        return;
      }
      emit(TodoDetailsDeleted(current.todo.id));
    } on Failure catch (failure) {
      if (isClosed) {
        return;
      }
      emit(current.copyWith(actionMessage: failure.message));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }
      emit(current.copyWith(actionMessage: error.toString()));
    }
  }

  void applyUpdated(Todo todo) {
    emit(TodoDetailsLoaded(todo: todo));
  }

  void clearActionMessage() {
    final current = state;
    if (current is TodoDetailsLoaded && current.actionMessage != null) {
      emit(current.copyWith(clearActionMessage: true));
    }
  }
}
