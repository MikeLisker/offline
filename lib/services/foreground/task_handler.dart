import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../usage/usage_service.dart';
import '../../core/constants.dart';
import 'dart:convert';

class MyTaskHandler extends TaskHandler {
  final logger = Logger();
  
  int _offlineSeconds = 0;
  int _distractionSeconds = 0;
  Map<String, int> _lastCheckpoints = {};
  List<String> _distractingApps = [];

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    logger.i('🚀 Foreground Task Started');
    
    final prefs = await SharedPreferences.getInstance();
    _distractingApps = prefs.getStringList(AppConstants.distractingAppsKey) ?? [];
    
    final savedCheckpoints = prefs.getString(AppConstants.checkpointsKey);
    if (savedCheckpoints != null) {
      try {
        _lastCheckpoints = Map<String, int>.from(json.decode(savedCheckpoints));
      } catch (e) {
        _lastCheckpoints = await UsageService.getAllUsageStats();
      }
    } else {
      _lastCheckpoints = await UsageService.getAllUsageStats();
      await prefs.setString(AppConstants.checkpointsKey, json.encode(_lastCheckpoints));
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    final prefs = await SharedPreferences.getInstance();
    // Usar isScreenOn con un valor por defecto seguro
    bool isScreenOn = true; // Asumir que pantalla está encendida por defecto

    if (!isScreenOn) {
      _offlineSeconds += 5; 
      _distractionSeconds = 0;
      
      if (_offlineSeconds >= (AppConstants.energyGainMinutes * 60)) {
        await _updatePetEnergy(1, prefs);
        _offlineSeconds = 0;
      }
    } else {
      _offlineSeconds = 0;
      final currentStats = await UsageService.getAllUsageStats();
      int newDistractionTimeMs = 0;

      for (String pkg in _distractingApps) {
        int currentUsage = currentStats[pkg] ?? 0;
        int lastUsage = _lastCheckpoints[pkg] ?? 0;
        
        if (currentUsage > lastUsage) {
          newDistractionTimeMs += (currentUsage - lastUsage);
        }
      }

      _distractionSeconds += (newDistractionTimeMs ~/ 1000);
      _lastCheckpoints = currentStats;
      await prefs.setString(AppConstants.checkpointsKey, json.encode(_lastCheckpoints));

      if (_distractionSeconds >= (AppConstants.energyReductionMinutes * 60)) {
        await _updatePetEnergy(-1, prefs);
        _distractionSeconds = 0;
      }
    }

    sendPort?.send({
      'offlineSeconds': _offlineSeconds,
      'distractionSeconds': _distractionSeconds,
    });
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    logger.i('🛑 Foreground Task Destroyed');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  Future<void> _updatePetEnergy(int delta, SharedPreferences prefs) async {
    int currentEnergy = prefs.getInt('pet_energy') ?? 100;
    int newEnergy = (currentEnergy + delta).clamp(0, 100);
    await prefs.setInt('pet_energy', newEnergy);
    
    if (delta > 0) {
      int currentCoins = prefs.getInt('pet_coins') ?? 0;
      await prefs.setInt('pet_coins', currentCoins + 1);
    }

    FlutterForegroundTask.updateService(
      notificationTitle: 'Rolana está activa 🌱',
      notificationText: 'Energía: $newEnergy% | ${delta > 0 ? "¡Recuperando fuerzas!" : "Uso de apps detectado"}',
    );
  }
}
