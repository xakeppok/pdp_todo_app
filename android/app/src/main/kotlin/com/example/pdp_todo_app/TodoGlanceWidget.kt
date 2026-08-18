package com.example.pdp_todo_app

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionSendBroadcast
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.updateAll
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

private val widgetBackground = ColorProvider(day = Color.White, night = Color(0xFF1C1B1F))
private val widgetOnBackground = ColorProvider(day = Color(0xFF1C1B1F), night = Color(0xFFE6E1E5))

class TodoGlanceWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Exact
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<HomeWidgetGlanceState>().preferences
            val todos = TodoWidgetStore.parseTodos(TodoWidgetStore.widgetTodosJson(prefs))
            val totalCount = TodoWidgetStore.totalCount(prefs, todos.size)
            TodoGlanceContent(
                context = context,
                todos = todos,
                totalCount = totalCount,
            )
        }
    }

    companion object {
        private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

        fun refreshAll(context: Context) {
            val appContext = context.applicationContext
            scope.launch {
                TodoGlanceWidget().updateAll(appContext)
            }
        }
    }
}

class TodoGlanceWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodoGlanceWidget>() {
    override val glanceAppWidget = TodoGlanceWidget()
}

@Composable
private fun TodoGlanceContent(
    context: Context,
    todos: List<WidgetTodo>,
    totalCount: Int,
) {
    val heightDp = LocalSize.current.height.value.toInt()
    val fit = fitTodos(context, heightDp, todos.size)
    val remaining = (totalCount - fit.visibleCount).coerceAtLeast(0)
    val listIntent = TodoWidgetIntents.viewIntent(context, TodoWidgetIntents.listUri())

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .background(widgetBackground)
            .cornerRadius(16.dp)
            .padding(16.dp),
    ) {
        Text(
            text = context.getString(R.string.widget_glance_title),
            style = TextStyle(
                color = widgetOnBackground,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
            ),
            maxLines = 1,
            modifier = GlanceModifier.clickable(onClick = actionStartActivity(listIntent)),
        )

        if (todos.isEmpty()) {
            Text(
                text = context.getString(R.string.widget_empty),
                style = TextStyle(
                    color = widgetOnBackground,
                    fontSize = 18.sp,
                ),
                modifier = GlanceModifier
                    .padding(top = 8.dp)
                    .clickable(onClick = actionStartActivity(listIntent)),
            )
            return@Column
        }

        todos.take(fit.visibleCount).forEach { todo ->
            TodoGlanceRow(context = context, todo = todo)
        }

        if (fit.showMore && remaining > 0) {
            Text(
                text = "+ $remaining more",
                style = TextStyle(
                    color = widgetOnBackground,
                    fontSize = 16.sp,
                ),
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(top = 4.dp)
                    .clickable(onClick = actionStartActivity(listIntent)),
            )
        }
    }
}

@Composable
private fun TodoGlanceRow(context: Context, todo: WidgetTodo) {
    val detailsIntent = TodoWidgetIntents.viewIntent(
        context,
        TodoWidgetIntents.detailsUri(todo.id),
    )
    val checkIcon = if (todo.completed) {
        R.drawable.widget_checkbox_checked
    } else {
        R.drawable.widget_checkbox_unchecked
    }

    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(40.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            provider = ImageProvider(checkIcon),
            contentDescription = context.getString(R.string.widget_complete_todo),
            modifier = GlanceModifier
                .size(32.dp)
                // Same broadcast as TodoWidget: TodoWidgetToggleReceiver + todo id.
                .clickable(
                    onClick = actionSendBroadcast(
                        TodoWidgetIntents.toggleIntent(context, todo.id),
                    ),
                ),
        )
        Text(
            text = todo.title,
            maxLines = 1,
            style = TextStyle(
                color = widgetOnBackground,
                fontSize = 18.sp,
            ),
            modifier = GlanceModifier
                .defaultWeight()
                .padding(start = 4.dp, end = 4.dp)
                .clickable(onClick = actionStartActivity(detailsIntent)),
        )
    }
}
