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
                UIDevice.current.isBatteryMonitoringEnabled = true

                let batteryLevel = UIDevice.current.batteryLevel

                if batteryLevel >= 0 {
                    result(Int(batteryLevel * 100))
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
