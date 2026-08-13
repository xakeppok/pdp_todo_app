import Flutter
import UIKit

final class MessagesChannel {

    private static let channelName = "pdp.flutter.app/messages"

    private let channel: FlutterBasicMessageChannel

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterBasicMessageChannel(
            name: Self.channelName,
            binaryMessenger: messenger,
            codec: FlutterStandardMessageCodec.sharedInstance()
        )

        channel.setMessageHandler { message, reply in
            guard let map = message as? [String: Any] else {
                reply([
                    "type": "pong",
                    "id": "unknown",
                    "payload": "Unknown or invalid message",
                ])
                return
            }

            let type = map["type"] as? String
            let id = map["id"] as? String
            let payload = map["payload"] as? String ?? ""

            guard type == "ping", let id, !id.isEmpty else {
                reply([
                    "type": "pong",
                    "id": id ?? "unknown",
                    "payload": "Unknown or invalid message",
                ])
                return
            }

            reply([
                "type": "pong",
                "id": id,
                "payload": "ios:\(payload)",
            ])
        }
    }
}
