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
        callback?.let(connectivityManager::unregisterNetworkCallback)
        callback = null
        eventSink = null
    }

    private fun emitStatus() {
        val status = currentStatus()
        mainHandler.post {
            eventSink?.success(status)
        }
    }

    private fun currentStatus(): String {
        val network = connectivityManager.activeNetwork ?: return "none"
        val capabilities =
            connectivityManager.getNetworkCapabilities(network) ?: return "none"
        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
            else -> "none"
        }
    }
}
