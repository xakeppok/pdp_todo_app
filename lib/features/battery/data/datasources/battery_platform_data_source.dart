import 'package:flutter/services.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/platform/platform_error_mapper.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_data_source.dart';

class BatteryPlatformDataSource implements BatteryDataSource {
  BatteryPlatformDataSource({
    this._channel = const MethodChannel(channelName),
  });

  static const channelName = 'pdp.flutter.app/battery';
  static const getBatteryLevelMethod = 'getBatteryLevel';

  final MethodChannel _channel;

  @override
  Future<int> getBatteryLevel() {
    return mapPlatformErrors(
      () async {
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
      },
      fallback: 'Failed to get battery level',
      missingPlugin: 'Battery channel is not implemented',
    );
  }
}
