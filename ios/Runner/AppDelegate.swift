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
    private var mapPigeonStreamHandler: MapPigeonStreamHandler?

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

        let mapPigeonStreamHandler = MapPigeonStreamHandler()
        OnMapClickStreamHandler.register(
            with: messenger,
            streamHandler: mapPigeonStreamHandler
        )
        engineBridge.applicationRegistrar.register(
            NativeMapViewFactory { latitude, longitude in
                mapPigeonStreamHandler.emit(latitude: latitude, longitude: longitude)
            },
            withId: "native-map",
            gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyEager
        )
        self.mapPigeonStreamHandler = mapPigeonStreamHandler
    }
}
