import Flutter
import MapLibre
import UIKit

final class NativeMapView: NSObject, FlutterPlatformView {
    private let mapView: MLNMapView
    private let onMapClick: (Double, Double) -> Void

    init(
        frame: CGRect,
        onMapClick: @escaping (Double, Double) -> Void
    ) {
        self.onMapClick = onMapClick
        mapView = MLNMapView(
            frame: frame,
            styleURL: URL(string: "https://demotiles.maplibre.org/style.json")
        )
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        super.init()
        NSLog("MapLifecycle: Map onCreate")
        addTapRecognizer()
    }

    deinit {
        NSLog("MapLifecycle: Map dispose")
    }

    func view() -> UIView {
        mapView
    }

    private func addTapRecognizer() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleMapTap(_:))
        )
        if let recognizers = mapView.gestureRecognizers {
            for recognizer in recognizers where recognizer is UITapGestureRecognizer {
                tap.require(toFail: recognizer)
            }
        }
        mapView.addGestureRecognizer(tap)
    }

    @objc
    private func handleMapTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        NSLog(
            "MapLifecycle: Map onMapClick %f %f",
            coordinate.latitude,
            coordinate.longitude
        )
        onMapClick(coordinate.latitude, coordinate.longitude)
    }
}
