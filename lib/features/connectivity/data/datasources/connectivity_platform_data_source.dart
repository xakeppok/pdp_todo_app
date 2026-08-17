import 'package:flutter/services.dart';
import 'package:pdp_todo_app/core/error/failures.dart';
import 'package:pdp_todo_app/core/platform/platform_error_mapper.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_data_source.dart';

class ConnectivityPlatformDataSource implements ConnectivityDataSource {
  ConnectivityPlatformDataSource({
    this._channel = const EventChannel(channelName),
  });

  static const channelName = 'pdp.flutter.app/connectivity';

  final EventChannel _channel;

  @override
  Stream<String> get connectivity {
    return mapPlatformStreamErrors(
      _channel.receiveBroadcastStream().map((event) {
        if (event is! String) {
          throw const PlatformFailure(
            'Connectivity status has unexpected type',
          );
        }
        return event;
      }),
      fallback: 'Failed to get connectivity',
      missingPlugin: 'Connectivity channel is not implemented',
    );
  }
}
