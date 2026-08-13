import 'package:flutter/services.dart';
import 'package:pdp_todo_app/core/error/failures.dart';

class BatteryPlatformDataSource {
  BatteryPlatformDataSource({
    this._channel = const MethodChannel(channelName),
  });

  static const channelName = 'pdp.flutter.app/battery';
  static const getBatteryLevelMethod = 'getBatteryLevel';

  final MethodChannel _channel;

  Future<int> getBatteryLevel() async {
    try {
      final batteryLevel = await _channel.invokeMethod<int>(
        getBatteryLevelMethod,
      );
      if (batteryLevel == null) {
        throw const PlatformFailure('Battery level not available');
      }
      return batteryLevel;
    } on PlatformException catch (e) {
      throw PlatformFailure(e.message ?? 'Failed to get battery level');
    }
  }
}
