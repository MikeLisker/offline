import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/app_usage.dart';

class ScreenTimeMonitor {
  static final logger = Logger();
  static const Duration CHECK_INTERVAL = Duration(minutes: 1);  // Cada minuto (era 5)
  static const platform = MethodChannel('com.example.offline/screen_time');

  DateTime? _lastCheckTime;
  DateTime? _screenOffStartTime;
  bool _wasScreenOff = false;
  Timer? _monitorTimer;
  final List<Function(Duration offlineTime)> _onOfflineDetected = [];
  final List<Function(String packageName, Duration screenTime)> _onDistractionDetected = [];
  
  // Checkpoints: guardan el último totalTimeInForeground conocido de cada app
  final Map<String, int> _screenTimeCheckpoints = {};
  
  // Lista dinámica de apps distractoras (actualizable)
  List<String> _distractingApps = [];

  /// Iniciar monitoreo en background
  void startMonitoring() {
    logger.i('🚀 Iniciando monitoreo de tiempo de pantalla');
    logger.i('📱 Apps distractoras configuradas: $_distractingApps');
    _lastCheckTime = DateTime.now();
    _screenOffStartTime = null;
    _wasScreenOff = false;

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

  /// Reinicia baseline de apps distractoras al uso actual total para evitar
  /// contar tiempo histórico previo a la selección del usuario.
  Future<void> resetDistractingAppsBaselines() async {
    if (_distractingApps.isEmpty) return;

    try {
      final now = DateTime.now();
      final statsJson = await platform.invokeMethod<String>('getScreenStats', {
        'startTime': 0,
        'endTime': now.millisecondsSinceEpoch,
        'distractingApps': _distractingApps,
      });

      if (statsJson == null || statsJson.isEmpty || statsJson == '{}') {
        for (final pkg in _distractingApps) {
          _screenTimeCheckpoints[pkg] = 0;
        }
        logger.i('🧭 Baseline distractoras reiniciado en 0 (sin stats nativas)');
        return;
      }

      final Map<String, dynamic> statsMap = jsonDecode(statsJson);
      for (final pkg in _distractingApps) {
        final raw = statsMap[pkg];
        _screenTimeCheckpoints[pkg] = _parseTimeToInt(raw);
      }

      logger.i('🧭 Baseline distractoras actualizado para ${_distractingApps.length} apps');
    } catch (e) {
      logger.e('❌ Error reiniciando baseline de distractoras: $e');
    }
  }

  /// Detener monitoreo
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _screenOffStartTime = null;
    _wasScreenOff = false;
    logger.i('🛑 Monitoreo detenido');
  }

  /// Verificar si una app es distractora
  bool isAppDistracting(String packageName) {
    return _distractingApps.contains(packageName);
  }
  
  /// Actualizar lista de apps distractoras dinámicamente
  void setDistractionApps(List<String> apps) {
    _distractingApps = List.from(apps);
    logger.i('🎯 Apps distractoras actualizadas: ${_distractingApps.length} apps');
  }
  
  /// Obtener lista de apps distractoras actual
  List<String> getDistractionApps() => List.from(_distractingApps);

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

      // Primero, consumir offline acumulado en nativo (exacto para dispositivos físicos).
      try {
        final pendingOfflineMs =
            await platform.invokeMethod<int>('consumePendingOfflineDurationMs') ?? 0;
        if (pendingOfflineMs > 0) {
          final offlineDuration = Duration(milliseconds: pendingOfflineMs);
          logger.w('✅ OFFLINE NATIVO CONSUMIDO: ${offlineDuration.inMinutes}m ${offlineDuration.inSeconds % 60}s');
          _onOfflineDetected.forEach((cb) {
            logger.i('↪️ Ejecutando callback offline (nativo)');
            cb(offlineDuration);
          });

          // Evitar doble conteo si también veníamos con estado local de pantalla apagada.
          _wasScreenOff = false;
          _screenOffStartTime = null;
          _lastCheckTime = now;
        }

        // Además, verificar estado de pantalla para logs/fallback.
        final isScreenOn = await platform.invokeMethod<bool>('isScreenOn') ?? false;
        logger.d('📱 Estado pantalla: ${isScreenOn ? "ENCENDIDA" : "APAGADA"}, tiempo desde último check: ${timeSinceLastCheck.inMinutes}m ${timeSinceLastCheck.inSeconds % 60}s');
        
        if (!isScreenOn) {
          // Inicia una sesión offline al detectar la pantalla apagada por primera vez.
          if (!_wasScreenOff) {
            _wasScreenOff = true;
            _screenOffStartTime = _lastCheckTime ?? now;
            logger.i('🕐 Iniciando sesión offline desde ${_screenOffStartTime!.toIso8601String()}');
          }

          final offlineDuration = now.difference(_screenOffStartTime!);
          logger.i('🔒 PANTALLA BLOQUEADA: ${offlineDuration.inMinutes}m de tiempo sin usar');

          if (offlineDuration.inMinutes >= 4) {
            logger.d('⏳ Offline acumulado >= 4m. Se aplicará energía al desbloquear para contar toda la sesión.');
          } else {
            logger.d('⏳ Pantalla bloqueada pero menos de 4 minutos (${offlineDuration.inMinutes}m). Acumulando...');
          }
          return;
        } else {
          // Pantalla encendida: cerrar sesión offline y aplicar energía una sola vez.
          if (_wasScreenOff && _screenOffStartTime != null) {
            final totalOfflineDuration = now.difference(_screenOffStartTime!);
            if (totalOfflineDuration.inMinutes >= 4) {
              logger.w('✅ OFFLINE COMPLETADO (pantalla se encendió) - Disparando callback con ${totalOfflineDuration.inMinutes}m');
              _onOfflineDetected.forEach((cb) {
                logger.i('↪️ Ejecutando callback offline (sesión completa al desbloquear)');
                cb(totalOfflineDuration);
              });
            } else {
              logger.d('ℹ️ Pantalla se encendió, pero el tiempo offline fue < 4m (${totalOfflineDuration.inMinutes}m).');
            }
          }

          _wasScreenOff = false;
          _screenOffStartTime = null;
          _lastCheckTime = now;
        }
      } on PlatformException catch (e) {
        logger.e('⚠️ Error verificando pantalla: ${e.message}');
      }

