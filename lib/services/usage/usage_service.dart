// import 'package:usage_stats/usage_stats.dart';
import 'package:logger/logger.dart';

class UsageService {
  static final logger = Logger();

  /// Verifica si el permiso de estadisticas de uso esta concedido
  static Future<bool> checkPermission() async {
    // bool? isGranted = await UsageStats.checkUsagePermission();
    // return isGranted ?? false;
    return false;
  }

  /// Abre la configuracion para que el usuario de el permiso
  static Future<void> openSettings() async {
    // await UsageStats.grantUsagePermission();
  }

  /// Obtiene el tiempo de uso total acumulado por cada app desde el inicio de los tiempos (segun Android)
  /// Retorna un Map de <PackageName, MillisecondsTotal>
  static Future<Map<String, int>> getAllUsageStats() async {
    try {
      // DateTime endDate = DateTime.now();
      // Pedimos estadisticas desde hace 1 dia para asegurar capturar el acumulado actual
      // DateTime startDate = endDate.subtract(const Duration(days: 1));

      // List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      
      Map<String, int> result = {};
      /*
      for (var info in usageStats) {
        int totalTime = int.parse(info.totalTimeInForeground ?? '0');
        if (totalTime > 0) {
          // Si ya existe (a veces Android devuelve duplicados por usuario), sumamos o tomamos el mayor
          if (result.containsKey(info.packageName)) {
            if (totalTime > result[info.packageName]!) {
              result[info.packageName!] = totalTime;
            }
          } else {
            result[info.packageName!] = totalTime;
          }
        }
      }
      */
      return result;
    } catch (e) {
      logger.e('Error obteniendo usage stats: ');
      return {};
    }
  }
}
