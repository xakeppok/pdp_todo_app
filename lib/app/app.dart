import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdp_todo_app/app/di.dart';
import 'package:pdp_todo_app/app/theme.dart';
import 'package:pdp_todo_app/app/theme_cubit.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_cubit.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({
    super.key,
    this.router,
    this.todosBloc,
    this.themeCubit,
    this.themeMode = ThemeMode.system,
  });

  final GoRouter? router;
  final TodosBloc? todosBloc;
  final ThemeCubit? themeCubit;

  final ThemeMode themeMode;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late final GoRouter _router;
  late final TodosBloc _todosBloc;
  late final ThemeCubit _themeCubit;
  late final bool _ownsBloc;
  late final bool _ownsThemeCubit;

  @override
  void initState() {
    super.initState();
    _router = widget.router ?? createConfiguredRouter();
    _ownsBloc = widget.todosBloc == null;
    _todosBloc =
        widget.todosBloc ??
        (createTodosBloc()..add(const TodosLoadRequested()));
    _ownsThemeCubit = widget.themeCubit == null;
    _themeCubit = widget.themeCubit ?? ThemeCubit(widget.themeMode);
  }

  @override
  void dispose() {
    if (_ownsBloc) {
      unawaited(_todosBloc.close());
    }
    if (_ownsThemeCubit) {
      unawaited(_themeCubit.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _todosBloc),
        BlocProvider.value(value: _themeCubit),
        BlocProvider(
          create: (_) {
            final batteryCubit = getIt<BatteryCubit>();
            unawaited(batteryCubit.getBatteryLevel());
            return batteryCubit;
          },
        ),
        BlocProvider(
          create: (_) => getIt<ConnectivityCubit>()..watch(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'PDP Todo',
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
