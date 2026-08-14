import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdp_todo_app/app/di.dart';
import 'package:pdp_todo_app/core/widgets/snack_bar_listener.dart';
import 'package:pdp_todo_app/features/todos/data/datasources/todo_data_source.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

class FailureModeToggleButton extends StatefulWidget {
  const FailureModeToggleButton({super.key});

  @override
  State<FailureModeToggleButton> createState() =>
      _FailureModeToggleButtonState();
}

class _FailureModeToggleButtonState extends State<FailureModeToggleButton> {
  FailureMode _mode = FailureMode.none;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<TodoDataSource>()) {
      _mode = getDataSourceFailureMode();
    }
  }

  void _cycle() {
    if (!getIt.isRegistered<TodoDataSource>()) return;

    final next = _mode.next;
    setDataSourceFailureMode(next);
    setState(() => _mode = next);

    context.showSnackBarMessage('FailureMode: ${next.label}');
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final icon = switch (_mode) {
      FailureMode.none => Icons.bug_report_outlined,
      FailureMode.throwOnWrite => Icons.edit_off,
      FailureMode.throwOnGet => Icons.cloud_off,
    };

    return IconButton(
      key: TodosKeys.failureModeToggle,
      tooltip: 'Failures: ${_mode.label}',
      icon: Icon(icon),
      onPressed: _cycle,
    );
  }
}
