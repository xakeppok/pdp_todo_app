import 'package:pdp_todo_app/features/connectivity/domain/entities/connectivity_status.dart';

abstract class ConnectivityRepository {
  Stream<ConnectivityStatus> get connectivity;
}
