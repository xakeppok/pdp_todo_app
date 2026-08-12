import 'package:flutter/material.dart';

import 'package:pdp_todo_app/features/todos/domain/entities/todo_filter.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

class TodoFilterBar extends StatelessWidget {
  const TodoFilterBar({
    required this.selected, required this.onChanged, super.key,
  });

  final TodoFilter selected;
  final ValueChanged<TodoFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: TodosKeys.filterBar,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final filter in TodoFilter.values) ...[
            FilterChip(
              key: TodosKeys.filter(filter),
              label: Text(filter.label),
              selected: selected == filter,
              onSelected: (_) => onChanged(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
