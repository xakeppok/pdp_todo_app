import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdp_todo_app/app/widgets/theme_toggle_button.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/core/widgets/snack_bar_listener.dart';
import 'package:pdp_todo_app/features/battery/presentation/widgets/battery_widget.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/widgets/connectivity_widget.dart';
import 'package:pdp_todo_app/features/messages/presentation/messages_keys.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/failure_mode_toggle_button.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todo_filter_bar.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todo_list_item.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todo_sort_menu.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todos_empty_view.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todos_error_view.dart';
import 'package:pdp_todo_app/features/todos/presentation/widgets/todos_loading_view.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({required this.clock, super.key});

  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return SnackBarListener<TodosBloc, TodosState>(
      messageOf: (state) => state is TodosLoaded ? state.actionMessage : null,
      onShown: (context, _) {
        context.read<TodosBloc>().add(const TodosActionMessageCleared());
      },
      child: Scaffold(
        key: TodosKeys.page,
        appBar: AppBar(
          title: const Text('Todos'),
          actions: [
            IconButton(
              key: MessagesKeys.openButton,
              tooltip: 'Messages channel',
              onPressed: () => context.push(AppRoutes.messages),
              icon: const Icon(Icons.sync_alt_rounded),
            ),
            const FailureModeToggleButton(),
            const ThemeToggleButton(),
            BlocBuilder<TodosBloc, TodosState>(
              builder: (context, state) {
                return TodoSortMenu(
                  selected: state.sort,
                  onChanged: (sort) =>
                      context.read<TodosBloc>().add(TodosSortChanged(sort)),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          key: TodosKeys.createFab,
          onPressed: () => context.push(AppRoutes.create),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            const BatteryWidget(),
            const ConnectivityWidget(),
            BlocBuilder<TodosBloc, TodosState>(
              builder: (context, state) {
                return TodoFilterBar(
                  selected: state.filter,
                  onChanged: (filter) =>
                      context.read<TodosBloc>().add(TodosFilterChanged(filter)),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<TodosBloc, TodosState>(
                builder: (context, state) {
                  return switch (state) {
                    TodosInitial() ||
                    TodosLoading() => const TodosLoadingView(),
                    TodosError(:final message) => TodosErrorView(
                      message: message,
                      onRetry: () => context.read<TodosBloc>().add(
                        const TodosRetryRequested(),
                      ),
                    ),
                    TodosEmpty() => TodosEmptyView(
                      onCreatePressed: () => context.push(AppRoutes.create),
                    ),
                    TodosLoaded(:final todos) => ListView.separated(
                      key: TodosKeys.list,
                      itemCount: todos.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        return TodoListItem(
                          todo: todo,
                          clock: clock,
                          onTap: () => context.push(AppRoutes.details(todo.id)),
                          onToggleCompleted: () =>
                              context.read<TodosBloc>().add(
                                TodosToggleCompleted(todo),
                              ),
                          onDelete: () => context.read<TodosBloc>().add(
                            TodosDeleteRequested(todo.id),
                          ),
                        );
                      },
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
