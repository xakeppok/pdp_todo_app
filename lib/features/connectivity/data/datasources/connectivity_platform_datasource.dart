import 'package:flutter/services.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_data_source.dart';

class ConnectivityPlatformDataSource implements ConnectivityDataSource {
  ConnectivityPlatformDataSource({
    this._channel = const EventChannel(channelName),
  });

  static const channelName = 'pdp.flutter.app/connectivity';
  static const isConnectedMethod = 'isConnected';

  final EventChannel _channel;

  @override
  Stream<String> get connectivity {
    return _channel
        .receiveBroadcastStream()
        .map((event) {
          if (event is! String) {
            throw const PlatformFailure(
              'Connectivity status has unexpected type',
            );
          }
          return event;
        })
        .handleError(
          (Object error, StackTrace stackTrace) {
            if (error is PlatformException) {
              throw PlatformFailure(
                error.message ?? 'Failed to get connectivity',
              );
            }
            if (error is MissingPluginException) {
              throw PlatformFailure(
                error.message ?? 'Connectivity channel is not implemented',
              );
            }
            Error.throwWithStackTrace(error, stackTrace);
          },
        );
  }
}
