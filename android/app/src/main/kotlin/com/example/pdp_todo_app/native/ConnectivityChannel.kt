package com.example.pdp_todo_app.native

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

private const val CONNECTIVITY_CHANNEL = "pdp.flutter.app/connectivity"

class ConnectivityChannel(
    context: Context,
    messenger: BinaryMessenger
) : EventChannel.StreamHandler {

    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private val channel = EventChannel(messenger, CONNECTIVITY_CHANNEL)

    private var eventSink: EventChannel.EventSink? = null
    private var callback: ConnectivityManager.NetworkCallback? = null

    init {
        channel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        unregisterCallback()
        eventSink = events
        emitStatus()

        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) = emitStatus()

            override fun onLost(network: Network) = emitStatus()

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) = emitStatus()
        }
        callback = networkCallback
        connectivityManager.registerNetworkCallback(
            NetworkRequest.Builder().build(),
            networkCallback
        )
    }

    override fun onCancel(arguments: Any?) {
        unregisterCallback()
        eventSink = null
    }

    fun dispose() {
        onCancel(null)
        channel.setStreamHandler(null)
    }

    private fun unregisterCallback() {
        callback?.let(connectivityManager::unregisterNetworkCallback)
        callback = null
    }

    private fun emitStatus() {
        val status = connectivityManager.appConnectivityStatus().channelValue
        mainHandler.post {
            eventSink?.success(status)
        }
    }
}
