import 'package:flutter/services.dart';

// Bridge al servicio nativo Android para mejorar estabilidad en dispositivos reales.

class ServiceManager {
  static const MethodChannel _platform = MethodChannel('com.example.offline/screen_time');

  static Future<bool> startService() async {
    try {
      final result = await _platform.invokeMethod<bool>('startScreenTimeService');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopService() async {
    try {
      final result = await _platform.invokeMethod<bool>('stopScreenTimeService');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
