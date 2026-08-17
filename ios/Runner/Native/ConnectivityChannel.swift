import Flutter
import Network

final class ConnectivityChannel: NSObject, FlutterStreamHandler {

    private let channel: FlutterEventChannel
    private var monitor: NWPathMonitor?
    private var eventSink: FlutterEventSink?

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterEventChannel(
            name: "pdp.flutter.app/connectivity",
            binaryMessenger: messenger
        )
        super.init()
        channel.setStreamHandler(self)
    }

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        stopMonitor()
        eventSink = events
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.eventSink?(AppConnectivityStatus.from(path: path).channelValue)
            }
        }
        monitor.start(queue: DispatchQueue(label: "pdp.connectivity"))
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopMonitor()
        eventSink = nil
        return nil
    }

    private func stopMonitor() {
        monitor?.cancel()
        monitor = nil
    }
}
