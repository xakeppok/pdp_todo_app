package com.example.pdp_todo_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

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
    val todos = TodoWidgetStore.parseTodos(TodoWidgetStore.widgetTodosJson(widgetData))
    val listIntent = TodoWidgetIntents.launchIntent(context, TodoWidgetIntents.listUri(), "list")
    views.setOnClickPendingIntent(R.id.widget_title, listIntent)
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
    val fit = fitTodos(context, heightDp, todos.size)

    for (index in todoSlots.indices) {
        val slot = todoSlots[index]
        if (index < fit.visibleCount) {
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

    val remaining = TodoWidgetStore.totalCount(widgetData, todos.size) - fit.visibleCount
    if (fit.showMore && remaining > 0) {
        views.setTextViewText(R.id.todo_more, "+ $remaining more")
        views.setViewVisibility(R.id.todo_more, View.VISIBLE)
    } else {
        views.setViewVisibility(R.id.todo_more, View.GONE)
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}

private fun widgetHeightDp(options: Bundle): Int {
    widgetSizes(options)?.minOfOrNull { it.height.toInt() }?.takeIf { it > 0 }?.let { return it }
    val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
    val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
    return listOf(minHeight, maxHeight).filter { it > 0 }.minOrNull() ?: 110
}

private fun widgetSizes(options: Bundle): List<SizeF>? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        options.getParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES, SizeF::class.java)
    } else {
        @Suppress("DEPRECATION")
        options.getParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES)
    }
}

internal data class TodoWidgetFit(
    val visibleCount: Int,
    val showMore: Boolean,
)

internal fun fitTodos(context: Context, heightDp: Int, total: Int): TodoWidgetFit {
    if (total <= 0) return TodoWidgetFit(0, false)
    val paddingDp = 32
    val titleDp = dimenDp(context, R.dimen.widget_title_height)
    val rowDp = dimenDp(context, R.dimen.widget_todo_row_height)
    val moreDp = dimenDp(context, R.dimen.widget_more_height)
    val available = (heightDp - paddingDp - titleDp).coerceAtLeast(0)
    val limit = TodoWidgetStore.WIDGET_LIMIT

    val maxWithoutMore = (available / rowDp).coerceAtMost(limit)
    if (total <= maxWithoutMore) {
        return TodoWidgetFit(total, false)
    }

    val maxWithMore = ((available - moreDp) / rowDp).coerceAtMost(limit)
    if (maxWithMore >= 1) {
        return TodoWidgetFit(maxWithMore.coerceAtMost(total), true)
    }

    return TodoWidgetFit(1.coerceAtMost(total).coerceAtMost(maxWithoutMore.coerceAtLeast(1)), false)
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
