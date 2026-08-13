package com.example.pdp_todo_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.pdp_todo_app.native.BatteryChannel
import com.example.pdp_todo_app.native.ConnectivityChannel
import com.example.pdp_todo_app.native.MessagesChannel

class MainActivity : FlutterActivity() {

    private lateinit var batteryChannel: BatteryChannel
    private lateinit var connectivityChannel: ConnectivityChannel
    private lateinit var messagesChannel: MessagesChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        batteryChannel = BatteryChannel(
            context = this,
            messenger = messenger
        )
        connectivityChannel = ConnectivityChannel(
            context = this,
            messenger = messenger
        )
        messagesChannel = MessagesChannel(messenger = messenger)
    }
}
