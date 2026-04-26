package com.example.offline

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.offline/screen_time"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getScreenStats" -> {
                    try {
                        val startTime = argumentAsLong(call, "startTime", 0L)
                        val endTime = argumentAsLong(call, "endTime", System.currentTimeMillis())
                        @Suppress("UNCHECKED_CAST")
                        val distractingApps = call.argument<List<String>>("distractingApps") ?: emptyList()
                        
                        val statsJson = getScreenTimeStatsJson(startTime, endTime, distractingApps)
                        result.success(statsJson)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "isScreenOn" -> {
                    try {
                        val isOn = isScreenCurrentlyOn()
                        result.success(isOn)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getInstalledApps" -> {
                    try {
                        val apps = getInstalledApps()
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "hasUsageAccess" -> {
                    try {
                        val hasAccess = hasUsageAccessPermission()
                        result.success(hasAccess)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "startScreenTimeService" -> {
                    try {
                        val serviceIntent = Intent(this, ScreenTimeService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        android.util.Log.d("OfflineApp", "✅ Servicio de monitoreo iniciado")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("OfflineApp", "❌ Error iniciando servicio: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "stopScreenTimeService" -> {
                    try {
                        stopService(Intent(this, ScreenTimeService::class.java))
                        android.util.Log.d("OfflineApp", "🛑 Servicio de monitoreo detenido")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("OfflineApp", "❌ Error deteniendo servicio: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "consumePendingOfflineDurationMs" -> {
                    try {
                        val value = consumePendingOfflineDurationMs()
                        result.success(value)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getPendingOfflineDurationMs" -> {
                    try {
                        val value = getPendingOfflineDurationMs()
                        result.success(value)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "showReminderNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "Rolana"
                        val text = call.argument<String>("text") ?: "Estas pasando mucho tiempo en esta app, recuerda cuidar tu jardin."
                        showReminderNotification(title, text)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showReminderNotification(title: String, text: String) {
        val channelId = "garden_reminders"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val existingChannel = notificationManager.getNotificationChannel(channelId)
            if (existingChannel == null) {
                val channel = NotificationChannel(
                    channelId,
                    "Recordatorios del jardín",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Notificaciones por uso prolongado en apps distractoras"
                }
                notificationManager.createNotificationChannel(channel)
            }
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
    }

    private fun getPendingOfflineDurationMs(): Long {
        val prefs = getSharedPreferences(ScreenTimeService.PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getLong(ScreenTimeService.KEY_PENDING_OFFLINE_MS, 0L)
    }

    private fun consumePendingOfflineDurationMs(): Long {
        val prefs = getSharedPreferences(ScreenTimeService.PREFS_NAME, Context.MODE_PRIVATE)
        val pending = prefs.getLong(ScreenTimeService.KEY_PENDING_OFFLINE_MS, 0L)
        if (pending > 0L) {
            prefs.edit().putLong(ScreenTimeService.KEY_PENDING_OFFLINE_MS, 0L).apply()
        }
        return pending
    }

    private fun argumentAsLong(call: MethodCall, key: String, defaultValue: Long): Long {
        val raw = call.argument<Any>(key) ?: return defaultValue
        return when (raw) {
            is Long -> raw
            is Int -> raw.toLong()
            is Number -> raw.toLong()
            is String -> raw.toLongOrNull() ?: defaultValue
            else -> defaultValue
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun getScreenTimeStatsJson(startTime: Long, endTime: Long, distractingApps: List<String>): String {
        val statsMap = mutableMapOf<String, String>()
        val distractingSet = distractingApps.map { it.trim().lowercase() }.toSet()
        
        try {
            // Verificar permisos
            if (!hasUsageAccessPermission()) {
                android.util.Log.w("OfflineApp", "Sin permisos de usage_stats")
                return "{}"
            }

            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            if (usageStatsManager == null) {
                android.util.Log.e("OfflineApp", "UsageStatsManager no disponible")
                return "{}"
            }

            android.util.Log.d("OfflineApp", "Consultando estadísticas de uso (${distractingApps.size} apps distractoras filtradas)...")
            
            // Obtener estadísticas de uso
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, 
                startTime, 
                endTime
            )

            android.util.Log.d("OfflineApp", "Se encontraron ${stats.size} apps totales en el sistema")
            
            for (stat in stats) {
                val packageName = stat.packageName
                val foregroundTime: Long = stat.totalTimeInForeground
                
                // SOLO incluir si es una app distractora configurada
                val isDistracting = distractingSet.contains(packageName.lowercase())
                
                if (isDistracting && foregroundTime > 0) {
                    statsMap[packageName] = foregroundTime.toString()
                    android.util.Log.d("OfflineApp", "✓ App distractora: $packageName, Tiempo: ${foregroundTime}ms")
                } else if (foregroundTime > 0) {
                    android.util.Log.d("OfflineApp", "✗ App ignorada (no distractora): $packageName")
                }
            }
            
            android.util.Log.d("OfflineApp", "✓ Retornando ${statsMap.size} apps distractoras con uso")
        } catch (e: Exception) {
            android.util.Log.e("OfflineApp", "Error en getScreenTimeStats: ${e.message}")
            e.printStackTrace()
        }

        // Convertir a JSON string
        val jsonBuilder = StringBuilder("{")
        statsMap.forEach { (key, value) ->
            jsonBuilder.append("\"$key\":$value,")
        }
        if (jsonBuilder.length > 1) {
            jsonBuilder.deleteCharAt(jsonBuilder.length - 1)  // Eliminar última coma
        }
        jsonBuilder.append("}")
        
        return jsonBuilder.toString()
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun getScreenTimeStats(startTime: Long, endTime: Long): Map<String, String> {
        val statsMap = mutableMapOf<String, String>()
        
        try {
            // Verificar permisos
            if (!hasUsageAccessPermission()) {
                android.util.Log.w("OfflineApp", "Sin permisos de uso_stats")
                return statsMap
            }

            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            if (usageStatsManager == null) {
                android.util.Log.e("OfflineApp", "UsageStatsManager no disponible")
                return statsMap
            }

            android.util.Log.d("OfflineApp", "Consultando estadísticas de uso...")
            
            // Obtener estadísticas de uso
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, 
                startTime, 
                endTime
            )

            android.util.Log.d("OfflineApp", "Se encontraron ${stats.size} apps con estadísticas")
            
            for (stat in stats) {
                val packageName = stat.packageName
                val foregroundTime: Long = stat.totalTimeInForeground  // Explícitamente Long
                
                if (foregroundTime > 0) {
                    // CONVERTIR A STRING para evitar problemas de serialización
                    statsMap[packageName] = foregroundTime.toString()
                    android.util.Log.d("OfflineApp", "App: $packageName, Tiempo: ${foregroundTime}ms")
                }
            }
            
            android.util.Log.d("OfflineApp", "Retornando ${statsMap.size} apps con uso")
        } catch (e: Exception) {
            android.util.Log.e("OfflineApp", "Error en getScreenTimeStats: ${e.message}")
            e.printStackTrace()
        }

        return statsMap
    }

    private fun isScreenCurrentlyOn(): Boolean {
        return try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
            powerManager?.isInteractive ?: false
        } catch (e: Exception) {
            false
        }
    }

    private fun hasUsageAccessPermission(): Boolean {
        return try {
            val context = applicationContext
            val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as? android.app.AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOpsManager?.unsafeCheckOpNoThrow(
                    "android:get_usage_stats",
                    android.os.Process.myUid(),
                    context.packageName
                ) ?: android.app.AppOpsManager.MODE_ERRORED
            } else {
                @Suppress("DEPRECATION")
                appOpsManager?.checkOpNoThrow(
                    "android:get_usage_stats",
                    android.os.Process.myUid(),
                    context.packageName
                ) ?: android.app.AppOpsManager.MODE_ERRORED
            }
            mode == android.app.AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    /// Obtener lista de apps instaladas
    private fun getInstalledApps(): List<Map<String, String>> {
        val appsList = mutableListOf<Map<String, String>>()
        
        try {
            val intent = Intent(Intent.ACTION_MAIN, null)
            intent.addCategory(Intent.CATEGORY_LAUNCHER)
            
            // Obtener lista de aplicaciones que se pueden lanzar
            val resolveInfos = packageManager.queryIntentActivities(intent, 0)
            
            for (resolveInfo in resolveInfos) {
                try {
                    val packageName = resolveInfo.activityInfo.packageName
                    val appName = resolveInfo.loadLabel(packageManager).toString()
                    
                    if (packageName.isNotEmpty() && appName.isNotEmpty()) {
                        appsList.add(mapOf(
                            "packageName" to packageName,
                            "appName" to appName
                        ))
                    }
                } catch (e: Exception) {
                    // Ignorar apps que causen error
                    continue
                }
            }
            
            // Eliminar duplicados y ordenar alfabéticamente
            val uniqueApps = appsList.distinctBy { it["packageName"] }
                .sortedBy { it["appName"] }
            
            return uniqueApps
        } catch (e: Exception) {
            e.printStackTrace()
            return emptyList()
        }
    }
}
