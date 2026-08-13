import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_data_source.dart';
import 'package:pdp_todo_app/features/connectivity/data/repositories/connectivity_repository_impl.dart';
import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:pdp_todo_app/features/connectivity/domain/usecases/watch_connectivity.dart';

class MockConnectivityDataSource extends Mock
    implements ConnectivityDataSource {}

void main() {
  late MockConnectivityDataSource dataSource;
  late ConnectivityRepositoryImpl repository;

  setUp(() {
    dataSource = MockConnectivityDataSource();
    repository = ConnectivityRepositoryImpl(dataSource);
  });

  test('maps native strings to ConnectivityStatus', () async {
    when(() => dataSource.connectivity).thenAnswer(
      (_) => Stream.fromIterable(['wifi', 'mobile', 'none']),
    );

    await expectLater(
      repository.connectivity,
      emitsInOrder([
        ConnectivityStatus.wifi,
        ConnectivityStatus.mobile,
        ConnectivityStatus.none,
        emitsDone,
      ]),
    );
  });

  test('maps an unknown native string to PlatformFailure', () async {
    when(() => dataSource.connectivity).thenAnswer(
      (_) => Stream.value('bluetooth'),
    );

    await expectLater(
      repository.connectivity,
      emitsError(
        isA<PlatformFailure>().having(
          (failure) => failure.message,
          'message',
          'Unknown connectivity status: bluetooth',
        ),
      ),
    );
  });

  test('WatchConnectivity delegates to the repository stream', () async {
    when(() => dataSource.connectivity).thenAnswer(
      (_) => Stream.value('wifi'),
    );

    await expectLater(
      WatchConnectivity(repository)(),
      emits(ConnectivityStatus.wifi),
    );
  });
}
