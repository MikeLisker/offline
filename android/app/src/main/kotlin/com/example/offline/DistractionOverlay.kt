package com.example.offline

import android.content.Context
import android.os.Build
import android.util.Log
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import android.widget.Button
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Vibrator
import androidx.core.content.ContextCompat

class DistractionOverlay(private val context: Context) {
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    private var overlayView: View? = null
    private var mediaPlayer: MediaPlayer? = null
    private var isShowing = false
    private var onReturnCallback: (() -> Unit)? = null

    companion object {
        private const val TAG = "DistractionOverlay"
    }

    fun show(onReturn: (() -> Unit)? = null) {
        if (isShowing) {
            Log.d(TAG, "Overlay ya está visible, ignorando show()")
            return
        }

        onReturnCallback = onReturn
        
        try {
            // Crear view container
            val container = FrameLayout(context)
            container.setBackgroundColor(0xCC000000.toInt()) // Overlay oscuro translúcido
            
            // Texto principal
            val textView = TextView(context)
            textView.text = "¡Liv te extraña! 🥺"
            textView.textSize = 28f
            textView.setTextColor(0xFFFFFFFF.toInt())
            textView.setPadding(32, 32, 32, 32)
            textView.setTypeface(null, android.graphics.Typeface.BOLD)
            
            // Subtexto
            val subtextView = TextView(context)
            subtextView.text = "Vuelve al jardín en 10 minutos\no puedo esperar más..."
            subtextView.textSize = 16f
            subtextView.setTextColor(0xFFCCCCCC.toInt())
            subtextView.setPadding(32, 0, 32, 32)
            
            // Botón "Volver"
            val button = Button(context)
            button.text = "Volver a Liv ❤️"
            button.textSize = 18f
            button.setPadding(32, 24, 32, 24)
            button.setBackgroundColor(0xFF4CAF50.toInt()) // Verde
            button.setTextColor(0xFFFFFFFF.toInt())
            
            button.setOnClickListener {
                Log.d(TAG, "User hizo tap en 'Volver'")
                playReturnSound()
                vibrate()
                hide()
                onReturnCallback?.invoke()
            }
            
            // Layout vertical
            val layout = android.widget.LinearLayout(context)
            layout.orientation = android.widget.LinearLayout.VERTICAL
            layout.gravity = android.view.Gravity.CENTER
            layout.setPadding(32, 100, 32, 100)
            
            layout.addView(textView, android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ))
            layout.addView(subtextView, android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ))
            layout.addView(button, android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = 32 })
            
            container.addView(layout, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))
            
            // Parámetros de window
            val params = WindowManager.LayoutParams().apply {
                type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }
                
                format = android.graphics.PixelFormat.RGBA_8888
                width = WindowManager.LayoutParams.MATCH_PARENT
                height = WindowManager.LayoutParams.MATCH_PARENT
                
                flags = WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            }
            
            // Hacer touchable cuando necesitamos interacción
            params.flags = WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                          WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
            
            overlayView = container
            windowManager.addView(container, params)
            isShowing = true
            
            Log.d(TAG, "✅ DistractionOverlay mostrado")
            playAlertSound()
            vibrate()
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error mostrando overlay: ${e.message}")
        }
    }

    fun hide() {
        if (isShowing && overlayView != null) {
            try {
                windowManager.removeView(overlayView)
                overlayView = null
                isShowing = false
                stopSounds()
                Log.d(TAG, "🛑 DistractionOverlay oculto")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error ocultando overlay: ${e.message}")
            }
        }
    }

    private fun playAlertSound() {
        try {
            mediaPlayer = MediaPlayer.create(context, android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION))
            mediaPlayer?.start()
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Error reproduciendo sonido: ${e.message}")
        }
    }

    private fun playReturnSound() {
        try {
            mediaPlayer = MediaPlayer.create(context, android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION))
            mediaPlayer?.start()
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Error reproduciendo sonido de retorno: ${e.message}")
        }
    }

    private fun vibrate() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(android.os.VibrationEffect.createWaveform(
                    longArrayOf(0, 100, 50, 100),
                    -1
                ))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longArrayOf(0, 100, 50, 100), -1)
            }
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Error en vibración: ${e.message}")
        }
    }

    private fun stopSounds() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }

    fun isVisible(): Boolean = isShowing
}
