part of 'todos_bloc.dart';

sealed class TodosState extends Equatable {
  const TodosState({
    required this.filter,
    required this.sort,
    this.allTodos = const [],
  });

  final TodoFilter filter;
  final TodoSort sort;
  final List<Todo> allTodos;

  @override
  List<Object?> get props => [filter, sort, allTodos];
}

final class TodosInitial extends TodosState {
  const TodosInitial({
    super.filter = TodoFilter.all,
    super.sort = TodoSort.dueDate,
    super.allTodos,
  });
}

final class TodosLoading extends TodosState {
  const TodosLoading({
    required super.filter,
    required super.sort,
    super.allTodos,
  });
}

final class TodosLoaded extends TodosState {
  const TodosLoaded({
    required this.todos,
    required super.allTodos,
    required super.filter,
    required super.sort,
    this.actionMessage,
  });

  final List<Todo> todos;
  final String? actionMessage;

  TodosLoaded copyWith({
    List<Todo>? todos,
    List<Todo>? allTodos,
    TodoFilter? filter,
    TodoSort? sort,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return TodosLoaded(
      todos: todos ?? this.todos,
      allTodos: allTodos ?? this.allTodos,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      actionMessage:
          clearActionMessage ? null : actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [todos, filter, sort, allTodos, actionMessage];
}

final class TodosEmpty extends TodosState {
  const TodosEmpty({
    required super.allTodos,
    required super.filter,
    required super.sort,
  });
}

final class TodosError extends TodosState {
  const TodosError({
    required this.message,
    required super.filter,
    required super.sort,
    super.allTodos,
  });

  final String message;

  @override
  List<Object?> get props => [message, filter, sort, allTodos];
}
