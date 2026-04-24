import 'package:flutter/material.dart';

class Pet {
  final String id;
  String name;
  int energy; // 0-100
  int level; // 1-10
  int coins; // Monedas virtuales
  Duration totalOfflineTime;
  DateTime lastUpdated;
  bool isAlive;
  Map<String, int> screenTimeCheckpoints; // Guardar último tiempo conocido de cada app
  DateTime? lastScreenTimeCheckpoint; // Última vez que se sincronizó

  Pet({
    this.id = 'default_pet',
    this.name = 'Offline Buddy',
    this.energy = 75,
    this.level = 1,
    this.coins = 0,
    this.totalOfflineTime = const Duration(),
    DateTime? lastUpdated,
    this.isAlive = true,    this.screenTimeCheckpoints = const {},
    this.lastScreenTimeCheckpoint,  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Calcular estado visual de la mascota
  String getState() {
    if (!isAlive) return 'dead';
    if (energy < 20) return 'sad';
    if (energy < 50) return 'neutral';
    if (energy < 80) return 'happy';
    return 'very_happy';
  }

  // Calcular siguiente nivel
  int getCoinsForNextLevel() {
    return level * 100; // 100 monedas por nivel
  }

  // Verificar si puede subir de nivel
  bool canLevelUp() {
    return coins >= getCoinsForNextLevel();
  }

  // Subir de nivel
  void levelUp() {
    if (canLevelUp()) {
      coins -= getCoinsForNextLevel();
      level = (level + 1).clamp(1, 10);
    }
  }

  // Añadir energía por tiempo offline
  void addEnergyFromOfflineTime(Duration offlineTime) {
    // 1 minuto offline = 1 punto de energía
    int energyGain = offlineTime.inMinutes ~/ 1;
    energy = (energy + energyGain).clamp(0, 100);
    
    // Cada 10 minutos offline = 1 moneda
    int coinsGain = offlineTime.inMinutes ~/ 10;
    coins += coinsGain;
    
    totalOfflineTime += offlineTime;
  }

  // Reducir energía por uso de pantalla
  // 5 minutos de uso de app distractora = -1 punto de energía
  void reduceEnergyFromScreenTime(Duration screenTime) {
    int energyLoss = screenTime.inMinutes ~/ 5;
    energy = (energy - energyLoss).clamp(0, 100);

    if (energy == 0) {
      isAlive = false;
    }
  }

  // Revivir mascota (con penalización)
  void revive() {
    isAlive = true;
    energy = 75; // Vuelve a 75% al revivir
    coins = (coins * 0.5).toInt(); // Pierde 50% de monedas
    screenTimeCheckpoints.clear(); // Resetear checkpoints
    lastScreenTimeCheckpoint = DateTime.now();
  }

  // Resetear checkpoints para nueva sesión
  void resetTimeCheckpoints() {
    screenTimeCheckpoints.clear();
    lastScreenTimeCheckpoint = DateTime.now();
  }

  @override
  String toString() =>
      'Pet(name: $name, energy: $energy, level: $level, coins: $coins)';
}
