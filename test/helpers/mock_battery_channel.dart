import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_platform_data_source.dart';

const batteryMethodChannel = MethodChannel(
  BatteryPlatformDataSource.channelName,
);

void setMockBatteryChannel(
  Future<Object?> Function(MethodCall call)? handler,
) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(batteryMethodChannel, handler);
}

void mockBatteryLevel(int level) {
  setMockBatteryChannel((call) async {
    if (call.method == BatteryPlatformDataSource.getBatteryLevelMethod) {
      return level;
    }
    return null;
  });
}

void mockBatteryChannelError({
  String code = 'UNAVAILABLE',
  String message = 'Battery level not available.',
}) {
  setMockBatteryChannel((call) async {
    throw PlatformException(code: code, message: message);
  });
}

void mockBatteryChannelNotImplemented() {
  setMockBatteryChannel((call) async {
    throw MissingPluginException();
  });
}

void mockBatteryChannelResult(Object? value) {
  setMockBatteryChannel((call) async => value);
}

void sendAppToBackground(WidgetTester tester) {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

void sendAppToForeground(WidgetTester tester) {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}
