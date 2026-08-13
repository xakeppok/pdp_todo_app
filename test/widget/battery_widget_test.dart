import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/app/widgets/battery_widget.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_platform_data_source.dart';
import 'package:pdp_todo_app/features/battery/data/repositories/battery_repository_impl.dart';
import 'package:pdp_todo_app/features/battery/domain/usecases/get_battery_level.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_cubit.dart';

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

  testWidgets('shows battery level returned by the native channel',
      (tester) async {
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

  testWidgets('shows unavailable when the native channel errors',
      (tester) async {
    mockBatteryChannelError();
    cubit = createCubit();
    addTearDown(cubit.close);
    await cubit.getBatteryLevel();

    await pumpBattery(tester);
    await tester.pump();

    expect(find.text('Battery unavailable'), findsOneWidget);
    expect(find.text('Tap to retry'), findsOneWidget);
  });
}
