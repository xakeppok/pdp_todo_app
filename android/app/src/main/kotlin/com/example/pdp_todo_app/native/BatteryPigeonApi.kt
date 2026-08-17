package com.example.pdp_todo_app.native

import android.content.Context
import com.example.pdp_todo_app.pigeon.BatteryHostApi
import com.example.pdp_todo_app.pigeon.FlutterError

class BatteryPigeonApi(
    private val context: Context
) : BatteryHostApi {
    override fun getBatteryLevel(): Long {
        val batteryLevel = BatteryLevelReader.capacityPercent(context)
            ?: throw FlutterError(
                "UNAVAILABLE",
                "Battery level not available.",
                null
            )
        return batteryLevel.toLong()
    }
}
