class AppConstants {
  static const String distractingAppsKey = 'distracting_apps';
  static const String checkpointsKey = 'app_usage_checkpoints';
  static const String lastOfflineTimeKey = 'last_offline_time';
  static const String petStateKey = 'pet_state_v1';
  
  static const int energyReductionMinutes = 5; // Cada 5 min de distracción, -1 energía
  static const int energyGainMinutes = 15;     // Cada 15 min offline, +1 energía
}
