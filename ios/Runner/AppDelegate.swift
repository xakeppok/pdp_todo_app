import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var batteryChannel: BatteryChannel?
    private var connectivityChannel: ConnectivityChannel?
    private var messagesChannel: MessagesChannel?
    private var batteryPigeonApi: BatteryPigeonApi?
    private var messagesPigeonApi: MessagesPigeonApi?
    private var connectivityPigeonStreamHandler: ConnectivityPigeonStreamHandler?
    
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
        messagesChannel = MessagesChannel(messenger: messenger)

        let batteryPigeonApi = BatteryPigeonApi()
        BatteryHostApiSetup.setUp(binaryMessenger: messenger, api: batteryPigeonApi)
        self.batteryPigeonApi = batteryPigeonApi

        let messagesPigeonApi = MessagesPigeonApi()
        MessagesHostApiSetup.setUp(binaryMessenger: messenger, api: messagesPigeonApi)
        self.messagesPigeonApi = messagesPigeonApi

        let connectivityPigeonStreamHandler = ConnectivityPigeonStreamHandler()
        ConnectivityEventsStreamHandler.register(
            with: messenger,
            streamHandler: connectivityPigeonStreamHandler
        )
        self.connectivityPigeonStreamHandler = connectivityPigeonStreamHandler
    }
}
