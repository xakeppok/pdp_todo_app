import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pdp_todo_app/core/router/app_routes.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todo_form_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

class CreateTodoPage extends StatelessWidget {
  const CreateTodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TodoFormPage(
      key: TodosKeys.createPage,
      title: 'Create Todo',
    );
  }
}

class EditTodoPage extends StatelessWidget {
  const EditTodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TodoFormPage(
      key: TodosKeys.editPage,
      title: 'Edit Todo',
    );
  }
}

class TodoFormPage extends StatefulWidget {
  const TodoFormPage({
    required this.title,
    super.key,
  });

  final String title;

  @override
  State<TodoFormPage> createState() => _TodoFormPageState();
}

class _TodoFormPageState extends State<TodoFormPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    final state = context.read<TodoFormCubit>().state;
    _titleController = TextEditingController(text: state.title);
    _descriptionController = TextEditingController(text: state.description);
    _dueDateController = TextEditingController(text: state.dueDateInput);
    _tagsController = TextEditingController(text: state.tagsInput);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TodoFormCubit, TodoFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == TodoFormStatus.success,
      listener: (context, state) {
        final saved = state.savedTodo;
        if (saved != null) {
          context.read<TodosBloc>().add(TodosItemUpserted(saved));
        }
        if (context.canPop()) {
          context.pop(saved);
        } else {
          context.go(AppRoutes.todos);
        }
      },
      builder: (context, state) {
        final cubit = context.read<TodoFormCubit>();
        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: TodosKeys.titleField,
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  errorText: state.fieldErrors['title'],
                ),
                onChanged: cubit.titleChanged,
              ),
              const SizedBox(height: 12),
              TextField(
                key: TodosKeys.descriptionField,
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onChanged: cubit.descriptionChanged,
              ),
              const SizedBox(height: 12),
              TextField(
                key: TodosKeys.dueDateField,
                controller: _dueDateController,
                decoration: InputDecoration(
                  labelText: 'Due date (YYYY-MM-DD)',
                  errorText: state.fieldErrors['dueDate'],
                ),
                onChanged: cubit.dueDateChanged,
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Priority',
                  errorText: state.fieldErrors['priority'],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TodoPriority>(
                    key: TodosKeys.priorityField,
                    value: state.priority,
                    isExpanded: true,
                    items: [
                      for (final priority in TodoPriority.values)
                        DropdownMenuItem(
                          value: priority,
                          child: Text(priority.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) cubit.priorityChanged(value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: TodosKeys.tagsField,
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                ),
                onChanged: cubit.tagsChanged,
              ),
              if (state.errorMessage != null && state.fieldErrors.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  key: TodosKeys.formError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: TodosKeys.submitButton,
                onPressed: state.status == TodoFormStatus.submitting
                    ? null
                    : cubit.submit,
                child: Text(
                  state.status == TodoFormStatus.submitting
                      ? 'Saving...'
                      : (state.isEditing ? 'Save changes' : 'Create todo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
