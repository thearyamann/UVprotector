package com.example.uv_index_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.math.roundToInt

class UVWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            
            // Extract values (matching Flutter WidgetService keys)
            val uvIndex = widgetData.getInt("uv_index", 0)
            val uvStatus = widgetData.getString("uv_status", "--")
            val burnTime = widgetData.getString("burn_time", "--")
            val sessionsText = widgetData.getString("sessions_text", "0/0")
            val protectionStatus = widgetData.getString("protection_status", "Not Applied")
            val timerRunning = widgetData.getBoolean("timer_running", false)
            val timerEndTime = widgetData.getLong("timer_end_time", 0L)

            // Determine layout based on widget size (Android doesn't make this trivial in Provider)
            // For now, we update both as they use mostly the same IDs where applicable.
            
            val views = RemoteViews(context.packageName, R.layout.uv_widget_medium).apply {
                setTextViewText(R.id.widget_uv_index, uvIndex.toString())
                setTextViewText(R.id.widget_uv_status, uvStatus)
                setTextViewText(R.id.widget_burn_time, "Burn in $burnTime")
                setTextViewText(R.id.widget_sessions_text, "$sessionsText Sessions")
                setTextViewText(R.id.widget_protection_status, protectionStatus)

                // Simple Timer logic for Android widget (Limited)
                if (timerRunning && timerEndTime > 0) {
                    val remainingMs = timerEndTime - System.currentTimeMillis()
                    val remainingMins = (remainingMs / (1000 * 60)).coerceAtLeast(0)
                    setTextViewText(R.id.widget_timer_text, "${remainingMins}m left")
                } else {
                    setTextViewText(R.id.widget_timer_text, "--:--")
                }

                // UV Color mapping
                val uvColor = when {
                    uvIndex >= 8 -> 0xFFEF4444.toInt() // Very High
                    uvIndex >= 6 -> 0xFFF97316.toInt() // High
                    uvIndex >= 3 -> 0xFFEAB308.toInt() // Moderate
                    else -> 0xFF22C55E.toInt() // Low
                }
                setTextColor(R.id.widget_uv_status, uvColor)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
