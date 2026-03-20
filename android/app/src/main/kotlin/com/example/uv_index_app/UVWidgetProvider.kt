package com.example.uv_index_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.*
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import android.graphics.drawable.GradientDrawable
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.min

class UVWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: android.content.SharedPreferences
    ) {
        val uvIndex = widgetData.getInt("uv_index", 0)
        val uvStatus = widgetData.getString("uv_status", "Low") ?: "Low"
        val burnTime = widgetData.getString("burn_time", "0 mins") ?: "0 mins"
        val timerRunning = widgetData.getBoolean("timer_running", false)
        val timerEndMs = widgetData.getLong("timer_end_time", 0L)
        val sessionsText = widgetData.getString("sessions_text", "0/0") ?: "0/0"
        val protectionStatus = widgetData.getString("protection_status", "Not Applied") ?: "Not Applied"
        val isLow = uvIndex <= 2

        val sessionsParts = sessionsText.split("/")
        val sessionsCompleted = sessionsParts.getOrNull(0)?.toIntOrNull() ?: 0
        val sessionsTotal = sessionsParts.getOrNull(1)?.toIntOrNull() ?: 0

        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val isSmall = minWidth > 0 && minWidth < 200

        if (isSmall) {
            updateSmallWidget(context, appWidgetManager, appWidgetId, uvIndex, uvStatus, timerRunning, timerEndMs, protectionStatus, isLow)
        } else {
            updateMediumWidget(context, appWidgetManager, appWidgetId, uvIndex, uvStatus, burnTime, timerRunning, timerEndMs, sessionsCompleted, sessionsTotal, protectionStatus, isLow)
        }
    }

    private fun updateSmallWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        uvIndex: Int,
        uvStatus: String,
        timerRunning: Boolean,
        timerEndMs: Long,
        protectionStatus: String,
        isLow: Boolean
    ) {
        val views = RemoteViews(context.packageName, R.layout.uv_widget_small)
        val rc = riskColor(uvIndex)

        views.setTextViewText(R.id.sw_uv_number, uvIndex.toString())
        views.setTextColor(R.id.sw_uv_number, rc)
        views.setTextColor(R.id.sw_pill_text, rc)
        views.setTextViewText(R.id.sw_pill_text, uvStatus.uppercase())

        if (isLow) {
            views.setViewVisibility(R.id.sw_timer_card, View.GONE)
            views.setViewVisibility(R.id.sw_message_card, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.sw_message_card, View.GONE)
            views.setViewVisibility(R.id.sw_timer_card, View.VISIBLE)

            val nowMs = System.currentTimeMillis()
            val remainMs = timerEndMs - nowMs

            if (timerRunning && timerEndMs > nowMs) {
                val mins = (remainMs / 60000).toInt()
                val secs = ((remainMs % 60000) / 1000).toInt()
                views.setTextViewText(R.id.sw_timer_text, String.format("%02d:%02d", mins, secs))
                val subLabel = if (protectionStatus == "Expiring Soon") "Expiring" else "Active"
                views.setTextViewText(R.id.sw_timer_sub, subLabel)
            } else {
                views.setTextViewText(R.id.sw_timer_text, "--:--")
                views.setTextViewText(R.id.sw_timer_sub, "Ready")
            }
        }

        updateWidgetClick(context, views)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun updateMediumWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        uvIndex: Int,
        uvStatus: String,
        burnTime: String,
        timerRunning: Boolean,
        timerEndMs: Long,
        sessionsCompleted: Int,
        sessionsTotal: Int,
        protectionStatus: String,
        isLow: Boolean
    ) {
        val views = RemoteViews(context.packageName, R.layout.uv_widget_medium)
        val rc = riskColor(uvIndex)

        views.setTextViewText(R.id.mw_uv_number, uvIndex.toString())
        views.setTextColor(R.id.mw_uv_number, rc)
        views.setTextViewText(R.id.mw_burn_time, "Burn in $burnTime")
        views.setTextColor(R.id.mw_burn_time, rc)
        views.setImageViewBitmap(R.id.mw_ring, drawRing(uvIndex, rc, 144))

        if (isLow) {
            views.setViewVisibility(R.id.mw_active_panel, View.GONE)
            views.setViewVisibility(R.id.mw_low_panel, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.mw_low_panel, View.GONE)
            views.setViewVisibility(R.id.mw_active_panel, View.VISIBLE)

            val (pillText, pillColor) = when (protectionStatus) {
                "Protected" -> "Protected" to Color.parseColor("#4ade80")
                "Expiring Soon" -> "Expiring Soon" to Color.parseColor("#f87171")
                "Done for today" -> "Done for today" to Color.parseColor("#4ade80")
                else -> "Unprotected" to Color.parseColor("#f87171")
            }
            views.setTextViewText(R.id.mw_protect_text, pillText.uppercase())
            views.setTextColor(R.id.mw_protect_text, pillColor)

            val nowMs = System.currentTimeMillis()
            val remainMs = timerEndMs - nowMs
            if (timerRunning && timerEndMs > nowMs) {
                val h = (remainMs / 3600000).toInt()
                val m = ((remainMs % 3600000) / 60000).toInt()
                val s = ((remainMs % 60000) / 1000).toInt()
                views.setTextViewText(R.id.mw_timer, String.format("%02d:%02d:%02d", h, m, s))
                views.setTextColor(R.id.mw_timer, Color.argb(235, 255, 255, 255))
            } else {
                views.setTextViewText(R.id.mw_timer, "--:--:--")
                views.setTextColor(R.id.mw_timer, Color.argb(76, 255, 255, 255))
            }

            views.setTextViewText(R.id.mw_sessions_label, "$sessionsCompleted / $sessionsTotal Sessions")
            val fraction = if (sessionsTotal > 0) sessionsCompleted.toFloat() / sessionsTotal else 0f
            views.setImageViewBitmap(R.id.mw_sessions_bar, drawSessionsBar(fraction, 400, 12))
        }

        updateWidgetClick(context, views)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun updateWidgetClick(context: Context, views: RemoteViews) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pi = android.app.PendingIntent.getActivity(
            context, 0, launchIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(android.R.id.background, pi)
    }

    private fun riskColor(uvIndex: Int): Int = when {
        uvIndex <= 2 -> Color.parseColor("#4ade80")
        uvIndex <= 5 -> Color.parseColor("#fbbf24")
        uvIndex <= 7 -> Color.parseColor("#f97316")
        else -> Color.parseColor("#f87171")
    }

    private fun drawRing(uvIndex: Int, color: Int, sizePx: Int): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val cx = sizePx / 2f
        val cy = sizePx / 2f
        val strokeW = sizePx * 0.07f
        val radius = cx - strokeW

        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = strokeW
            color = Color.argb(20, 255, 255, 255)
        }
        val oval = RectF(cx - radius, cy - radius, cx + radius, cy + radius)
        canvas.drawArc(oval, -90f, 360f, false, trackPaint)

        val progress = min(uvIndex / 11f, 1f)
        val sweepAngle = progress * 360f

        val startColor = riskColor(maxOf(0, uvIndex - 2))
        val gradient = SweepGradient(cx, cy, intArrayOf(startColor, color), null)

        val arcPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = strokeW
            strokeCap = Paint.Cap.ROUND
            shader = gradient
        }
        canvas.rotate(-90f, cx, cy)
        canvas.drawArc(oval, 0f, sweepAngle, false, arcPaint)
        return bmp
    }

    private fun drawSessionsBar(fraction: Float, w: Int, h: Int): Bitmap {
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val r = h / 2f

        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(25, 255, 255, 255)
        }
        canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), r, r, trackPaint)

        val fillW = (w * fraction).coerceAtLeast(8f)
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(0f, 0f, fillW, 0f,
                Color.parseColor("#4ade80"), Color.parseColor("#22d3ee"),
                Shader.TileMode.CLAMP)
        }
        canvas.drawRoundRect(RectF(0f, 0f, fillW, h.toFloat()), r, r, fillPaint)
        return bmp
    }
}
