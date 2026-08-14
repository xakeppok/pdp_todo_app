import Flutter
import UIKit

final class NativeMapViewFactory: NSObject, FlutterPlatformViewFactory {
    private let onMapClick: (Double, Double) -> Void

    init(onMapClick: @escaping (Double, Double) -> Void) {
        self.onMapClick = onMapClick
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        NativeMapView(frame: frame, onMapClick: onMapClick)
    }

    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol) {
        FlutterStandardMessageCodec.sharedInstance()
    }
}