      // Si pantalla está encendida, obtener estadísticas de apps
      try {
        // Verificar que hay apps distractoras configuradas
        if (_distractingApps.isEmpty) {
          logger.d('ℹ️ Sin apps distractoras configuradas. Saltando monitoreo.');
          _lastCheckTime = now;
          return;
        }

        logger.d('📲 Llamando a getScreenStats...');
        final statsJson = await platform.invokeMethod<String>('getScreenStats', {
          'startTime': 0, // Obtener TODO el historial disponible
          'endTime': now.millisecondsSinceEpoch,
          'distractingApps': _distractingApps,
        });

        if (statsJson == null || statsJson.isEmpty || statsJson == '{}') {
          logger.d('📊 No hay estadísticas disponibles en este período');
          _lastCheckTime = now;
          return;
        }

        // Parsear JSON
        final Map<String, dynamic> statsMap = jsonDecode(statsJson);

        bool anyDistractionDetected = false;
        
        logger.i('📊 Estadísticas recibidas: ${statsMap.length} apps');
        logger.i('🎯 Apps distractoras a detectar: $_distractingApps');
        
        // Procesar datos: solo contar el incremento desde el último checkpoint
        for (var entry in statsMap.entries) {
          final packageName = entry.key;
          
          // Convertir el valor a num (viene como String desde Kotlin)
          num currentTotalUsage = 0;
          try {
            final value = entry.value;
            if (value == null) {
              continue;
            } else if (value is int) {
              currentTotalUsage = value;
            } else if (value is double) {
              currentTotalUsage = value.toInt();
            } else if (value is String) {
              currentTotalUsage = int.tryParse(value) ?? 0;
            } else if (value is num) {
              currentTotalUsage = value;
            }
          } catch (e) {
            logger.e('❌ Error convirtiendo valor para $packageName: ${entry.value} (${entry.value.runtimeType}), error: $e');
            continue;
          }

          // Solo procesar si es app distractora
          if (!isAppDistracting(packageName)) {
            continue;
          }

          logger.d('🔍 Chequeando app distractora: $packageName, uso total: ${currentTotalUsage}ms');

          // Obtener el checkpoint anterior (0 si es la primera vez)
          final lastKnownUsage = _screenTimeCheckpoints[packageName] ?? 0;
          
          // Calcular el NUEVO tiempo usado desde el último checkpoint
          final newUsage = (currentTotalUsage - lastKnownUsage).toInt();

          if (newUsage > 0) {
            final newUsageDuration = Duration(milliseconds: newUsage);

            if (newUsageDuration.inSeconds > 0) {
              logger.w('📱 ¡DISTRACCIÓN DETECTADA! $packageName: ${newUsageDuration.inMinutes}m nuevos (checkpoint: ${lastKnownUsage}ms → actual: ${currentTotalUsage}ms)');
              _onDistractionDetected.forEach((cb) => cb(packageName, newUsageDuration));
              anyDistractionDetected = true;
            }

            // Actualizar checkpoint al valor actual total
            _screenTimeCheckpoints[packageName] = currentTotalUsage.toInt();
          }
        }

        if (!anyDistractionDetected) {
          logger.d('✔️ Sin distracción detectada en este período');
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
      final statsJson = await platform.invokeMethod<String>('getScreenStats', {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'distractingApps': _distractingApps,
      });

      if (statsJson == null || statsJson.isEmpty || statsJson == '{}') {
        return [];
      }

      final Map<String, dynamic> stats = jsonDecode(statsJson);

      return stats.entries
          .map((entry) => AppUsageData(
                packageName: entry.key,
                appName: entry.key,
                usageTime: Duration(
                  milliseconds: entry.value is num
                      ? (entry.value as num).toInt()
                      : int.tryParse(entry.value.toString()) ?? 0,
                ),
                lastTimeUsed: DateTime.now(),
                isDistracting: isAppDistracting(entry.key),
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
