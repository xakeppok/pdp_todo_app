import 'package:flutter/services.dart';
import 'package:pdp_todo_app/core/error/failures.dart';

class BatteryPlatformDataSource {
  static const platform = MethodChannel('pdp.flutter.app/battery');
  Future<int> getBatteryLevel() async {
    try {
      final batteryLevel = await platform.invokeMethod<int>(
        'getBatteryLevel',
      );
      if (batteryLevel == null) {
        throw Exception('Battery level not available');
      }
      return batteryLevel;
    } on PlatformException catch (e) {
      throw PlatformFailure(e.message ?? 'Failed to get battery level');
    }
  }
}
