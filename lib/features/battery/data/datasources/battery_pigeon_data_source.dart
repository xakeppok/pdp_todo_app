import 'package:flutter/services.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_data_source.dart';

class BatteryPigeonDataSource implements BatteryDataSource {
  BatteryPigeonDataSource({
    BatteryHostApi? api,
  }) : _api = api ?? BatteryHostApi();

  final BatteryHostApi _api;

  @override
  Future<int> getBatteryLevel() async {
    try {
      return await _api.getBatteryLevel();
    } on PlatformException catch (e) {
      throw PlatformFailure(e.message ?? 'Failed to get battery level');
    } on MissingPluginException catch (e) {
      throw PlatformFailure(
        e.message ?? 'Battery pigeon API is not implemented',
      );
    }
  }
}
