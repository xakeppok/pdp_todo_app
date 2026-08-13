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

    private fun currentStatus(): ApiConnectivityStatus {
        val network = connectivityManager.activeNetwork
            ?: return ApiConnectivityStatus.NONE
        val capabilities =
            connectivityManager.getNetworkCapabilities(network)
                ?: return ApiConnectivityStatus.NONE
        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) ->
                ApiConnectivityStatus.WIFI
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ->
                ApiConnectivityStatus.MOBILE
            else -> ApiConnectivityStatus.NONE
        }
    }
}
