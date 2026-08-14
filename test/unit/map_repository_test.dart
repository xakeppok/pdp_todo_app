import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/features/native_map/data/datasources/map_data_source.dart';
import 'package:pdp_todo_app/features/native_map/data/repositories/map_repository_impl.dart';
import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';
import 'package:pdp_todo_app/features/native_map/domain/usecases/watch_map_clicks.dart';

class MockMapDataSource extends Mock implements MapDataSource {}

void main() {
  late MockMapDataSource dataSource;
  late MapRepositoryImpl repository;

  setUp(() {
    dataSource = MockMapDataSource();
    repository = MapRepositoryImpl(dataSource);
  });

  test('forwards native map clicks', () async {
    const click = MapClick(latitude: 55.7558, longitude: 37.6173);
    when(() => dataSource.mapClicks).thenAnswer((_) => Stream.value(click));

    await expectLater(repository.mapClicks, emits(click));
  });

  test('WatchMapClicks delegates to the repository stream', () async {
    const click = MapClick(latitude: 1.23, longitude: 4.56);
    when(() => dataSource.mapClicks).thenAnswer((_) => Stream.value(click));

    await expectLater(WatchMapClicks(repository)(), emits(click));
  });

  test('MapClick label formats coordinates to 6 decimal places', () {
    const click = MapClick(latitude: 55.7558, longitude: 37.6173);

    expect(click.label, '55.755800, 37.617300');
  });
}
