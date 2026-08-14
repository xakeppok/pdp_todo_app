package com.example.pdp_todo_app.native

import android.os.Handler
import android.os.Looper
import com.example.pdp_todo_app.pigeon.ApiMapClick
import com.example.pdp_todo_app.pigeon.OnMapClickStreamHandler
import com.example.pdp_todo_app.pigeon.PigeonEventSink

class MapPigeonStreamHandler : OnMapClickStreamHandler() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: PigeonEventSink<ApiMapClick>? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<ApiMapClick>) {
        eventSink = sink
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }

    fun emit(latitude: Double, longitude: Double) {
        mainHandler.post {
            eventSink?.success(
                ApiMapClick(
                    latitude = latitude,
                    longitude = longitude,
                )
            )
        }
    }
}
