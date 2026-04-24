import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/app_usage.dart';

class ScreenTimeMonitor {
  static final logger = Logger();
  static const Duration CHECK_INTERVAL = Duration(minutes: 5);
  static const platform = MethodChannel('com.example.offline/screen_time');

  DateTime? _lastCheckTime;
  Timer? _monitorTimer;
  final List<Function(Duration offlineTime)> _onOfflineDetected = [];
  final List<Function(String packageName, Duration screenTime)> _onDistractionDetected = [];
  
  // Checkpoints: guardan el último totalTimeInForeground conocido de cada app
  final Map<String, int> _screenTimeCheckpoints = {};

  /// Iniciar monitoreo en background
  void startMonitoring() {
    logger.i('🚀 Iniciando monitoreo de tiempo de pantalla');
    _lastCheckTime = DateTime.now();

    _monitorTimer = Timer.periodic(CHECK_INTERVAL, (_) {
      _checkScreenTime();
    });
    
    // Hacer una verificación inmediata después de 1 segundo
    Future.delayed(Duration(seconds: 1), _checkScreenTime);
  }

  /// Cargar checkpoints desde storage
  void loadCheckpoints(Map<String, int> checkpoints) {
    _screenTimeCheckpoints.clear();
    _screenTimeCheckpoints.addAll(checkpoints);
    logger.i('📥 Checkpoints cargados: ${checkpoints.length} apps');
  }

  /// Obtener checkpoints actuales (para guardar)
  Map<String, int> getCheckpoints() => Map.from(_screenTimeCheckpoints);

  /// Detener monitoreo
  void stopMonitoring() {
    _monitorTimer?.cancel();
    logger.i('🛑 Monitoreo detenido');
  }

  /// Verificar si una app es distractora
  bool isAppDistracting(String packageName) {
    final distractingPackages = {
      'com.google.android.youtube',
      'com.instagram.android',
      'com.zhiliaoapp.musically',
      'com.facebook.katana',
      'com.twitter.android',
      'com.reddit.frontpage',
      'com.snapchat.android',
      'com.whatsapp',
      'com.telegram',
      'com.viber.voip',
    };
    return distractingPackages.contains(packageName);
  }

  /// Registrar callback cuando detecta tiempo offline
  void onOfflineDetected(Function(Duration) callback) {
    _onOfflineDetected.add(callback);
  }

  /// Registrar callback cuando detecta uso de apps distractoras
  void onDistractionDetected(
      Function(String packageName, Duration screenTime) callback) {
    _onDistractionDetected.add(callback);
  }

  /// Verificar tiempo de pantalla actual vía native channel
  Future<void> _checkScreenTime() async {
    try {
      if (_lastCheckTime == null) return;

      final now = DateTime.now();
      final timeSinceLastCheck = now.difference(_lastCheckTime!);

      // Primero, verificar si pantalla está apagada (offline)
      try {
        final isScreenOn = await platform.invokeMethod<bool>('isScreenOn') ?? false;
        
        if (!isScreenOn) {
          // Pantalla bloqueada = tiempo offline
          // Por cada 4 minutos bloqueado, mascota recupera 2 puntos de energía
          final offlineMinutes = timeSinceLastCheck.inMinutes;
          if (offlineMinutes >= 4) {
            logger.i('✅ Usuario OFFLINE: ${offlineMinutes}m pantalla bloqueada');
            _onOfflineDetected.forEach((cb) => cb(timeSinceLastCheck));
          }
          _lastCheckTime = now;
          return;
        }
      } on PlatformException catch (e) {
        logger.e('⚠️ Error verificando pantalla: ${e.message}');
      }

      // Si pantalla está encendida, obtener estadísticas de apps
      try {
        final stats = await platform.invokeMethod<Map>('getScreenStats', {
          'startTime': 0, // Obtener TODO el historial disponible
          'endTime': now.millisecondsSinceEpoch,
        });

        if (stats == null || stats.isEmpty) {
          logger.w('⚠️ No se obtuvieron estadísticas de pantalla');
          _lastCheckTime = now;
          return;
        }

        bool anyDistractionDetected = false;
        
        // Procesar datos: solo contar el incremento desde el último checkpoint
        for (var entry in stats.entries) {
          final packageName = entry.key as String;
          final currentTotalUsage = entry.value as int? ?? 0;

          // Obtener el checkpoint anterior (0 si es la primera vez)
          final lastKnownUsage = _screenTimeCheckpoints[packageName] ?? 0;
          
          // Calcular el NUEVO tiempo usado desde el último checkpoint
          final newUsage = currentTotalUsage - lastKnownUsage;

          if (newUsage > 0) {
            final newUsageDuration = Duration(milliseconds: newUsage);

            // Solo procesar si es app distractora
            if (isAppDistracting(packageName) && newUsageDuration.inSeconds > 0) {
              logger.w('📱 App distractora: $packageName - ${newUsageDuration.inMinutes}m nuevos');
              _onDistractionDetected.forEach((cb) => cb(packageName, newUsageDuration));
              anyDistractionDetected = true;
            }

            // Actualizar checkpoint al valor actual total
            _screenTimeCheckpoints[packageName] = currentTotalUsage;
          }
        }

        if (!anyDistractionDetected) {
          logger.i('📊 Sin uso de apps distractoras en este período');
        }
      } on PlatformException catch (e) {
        logger.e('❌ Error llamando método nativo: ${e.message}');
      }

      _lastCheckTime = now;
    } catch (e) {
      logger.e('❌ Error monitoreando pantalla: $e');
    }
  }

  /// Obtener estadísticas manualmente
  Future<List<AppUsageData>> getAppUsageStats({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final stats = await platform.invokeMethod<Map>('getScreenStats', {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
      });

      if (stats == null) return [];

      return stats.entries
          .map((entry) => AppUsageData(
                packageName: entry.key as String,
                appName: entry.key as String,
                usageTime: Duration(milliseconds: entry.value as int? ?? 0),
                lastTimeUsed: DateTime.now(),
                isDistracting: isAppDistracting(entry.key as String),
              ))
          .toList();
    } catch (e) {
      logger.e('❌ Error obteniendo estadísticas: $e');
      return [];
    }
  }

  /// Verificar si la pantalla está encendida
  Future<bool> isScreenOn() async {
    try {
      final isOn = await platform.invokeMethod<bool>('isScreenOn');
      return isOn ?? false;
    } catch (e) {
      logger.e('Error verificando pantalla: $e');
      return false;
    }
  }

  /// Convertir tiempo a int
  int _parseTimeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
}
