import Flutter
import UIKit

final class BatteryChannel {

    private let channel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "pdp.flutter.app/battery",
            binaryMessenger: messenger
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getBatteryLevel":
                if let batteryLevel = BatteryLevelReader.capacityPercent() {
                    result(batteryLevel)
                } else {
                    result(
                        FlutterError(
                            code: "UNAVAILABLE",
                            message: "Battery level not available.",
                            details: nil
                        )
                    )
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
