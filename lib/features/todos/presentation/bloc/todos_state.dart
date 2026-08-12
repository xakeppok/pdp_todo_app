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
  });

  final List<Todo> todos;

  @override
  List<Object?> get props => [todos, filter, sort, allTodos];
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
