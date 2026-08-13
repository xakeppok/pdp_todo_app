import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_platform_datasource.dart';
import 'package:pdp_todo_app/features/connectivity/data/repositories/connectivity_repository_impl.dart';
import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:pdp_todo_app/features/connectivity/domain/usecases/watch_connectivity.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_cubit.dart';
import 'package:pdp_todo_app/features/connectivity/presentation/bloc/connectivity_state.dart';

import '../helpers/mock_connectivity_channel.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWatchConnectivity watchConnectivity;

  setUp(() {
    watchConnectivity = MockWatchConnectivity();
  });

  tearDown(() => setMockConnectivityChannel(null));

  test('starts in initial state', () {
    expect(
      ConnectivityCubit(watchConnectivity).state,
      const ConnectivityInitial(),
    );
  });

  blocTest<ConnectivityCubit, ConnectivityState>(
    'emits loading then loaded from use case',
    build: () => ConnectivityCubit(watchConnectivity),
    setUp: () {
      when(watchConnectivity.call).thenAnswer(
        (_) => Stream.value(ConnectivityStatus.wifi),
      );
    },
    act: (cubit) => cubit.watch(),
    expect: () => const [
      ConnectivityLoading(),
      ConnectivityLoaded(ConnectivityStatus.wifi),
    ],
  );

  blocTest<ConnectivityCubit, ConnectivityState>(
    'emits subsequent statuses from the stream',
    build: () => ConnectivityCubit(watchConnectivity),
    setUp: () {
      when(watchConnectivity.call).thenAnswer(
        (_) => Stream.fromIterable([
          ConnectivityStatus.wifi,
          ConnectivityStatus.none,
        ]),
      );
    },
    act: (cubit) => cubit.watch(),
    expect: () => const [
      ConnectivityLoading(),
      ConnectivityLoaded(ConnectivityStatus.wifi),
      ConnectivityLoaded(ConnectivityStatus.none),
    ],
  );

  blocTest<ConnectivityCubit, ConnectivityState>(
    'emits loading then error on PlatformFailure',
    build: () => ConnectivityCubit(watchConnectivity),
    setUp: () {
      when(watchConnectivity.call).thenAnswer(
        (_) => Stream.error(
          const PlatformFailure('Connectivity not available.'),
        ),
      );
    },
    act: (cubit) => cubit.watch(),
    expect: () => const [
      ConnectivityLoading(),
      ConnectivityError('Connectivity not available.'),
    ],
  );

  blocTest<ConnectivityCubit, ConnectivityState>(
    'reads connectivity through mocked native channel',
    setUp: () => mockConnectivityEvents(['mobile']),
    build: () => ConnectivityCubit(
      WatchConnectivity(
        ConnectivityRepositoryImpl(ConnectivityPlatformDataSource()),
      ),
    ),
    act: (cubit) => cubit.watch(),
    expect: () => const [
      ConnectivityLoading(),
      ConnectivityLoaded(ConnectivityStatus.mobile),
    ],
  );

  blocTest<ConnectivityCubit, ConnectivityState>(
    'emits error when native payload has the wrong codec type',
    setUp: () => mockConnectivityEvents([1]),
    build: () => ConnectivityCubit(
      WatchConnectivity(
        ConnectivityRepositoryImpl(ConnectivityPlatformDataSource()),
      ),
    ),
    act: (cubit) => cubit.watch(),
    expect: () => const [
      ConnectivityLoading(),
      ConnectivityError('Connectivity status has unexpected type'),
    ],
  );
}
