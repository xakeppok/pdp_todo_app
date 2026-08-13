import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        let batteryChannel = FlutterMethodChannel(
            name: "pdp.flutter.app/battery",
            binaryMessenger: engineBridge.applicationRegistrar.messenger()
        )
        
        batteryChannel.setMethodCallHandler { call, result in
            
            if call.method == "getBatteryLevel" {
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
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
