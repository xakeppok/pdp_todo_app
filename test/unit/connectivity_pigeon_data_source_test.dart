import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_pigeon_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('emits native connectivity status names', () async {
    final dataSource = ConnectivityPigeonDataSource(
      watchConnectivity: ({instanceName = ''}) {
        return Stream.fromIterable([
          ApiConnectivityStatus.wifi,
          ApiConnectivityStatus.mobile,
          ApiConnectivityStatus.none,
        ]);
      },
    );

    await expectLater(
      dataSource.connectivity,
      emitsInOrder(['wifi', 'mobile', 'none', emitsDone]),
    );
  });

  test('maps native UNAVAILABLE error to PlatformFailure', () async {
    final dataSource = ConnectivityPigeonDataSource(
      watchConnectivity: ({instanceName = ''}) {
        return Stream<ApiConnectivityStatus>.error(
          PlatformException(
            code: 'UNAVAILABLE',
            message: 'Connectivity not available.',
          ),
        );
      },
    );

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
