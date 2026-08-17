import Network

final class ConnectivityPigeonStreamHandler: ConnectivityEventsStreamHandler {
    private var monitor: NWPathMonitor?
    private var eventSink: PigeonEventSink<ApiConnectivityStatus>?

    override func onListen(
        withArguments arguments: Any?,
        sink: PigeonEventSink<ApiConnectivityStatus>
    ) {
        stopMonitor()
        eventSink = sink
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.eventSink?.success(AppConnectivityStatus.from(path: path).pigeonStatus)
            }
        }
        monitor.start(queue: DispatchQueue(label: "pdp.connectivity.pigeon"))
    }

    override func onCancel(withArguments arguments: Any?) {
        stopMonitor()
        eventSink = nil
    }

    private func stopMonitor() {
        monitor?.cancel()
        monitor = nil
    }
}
