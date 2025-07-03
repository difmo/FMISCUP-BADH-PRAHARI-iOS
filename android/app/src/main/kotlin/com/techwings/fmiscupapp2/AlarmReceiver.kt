package com.techwings.fmiscupapp2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        context?.let {
            val hour = intent?.getIntExtra("hour", -1) ?: -1
            val minute = intent?.getIntExtra("minute", -1) ?: -1
            val notificationId = hour * 100 + minute
            Log.d("AlarmReceiver", "Alarm triggered at $hour:$minute")
            try {
                NotificationFactory.fireNotification(it, notificationId)
            } catch (e: Exception) {
                Toast.makeText(it, "Notification error: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
