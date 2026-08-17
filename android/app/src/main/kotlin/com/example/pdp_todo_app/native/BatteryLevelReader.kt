package com.example.pdp_todo_app.native

import android.content.Context
import android.os.BatteryManager

internal object BatteryLevelReader {
    fun capacityPercent(context: Context): Int? {
        val batteryManager =
            context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = batteryManager.getIntProperty(
            BatteryManager.BATTERY_PROPERTY_CAPACITY
        )
        return if (batteryLevel == -1) null else batteryLevel
    }
}
