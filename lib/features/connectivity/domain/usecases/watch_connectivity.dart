import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:pdp_todo_app/features/connectivity/domain/repositories/connectivity_repository.dart';

class WatchConnectivity {
  const WatchConnectivity(this._repository);

  final ConnectivityRepository _repository;

  Stream<ConnectivityStatus> call() => _repository.connectivity;
}
