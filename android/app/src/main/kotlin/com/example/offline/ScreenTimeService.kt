package com.example.offline

import android.app.Service
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.Context
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.os.IBinder
import android.os.Build
import androidx.core.app.NotificationCompat
import android.util.Log

class ScreenTimeService : Service() {
    companion object {
        const val CHANNEL_ID = "ScreenTimeMonitor"
        const val NOTIFICATION_ID = 1001
        private const val TAG = "OfflineApp"
        const val PREFS_NAME = "screen_time_service_prefs"
        const val KEY_LAST_SCREEN_OFF_MS = "last_screen_off_ms"
        const val KEY_PENDING_OFFLINE_MS = "pending_offline_ms"
    }

    private var screenReceiver: BroadcastReceiver? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "✅ ScreenTimeService iniciado")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        registerScreenReceiverIfNeeded()
        return START_STICKY
    }

    private fun registerScreenReceiverIfNeeded() {
        if (screenReceiver != null) return

        screenReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action ?: return
                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val now = System.currentTimeMillis()

                when (action) {
                    Intent.ACTION_SCREEN_OFF -> {
                        prefs.edit().putLong(KEY_LAST_SCREEN_OFF_MS, now).apply()
                        Log.d(TAG, "🔒 SCREEN_OFF detectado en $now")
                    }
                    Intent.ACTION_USER_PRESENT,
                    Intent.ACTION_SCREEN_ON -> {
                        val lastOff = prefs.getLong(KEY_LAST_SCREEN_OFF_MS, 0L)
                        if (lastOff > 0L && now > lastOff) {
                            val duration = now - lastOff
                            val pending = prefs.getLong(KEY_PENDING_OFFLINE_MS, 0L)
                            prefs.edit()
                                .putLong(KEY_PENDING_OFFLINE_MS, pending + duration)
                                .putLong(KEY_LAST_SCREEN_OFF_MS, 0L)
                                .apply()
                            Log.d(TAG, "🔓 SCREEN_ON/USER_PRESENT detectado. Offline acumulado +${duration}ms")
                        }
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }

        registerReceiver(screenReceiver, filter)
        Log.d(TAG, "📡 BroadcastReceiver de pantalla registrado")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Time Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoreo de tiempo offline"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): android.app.Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Offline Buddy")
            .setContentText("Monitoreando tiempo offline...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        screenReceiver?.let {
            unregisterReceiver(it)
            Log.d(TAG, "🛑 BroadcastReceiver de pantalla desregistrado")
        }
        screenReceiver = null
        super.onDestroy()
    }
}
