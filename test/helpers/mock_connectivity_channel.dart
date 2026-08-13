import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/features/connectivity/data/datasources/connectivity_platform_datasource.dart';

const connectivityEventChannel = EventChannel(
  ConnectivityPlatformDataSource.channelName,
);

void setMockConnectivityChannel(MockStreamHandler? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(connectivityEventChannel, handler);
}

void mockConnectivityEvents(
  List<Object?> events, {
  bool endOfStream = false,
}) {
  setMockConnectivityChannel(
    MockStreamHandler.inline(
      onListen: (_, sink) {
        events.forEach(sink.success);
        if (endOfStream) {
          sink.endOfStream();
        }
      },
    ),
  );
}

void mockConnectivityListen(
  void Function(MockStreamHandlerEventSink sink) onListen,
) {
  setMockConnectivityChannel(
    MockStreamHandler.inline(onListen: (_, sink) => onListen(sink)),
  );
}

void mockConnectivityChannelError({
  String code = 'UNAVAILABLE',
  String message = 'Connectivity not available.',
}) {
  setMockConnectivityChannel(
    MockStreamHandler.inline(
      onListen: (_, sink) {
        sink.error(code: code, message: message);
      },
    ),
  );
}
