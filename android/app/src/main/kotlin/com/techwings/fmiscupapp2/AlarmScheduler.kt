package com.techwings.fmiscupapp2

import android.annotation.TargetApi
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

class AlarmScheduler(private val context: Context) {

    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun setScheduledAlarms() {
        val times = listOf(
            Pair(4, 0),   // 04:00 AM
            Pair(8, 0),   // 08:00 AM
            Pair(12, 0),  // 12:00 PM
            Pair(16, 0),  // 04:00 PM
            Pair(20, 0),  // 08:00 PM
            Pair(0, 0)    // 00:00 AM (midnight)
        )

        times.forEach { (hour, minute) ->
            setAlarm(hour, minute)
        }
    }

    @TargetApi(Build.VERSION_CODES.M)
    fun setAlarm(hour: Int, minute: Int) {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (before(Calendar.getInstance())) {
                add(Calendar.DAY_OF_MONTH, 1)
            }
        }

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("hour", hour)
            putExtra("minute", minute)
        }

        val requestCode = hour * 100 + minute
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            calendar.timeInMillis,
            pendingIntent
        )
    }
}
