import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
// import 'package:usage_stats/usage_stats.dart';  // Temporarily disabled
import 'dart:io';

final logger = Logger();

class PermissionsService {
  static final PermissionsService _instance = PermissionsService._internal();
  static const platform = MethodChannel('com.example.offline/screen_time');

  factory PermissionsService() {
    return _instance;
  }

  PermissionsService._internal();

  /// Request all necessary permissions for the app
  Future<bool> requestAllPermissions() async {
    try {
      logger.i('🔐 Iniciando solicitud de permisos...');

      final permissions = <Permission>[
        if (Platform.isAndroid) ...[
          Permission.notification,
          Permission.scheduleExactAlarm,
        ]
      ];

      // Request all permissions at once
      final statuses = await permissions.request();

      // Log the status of each permission
      statuses.forEach((permission, status) {
        logger.i(
          '${permission.toString()}: ${status.toString()}',
        );
      });

      // Check if all critical permissions are granted
      final allGranted = statuses.values.every(
        (status) => status.isGranted || status.isDenied,
      );

      if (allGranted) {
        logger.i('✅ Permisos solicitados exitosamente');
      } else {
        logger.w('⚠️ Algunos permisos fueron rechazados');
      }
      
      return true;
    } catch (e) {
      logger.e('Error solicitando permisos: $e');
      return false;
    }
  }

  /// Check if Usage Access permission is enabled
  Future<bool> isUsageAccessEnabled() async {
    try {
      if (!Platform.isAndroid) {
        logger.i('ℹ️ Plataforma no Android - permisos no aplicables');
        return false;
      }

      // Llamar al método nativo Android para verificar si tiene acceso a estadísticas
      final result = await platform.invokeMethod<bool>('hasUsageAccess');
      final hasAccess = result ?? false;

      if (hasAccess) {
        logger.i('✅ Acceso a estadísticas de uso OTORGADO ✓');
      } else {
        logger.w('⚠️ ¡PERMISO REQUERIDO! Acceso a estadísticas de uso NO OTORGADO');
        logger.w('📱 Para habilitar:');
        logger.w('   1. Abre Configuración');
        logger.w('   2. Ve a Aplicaciones especiales (o similar según tu dispositivo)');
        logger.w('   3. Busca "Acceso de estadísticas de uso" o "Usage Stats"');
        logger.w('   4. Activa "Offline" o esta aplicación');
      }
      return hasAccess;
    } on PlatformException catch (e) {
      logger.e('❌ Error verificando acceso a estadísticas: ${e.message}');
      return false;
    } catch (e) {
      logger.e('Error checking usage access: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  Future<bool> allPermissionsGranted() async {
    try {
      final notification = await Permission.notification.isGranted;
      final scheduleExact = await Permission.scheduleExactAlarm.isGranted;
      final usageAccess = await isUsageAccessEnabled();

      return notification && scheduleExact && usageAccess;
    } catch (e) {
      logger.e('Error checking permissions: $e');
      return false;
    }
  }

  /// Check specific permission status
  Future<PermissionStatus> checkPermission(Permission permission) async {
    try {
      return await permission.status;
    } catch (e) {
      logger.e('Error checking permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request specific permission
  Future<PermissionStatus> requestPermission(Permission permission) async {
    try {
      return await permission.request();
    } catch (e) {
      logger.e('Error requesting permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Open app settings
  Future<bool> openAppSettingsPage() async {
    try {
      return await openAppSettings();
    } catch (e) {
      logger.e('Error opening app settings: $e');
      return false;
    }
  }

  /// Get human-readable permission description
  String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.notification:
        return 'Enviar notificaciones';
      case Permission.scheduleExactAlarm:
        return 'Programar alarmas exactas';
      default:
        return 'Permiso desconocido';
    }
  }
}
