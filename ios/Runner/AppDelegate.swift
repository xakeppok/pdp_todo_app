import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var batteryChannel: BatteryChannel?
    private var connectivityChannel: ConnectivityChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        let messenger = engineBridge.applicationRegistrar.messenger()
        batteryChannel = BatteryChannel(messenger: messenger)
        connectivityChannel = ConnectivityChannel(messenger: messenger)
    }
}

