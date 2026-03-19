package com.example.uv_index_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.*
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class UVWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, widgetData: SharedPreferences) {
        val uvIndex = widgetData.getInt("uv_index", 0)
        val uvStatus = widgetData.getString("uv_status", "Low") ?: "Low"
        val burnTime = widgetData.getString("burn_time", "0") ?: "0"
        val timerRunning = widgetData.getBoolean("timer_running", false)
        val timerEndMs = widgetData.getLong("timer_end_time", 0L)
        val sessionsCompleted = widgetData.getInt("sessions_completed", 0)
        val sessionsTotal = widgetData.getInt("sessions_total", 0)
        val protectionStatus = widgetData.getString("protection_status", "Unprotected") ?: "Unprotected"
        val isLowUv = widgetData.getBoolean("is_low_uv", false)

        val riskColor = getRiskColor(uvIndex)

        // ---------------- SMALL WIDGET ----------------
        val smallViews = RemoteViews(context.packageName, R.layout.uv_widget_small).apply {
            setTextViewText(R.id.tv_uv_index, uvIndex.toString())
            setTextColor(R.id.tv_uv_index, riskColor)
            
            setImageViewBitmap(R.id.iv_status_pill, createStatusPillBitmap(uvStatus, riskColor))
            
            if (isLowUv) {
                setViewVisibility(R.id.bottom_card_standard, android.view.View.GONE)
                setViewVisibility(R.id.bottom_card_low_uv, android.view.View.VISIBLE)
            } else {
                setViewVisibility(R.id.bottom_card_standard, android.view.View.VISIBLE)
                setViewVisibility(R.id.bottom_card_low_uv, android.view.View.GONE)
                
                if (timerRunning && timerEndMs > 0) {
                    setViewVisibility(R.id.timer, android.view.View.VISIBLE)
                    setViewVisibility(R.id.tv_timer_fallback, android.view.View.GONE)
                    setTextViewText(R.id.tv_bottom_status, "Active")
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        setChronometerCountDown(R.id.timer, true)
                        setChronometer(R.id.timer, SystemClock.elapsedRealtime() + (timerEndMs - System.currentTimeMillis()), null, false)
                    } else {
                        setViewVisibility(R.id.timer, android.view.View.GONE)
                        setViewVisibility(R.id.tv_timer_fallback, android.view.View.VISIBLE)
                        setTextViewText(R.id.tv_timer_fallback, "Active")
                    }
                } else {
                    setViewVisibility(R.id.timer, android.view.View.GONE)
                    setViewVisibility(R.id.tv_timer_fallback, android.view.View.VISIBLE)
                    setTextViewText(R.id.tv_bottom_status, "Ready")
                }
            }
        }
        
        // ---------------- MEDIUM WIDGET ----------------
        val mediumViews = RemoteViews(context.packageName, R.layout.uv_widget_medium).apply {
            setImageViewBitmap(R.id.iv_uv_ring, createCircularRing(uvIndex, riskColor, 300))
            
            setTextViewText(R.id.tv_burn_time, "$burnTime mins")
            setTextColor(R.id.tv_burn_time, riskColor)
            
            if (isLowUv) {
                setViewVisibility(R.id.right_card_standard, android.view.View.GONE)
                setViewVisibility(R.id.right_card_low_uv, android.view.View.VISIBLE)
                
                val goodColor = Color.parseColor("#4ade80")
                setImageViewBitmap(R.id.iv_low_uv_pill, createStatusPillBitmap("UV IS LOW", goodColor))
                setTextViewText(R.id.tv_sessions_low_uv, "$sessionsCompleted / $sessionsTotal Sessions")
            } else {
                setViewVisibility(R.id.right_card_standard, android.view.View.VISIBLE)
                setViewVisibility(R.id.right_card_low_uv, android.view.View.GONE)
                
                val isGood = protectionStatus.lowercase().contains("protected") || protectionStatus.lowercase().contains("done")
                val protColor = if (isGood) Color.parseColor("#4ade80") else Color.parseColor("#f87171")
                
                setImageViewBitmap(R.id.iv_protection_pill, createStatusPillBitmap(protectionStatus, protColor))
                
                if (timerRunning && timerEndMs > 0) {
                    setViewVisibility(R.id.timer_large, android.view.View.VISIBLE)
                    setViewVisibility(R.id.tv_timer_large_fallback, android.view.View.GONE)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        setChronometerCountDown(R.id.timer_large, true)
                        setChronometer(R.id.timer_large, SystemClock.elapsedRealtime() + (timerEndMs - System.currentTimeMillis()), "%s", false)
                    }
                } else {
                    setViewVisibility(R.id.timer_large, android.view.View.GONE)
                    setViewVisibility(R.id.tv_timer_large_fallback, android.view.View.VISIBLE)
                }
                
                setTextViewText(R.id.tv_sessions, "$sessionsCompleted / $sessionsTotal Sessions")
                setImageViewBitmap(R.id.iv_session_progress, createProgressBarBitmap(sessionsCompleted, sessionsTotal, 400, 10))
            }
        }

        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val views = if (minWidth > 0 && minWidth < 200) smallViews else mediumViews
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getRiskColor(index: Int): Int {
        return when {
            index >= 8 -> Color.parseColor("#f87171")
            index >= 6 -> Color.parseColor("#f97316")
            index >= 3 -> Color.parseColor("#fbbf24")
            else -> Color.parseColor("#4ade80")
        }
    }

    private fun createStatusPillBitmap(text: String, color: Int): Bitmap {
        val displayDensity = 3f 
        val textSizePx = 10f * displayDensity * 1.5f 
        
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            textSize = textSizePx
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            letterSpacing = 0.08f
        }
        
        val textWidth = textPaint.measureText(text.uppercase())
        val height = 24f * displayDensity 
        val dotRadius = 2.5f * displayDensity
        val paddingStart = 8f * displayDensity
        val dotSpacing = 4f * displayDensity
        val paddingEnd = 10f * displayDensity
        
        val width = paddingStart + (dotRadius * 2) + dotSpacing + textWidth + paddingEnd
        
        val bitmap = Bitmap.createBitmap(width.toInt(), height.toInt(), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            this.color = color
            alpha = (255 * 0.22).toInt()
        }
        val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 1f * displayDensity
            this.color = color
            alpha = (255 * 0.40).toInt()
        }
        
        val radius = height / 2f
        canvas.drawRoundRect(0f, 0f, width.toFloat(), height, radius, radius, bgPaint)
        
        val inset = (1f * displayDensity) / 2f
        canvas.drawRoundRect(inset, inset, width.toFloat() - inset, height - inset, radius, radius, borderPaint)
        
        val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }
        val dotX = paddingStart + dotRadius
        val dotY = height / 2f
        canvas.drawCircle(dotX, dotY, dotRadius, dotPaint)
        
        val textX = dotX + dotRadius + dotSpacing
        val textY = (height / 2f) - ((textPaint.descent() + textPaint.ascent()) / 2f)
        canvas.drawText(text.uppercase(), textX, textY, textPaint)
        
        return bitmap
    }

    private fun createCircularRing(uvIndex: Int, riskColor: Int, size: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        val strokeWidth = size * 0.08f
        val padding = strokeWidth / 2f
        val rect = RectF(padding, padding, size - padding, size - padding)
        
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.parseColor("#14FFFFFF")
            this.strokeWidth = strokeWidth
        }
        canvas.drawArc(rect, 0f, 360f, false, trackPaint)
        
        val progress = Math.min((uvIndex / 11f), 1f)
        val sweepAngle = 360f * progress
        
        val startColor = getRiskColor(Math.max(0, uvIndex - 2))
        val gradient = LinearGradient(0f, 0f, 0f, size.toFloat(), startColor, riskColor, Shader.TileMode.CLAMP)
        
        val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            strokeCap = Paint.Cap.ROUND
            shader = gradient
        }
        
        canvas.drawArc(rect, -90f, sweepAngle, false, progressPaint)
        
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = riskColor
            textSize = size * 0.45f
            textAlign = Paint.Align.CENTER
            typeface = Typeface.DEFAULT_BOLD
        }
        
        val textY = (size / 2f) - ((textPaint.descent() + textPaint.ascent()) / 2f)
        canvas.drawText(uvIndex.toString(), size / 2f, textY, textPaint)
        
        return bitmap
    }

    private fun createProgressBarBitmap(completed: Int, total: Int, width: Int, height: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1AFFFFFF")
            style = Paint.Style.FILL
        }
        val radius = height / 2f
        canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), radius, radius, trackPaint)
        
        val realTotal = if (total > 0) total else 1
        val progress = Math.min((completed.toFloat() / realTotal.toFloat()), 1f)
        
        if (progress > 0) {
            val gradient = LinearGradient(0f, 0f, width.toFloat(), 0f, Color.parseColor("#4ade80"), Color.parseColor("#22d3ee"), Shader.TileMode.CLAMP)
            val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                shader = gradient
            }
            canvas.drawRoundRect(0f, 0f, width * progress, height.toFloat(), radius, radius, fillPaint)
        }
        
        return bitmap
    }
}
