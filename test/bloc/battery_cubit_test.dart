import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_platform_data_source.dart';
import 'package:pdp_todo_app/features/battery/data/repositories/battery_repository_impl.dart';
import 'package:pdp_todo_app/features/battery/domain/usecases/get_battery_level.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_cubit.dart';
import 'package:pdp_todo_app/features/battery/presentation/bloc/battery_state.dart';

import '../helpers/mock_battery_channel.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGetBatteryLevel getBatteryLevel;

  setUp(() {
    getBatteryLevel = MockGetBatteryLevel();
  });

  tearDown(() => setMockBatteryChannel(null));

  test('starts in initial state', () {
    expect(BatteryCubit(getBatteryLevel).state, const BatteryInitial());
  });

  blocTest<BatteryCubit, BatteryState>(
    'emits loading then loaded from use case',
    build: () => BatteryCubit(getBatteryLevel),
    setUp: () {
      when(() => getBatteryLevel()).thenAnswer((_) async => 64);
    },
    act: (cubit) => cubit.getBatteryLevel(),
    expect: () => const [
      BatteryLoading(),
      BatteryLoaded(64),
    ],
  );

  blocTest<BatteryCubit, BatteryState>(
    'refresh from loaded does not emit loading',
    build: () => BatteryCubit(getBatteryLevel),
    seed: () => const BatteryLoaded(42),
    setUp: () {
      when(() => getBatteryLevel()).thenAnswer((_) async => 18);
    },
    act: (cubit) => cubit.getBatteryLevel(),
    expect: () => const [
      BatteryLoaded(18),
    ],
  );

  blocTest<BatteryCubit, BatteryState>(
    'emits loading then error on PlatformFailure',
    build: () => BatteryCubit(getBatteryLevel),
    setUp: () {
      when(() => getBatteryLevel()).thenThrow(
        const PlatformFailure('Battery level not available.'),
      );
    },
    act: (cubit) => cubit.getBatteryLevel(),
    expect: () => const [
      BatteryLoading(),
      BatteryError('Battery level not available.'),
    ],
  );

  blocTest<BatteryCubit, BatteryState>(
    'reads battery through mocked native channel',
    setUp: () => mockBatteryLevel(91),
    build: () => BatteryCubit(
      GetBatteryLevel(
        BatteryRepositoryImpl(BatteryPlatformDataSource()),
      ),
    ),
    act: (cubit) => cubit.getBatteryLevel(),
    expect: () => const [
      BatteryLoading(),
      BatteryLoaded(91),
    ],
  );

  blocTest<BatteryCubit, BatteryState>(
    'emits error when native method is not implemented',
    setUp: mockBatteryChannelNotImplemented,
    build: () => BatteryCubit(
      GetBatteryLevel(
        BatteryRepositoryImpl(BatteryPlatformDataSource()),
      ),
    ),
    act: (cubit) => cubit.getBatteryLevel(),
    expect: () => [
      const BatteryLoading(),
      isA<BatteryError>().having(
        (state) => state.error,
        'error',
        contains('No implementation found'),
      ),
    ],
  );

  blocTest<BatteryCubit, BatteryState>(
    'emits error when native payload has the wrong codec type',
    setUp: () => mockBatteryChannelResult('76'),
    build: () => BatteryCubit(
      GetBatteryLevel(
        BatteryRepositoryImpl(BatteryPlatformDataSource()),
      ),
    ),
    act: (cubit) => cubit.getBatteryLevel(),
    expect: () => const [
      BatteryLoading(),
      BatteryError('Battery level has unexpected type'),
    ],
  );

  blocTest<BatteryCubit, BatteryState>(
    'does not refresh when lifecycle goes to background',
    build: () => BatteryCubit(getBatteryLevel),
    seed: () => const BatteryLoaded(42),
    setUp: () {
      when(() => getBatteryLevel()).thenAnswer((_) async => 18);
    },
    act: (cubit) {
      cubit
        ..handleAppLifecycle(AppLifecycleState.inactive)
        ..handleAppLifecycle(AppLifecycleState.hidden)
        ..handleAppLifecycle(AppLifecycleState.paused);
    },
    expect: () => <BatteryState>[],
    verify: (_) => verifyNever(() => getBatteryLevel()),
  );

  blocTest<BatteryCubit, BatteryState>(
    'refreshes battery when lifecycle resumes from background',
    build: () => BatteryCubit(getBatteryLevel),
    seed: () => const BatteryLoaded(42),
    setUp: () {
      when(() => getBatteryLevel()).thenAnswer((_) async => 18);
    },
    act: (cubit) => cubit.handleAppLifecycle(AppLifecycleState.resumed),
    expect: () => const [
      BatteryLoaded(18),
    ],
  );
}
