import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/pigeon/platform_apis.g.dart',
    dartOptions: DartOptions(),
    dartPackageName: 'pdp_todo_app',
    kotlinOut:
        'android/app/src/main/kotlin/com/example/pdp_todo_app/pigeon/PlatformApis.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.example.pdp_todo_app.pigeon',
    ),
    swiftOut: 'ios/Runner/Native/PlatformApis.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
enum ApiMessageType {
  ping,
  pong,
}

class ApiChannelMessage {
  ApiChannelMessage({
    required this.type,
    required this.id,
    required this.payload,
  });

  ApiMessageType type;
  String id;
  String payload;
}

enum ApiConnectivityStatus {
  wifi,
  mobile,
  none,
}

class ApiMapClick {
  ApiMapClick({
    required this.latitude,
    required this.longitude,
  });

  double latitude;
  double longitude;
}

@HostApi()
abstract class BatteryHostApi {
  int getBatteryLevel();
}

@HostApi()
abstract class MessagesHostApi {
  ApiChannelMessage sendPing(ApiChannelMessage ping);
}

@EventChannelApi()
abstract class PlatformEventApi {
  ApiConnectivityStatus connectivityEvents();
  ApiMapClick onMapClick();
}
