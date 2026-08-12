part of 'todos_bloc.dart';

sealed class TodosEvent extends Equatable {
  const TodosEvent();

  @override
  List<Object?> get props => [];
}

final class TodosLoadRequested extends TodosEvent {
  const TodosLoadRequested();
}

final class TodosRetryRequested extends TodosEvent {
  const TodosRetryRequested();
}

final class TodosFilterChanged extends TodosEvent {
  const TodosFilterChanged(this.filter);

  final TodoFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class TodosSortChanged extends TodosEvent {
  const TodosSortChanged(this.sort);

  final TodoSort sort;

  @override
  List<Object?> get props => [sort];
}

final class TodosToggleCompleted extends TodosEvent {
  const TodosToggleCompleted(this.todo);

  final Todo todo;

  @override
  List<Object?> get props => [todo];
}

final class TodosDeleteRequested extends TodosEvent {
  const TodosDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class TodosItemUpserted extends TodosEvent {
  const TodosItemUpserted(this.todo);

  final Todo todo;

  @override
  List<Object?> get props => [todo];
}

final class TodosItemRemoved extends TodosEvent {
  const TodosItemRemoved(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
