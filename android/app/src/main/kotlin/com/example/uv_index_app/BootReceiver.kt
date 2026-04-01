package com.example.uv_index_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // WorkManager tasks will be re-scheduled when the app is opened
            // The Flutter workmanager plugin handles this automatically
            // Just ensure the app can receive boot completed
        }
    }
}
