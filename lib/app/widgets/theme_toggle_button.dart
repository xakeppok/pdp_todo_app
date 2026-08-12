import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/app/theme_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/todos_keys.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final (icon, tooltip) = switch (mode) {
          ThemeMode.system => (Icons.brightness_auto, 'Theme: system'),
          ThemeMode.light => (Icons.light_mode, 'Theme: light'),
          ThemeMode.dark => (Icons.dark_mode, 'Theme: dark'),
        };
        return IconButton(
          key: TodosKeys.themeToggle,
          tooltip: tooltip,
          icon: Icon(icon),
          onPressed: () => context.read<ThemeCubit>().cycle(),
        );
      },
    );
  }
}
