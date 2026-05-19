package com.example.offline

import android.app.Service
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.*

/**
 * Foreground Service que mantiene el monitoreo de tiempo de pantalla activo en background
 */
class MonitoringService : Service() {
    
    companion object {
        private const val TAG = "MonitoringService"
        private const val CHANNEL_ID = "offline_monitoring_channel"
        private const val NOTIFICATION_ID = 1000
    }

    private val binder = LocalBinder()
    private var alarmManager: AlarmManager? = null
    
    inner class LocalBinder : Binder() {
        fun getService(): MonitoringService = this@MonitoringService
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "✅ MonitoringService creado")
        createNotificationChannel()
        alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            Log.d(TAG, "🔄 MonitoringService.onStartCommand() - action: ${intent?.action}")
            
            // Iniciar como foreground inmediatamente
            startForegroundNotification()
            
            when (intent?.action) {
                "CHECK_SCREEN_TIME" -> {
                    performMonitoring()
                }
                "START_MONITORING" -> {
                    startBackgroundMonitoring()
                }
                "STOP_MONITORING" -> {
                    stopBackgroundMonitoring()
                }
            }
            
            // Retornar STICKY para que se reinicie automáticamente si se mata
            return START_STICKY
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error en onStartCommand: ${e.message}")
            return START_NOT_STICKY
        }
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Monitoreo de Tiempo",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoreo de distracción en background"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startForegroundNotification() {
        try {
            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Liv te monitorea 👀")
                .setContentText("Midiendo tu tiempo en apps...")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .build()
            
            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "✅ Foreground service iniciado")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error iniciando foreground: ${e.message}")
        }
    }

    /**
     * Ejecutar el monitoreo
     */
    private fun performMonitoring() {
        Log.d(TAG, "⏱️ Ejecutando monitoreo en background...")
    }

    /**
     * Iniciar monitoreo periódico con AlarmManager
     */
    private fun startBackgroundMonitoring() {
        Log.d(TAG, "🚀 Iniciando monitoreo periódico cada minuto...")
        
        if (alarmManager == null) return
        
        val intent = Intent(this, MonitoringBroadcastReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        try {
            // Ejecutar cada 1 minuto (60000 ms)
            alarmManager?.setInexactRepeating(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                60000,
                60000,
                pendingIntent
            )
            Log.d(TAG, "✅ AlarmManager configurado para ejecutarse cada 60s")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error configurando AlarmManager: ${e.message}")
        }
    }

    /**
     * Detener monitoreo periódico
     */
    private fun stopBackgroundMonitoring() {
        Log.d(TAG, "🛑 Deteniendo monitoreo periódico...")
        
        if (alarmManager == null) return
        
        val intent = Intent(this, MonitoringBroadcastReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        try {
            alarmManager?.cancel(pendingIntent)
            Log.d(TAG, "✅ AlarmManager cancelado")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error cancelando AlarmManager: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "🛑 MonitoringService destruido")
        stopBackgroundMonitoring()
    }
}
