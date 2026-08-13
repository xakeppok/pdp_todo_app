package com.example.pdp_todo_app.native

import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec

private const val MESSAGES_CHANNEL = "pdp.flutter.app/messages"

class MessagesChannel(
    messenger: BinaryMessenger
) {
    private val channel = BasicMessageChannel(
        messenger,
        MESSAGES_CHANNEL,
        StandardMessageCodec.INSTANCE
    )

    init {
        channel.setMessageHandler { message, reply ->
            val map = message as? Map<*, *>
            val type = map?.get("type") as? String
            val id = map?.get("id") as? String
            val payload = map?.get("payload") as? String ?: ""

            if (type != "ping" || id.isNullOrEmpty()) {
                reply.reply(
                    mapOf(
                        "type" to "pong",
                        "id" to (id ?: "unknown"),
                        "payload" to "Unknown or invalid message"
                    )
                )
                return@setMessageHandler
            }

            reply.reply(
                mapOf(
                    "type" to "pong",
                    "id" to id,
                    "payload" to "android:$payload"
                )
            )
        }
    }
}
