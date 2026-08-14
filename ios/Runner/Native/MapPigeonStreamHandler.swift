import Foundation

final class MapPigeonStreamHandler: OnMapClickStreamHandler {
    private var eventSink: PigeonEventSink<ApiMapClick>?

    override func onListen(
        withArguments arguments: Any?,
        sink: PigeonEventSink<ApiMapClick>
    ) {
        eventSink = sink
    }

    override func onCancel(withArguments arguments: Any?) {
        eventSink = nil
    }

    func emit(latitude: Double, longitude: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?.success(
                ApiMapClick(latitude: latitude, longitude: longitude)
            )
        }
    }
}
