package com.example.pdp_todo_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Intent
import com.example.pdp_todo_app.native.BatteryChannel
import com.example.pdp_todo_app.native.BatteryPigeonApi
import com.example.pdp_todo_app.native.ConnectivityChannel
import com.example.pdp_todo_app.native.ConnectivityPigeonStreamHandler
import com.example.pdp_todo_app.native.MapPigeonStreamHandler
import com.example.pdp_todo_app.native.MessagesChannel
import com.example.pdp_todo_app.native.MessagesPigeonApi
import com.example.pdp_todo_app.native.NativeMapViewFactory
import com.example.pdp_todo_app.pigeon.BatteryHostApi
import com.example.pdp_todo_app.pigeon.ConnectivityEventsStreamHandler
import com.example.pdp_todo_app.pigeon.MessagesHostApi
import com.example.pdp_todo_app.pigeon.OnMapClickStreamHandler
import org.maplibre.android.MapLibre.getInstance
import org.maplibre.android.WellKnownTileServer

class MainActivity : FlutterActivity() {

    private lateinit var batteryChannel: BatteryChannel
    private lateinit var connectivityChannel: ConnectivityChannel
    private lateinit var messagesChannel: MessagesChannel
    private lateinit var batteryPigeonApi: BatteryPigeonApi
    private lateinit var messagesPigeonApi: MessagesPigeonApi
    private lateinit var connectivityPigeonStreamHandler: ConnectivityPigeonStreamHandler
    private lateinit var mapViewFactory: NativeMapViewFactory
    private lateinit var mapPigeonStreamHandler: MapPigeonStreamHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        getInstance(
            this,
            null,
            WellKnownTileServer.MapLibre
        )

        mapPigeonStreamHandler = MapPigeonStreamHandler()
        mapViewFactory = NativeMapViewFactory(
            this,
            mapPigeonStreamHandler::emit,
        )

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "native-map",
                mapViewFactory
            )

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        OnMapClickStreamHandler.register(
            messenger,
            mapPigeonStreamHandler
        )
        batteryChannel = BatteryChannel(
            context = this,
            messenger = messenger
        )
        connectivityChannel = ConnectivityChannel(
            context = this,
            messenger = messenger
        )
        messagesChannel = MessagesChannel(messenger = messenger)

        batteryPigeonApi = BatteryPigeonApi(context = this)
        BatteryHostApi.setUp(messenger, batteryPigeonApi)
        messagesPigeonApi = MessagesPigeonApi()
        MessagesHostApi.setUp(messenger, messagesPigeonApi)
        connectivityPigeonStreamHandler = ConnectivityPigeonStreamHandler(context = this)
        ConnectivityEventsStreamHandler.register(
            messenger,
            connectivityPigeonStreamHandler
        )
    }

    override fun getInitialRoute(): String? {
        return widgetRoute(intent) ?: super.getInitialRoute()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = widgetRoute(intent) ?: return
        flutterEngine?.navigationChannel?.pushRoute(route)
    }

    private fun widgetRoute(intent: Intent?): String? {
        val uri = intent?.data ?: return null
        if (uri.scheme != "todowidget") return null
        val path = uri.path
        return if (path.isNullOrEmpty() || path == "/") "/todos" else path
    }
}
