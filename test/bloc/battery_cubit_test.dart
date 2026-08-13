import 'package:bloc_test/bloc_test.dart';
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
}
