import 'package:flutter/material.dart';

import 'package:pdp_todo_app/features/todos/domain/entities/todo_sort.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

class TodoSortMenu extends StatelessWidget {
  const TodoSortMenu({
    required this.selected, required this.onChanged, super.key,
  });

  final TodoSort selected;
  final ValueChanged<TodoSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TodoSort>(
      key: TodosKeys.sortMenu,
      initialValue: selected,
      tooltip: 'Sort todos',
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final sort in TodoSort.values)
          PopupMenuItem(
            key: TodosKeys.sort(sort),
            value: sort,
            child: Text('Sort by ${sort.label.toLowerCase()}'),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort),
            const SizedBox(width: 4),
            Text(selected.label),
          ],
        ),
      ),
    );
  }
}
