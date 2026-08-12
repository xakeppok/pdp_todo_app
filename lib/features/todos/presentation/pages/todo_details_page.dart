import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_details_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todo_list_item.dart';

class TodoDetailsPage extends StatelessWidget {
  const TodoDetailsPage({
    required this.clock, super.key,
  });

  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TodoDetailsCubit, TodoDetailsState>(
          listenWhen: (previous, current) =>
              current is TodoDetailsDeleted ||
              (current is TodoDetailsLoaded && current.actionMessage != null),
          listener: (context, state) {
            if (state is TodoDetailsDeleted) {
              context.read<TodosBloc>().add(TodosItemRemoved(state.id));
              context.go(AppRoutes.todos);
              return;
            }
            if (state is TodoDetailsLoaded && state.actionMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.actionMessage!)),
              );
              context.read<TodoDetailsCubit>().clearActionMessage();
            }
          },
        ),
        BlocListener<TodoDetailsCubit, TodoDetailsState>(
          listenWhen: (previous, current) {
            if (current is! TodoDetailsLoaded) return false;
            if (previous is! TodoDetailsLoaded) return true;
            return previous.todo != current.todo;
          },
          listener: (context, state) {
            if (state is TodoDetailsLoaded) {
              context.read<TodosBloc>().add(TodosItemUpserted(state.todo));
            }
          },
        ),
      ],
      child: Scaffold(
        key: TodosKeys.detailsPage,
        appBar: AppBar(
          title: const Text('Todo details'),
          actions: [
            BlocBuilder<TodoDetailsCubit, TodoDetailsState>(
              builder: (context, state) {
                if (state is! TodoDetailsLoaded) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  key: TodosKeys.editButton,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final result = await context.push<Todo>(
                      AppRoutes.edit(state.todo.id),
                      extra: state.todo,
                    );
                    if (result != null && context.mounted) {
                      context.read<TodoDetailsCubit>().applyUpdated(result);
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<TodoDetailsCubit, TodoDetailsState>(
          builder: (context, state) {
            return switch (state) {
              TodoDetailsInitial() || TodoDetailsLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
              TodoDetailsError(:final message) => Center(
                  child: Text(
                    message,
                    key: TodosKeys.detailsError,
                  ),
                ),
              TodoDetailsDeleted() => const SizedBox.shrink(),
              TodoDetailsLoaded(:final todo) => _TodoDetailsBody(
                  todo: todo,
                  clock: clock,
                ),
            };
          },
        ),
      ),
    );
  }
}

class _TodoDetailsBody extends StatelessWidget {
  const _TodoDetailsBody({
    required this.todo,
    required this.clock,
  });

  final Todo todo;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TodoDetailsCubit>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          todo.title,
          key: TodosKeys.detailsTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          todo.description.isEmpty ? 'No description' : todo.description,
          key: TodosKeys.detailsDescription,
        ),
        const SizedBox(height: 16),
        TodoListItem(
          todo: todo,
          clock: clock,
          onToggleCompleted: cubit.toggleCompleted,
        ),
        if (todo.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final tag in todo.tags)
                Chip(
                  key: TodosKeys.tag(tag),
                  label: Text(tag),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.tonal(
          key: TodosKeys.detailsToggleButton,
          onPressed: cubit.toggleCompleted,
          child: Text(
            todo.completed ? 'Mark as active' : 'Mark as completed',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: TodosKeys.detailsDeleteButton,
          onPressed: cubit.delete,
          child: const Text('Delete todo'),
        ),
      ],
    );
  }
}
