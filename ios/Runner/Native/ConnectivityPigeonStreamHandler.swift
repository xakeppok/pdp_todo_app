import Network

final class ConnectivityPigeonStreamHandler: ConnectivityEventsStreamHandler {
    private var monitor: NWPathMonitor?
    private var eventSink: PigeonEventSink<ApiConnectivityStatus>?

    override func onListen(
        withArguments arguments: Any?,
        sink: PigeonEventSink<ApiConnectivityStatus>
    ) {
        eventSink = sink
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.eventSink?.success(self?.status(for: path) ?? .none)
            }
        }
        monitor.start(queue: DispatchQueue(label: "pdp.connectivity.pigeon"))
    }

    override func onCancel(withArguments arguments: Any?) {
        monitor?.cancel()
        monitor = nil
        eventSink = nil
    }

    private func status(for path: NWPath) -> ApiConnectivityStatus {
        guard path.status == .satisfied else {
            return .none
        }
        if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
            return .wifi
        }
        if path.usesInterfaceType(.cellular) {
            return .mobile
        }
        return .none
    }
}
