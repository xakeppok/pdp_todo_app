package com.example.pdp_todo_app.native

import android.content.Context
import android.os.BatteryManager
import com.example.pdp_todo_app.pigeon.BatteryHostApi
import com.example.pdp_todo_app.pigeon.FlutterError

class BatteryPigeonApi(
    context: Context
) : BatteryHostApi {
    private val batteryManager =
        context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager

    override fun getBatteryLevel(): Long {
        val batteryLevel = batteryManager.getIntProperty(
            BatteryManager.BATTERY_PROPERTY_CAPACITY
        )

        if (batteryLevel == -1) {
            throw FlutterError(
                "UNAVAILABLE",
                "Battery level not available.",
                null
            )
        }

        return batteryLevel.toLong()
    }
}
