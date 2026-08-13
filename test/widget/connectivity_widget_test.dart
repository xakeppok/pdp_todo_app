import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_cubit.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_state.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/widgets/connectivity_widget.dart';

import '../helpers/pump_app.dart';

void main() {
  late MockWatchConnectivity watchConnectivity;
  late ConnectivityCubit cubit;

  Future<void> pumpConnectivity(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: ConnectivityWidget()),
        ),
      ),
    );
  }

  setUp(() {
    watchConnectivity = MockWatchConnectivity();
  });

  testWidgets('shows wifi status from the cubit', (tester) async {
    when(watchConnectivity.call).thenAnswer(
      (_) => Stream.value(ConnectivityStatus.wifi),
    );
    cubit = ConnectivityCubit(watchConnectivity);
    addTearDown(cubit.close);
    final loaded = cubit.stream.firstWhere(
      (state) => state is ConnectivityLoaded,
    );
    cubit.watch();
    await loaded;

    await pumpConnectivity(tester);

    expect(find.text('Wi-Fi'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('shows offline status from the cubit', (tester) async {
    when(watchConnectivity.call).thenAnswer(
      (_) => Stream.value(ConnectivityStatus.none),
    );
    cubit = ConnectivityCubit(watchConnectivity);
    addTearDown(cubit.close);
    final loaded = cubit.stream.firstWhere(
      (state) => state is ConnectivityLoaded,
    );
    cubit.watch();
    await loaded;

    await pumpConnectivity(tester);

    expect(find.text('Offline'), findsWidgets);
  });

  testWidgets('shows unavailable when the stream errors', (tester) async {
    when(watchConnectivity.call).thenAnswer(
      (_) => Stream.error(
        const PlatformFailure('Connectivity not available.'),
      ),
    );
    cubit = ConnectivityCubit(watchConnectivity);
    addTearDown(cubit.close);
    final failed = cubit.stream.firstWhere(
      (state) => state is ConnectivityError,
    );
    cubit.watch();
    await failed;

    await pumpConnectivity(tester);

    expect(find.text('Connectivity unavailable'), findsOneWidget);
    expect(find.text('Tap to retry'), findsOneWidget);
  });

  testWidgets('retrying error mid-animation does not throw duplicate keys', (
    tester,
  ) async {
    final controller = StreamController<ConnectivityStatus>.broadcast();
    addTearDown(controller.close);
    when(watchConnectivity.call).thenAnswer((_) => controller.stream);

    cubit = ConnectivityCubit(watchConnectivity);
    addTearDown(cubit.close);

    cubit.watch();
    controller.addError(
      const PlatformFailure('Connectivity not available.'),
    );
    await cubit.stream.firstWhere((state) => state is ConnectivityError);
    await pumpConnectivity(tester);

    cubit.watch();
    await tester.pump();
    controller.addError(
      const PlatformFailure('Connectivity not available.'),
    );
    await tester.pump();

    expect(find.text('Connectivity unavailable'), findsOneWidget);
  });

  testWidgets('updates when a new status is emitted', (tester) async {
    final controller = StreamController<ConnectivityStatus>.broadcast();
    addTearDown(controller.close);
    when(watchConnectivity.call).thenAnswer((_) => controller.stream);

    cubit = ConnectivityCubit(watchConnectivity);
    addTearDown(cubit.close);

    final wifi = cubit.stream.firstWhere(
      (state) =>
          state is ConnectivityLoaded &&
          state.status == ConnectivityStatus.wifi,
    );
    cubit.watch();
    controller.add(ConnectivityStatus.wifi);
    await wifi;
    await pumpConnectivity(tester);
    expect(find.text('Wi-Fi'), findsOneWidget);

    controller.add(ConnectivityStatus.mobile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('Wi-Fi'), findsNothing);
    expect(find.text('Online'), findsOneWidget);
  });
}
