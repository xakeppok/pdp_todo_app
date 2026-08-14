package com.example.pdp_todo_app.native

import android.content.Context
import android.util.Log
import android.view.View
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.platform.PlatformView
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.MapView

class NativeMapView(
    context: Context,
    private val lifecycleOwner: LifecycleOwner,
    private val onMapClick: (latitude: Double, longitude: Double) -> Unit,
) : PlatformView, DefaultLifecycleObserver {

    private val mapView = MapView(context)
    private var map: MapLibreMap? = null
    private var destroyed = false

    private val clickListener = MapLibreMap.OnMapClickListener { point ->
        onMapClick(point.latitude, point.longitude)
        true
    }

    init {
        lifecycleOwner.lifecycle.addObserver(this)
    }

    override fun getView(): View = mapView

    override fun onCreate(owner: LifecycleOwner) {
        Log.d(TAG, "Map onCreate")
        mapView.onCreate(null)
        mapView.getMapAsync { mapLibreMap ->
            map = mapLibreMap
            mapLibreMap.addOnMapClickListener(clickListener)
            mapLibreMap.setStyle("https://demotiles.maplibre.org/style.json")
        }
    }

    override fun onStart(owner: LifecycleOwner) {
        Log.d(TAG, "Map onStart")
        mapView.onStart()
    }

    override fun onResume(owner: LifecycleOwner) {
        Log.d(TAG, "Map onResume")
        mapView.onResume()
    }

    override fun onPause(owner: LifecycleOwner) {
        Log.d(TAG, "Map onPause")
        mapView.onPause()
    }

    override fun onStop(owner: LifecycleOwner) {
        Log.d(TAG, "Map onStop")
        mapView.onStop()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        Log.d(TAG, "Map onDestroy")
        destroyMap()
    }

    override fun dispose() {
        Log.d(TAG, "Map dispose")
        lifecycleOwner.lifecycle.removeObserver(this)
        if (destroyed) return
        mapView.onPause()
        mapView.onStop()
        destroyMap()
    }

    private fun destroyMap() {
        if (destroyed) return
        destroyed = true
        map?.removeOnMapClickListener(clickListener)
        map = null
        mapView.onDestroy()
    }

    private companion object {
        const val TAG = "MapLifecycle"
    }
}
