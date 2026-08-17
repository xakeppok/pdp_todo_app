import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
import 'package:pdp_todo_app/core/platform/platform_error_mapper.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_data_source.dart';

class ConnectivityPigeonDataSource implements ConnectivityDataSource {
  ConnectivityPigeonDataSource({
    Stream<ApiConnectivityStatus> Function({String instanceName})?
    watchConnectivity,
  }) : _watchConnectivity = watchConnectivity ?? connectivityEvents;

  final Stream<ApiConnectivityStatus> Function({String instanceName})
  _watchConnectivity;

  @override
  Stream<String> get connectivity {
    return mapPlatformStreamErrors(
      _watchConnectivity().map((status) => status.name),
      fallback: 'Failed to get connectivity',
      missingPlugin: 'Connectivity pigeon API is not implemented',
    );
  }
}
