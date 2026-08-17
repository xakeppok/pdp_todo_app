import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
import 'package:pdp_todo_app/core/platform/platform_error_mapper.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_data_source.dart';

class BatteryPigeonDataSource implements BatteryDataSource {
  BatteryPigeonDataSource({
    BatteryHostApi? api,
  }) : _api = api ?? BatteryHostApi();

  final BatteryHostApi _api;

  @override
  Future<int> getBatteryLevel() {
    return mapPlatformErrors(
      _api.getBatteryLevel,
      fallback: 'Failed to get battery level',
      missingPlugin: 'Battery pigeon API is not implemented',
    );
  }
}
