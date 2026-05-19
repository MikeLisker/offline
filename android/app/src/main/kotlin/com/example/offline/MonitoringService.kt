package com.example.offline

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.util.Log
import android.app.PendingIntent
import android.app.AlarmManager
import android.content.Context
import java.util.*

/**
 * Service que mantiene el monitoreo de tiempo de pantalla activo incluso en background
 */
class MonitoringService : Service() {
    
    companion object {
        private const val TAG = "MonitoringService"
        private const val CHANNEL_ID = "offline_monitoring"
    }

    private val binder = LocalBinder()
    private var alarmManager: AlarmManager? = null
    
    inner class LocalBinder : Binder() {
        fun getService(): MonitoringService = this@MonitoringService
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "✅ MonitoringService creado")
        alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "🔄 MonitoringService.onStartCommand() - action: ${intent?.action}")
        
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
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    /**
     * Ejecutar el monitoreo (debe ser llamado desde MainActivity cada minuto)
     */
    private fun performMonitoring() {
        Log.d(TAG, "⏱️ Ejecutando monitoreo en background...")
        // El monitoreo real se hace desde Flutter a través del MethodChannel
        // Este service solo mantiene viva la app en background
    }

    /**
     * Iniciar monitoreo periódico con AlarmManager
     */
    private fun startBackgroundMonitoring() {
        Log.d(TAG, "🚀 Iniciando monitoreo periódico en background...")
        
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
