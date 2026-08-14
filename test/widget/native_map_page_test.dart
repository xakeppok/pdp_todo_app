import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';
import 'package:pdp_todo_app/features/native_map/domain/usecases/watch_map_clicks.dart';
import 'package:pdp_todo_app/features/native_map/presentation/bloc/map_cubit.dart';
import 'package:pdp_todo_app/features/native_map/presentation/native_map_keys.dart';
import 'package:pdp_todo_app/features/native_map/presentation/pages/native_map_page.dart';

class MockWatchMapClicks extends Mock implements WatchMapClicks {}

void main() {
  late MockWatchMapClicks watchMapClicks;
  late MapCubit cubit;

  Future<void> pumpMap(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const NativeMapPage(),
        ),
      ),
    );
  }

  setUp(() {
    watchMapClicks = MockWatchMapClicks();
    when(watchMapClicks.call).thenAnswer((_) => const Stream.empty());
    cubit = MapCubit(watchMapClicks);
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('shows map page and tap prompt', (tester) async {
    await pumpMap(tester);

    expect(find.byKey(NativeMapKeys.page), findsOneWidget);
    expect(find.text('Native map'), findsOneWidget);
    expect(find.byKey(NativeMapKeys.clickLabel), findsOneWidget);
    expect(find.text('Tap the map'), findsOneWidget);
  });

  testWidgets('shows coordinates when native click arrives', (tester) async {
    final clicks = StreamController<MapClick>.broadcast();
    addTearDown(clicks.close);
    when(watchMapClicks.call).thenAnswer((_) => clicks.stream);

    cubit.watch();
    await pumpMap(tester);

    clicks.add(const MapClick(latitude: 55.7558, longitude: 37.6173));
    await tester.pump();

    expect(find.text('55.755800, 37.617300'), findsOneWidget);
    expect(find.text('Tap the map'), findsNothing);
  });

  testWidgets('shows error banner and snackbar when the stream fails', (
    tester,
  ) async {
    final clicks = StreamController<MapClick>.broadcast();
    addTearDown(clicks.close);
    when(watchMapClicks.call).thenAnswer((_) => clicks.stream);

    cubit.watch();
    await pumpMap(tester);

    clicks.addError(const PlatformFailure('Map click stream not available.'));
    await tester.pump();

    expect(find.text('Map click stream unavailable'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Map click stream not available.'), findsOneWidget);
  });

  testWidgets('embeds AndroidView on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await pumpMap(tester);

    expect(find.byType(AndroidView), findsOneWidget);
    expect(find.byType(UiKitView), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('embeds UiKitView on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await pumpMap(tester);

    expect(find.byType(UiKitView), findsOneWidget);
    expect(find.byType(AndroidView), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows fallback on unsupported platforms', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await pumpMap(tester);

    expect(
      find.text('Native map is only available on Android and iOS'),
      findsOneWidget,
    );
    expect(find.byType(AndroidView), findsNothing);
    expect(find.byType(UiKitView), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
