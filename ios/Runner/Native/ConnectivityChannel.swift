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
        eventSink = events
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.eventSink?(self?.status(for: path) ?? "none")
            }
        }
        monitor.start(queue: DispatchQueue(label: "pdp.connectivity"))
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        monitor?.cancel()
        monitor = nil
        eventSink = nil
        return nil
    }

    private func status(for path: NWPath) -> String {
        guard path.status == .satisfied else {
            return "none"
        }
        if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
            return "wifi"
        }
        if path.usesInterfaceType(.cellular) {
            return "mobile"
        }
        return "none"
    }
}
