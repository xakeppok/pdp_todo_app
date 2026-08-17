import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdp_todo_app/app/app.dart';
import 'package:pdp_todo_app/app/di.dart';
import 'package:pdp_todo_app/core/clock/clock.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    final talker = TalkerFlutter.init();
    Bloc.observer = TalkerBlocObserver(
      talker: talker,
      settings: const TalkerBlocLoggerSettings(
        printCreations: true,
        printClosings: true,
        printChanges: true,
      ),
    );
  }
  await configureDependencies(
    clock: FixedClock(DateTime(2026, 8, 12, 15)),
  );
  runApp(const TodoApp());
}
