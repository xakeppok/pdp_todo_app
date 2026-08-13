import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_platform_data_source.dart';
import 'package:pdp_todo_app/features/battery/data/repositories/battery_repository_impl.dart';
import 'package:pdp_todo_app/features/battery/domain/usecases/get_battery_level.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_cubit.dart';
import 'package:pdp_todo_app/features/battery/presentation/widgets/battery_widget.dart';

import '../helpers/mock_battery_channel.dart';

void main() {
  late BatteryCubit cubit;

  BatteryCubit createCubit() {
    return BatteryCubit(
      GetBatteryLevel(
        BatteryRepositoryImpl(BatteryPlatformDataSource()),
      ),
    );
  }

  Future<void> pumpBattery(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: BatteryWidget()),
        ),
      ),
    );
  }

  tearDown(() => setMockBatteryChannel(null));

  testWidgets('shows battery level returned by the native channel', (
    tester,
  ) async {
    mockBatteryLevel(42);
    cubit = createCubit();
    addTearDown(cubit.close);
    await cubit.getBatteryLevel();

    await pumpBattery(tester);
    await tester.pumpAndSettle();

    expect(find.text('42%'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('Fair'), findsOneWidget);
  });

  testWidgets('shows unavailable when the native channel errors', (
    tester,
  ) async {
    mockBatteryChannelError();
    cubit = createCubit();
    addTearDown(cubit.close);
    await cubit.getBatteryLevel();

    await pumpBattery(tester);
    await tester.pump();

    expect(find.text('Battery unavailable'), findsOneWidget);
    expect(find.text('Tap to retry'), findsOneWidget);
  });

  testWidgets('retrying error mid-animation does not throw duplicate keys', (
    tester,
  ) async {
    mockBatteryChannelError();
    cubit = createCubit();
    addTearDown(cubit.close);
    await cubit.getBatteryLevel();

    await pumpBattery(tester);
    await tester.pump();

    final delayed = Completer<void>();
    setMockBatteryChannel((call) async {
      await delayed.future;
      throw PlatformException(
        code: 'UNAVAILABLE',
        message: 'Battery level not available.',
      );
    });

    unawaited(cubit.getBatteryLevel());
    await tester.pump();
    delayed.complete();
    await tester.pump();

    expect(find.text('Battery unavailable'), findsOneWidget);
  });

  testWidgets('does not hit the channel in background, refreshes on resume', (
    tester,
  ) async {
    var calls = 0;
    var level = 42;
    setMockBatteryChannel((call) async {
      calls += 1;
      return level;
    });

    cubit = createCubit();
    addTearDown(cubit.close);
    await cubit.getBatteryLevel();
    expect(calls, 1);

    await pumpBattery(tester);
    await tester.pumpAndSettle();
    expect(find.text('42%'), findsOneWidget);

    level = 18;
    sendAppToBackground(tester);
    await tester.pump();

    expect(calls, 1);
    expect(find.text('42%'), findsOneWidget);

    sendAppToForeground(tester);
    await tester.pump();

    expect(find.text('Reading battery…'), findsNothing);
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('18%'), findsOneWidget);
  });
}
