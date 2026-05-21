package com.example.offline

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.app.usage.UsageStatsManager
import android.content.SharedPreferences
import android.app.usage.UsageStats
import android.os.Build
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
        Log.d(TAG, "📡 Monitoreo en background recibido (PASIVO - Flutter cuenta el tiempo)")
        
        try {
            // ✅ CAMBIO: Este BroadcastReceiver ahora es PASIVO
            // Flutter ScreenTimeMonitor es el ÚNICO que cuenta el tiempo
            // Este servicio solo existe para mantener la app "viva" en background
            // pero NO acumula tiempo
            
            Log.d(TAG, "✅ BroadcastReceiver ejecutado (sin acumulación - Flutter maneja conteo)")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error: ${e.message}")
        }
    }

    // 🔴 DESACTIVADA: La lógica de performBackgroundCheck ya no se ejecuta
    // Flutter ScreenTimeMonitor en Dart es el ÚNICO sistema que cuenta tiempo
    @Deprecated(
        "Android ya no acumula tiempo. Flutter ScreenTimeMonitor es el único contador.",
        replaceWith = ReplaceWith("Flutter ScreenTimeMonitor"),
        level = DeprecationLevel.WARNING
    )
    private fun performBackgroundCheck(context: Context) {
        // Esta función ya no se utiliza
        // Ver: lib/services/screen_time_monitor.dart
    }
}
