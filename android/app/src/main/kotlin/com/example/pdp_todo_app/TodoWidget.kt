package com.example.pdp_todo_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

private data class TodoSlot(val rowId: Int, val checkId: Int, val titleId: Int)

private val todoSlots = listOf(
    TodoSlot(R.id.todo_row_1, R.id.todo_check_1, R.id.todo_title_1),
    TodoSlot(R.id.todo_row_2, R.id.todo_check_2, R.id.todo_title_2),
    TodoSlot(R.id.todo_row_3, R.id.todo_check_3, R.id.todo_title_3),
    TodoSlot(R.id.todo_row_4, R.id.todo_check_4, R.id.todo_title_4),
    TodoSlot(R.id.todo_row_5, R.id.todo_check_5, R.id.todo_title_5),
    TodoSlot(R.id.todo_row_6, R.id.todo_check_6, R.id.todo_title_6),
    TodoSlot(R.id.todo_row_7, R.id.todo_check_7, R.id.todo_title_7),
    TodoSlot(R.id.todo_row_8, R.id.todo_check_8, R.id.todo_title_8),
)

class TodoWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(
            context,
            appWidgetManager,
            appWidgetId,
            HomeWidgetPlugin.getData(context)
        )
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    widgetData: SharedPreferences
) {
    val views = RemoteViews(context.packageName, R.layout.todo_widget)
    val todos = parseTodos(TodoWidgetStore.widgetTodosJson(widgetData))
    val listIntent = TodoWidgetIntents.launchIntent(context, TodoWidgetIntents.listUri(), "list")
    views.setOnClickPendingIntent(R.id.todo_more, listIntent)

    if (todos.isEmpty()) {
        views.setViewVisibility(R.id.todo_empty, View.VISIBLE)
        views.setViewVisibility(R.id.todo_more, View.GONE)
        for (slot in todoSlots) {
            views.setViewVisibility(slot.rowId, View.GONE)
        }
        appWidgetManager.updateAppWidget(appWidgetId, views)
        return
    }

    views.setViewVisibility(R.id.todo_empty, View.GONE)

    val heightDp = widgetHeightDp(appWidgetManager.getAppWidgetOptions(appWidgetId))
    val visibleCount = visibleTodoCount(context, heightDp, todos.size)

    for (index in todoSlots.indices) {
        val slot = todoSlots[index]
        if (index < visibleCount) {
            val todo = todos[index]
            views.setViewVisibility(slot.rowId, View.VISIBLE)
            setChecked(views, slot.checkId, todo.completed)
            views.setTextViewText(slot.titleId, todo.title)
            views.setOnClickPendingIntent(
                slot.checkId,
                TodoWidgetIntents.completeBroadcastIntent(context, todo.id)
            )
            val details = TodoWidgetIntents.launchIntent(
                context,
                TodoWidgetIntents.detailsUri(todo.id),
                "details-${todo.id}"
            )
            views.setOnClickPendingIntent(slot.titleId, details)
        } else {
            views.setViewVisibility(slot.rowId, View.GONE)
        }
    }

    val remaining = TodoWidgetStore.totalCount(widgetData, todos.size) - visibleCount
    if (remaining > 0) {
        views.setTextViewText(R.id.todo_more, "+ $remaining more")
        views.setViewVisibility(R.id.todo_more, View.VISIBLE)
    } else {
        views.setViewVisibility(R.id.todo_more, View.GONE)
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}

private data class WidgetTodo(
    val id: String,
    val title: String,
    val completed: Boolean
)

private fun parseTodos(todosJson: String?): List<WidgetTodo> {
    if (todosJson.isNullOrBlank()) return emptyList()

    return try {
        val array = JSONArray(todosJson)
        buildList(array.length()) {
            for (i in 0 until array.length()) {
                val todo = array.optJSONObject(i) ?: continue
                val id = todo.optString("id")
                val title = todo.optString("title")
                if (id.isBlank() || title.isBlank()) continue
                add(
                    WidgetTodo(
                        id = id,
                        title = title,
                        completed = todo.optBoolean("completed", false)
                    )
                )
                if (size >= TodoWidgetStore.WIDGET_LIMIT) break
            }
        }
    } catch (_: Exception) {
        emptyList()
    }
}

private fun widgetHeightDp(options: Bundle): Int {
    val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
    if (maxHeight > 0) return maxHeight
    val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
    if (minHeight > 0) return minHeight
    return 110
}

private fun visibleTodoCount(context: Context, heightDp: Int, total: Int): Int {
    if (total <= 0) return 0
    val paddingDp = 32
    val titleDp = dimenDp(context, R.dimen.widget_title_height)
    val rowDp = dimenDp(context, R.dimen.widget_todo_row_height)
    val moreDp = dimenDp(context, R.dimen.widget_more_height)
    val available = heightDp - paddingDp - titleDp
    if (available < rowDp) return 1.coerceAtMost(total)

    val maxWithoutMore = (available / rowDp).coerceAtLeast(1).coerceAtMost(todoSlots.size)
    if (total <= maxWithoutMore) return total

    val maxWithMore = ((available - moreDp) / rowDp).coerceAtLeast(1).coerceAtMost(todoSlots.size)
    return maxWithMore.coerceAtMost(total)
}

private fun dimenDp(context: Context, id: Int): Int {
    val density = context.resources.displayMetrics.density
    return (context.resources.getDimension(id) / density).toInt().coerceAtLeast(1)
}

private fun setChecked(views: RemoteViews, viewId: Int, checked: Boolean) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        views.setCompoundButtonChecked(viewId, checked)
    } else {
        views.setBoolean(viewId, "setChecked", checked)
    }
}
