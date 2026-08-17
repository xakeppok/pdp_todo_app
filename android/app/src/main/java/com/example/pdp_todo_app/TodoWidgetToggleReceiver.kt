package com.example.pdp_todo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class TodoWidgetToggleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.data?.getQueryParameter("id") ?: return
        TodoWidgetStore.toggleCompleted(context, id)
    }

    companion object {
        const val ACTION = "com.example.pdp_todo_app.TOGGLE_TODO"
    }
}
