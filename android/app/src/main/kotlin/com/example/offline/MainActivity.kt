package com.example.offline

import android.app.ActivityManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.offline/screen_time"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getScreenStats" -> {
                    try {
                        val startTime = call.argument<Long>("startTime") ?: 0L
                        val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                        
                        val stats = getScreenTimeStats(startTime, endTime)
                        result.success(stats)
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
                else -> result.notImplemented()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun getScreenTimeStats(startTime: Long, endTime: Long): Map<String, Int> {
        val statsMap = mutableMapOf<String, Int>()
        
        try {
            // Verificar permisos
            if (!hasUsageAccessPermission()) {
                return statsMap
            }

            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            if (usageStatsManager == null) {
                return statsMap
            }

            // Obtener estadísticas de uso
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, 
                startTime, 
                endTime
            )

            for (stat in stats) {
                val packageName = stat.packageName
                val foregroundTime = stat.totalTimeInForeground.toInt()
                
                if (foregroundTime > 0) {
                    statsMap[packageName] = foregroundTime
                }
            }
        } catch (e: Exception) {
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
}
