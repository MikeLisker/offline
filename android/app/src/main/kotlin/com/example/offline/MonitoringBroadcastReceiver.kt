package com.example.offline

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.app.usage.UsageStatsManager
import android.content.SharedPreferences
import android.app.usage.UsageStats
import java.util.*

/**
 * BroadcastReceiver que ejecuta el monitoreo cada minuto EN BACKGROUND
 * SIN traer la app a foreground
 */
class MonitoringBroadcastReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "MonitoringReceiver"
        private const val PREFS_NAME = "offline_monitoring"
        private const val KEY_SESSION_DISTRACTION_MS = "session_distraction_ms"
        private const val KEY_LAST_UPDATE = "last_update"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "📡 Monitoreo en background ejecutado...")
        
        try {
            // Hacer chequeo de distracción completamente en nativo
            performBackgroundCheck(context)
            Log.d(TAG, "✅ Chequeo completado sin molestar al usuario")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error en monitoreo background: ${e.message}")
        }
    }

    private fun performBackgroundCheck(context: Context) {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        // Apps distractoras: YouTube y DeskClock
        val distractingApps = listOf(
            "com.google.android.youtube",
            "com.google.android.deskclock"
        )
        
        val now = Calendar.getInstance()
        val queryUsageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST,
            0, // Desde el principio
            now.timeInMillis
        )
        
        // Acumular incremento de esta sesión
        var newDistractionMs = 0L
        
        for (stat in queryUsageStats) {
            if (stat.packageName in distractingApps) {
                val currentTotal = stat.totalTimeInForeground
                val lastCheckpoint = prefs.getLong("checkpoint_${stat.packageName}", 0L)
                
                Log.d(TAG, "  📊 ${stat.packageName}: total=${currentTotal}ms, checkpoint=${lastCheckpoint}ms")
                
                // Calcular incremento
                if (currentTotal > lastCheckpoint) {
                    val increment = currentTotal - lastCheckpoint
                    newDistractionMs += increment
                    Log.d(TAG, "    ➕ Nuevo uso: ${increment}ms")
                } else if (currentTotal > 0 && lastCheckpoint > 0) {
                    // App sigue abierta pero sin incremento: +60s por check
                    newDistractionMs += 60000
                    Log.d(TAG, "    ⏱️ App abierta sin incremento: +60s")
                } else if (currentTotal > 0 && lastCheckpoint == 0L) {
                    // Primera detección: +60s inicial
                    newDistractionMs += 60000
                    Log.d(TAG, "    🎯 Primera detección: +60s inicial")
                }
                
                // Actualizar checkpoint
                prefs.edit().putLong("checkpoint_${stat.packageName}", currentTotal).apply()
            }
        }
        
        // Acumular en sesión total
        val currentSession = prefs.getLong(KEY_SESSION_DISTRACTION_MS, 0)
        val newSession = currentSession + newDistractionMs
        prefs.edit().putLong(KEY_SESSION_DISTRACTION_MS, newSession).apply()
        prefs.edit().putLong(KEY_LAST_UPDATE, System.currentTimeMillis()).apply()
        
        Log.d(TAG, "💾 Sesión: ${currentSession/1000}s + ${newDistractionMs/1000}s = ${newSession/1000}s (${newSession/60000}m)")
        
        // Si pasó 5 minutos (300s = 300000ms), marcar para mostrar overlay
        if (newSession >= 300000) {
            Log.w(TAG, "🚨 ¡5 MINUTOS DE DISTRACCIÓN DETECTADOS!")
            prefs.edit().putBoolean("should_show_overlay", true).apply()
            // Resetear la sesión después de mostrar overlay
            prefs.edit().putLong(KEY_SESSION_DISTRACTION_MS, 0).apply()
        }
    }
}
