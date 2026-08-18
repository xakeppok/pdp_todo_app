package com.example.pdp_todo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class TodoWidgetToggleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        val id = intent.getStringExtra(EXTRA_ID)
            ?: intent.data?.getQueryParameter("id")
            ?: return
        TodoWidgetStore.toggleCompleted(context, id)
    }

    companion object {
        const val ACTION = "com.example.pdp_todo_app.TOGGLE_TODO"
        const val EXTRA_ID = "todo_id"
    }
}
