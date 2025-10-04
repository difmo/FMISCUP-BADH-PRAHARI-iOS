package com.techwings.fmiscupapp2

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*
import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.techwings.fmiscupapp2"
    private val ALARM_CHANNEL = "alarm_channel"
    private lateinit var alarmManager: AlarmManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeveloperModeEnabled" -> {
                    val isEnabled = isDeveloperModeEnabled(this)
                    result.success(isEnabled)
                }

                "openDeveloperSettings" -> {
                    try {
                        val intent =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                                Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                            } else {
                                Intent(Settings.ACTION_SETTINGS)
                            }
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Cannot open developer settings", null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // Alarm Control Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAlarms" -> {
    val scheduler = AlarmScheduler(this)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (alarmManager.canScheduleExactAlarms()) {
            scheduler.setScheduledAlarms()
            result.success("Alarms set")
        } else {
            result.error("PERMISSION_DENIED", "Exact alarm permission not granted", null)
        }
    } else {
        scheduler.setScheduledAlarms()
        result.success("Alarms set")
    }
}


                "requestExactAlarmPermission" -> {
                    requestExactAlarmPermission(this)
                    result.success("Permission Requested")
                }

                "cancelAlarms" -> {
                    //cancelAlarms()
                    result.success("Alarms_canceled")
                }

                else -> result.notImplemented()
            }
        }
    }


    fun requestExactAlarmPermission(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (!alarmManager.canScheduleExactAlarms()) {
                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
                Toast.makeText(context, "Please allow exact alarm permission", Toast.LENGTH_LONG)
                    .show()
            }
        }
    }


    private fun isDeveloperModeEnabled(context: Context): Boolean {
        return Settings.Secure.getInt(
            context.contentResolver, Settings.Secure.DEVELOPMENT_SETTINGS_ENABLED, 0
        ) != 0
    }

    private fun setScheduledAlarms() {
        val times = listOf(
            Pair(21, 2), Pair(21, 4), Pair(21, 6)
        )

        times.forEach { (hour, minute) ->
            setAlarm(hour, minute)
        }
    }

    private fun setAlarm(hour: Int, minute: Int) {
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

        val requestCode = hour * 100 + minute

        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "ALARM_$requestCode"  // Make each intent unique
            putExtra("hour", hour)
            putExtra("minute", minute)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP, calendar.timeInMillis, AlarmManager.INTERVAL_DAY, pendingIntent
        )
    }

    private fun calculateTriggerTime(hour: Int, minute: Int): Long {
        val currentTime = Calendar.getInstance()
        val targetTime = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (before(currentTime)) add(Calendar.DATE, 1)
        }
        return targetTime.timeInMillis
    }
}
