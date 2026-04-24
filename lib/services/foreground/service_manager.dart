// ServiceManager: Simplificado, no necesita flutter_foreground_task
// El ScreenTimeMonitor usa un Timer simple

class ServiceManager {
  static Future<bool> startService() async {
    // No-op: No se necesita servicio en foreground
    // El monitoring se hace con Timer en ScreenTimeMonitor
    return true;
  }

  static Future<bool> stopService() async {
    // No-op
    return true;
  }
}
