package com.example.offline

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat

/**
 * Servicio en foreground que gestiona mostrar/ocultar el overlay de distracción
 * incluso cuando la app principal no está en primer plano
 */
class OverlayService : Service() {
    
    companion object {
        private const val TAG = "OverlayService"
        private const val CHANNEL_ID = "overlay_channel"
        private const val NOTIFICATION_ID = 1001
    }

    private val binder = LocalBinder()
    private var distractionOverlay: DistractionOverlay? = null
    private var isInForeground = false

    inner class LocalBinder : Binder() {
        fun getService(): OverlayService = this@OverlayService
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "✅ OverlayService creado")
        createNotificationChannel()
        // No iniciar foreground aquí - esperar a onStartCommand()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "🔄 OverlayService.onStartCommand() - action: ${intent?.action}")
        
        try {
            // Verificar permisos de overlay
            if (!hasOverlayPermission()) {
                Log.e(TAG, "❌ Sin permisos de SYSTEM_ALERT_WINDOW")
                stopSelf()
                return START_NOT_STICKY
            }
            
            // Si no estamos en foreground, iniciar ahora
            if (!isInForeground) {
                startForegroundNotification()
                isInForeground = true
            }
            
            when (intent?.action) {
                "SHOW_OVERLAY" -> {
                    // Ejecutar en el main thread usando Handler con Looper.getMainLooper()
                    Handler(Looper.getMainLooper()).post {
                        try {
                            showOverlay()
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ Error mostrando overlay: ${e.message}")
                            e.printStackTrace()
                        }
                    }
                }
                "HIDE_OVERLAY" -> {
                    Handler(Looper.getMainLooper()).post {
                        hideOverlay()
                    }
                }
            }
            
            return START_STICKY
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error en onStartCommand: ${e.message}")
            e.printStackTrace()
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
                "Overlay Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startForegroundNotification() {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Liv te monitorea")
            .setContentText("Monitoreando tiempo en apps...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        
        startForeground(NOTIFICATION_ID, notification)
        Log.d(TAG, "✅ Foreground service iniciado con notificación")
    }

    /**
     * Verificar si tenemos permisos de SYSTEM_ALERT_WINDOW
     */
    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true // En Android < 6.0 no es necesario en tiempo de ejecución
        }
    }

    /**
     * Mostrar el overlay de distracción
     */
    private fun showOverlay() {
        Log.d(TAG, "📺 Intentando mostrar overlay...")
        
        try {
            if (distractionOverlay == null) {
                distractionOverlay = DistractionOverlay(this)
            }
            
            distractionOverlay?.show {
                Log.d(TAG, "✅ Usuario hizo clic en 'Volver a Liv'")
                hideOverlay()
            }
            
            Log.d(TAG, "✅ Overlay mostrado exitosamente")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error mostrando overlay: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * Ocultar el overlay
     */
    private fun hideOverlay() {
        Log.d(TAG, "🛑 Ocultando overlay...")
        
        try {
            distractionOverlay?.hide()
            Log.d(TAG, "✅ Overlay ocultado")
            // NO detener el servicio - debe permanecer en foreground
            // para poder mostrar overlays nuevamente cuando sea necesario
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error ocultando overlay: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "🛑 OverlayService destruido")
        distractionOverlay?.hide()
        distractionOverlay = null
    }
}
