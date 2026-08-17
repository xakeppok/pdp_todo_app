package com.example.pdp_todo_app.native

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Handler
import android.os.Looper
import com.example.pdp_todo_app.pigeon.ApiConnectivityStatus
import com.example.pdp_todo_app.pigeon.ConnectivityEventsStreamHandler
import com.example.pdp_todo_app.pigeon.PigeonEventSink

class ConnectivityPigeonStreamHandler(
    context: Context
) : ConnectivityEventsStreamHandler() {

    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: PigeonEventSink<ApiConnectivityStatus>? = null
    private var callback: ConnectivityManager.NetworkCallback? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<ApiConnectivityStatus>) {
        unregisterCallback()
        eventSink = sink
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

    override fun onCancel(p0: Any?) {
        unregisterCallback()
        eventSink = null
    }

    fun dispose() {
        onCancel(null)
    }

    private fun unregisterCallback() {
        callback?.let(connectivityManager::unregisterNetworkCallback)
        callback = null
    }

    private fun emitStatus() {
        val status = connectivityManager.appConnectivityStatus().toPigeon()
        mainHandler.post {
            eventSink?.success(status)
        }
    }
}

private fun AppConnectivityStatus.toPigeon(): ApiConnectivityStatus {
    return when (this) {
        AppConnectivityStatus.WIFI -> ApiConnectivityStatus.WIFI
        AppConnectivityStatus.MOBILE -> ApiConnectivityStatus.MOBILE
        AppConnectivityStatus.NONE -> ApiConnectivityStatus.NONE
    }
}
