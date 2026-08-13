import 'package:flutter/services.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/pigeon/platform_apis.g.dart';
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
    return _watchConnectivity().map((status) => status.name).handleError(
      (Object error, StackTrace stackTrace) {
        if (error is PlatformException) {
          throw PlatformFailure(
            error.message ?? 'Failed to get connectivity',
          );
        }
        if (error is MissingPluginException) {
          throw PlatformFailure(
            error.message ?? 'Connectivity pigeon API is not implemented',
          );
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }
}
