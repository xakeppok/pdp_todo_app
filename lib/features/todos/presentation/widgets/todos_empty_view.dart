import 'package:flutter/material.dart';

import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

class TodosEmptyView extends StatelessWidget {
  const TodosEmptyView({super.key, this.onCreatePressed});

  final VoidCallback? onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: TodosKeys.emptyView,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No todos yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first todo to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onCreatePressed != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                key: TodosKeys.emptyCreateButton,
                onPressed: onCreatePressed,
                child: const Text('Create todo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
