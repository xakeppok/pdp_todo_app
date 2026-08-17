import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
import 'package:pdp_todo_app/core/platform/platform_error_mapper.dart';
import 'package:pdp_todo_app/features/native_map/data/datasources/map_data_source.dart';
import 'package:pdp_todo_app/features/native_map/domain/entities/map_click.dart';

class MapPigeonDataSource implements MapDataSource {
  MapPigeonDataSource({
    Stream<ApiMapClick> Function({String instanceName})? watchMapClicks,
  }) : _watchMapClicks = watchMapClicks ?? onMapClick;

  final Stream<ApiMapClick> Function({String instanceName}) _watchMapClicks;

  @override
  Stream<MapClick> get mapClicks {
    return mapPlatformStreamErrors(
      _watchMapClicks().map(
        (event) => MapClick(
          latitude: event.latitude,
          longitude: event.longitude,
        ),
      ),
      fallback: 'Failed to listen for map clicks',
      missingPlugin: 'Map click pigeon API is not implemented',
    );
  }
}
