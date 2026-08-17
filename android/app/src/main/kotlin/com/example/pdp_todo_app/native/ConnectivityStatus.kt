package com.example.pdp_todo_app.native

import android.net.ConnectivityManager
import android.net.NetworkCapabilities

internal enum class AppConnectivityStatus {
    WIFI,
    MOBILE,
    NONE;

    val channelValue: String
        get() = when (this) {
            WIFI -> "wifi"
            MOBILE -> "mobile"
            NONE -> "none"
        }
}

internal fun ConnectivityManager.appConnectivityStatus(): AppConnectivityStatus {
    val network = activeNetwork ?: return AppConnectivityStatus.NONE
    val capabilities = getNetworkCapabilities(network) ?: return AppConnectivityStatus.NONE
    return when {
        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) ->
            AppConnectivityStatus.WIFI
        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ->
            AppConnectivityStatus.MOBILE
        else -> AppConnectivityStatus.NONE
    }
}
