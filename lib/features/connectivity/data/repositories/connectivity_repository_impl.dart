import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_data_source.dart';
import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:pdp_todo_app/features/connectivity/domain/repositories/connectivity_repository.dart';

class ConnectivityRepositoryImpl implements ConnectivityRepository {
  const ConnectivityRepositoryImpl(this._dataSource);

  final ConnectivityDataSource _dataSource;

  @override
  Stream<ConnectivityStatus> get connectivity {
    return _dataSource.connectivity.map(_mapStatus);
  }

  ConnectivityStatus _mapStatus(String raw) {
    final status = ConnectivityStatus.tryParse(raw);
    if (status == null) {
      throw PlatformFailure('Unknown connectivity status: $raw');
    }
    return status;
  }
}
