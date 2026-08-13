import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_platform_data_source.dart';

import '../helpers/mock_battery_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BatteryPlatformDataSource dataSource;
  late List<MethodCall> log;

  setUp(() {
    dataSource = BatteryPlatformDataSource();
    log = <MethodCall>[];
    setMockBatteryChannel((call) async {
      log.add(call);
      if (call.method == BatteryPlatformDataSource.getBatteryLevelMethod) {
        return 76;
      }
      return null;
    });
  });

  tearDown(() => setMockBatteryChannel(null));

  test('channel name matches Android and iOS native hosts', () {
    expect(BatteryPlatformDataSource.channelName, 'pdp.flutter.app/battery');
    expect(
      BatteryPlatformDataSource.getBatteryLevelMethod,
      'getBatteryLevel',
    );
  });

  test('invokes getBatteryLevel on the native channel and returns level',
      () async {
    final level = await dataSource.getBatteryLevel();

    expect(level, 76);
    expect(
      log,
      [
        isMethodCall(
          BatteryPlatformDataSource.getBatteryLevelMethod,
          arguments: null,
        ),
      ],
    );
  });

  test('maps native UNAVAILABLE error to PlatformFailure', () async {
    mockBatteryChannelError();

    expect(
      dataSource.getBatteryLevel,
      throwsA(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Battery level not available.',
        ),
      ),
    );
  });

  test('maps a null native result to PlatformFailure', () async {
    setMockBatteryChannel((call) async => null);

    expect(
      dataSource.getBatteryLevel,
      throwsA(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Battery level not available',
        ),
      ),
    );
  });

}
