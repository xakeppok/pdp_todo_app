import 'package:flutter/material.dart';

import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo.dart';
import 'package:pdp_todo_app/features/todos/domain/entities/todo_priority.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

class TodoListItem extends StatelessWidget {
  const TodoListItem({
    required this.todo,
    required this.clock,
    super.key,
    this.onTap,
    this.onToggleCompleted,
    this.onDelete,
  });

  final Todo todo;
  final Clock clock;
  final VoidCallback? onTap;
  final VoidCallback? onToggleCompleted;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final overdue = todo.isOverdue(clock);
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      key: TodosKeys.item(todo.id),
      onTap: onTap,
      leading: Checkbox(
        key: TodosKeys.toggle(todo.id),
        value: todo.completed,
        onChanged: onToggleCompleted == null
            ? null
            : (_) => onToggleCompleted!(),
      ),
      title: Text(
        todo.title,
        key: TodosKeys.title(todo.id),
        style: TextStyle(
          decoration: todo.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dueLabel(todo.dueDate),
            key: TodosKeys.due(todo.id),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _PriorityChip(priority: todo.priority),
              if (overdue)
                Chip(
                  key: TodosKeys.overdue(todo.id),
                  label: const Text('Overdue'),
                  backgroundColor: scheme.errorContainer,
                  labelStyle: TextStyle(color: scheme.onErrorContainer),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: onDelete == null
          ? null
          : IconButton(
              key: TodosKeys.delete(todo.id),
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
    );
  }

  String _dueLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'Due $month/$day/${date.year}';
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TodoPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TodoPriority.high => Colors.red.shade700,
      TodoPriority.medium => Colors.orange.shade800,
      TodoPriority.low => Colors.blueGrey.shade600,
    };
    return Chip(
      key: TodosKeys.priority(priority),
      label: Text(priority.label),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
