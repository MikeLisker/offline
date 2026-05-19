package com.example.offline

import android.content.Context
import android.content.Intent
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
            // Crear view container - fondo semi-transparente
            val container = android.widget.FrameLayout(context).apply {
                setBackgroundColor(0xDD000000.toInt()) // Más opaco para mejor contraste
            }
            
            // Crear un RelativeLayout para centrar mejor el contenido
            val contentLayout = android.widget.RelativeLayout(context).apply {
                layoutParams = android.widget.FrameLayout.LayoutParams(
                    android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                    android.widget.FrameLayout.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(android.graphics.Color.TRANSPARENT)
            }
            
            // Crear view para el contenido principal (card blanca)
            val cardView = android.widget.LinearLayout(context).apply {
                orientation = android.widget.LinearLayout.VERTICAL
                gravity = android.view.Gravity.CENTER_HORIZONTAL
                setPadding(48, 80, 48, 80)
                setBackgroundColor(0xFFFFFFFF.toInt()) // Fondo blanco
                
                layoutParams = android.widget.RelativeLayout.LayoutParams(
                    android.widget.RelativeLayout.LayoutParams.MATCH_PARENT,
                    android.widget.RelativeLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    addRule(android.widget.RelativeLayout.CENTER_IN_PARENT)
                    marginStart = 32
                    marginEnd = 32
                }
            }
            
            // Texto principal
            val textView = android.widget.TextView(context).apply {
                text = "¡Liv te extraña! 🥺"
                textSize = 32f
                setTextColor(0xFF000000.toInt())
                typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
                gravity = android.view.Gravity.CENTER
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { bottomMargin = 24 }
            }
            cardView.addView(textView)
            
            // Subtexto
            val subtextView = android.widget.TextView(context).apply {
                text = "Vuelve al jardín en 10 minutos\no puedo esperar más..."
                textSize = 18f
                setTextColor(0xFF666666.toInt())
                gravity = android.view.Gravity.CENTER
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { bottomMargin = 48 }
            }
            cardView.addView(subtextView)
            
            // Contenedor de botones (horizontal)
            val buttonContainer = android.widget.LinearLayout(context).apply {
                orientation = android.widget.LinearLayout.HORIZONTAL
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { bottomMargin = 0 }
            }
            
            // Botón "Ignorar" (izquierda)
            val ignoreButton = android.widget.Button(context).apply {
                text = "Ignorar"
                textSize = 16f
                setPadding(32, 24, 32, 24)
                setBackgroundColor(0xFFCCCCCC.toInt())
                setTextColor(0xFF333333.toInt())
                
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    0,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f // weight = 1 para ocupar espacio igual
                ).apply { marginEnd = 12 }
                
                setOnClickListener {
                    Log.d(TAG, "✅ User hizo tap en 'Ignorar'")
                    
                    // Solo cerrar el overlay sin traer la app
                    // El overlay reaparecerá en 2 minutos
                    hide()
                    onReturnCallback?.invoke()
                }
            }
            buttonContainer.addView(ignoreButton)
            
            // Botón "Volver a Liv" (derecha)
            val returnButton = android.widget.Button(context).apply {
                text = "Volver a Liv ❤️"
                textSize = 16f
                setPadding(32, 24, 32, 24)
                setBackgroundColor(0xFF4CAF50.toInt())
                setTextColor(0xFFFFFFFF.toInt())
                
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    0,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f // weight = 1 para ocupar espacio igual
                ).apply { marginStart = 12 }
                
                setOnClickListener {
                    Log.d(TAG, "✅ User hizo tap en 'Volver a Liv'")
                    try {
                        playReturnSound()
                        vibrate()
                    } catch (e: Exception) {
                        Log.w(TAG, "⚠️ Error con sonido/vibración: ${e.message}")
                    }
                    
                    // Traer MainActivity al foreground
                    try {
                        val intent = Intent(context, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                        }
                        context.startActivity(intent)
                        Log.d(TAG, "✅ MainActivity traída al foreground")
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error trayendo MainActivity: ${e.message}")
                    }
                    
                    hide()
                    onReturnCallback?.invoke()
                }
            }
            buttonContainer.addView(returnButton)
            
            cardView.addView(buttonContainer)
            
            // Agregar la card al content layout
            contentLayout.addView(cardView)
            
            // Agregar content layout al container
            container.addView(contentLayout)
            
            // Parámetros de window para que aparezca en background
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
                
                // FLAGS: Permitir que sea interactivo y visible
                flags = WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                
                // Importante: NO usar FLAG_NOT_FOCUSABLE y FLAG_NOT_TOUCHABLE
                // Ya que queremos que los botones sean clicables
            }
            
            overlayView = container
            
            // Verificar que el windowManager sea válido
            if (windowManager == null) {
                Log.e(TAG, "❌ WindowManager es null!")
                return
            }
            
            windowManager.addView(container, params)
            isShowing = true
            
            Log.d(TAG, "✅ DistractionOverlay mostrado")
            try {
                playAlertSound()
                vibrate()
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ Error con sonido/vibración al mostrar: ${e.message}")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error mostrando overlay: ${e.message}")
            e.printStackTrace()
            isShowing = false
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
