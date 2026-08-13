final class MessagesPigeonApi: MessagesHostApi {
    func sendPing(ping: ApiChannelMessage) throws -> ApiChannelMessage {
        guard ping.type == .ping, !ping.id.isEmpty else {
            return ApiChannelMessage(
                type: .pong,
                id: ping.id.isEmpty ? "unknown" : ping.id,
                payload: "Unknown or invalid message"
            )
        }

        return ApiChannelMessage(
            type: .pong,
            id: ping.id,
            payload: "ios:\(ping.payload)"
        )
    }
}
