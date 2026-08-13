import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_platform_datasource.dart';

import '../helpers/mock_connectivity_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConnectivityPlatformDataSource dataSource;

  setUp(() {
    dataSource = ConnectivityPlatformDataSource();
  });

  tearDown(() => setMockConnectivityChannel(null));

  test('channel name matches the native EventChannel contract', () {
    expect(
      ConnectivityPlatformDataSource.channelName,
      'pdp.flutter.app/connectivity',
    );
  });

  test('emits native connectivity strings', () async {
    mockConnectivityEvents(['wifi', 'mobile', 'none'], endOfStream: true);

    await expectLater(
      dataSource.connectivity,
      emitsInOrder(['wifi', 'mobile', 'none', emitsDone]),
    );
  });

  test('maps a non-String codec payload to PlatformFailure', () async {
    mockConnectivityEvents([1]);

    await expectLater(
      dataSource.connectivity,
      emitsError(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Connectivity status has unexpected type',
        ),
      ),
    );
  });

  test('maps native UNAVAILABLE error to PlatformFailure', () async {
    mockConnectivityChannelError();

    await expectLater(
      dataSource.connectivity,
      emitsError(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Connectivity not available.',
        ),
      ),
    );
  });
}
