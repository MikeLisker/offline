package com.example.offline

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * Worker que ejecuta el monitoreo de tiempo de pantalla cada 1 minuto
 * incluso cuando la app está en background
 */
class BackgroundMonitorWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        return try {
            Log.d("BackgroundMonitor", "🔄 Ejecutando monitoreo en background...")
            
            // Llamar al MainActivity para ejecutar el chequeo
            val intent = android.content.Intent(applicationContext, MainActivity::class.java).apply {
                action = "com.example.offline.CHECK_SCREEN_TIME"
                addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            applicationContext.startService(
                android.content.Intent(applicationContext, MonitoringService::class.java).apply {
                    action = "CHECK_SCREEN_TIME"
                }
            )
            
            Log.d("BackgroundMonitor", "✅ Monitoreo ejecutado desde WorkManager")
            Result.success()
        } catch (e: Exception) {
            Log.e("BackgroundMonitor", "❌ Error en WorkManager: ${e.message}")
            Result.retry()
        }
    }
}
