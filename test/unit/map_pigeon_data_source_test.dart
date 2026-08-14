import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
import 'package:pdp_todo_app/features/native_map/data/datasources/map_pigeon_data_source.dart';
import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps native map clicks to MapClick', () async {
    final dataSource = MapPigeonDataSource(
      watchMapClicks: ({instanceName = ''}) {
        return Stream.fromIterable([
          ApiMapClick(latitude: 55.7558, longitude: 37.6173),
          ApiMapClick(latitude: 0, longitude: 0),
        ]);
      },
    );

    await expectLater(
      dataSource.mapClicks,
      emitsInOrder([
        const MapClick(latitude: 55.7558, longitude: 37.6173),
        const MapClick(latitude: 0, longitude: 0),
        emitsDone,
      ]),
    );
  });

  test('maps native UNAVAILABLE error to PlatformFailure', () async {
    final dataSource = MapPigeonDataSource(
      watchMapClicks: ({instanceName = ''}) {
        return Stream<ApiMapClick>.error(
          PlatformException(
            code: 'UNAVAILABLE',
            message: 'Map click stream not available.',
          ),
        );
      },
    );

    await expectLater(
      dataSource.mapClicks,
      emitsError(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Map click stream not available.',
        ),
      ),
    );
  });

  test('maps missing plugin to PlatformFailure', () async {
    final dataSource = MapPigeonDataSource(
      watchMapClicks: ({instanceName = ''}) {
        return Stream<ApiMapClick>.error(
          MissingPluginException('Map click pigeon API is not implemented'),
        );
      },
    );

    await expectLater(
      dataSource.mapClicks,
      emitsError(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Map click pigeon API is not implemented',
        ),
      ),
    );
  });
}
