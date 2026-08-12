import 'package:flutter/material.dart';

import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

class TodosLoadingView extends StatelessWidget {
  const TodosLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: TodosKeys.loadingView,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading todos...'),
        ],
      ),
    );
  }
}
