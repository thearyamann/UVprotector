package com.example.uv_index_app

import android.appwidget.AppWidgetManager

class UVWidgetMediumProvider : UVWidgetProvider() {
    override fun shouldUseSmallLayout(
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ): Boolean = false
}
