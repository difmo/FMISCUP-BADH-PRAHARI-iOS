package com.techwings.fmiscupapp2

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

class NotificationFactory {

    companion object {
        val channelId = "my_channel_id"
        val channelName = "My Channel"

        fun fireNotification(context: Context, notificationId: Int) {
            createNotificationChannel(context, channelId, channelName)
            sendNotification(
                context,
                channelId,
                notificationId,
                "Flood Data Saving Reminder",
                "Please ensure all remaining flood information is saved."
            )
        }

        fun createNotificationChannel(context: Context, channelId: String, channelName: String) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val importance = NotificationManager.IMPORTANCE_HIGH
                val channel = NotificationChannel(channelId, channelName, importance).apply {
                    description = "Notification channel description"
                }

                val notificationManager =
                    context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            }
        }

        fun sendNotification(
            context: Context,
            channelId: String,
            notificationId: Int,
            title: String,
            message: String
        ) {
            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(androidx.core.R.drawable.ic_call_answer) // Replace with your icon
                .setContentTitle(title)
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_HIGH)

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId, builder.build())
        }
    }
}
