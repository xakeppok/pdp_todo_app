package com.example.pdp_todo_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.min

internal object TodoWidgetStore {
    const val TODOS_KEY = "todos"
    const val WIDGET_TODOS_KEY = "widget_todos"
    const val TODOS_TOTAL_KEY = "todos_total"
    const val WIDGET_LIMIT = 8

    fun toggleCompleted(context: Context, id: String): Boolean {
        val prefs = HomeWidgetPlugin.getData(context)
        val json = prefs.getString(TODOS_KEY, null) ?: return false
        val array = try {
            JSONArray(json)
        } catch (_: Exception) {
            return false
        }

        var changed = false
        for (i in 0 until array.length()) {
            val todo = array.optJSONObject(i) ?: continue
            if (todo.optString("id") != id) continue
            todo.put("completed", !todo.optBoolean("completed", false))
            changed = true
        }
        if (!changed) return false

        prefs.edit()
            .putString(TODOS_KEY, array.toString())
            .putString(WIDGET_TODOS_KEY, widgetProjection(array).toString())
            .putInt(TODOS_TOTAL_KEY, array.length())
            .commit()
        refresh(context)
        return true
    }

    fun widgetTodosJson(prefs: SharedPreferences): String? {
        return prefs.getString(WIDGET_TODOS_KEY, null)
    }

    fun totalCount(prefs: SharedPreferences, visibleCount: Int): Int {
        if (prefs.contains(TODOS_TOTAL_KEY)) {
            return prefs.getInt(TODOS_TOTAL_KEY, visibleCount)
        }
        return visibleCount
    }

    fun refresh(context: Context) {
        val prefs = HomeWidgetPlugin.getData(context)
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, TodoWidget::class.java))
        for (id in ids) {
            updateAppWidget(context, manager, id, prefs)
        }
    }

    private fun widgetProjection(todos: JSONArray): JSONArray {
        val slice = JSONArray()
        val limit = min(WIDGET_LIMIT, todos.length())
        for (i in 0 until limit) {
            val src = todos.optJSONObject(i) ?: continue
            slice.put(
                JSONObject().apply {
                    put("id", src.optString("id"))
                    put("title", src.optString("title"))
                    put("completed", src.optBoolean("completed", false))
                }
            )
        }
        return slice
    }
}
