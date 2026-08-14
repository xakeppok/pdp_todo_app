import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';
import 'package:pdp_todo_app/features/native_map/domain/usecases/watch_map_clicks.dart';
import 'package:pdp_todo_app/features/native_map/presentation/bloc/map_cubit.dart';
import 'package:pdp_todo_app/features/native_map/presentation/bloc/map_state.dart';

class MockWatchMapClicks extends Mock implements WatchMapClicks {}

void main() {
  late MockWatchMapClicks watchMapClicks;

  setUp(() {
    watchMapClicks = MockWatchMapClicks();
  });

  test('starts in initial state', () {
    expect(MapCubit(watchMapClicks).state, const MapInitial());
  });

  blocTest<MapCubit, MapState>(
    'emits clicked coordinates from use case',
    build: () => MapCubit(watchMapClicks),
    setUp: () {
      when(watchMapClicks.call).thenAnswer(
        (_) => Stream.value(
          const MapClick(latitude: 55.7558, longitude: 37.6173),
        ),
      );
    },
    act: (cubit) => cubit.watch(),
    expect: () => const [
      MapClicked(MapClick(latitude: 55.7558, longitude: 37.6173)),
    ],
  );

  blocTest<MapCubit, MapState>(
    'emits subsequent clicks from the stream',
    build: () => MapCubit(watchMapClicks),
    setUp: () {
      when(watchMapClicks.call).thenAnswer(
        (_) => Stream.fromIterable([
          const MapClick(latitude: 1, longitude: 2),
          const MapClick(latitude: 3, longitude: 4),
        ]),
      );
    },
    act: (cubit) => cubit.watch(),
    expect: () => const [
      MapClicked(MapClick(latitude: 1, longitude: 2)),
      MapClicked(MapClick(latitude: 3, longitude: 4)),
    ],
  );

  blocTest<MapCubit, MapState>(
    'emits error on PlatformFailure',
    build: () => MapCubit(watchMapClicks),
    setUp: () {
      when(watchMapClicks.call).thenAnswer(
        (_) => Stream.error(
          const PlatformFailure('Map click stream not available.'),
        ),
      );
    },
    act: (cubit) => cubit.watch(),
    expect: () => const [
      MapError('Map click stream not available.'),
    ],
  );
}
