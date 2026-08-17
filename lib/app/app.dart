import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:pdp_todo_app/app/di.dart';
import 'package:pdp_todo_app/app/theme.dart';
import 'package:pdp_todo_app/app/theme_cubit.dart';
import 'package:pdp_todo_app/core/home_widget/todo_widget_contract.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_cubit.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_cubit.dart';
import 'package:pdp_todo_app/features/messages/presentation/bloc/messages_cubit.dart';
import 'package:pdp_todo_app/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:pdp_todo_app/features/todos/presentation/todo_widget_link.dart';

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

class _TodoAppState extends State<TodoApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  late final TodosBloc _todosBloc;
  late final ThemeCubit _themeCubit;
  late final bool _ownsBloc;
  late final bool _ownsThemeCubit;
  late final bool _syncOnResume;
  StreamSubscription<Uri?>? _widgetClicks;

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
    _syncOnResume = widget.router == null && widget.todosBloc == null;
    if (_syncOnResume) {
      WidgetsBinding.instance.addObserver(this);
      unawaited(_listenToWidgetClicks());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _todosBloc.add(const TodosSyncRequested());
    }
  }

  @override
  void dispose() {
    if (_syncOnResume) {
      WidgetsBinding.instance.removeObserver(this);
      unawaited(_widgetClicks?.cancel());
    }
    if (_ownsBloc) {
      unawaited(_todosBloc.close());
    }
    if (_ownsThemeCubit) {
      unawaited(_themeCubit.close());
    }
    super.dispose();
  }

  Future<void> _listenToWidgetClicks() async {
    await HomeWidget.setAppGroupId(TodoWidgetContract.appGroupId);
    _openWidgetUri(await HomeWidget.initiallyLaunchedFromHomeWidget());
    _widgetClicks = HomeWidget.widgetClicked.listen(_openWidgetUri);
  }

  void _openWidgetUri(Uri? uri) {
    final location = TodoWidgetLink.tryParse(uri)?.location;
    if (location == null) {
      return;
    }
    _router.go(location);
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
        BlocProvider(
          create: (_) => getIt<MessagesCubit>(),
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
