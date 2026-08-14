package com.example.pdp_todo_app.native

import android.content.Context
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class NativeMapViewFactory(
    private val lifecycleOwner: LifecycleOwner,
    private val onMapClick: (latitude: Double, longitude: Double) -> Unit,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?,
    ): PlatformView {
        return NativeMapView(
            context = context,
            lifecycleOwner = lifecycleOwner,
            onMapClick = onMapClick,
        )
    }
}
