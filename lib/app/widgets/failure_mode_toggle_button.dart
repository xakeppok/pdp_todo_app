import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdp_todo_app/app/di.dart';
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

    final next = switch (_mode) {
      FailureMode.none => FailureMode.throwOnWrite,
      FailureMode.throwOnWrite => FailureMode.throwOnGet,
      FailureMode.throwOnGet => FailureMode.none,
    };
    setDataSourceFailureMode(next);
    setState(() => _mode = next);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('FailureMode: ${next.name}')),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final (icon, tooltip) = switch (_mode) {
      FailureMode.none => (Icons.bug_report_outlined, 'Failures: off'),
      FailureMode.throwOnWrite => (Icons.edit_off, 'Failures: writes'),
      FailureMode.throwOnGet => (Icons.cloud_off, 'Failures: reads'),
    };

    return IconButton(
      key: TodosKeys.failureModeToggle,
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: _cycle,
    );
  }
}
