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
      final batteryLevel = await _channel.invokeMethod<Object?>(
        getBatteryLevelMethod,
      );
      if (batteryLevel == null) {
        throw const PlatformFailure('Battery level not available');
      }
      if (batteryLevel is! int) {
        throw const PlatformFailure('Battery level has unexpected type');
      }
      return batteryLevel;
    } on PlatformException catch (e) {
      throw PlatformFailure(e.message ?? 'Failed to get battery level');
    } on MissingPluginException catch (e) {
      throw PlatformFailure(
        e.message ?? 'Battery channel is not implemented',
      );
    }
  }
}
