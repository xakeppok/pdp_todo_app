package com.example.pdp_todo_app

import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build

internal object TodoWidgetIntents {
    fun detailsUri(id: String): Uri {
        return Uri.parse("todowidget://app/todos/$id")
    }

    fun listUri(): Uri {
        return Uri.parse("todowidget://app/todos")
    }

    fun completeBroadcastIntent(context: Context, id: String): PendingIntent {
        val intent = Intent(context, TodoWidgetToggleReceiver::class.java).apply {
            data = completeUri(id)
            action = TodoWidgetToggleReceiver.ACTION
        }
        return PendingIntent.getBroadcast(
            context,
            31 * "complete".hashCode() + id.hashCode(),
            intent,
            pendingIntentFlags()
        )
    }

    fun launchIntent(context: Context, uri: Uri, key: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            data = uri
            action = Intent.ACTION_VIEW
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val requestCode = key.hashCode()
        val flags = pendingIntentFlags()
        if (Build.VERSION.SDK_INT < 34) {
            return PendingIntent.getActivity(context, requestCode, intent, flags)
        }

        val options = ActivityOptions.makeBasic()
        if (Build.VERSION.SDK_INT >= 35) {
            options.setPendingIntentCreatorBackgroundActivityStartMode(
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
            )
        } else {
            options.pendingIntentBackgroundActivityStartMode =
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }
        return PendingIntent.getActivity(context, requestCode, intent, flags, options.toBundle())
    }

    private fun completeUri(id: String): Uri {
        return Uri.Builder()
            .scheme("todowidget")
            .authority("complete")
            .appendQueryParameter("id", id)
            .build()
    }

    private fun pendingIntentFlags(): Int {
        return PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    }
}
