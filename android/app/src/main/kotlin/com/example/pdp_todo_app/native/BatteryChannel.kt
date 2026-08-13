package com.example.pdp_todo_app.native

import android.content.Context
import android.os.BatteryManager
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

    private val batteryManager =
        context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val batteryLevel = batteryManager.getIntProperty(
                        BatteryManager.BATTERY_PROPERTY_CAPACITY
                    )

                    if (batteryLevel != -1) {
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