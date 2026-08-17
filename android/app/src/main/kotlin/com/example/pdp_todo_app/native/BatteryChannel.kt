package com.example.pdp_todo_app.native

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

private const val BATTERY_CHANNEL = "pdp.flutter.app/battery"

class BatteryChannel(
    context: Context,
    messenger: BinaryMessenger
) {
    private val channel = MethodChannel(
        messenger,
        BATTERY_CHANNEL
    )

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val batteryLevel = BatteryLevelReader.capacityPercent(context)
                    if (batteryLevel != null) {
                        result.success(batteryLevel)
                    } else {
                        result.error(
                            "UNAVAILABLE",
                            "Battery level not available.",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
