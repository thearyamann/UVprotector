package com.example.uv_index_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.SweepGradient
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.min

open class UVWidgetProvider : HomeWidgetProvider() {

    protected open fun shouldUseSmallLayout(
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ): Boolean {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        return minWidth > 0 && minWidth < 200
    }

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

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        val uvIndex = widgetData.getInt("uv_index", 0)
        val uvStatus = widgetData.getString("uv_status", "Low") ?: "Low"
        val burnTime = widgetData.getString("burn_time", "0 mins") ?: "0 mins"
        val timerRunning = widgetData.getBoolean("timer_running", false)
        val timerEndMs = widgetData.getLong("timer_end_time", 0L)
        val timerProgressPercent = widgetData.getInt("timer_progress_percent", 0)
        val sessionsText = widgetData.getString("sessions_text", "0/0") ?: "0/0"
        val protectionStatus = widgetData.getString("protection_status", "Not Applied") ?: "Not Applied"
        val isLow = uvIndex <= 2

        val sessionsParts = sessionsText.split("/")
        val sessionsCompleted = sessionsParts.getOrNull(0)?.toIntOrNull() ?: 0
        val sessionsTotal = sessionsParts.getOrNull(1)?.toIntOrNull() ?: 0

        val isSmall = shouldUseSmallLayout(appWidgetManager, appWidgetId)

        if (isSmall) {
            updateSmallWidget(context, appWidgetManager, appWidgetId, uvIndex, uvStatus, timerRunning, timerEndMs, protectionStatus, isLow)
        } else {
            updateMediumWidget(context, appWidgetManager, appWidgetId, uvIndex, uvStatus, burnTime, timerRunning, timerEndMs, timerProgressPercent, sessionsCompleted, sessionsTotal, protectionStatus, isLow)
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
            views.setInt(R.id.sw_pill_text, "setBackgroundResource", R.drawable.pill_bg_green)
            views.setViewVisibility(R.id.sw_timer_card, View.GONE)
            views.setViewVisibility(R.id.sw_message_card, View.VISIBLE)
            stopChronometer(views, R.id.sw_timer_text)
        } else {
            views.setInt(R.id.sw_pill_text, "setBackgroundResource", R.drawable.pill_bg_high)
            views.setViewVisibility(R.id.sw_message_card, View.GONE)
            views.setViewVisibility(R.id.sw_timer_card, View.VISIBLE)

            val nowMs = System.currentTimeMillis()
            val remainMs = timerEndMs - nowMs

            if (timerRunning && timerEndMs > nowMs) {
                bindCountdownChronometer(views, R.id.sw_timer_text, remainMs)
                val subLabel = if (protectionStatus == "Expiring Soon") "Expiring" else "Active"
                views.setTextViewText(R.id.sw_timer_sub, subLabel)
            } else {
                stopChronometer(views, R.id.sw_timer_text)
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
        timerProgressPercent: Int,
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
            stopChronometer(views, R.id.mw_timer)
            views.setTextViewText(
                R.id.mw_low_sessions,
                "$sessionsCompleted / $sessionsTotal Sessions"
            )
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
                bindCountdownChronometer(views, R.id.mw_timer, remainMs)
                views.setTextColor(R.id.mw_timer, Color.argb(235, 255, 255, 255))
            } else {
                stopChronometer(views, R.id.mw_timer)
                views.setTextViewText(R.id.mw_timer, "--:--:--")
                views.setTextColor(R.id.mw_timer, Color.argb(76, 255, 255, 255))
            }

            views.setTextViewText(R.id.mw_sessions_label, "$sessionsCompleted / $sessionsTotal Sessions")
            val fraction = (timerProgressPercent.coerceIn(0, 100) / 100f)
            views.setImageViewBitmap(R.id.mw_sessions_bar, drawTimerBar(fraction, 400, 12))
        }

        updateWidgetClick(context, views)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun updateWidgetClick(context: Context, views: RemoteViews) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return
        val pi = android.app.PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(android.R.id.background, pi)
    }

    private fun bindCountdownChronometer(
        views: RemoteViews,
        viewId: Int,
        remainingMs: Long
    ) {
        val safeRemainingMs = remainingMs.coerceAtLeast(0L)
        val base = SystemClock.elapsedRealtime() + safeRemainingMs
        views.setChronometer(viewId, base, null, true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            views.setChronometerCountDown(viewId, true)
        }
    }

    private fun stopChronometer(views: RemoteViews, viewId: Int) {
        views.setChronometer(viewId, SystemClock.elapsedRealtime(), null, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            views.setChronometerCountDown(viewId, false)
        }
    }

    private fun riskColor(uvIndex: Int): Int = when {
        uvIndex <= 2 -> Color.parseColor("#4ade80")
        uvIndex <= 5 -> Color.parseColor("#fbbf24")
        uvIndex <= 7 -> Color.parseColor("#f97316")
        else -> Color.parseColor("#f9741b")
    }

    private fun drawRing(uvIndex: Int, ringColor: Int, sizePx: Int): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val cx = sizePx / 2f
        val cy = sizePx / 2f
        val strokeW = sizePx * 0.07f
        val radius = cx - strokeW

        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = strokeW
            this.color = Color.argb(20, 255, 255, 255)
        }
        val oval = RectF(cx - radius, cy - radius, cx + radius, cy + radius)
        canvas.drawArc(oval, -90f, 360f, false, trackPaint)

        val progress = min(uvIndex / 11f, 1f)
        val sweepAngle = progress * 360f

        val startColor = riskColor(maxOf(0, uvIndex - 2))
        val gradient = SweepGradient(cx, cy, intArrayOf(startColor, ringColor), null)

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

    private fun drawTimerBar(fraction: Float, w: Int, h: Int): Bitmap {
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val r = h / 2f

        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(25, 255, 255, 255)
        }
        canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), r, r, trackPaint)

        val fillW = (w * fraction).coerceAtLeast(8f)
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = when {
                fraction > 0.5f -> Color.parseColor("#16a34a")
                fraction > 0.2f -> Color.parseColor("#eab308")
                else -> Color.parseColor("#ef4444")
            }
        }
        canvas.drawRoundRect(RectF(0f, 0f, fillW, h.toFloat()), r, r, fillPaint)
        return bmp
    }
}
