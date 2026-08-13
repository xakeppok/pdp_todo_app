package com.example.pdp_todo_app.native

import com.example.pdp_todo_app.pigeon.ApiChannelMessage
import com.example.pdp_todo_app.pigeon.ApiMessageType
import com.example.pdp_todo_app.pigeon.MessagesHostApi

class MessagesPigeonApi : MessagesHostApi {
    override fun sendPing(ping: ApiChannelMessage): ApiChannelMessage {
        if (ping.type != ApiMessageType.PING || ping.id.isEmpty()) {
            return ApiChannelMessage(
                type = ApiMessageType.PONG,
                id = ping.id.ifEmpty { "unknown" },
                payload = "Unknown or invalid message"
            )
        }

        return ApiChannelMessage(
            type = ApiMessageType.PONG,
            id = ping.id,
            payload = "android:${ping.payload}"
        )
    }
}
