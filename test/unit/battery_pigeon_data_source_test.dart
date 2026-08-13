import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
import 'package:pdp_todo_app/features/battery/data/datasources/battery_pigeon_data_source.dart';

class MockBatteryHostApi extends Mock implements BatteryHostApi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBatteryHostApi api;
  late BatteryPigeonDataSource dataSource;

  setUp(() {
    api = MockBatteryHostApi();
    dataSource = BatteryPigeonDataSource(api: api);
  });

  test('returns battery level from BatteryHostApi', () async {
    when(api.getBatteryLevel).thenAnswer((_) async => 76);

    await expectLater(dataSource.getBatteryLevel(), completion(76));
    verify(api.getBatteryLevel).called(1);
  });

  test('maps native UNAVAILABLE error to PlatformFailure', () async {
    when(api.getBatteryLevel).thenThrow(
      PlatformException(
        code: 'UNAVAILABLE',
        message: 'Battery level not available.',
      ),
    );

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

  test('maps missing host implementation to PlatformFailure', () async {
    final unregistered = BatteryPigeonDataSource();

    expect(
      unregistered.getBatteryLevel,
      throwsA(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          contains('Unable to establish connection'),
        ),
      ),
    );
  });
}
