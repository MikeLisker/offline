import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/pet.dart';

class PetStorageService {
  static final logger = Logger();
  static const String PET_BOX = 'pet_box';
  static const String STATS_BOX = 'stats_box';

  late Box<dynamic> _petBox;
  late Box<dynamic> _statsBox;
  bool _isInitialized = false;

  Future<void> init() async {
    try {
      // Evitar inicializar dos veces
      if (_isInitialized) {
        logger.i('✅ Storage ya está inicializado');
        return;
      }

      await Hive.initFlutter();
      _petBox = await Hive.openBox(PET_BOX);
      _statsBox = await Hive.openBox(STATS_BOX);
      _isInitialized = true;
      logger.i('✅ Storage inicializado correctamente');
    } catch (e) {
      logger.e('❌ Error inicializando storage: $e');
      // No relanzar la excepción - permitir que la app funcione con storage en memoria
      _isInitialized = false;
    }
  }

  /// Verificar si el storage está disponible
  bool get isAvailable => _isInitialized;

  /// Guardar mascota
  Future<void> savePet(Pet pet) async {
    // Si el storage no está disponible, simplemente log y retorna
    if (!_isInitialized) {
      logger.w('⚠️ Storage no disponible - mascota no se guardará');
      return;
    }

    try {
      final petJson = {
        'id': pet.id,
        'name': pet.name,
        'energy': pet.energy,
        'level': pet.level,
        'coins': pet.coins,
        'totalOfflineTime': pet.totalOfflineTime.inSeconds,
        'lastUpdated': pet.lastUpdated.toIso8601String(),
        'isAlive': pet.isAlive,
        'screenTimeCheckpoints': pet.screenTimeCheckpoints,
        'lastScreenTimeCheckpoint': pet.lastScreenTimeCheckpoint?.toIso8601String(),
      };
      await _petBox.put('pet', jsonEncode(petJson));
      logger.d('💾 Mascota guardada: ${pet.name}');
    } catch (e) {
      logger.e('❌ Error guardando mascota: $e');
    }
  }

  /// Cargar mascota
  Future<Pet> loadPet() async {
    try {
      // Si el storage no está disponible, devolver pet por defecto
      if (!_isInitialized) {
        logger.w('⚠️ Storage no disponible - usando mascota por defecto');
        return Pet();
      }

      final petData = _petBox.get('pet');
      if (petData == null) {
        logger.i('📝 Creando nueva mascota por defecto');
        return Pet();
      }

      final petJson = jsonDecode(petData);
      
      // Cargar checkpoints (puede ser null o estar vacío)
      Map<String, int> checkpoints = {};
      if (petJson['screenTimeCheckpoints'] is Map) {
        (petJson['screenTimeCheckpoints'] as Map).forEach((key, value) {
          checkpoints[key.toString()] = value as int? ?? 0;
        });
      }
      
      DateTime? lastCheckpoint;
      if (petJson['lastScreenTimeCheckpoint'] != null) {
        try {
          lastCheckpoint = DateTime.parse(petJson['lastScreenTimeCheckpoint']);
        } catch (e) {
          logger.w('⚠️ Error parseando lastScreenTimeCheckpoint: $e');
        }
      }
      
      return Pet(
        id: petJson['id'] ?? 'default_pet',
        name: petJson['name'] ?? 'Offline Buddy',
        energy: petJson['energy'] ?? 75,
        level: petJson['level'] ?? 1,
        coins: petJson['coins'] ?? 0,
        totalOfflineTime:
            Duration(seconds: petJson['totalOfflineTime'] ?? 0),
        lastUpdated: DateTime.parse(
            petJson['lastUpdated'] ?? DateTime.now().toIso8601String()),
        isAlive: petJson['isAlive'] ?? true,
        screenTimeCheckpoints: checkpoints,
        lastScreenTimeCheckpoint: lastCheckpoint,
      );
    } catch (e) {
      logger.e('❌ Error cargando mascota: $e');
      return Pet();
    }
  }

  /// Guardar estadísticas diarias
  Future<void> saveDailyStats({
    required DateTime date,
    required Duration offlineTime,
    required Duration screenTime,
    required List<String> distractingAppsUsed,
  }) async {
    // Si el storage no está disponible, simplemente log y retorna
    if (!_isInitialized) {
      logger.w('⚠️ Storage no disponible - estadísticas no se guardarán');
      return;
    }

    try {
      final key = 'stats_${date.toIso8601String().split('T')[0]}';
      final existingData = _statsBox.get(key);
      Duration existingOfflineTime = Duration.zero;
      Duration existingScreenTime = Duration.zero;
      List<String> existingApps = [];

      if (existingData != null) {
        try {
          final existingJson = jsonDecode(existingData);
          existingOfflineTime = Duration(
            seconds: existingJson['offlineTime'] ?? 0,
          );
          existingScreenTime = Duration(
            seconds: existingJson['screenTime'] ?? 0,
          );
          if (existingJson['distractingApps'] is List) {
            existingApps = (existingJson['distractingApps'] as List)
                .map((item) => item.toString())
                .toList();
          }
        } catch (e) {
          logger.w('⚠️ Error leyendo estadísticas previas de $key: $e');
        }
      }

      final stats = {
        'date': date.toIso8601String(),
        'offlineTime': existingOfflineTime.inSeconds + offlineTime.inSeconds,
        'screenTime': existingScreenTime.inSeconds + screenTime.inSeconds,
        'distractingApps': {...existingApps, ...distractingAppsUsed}.toList(),
      };
      await _statsBox.put(key, jsonEncode(stats));
      logger.d('📊 Estadísticas guardadas para ${date.toIso8601String()}');
    } catch (e) {
      logger.e('❌ Error guardando estadísticas: $e');
    }
  }

  /// Obtener estadísticas de un día
  Future<Map<String, dynamic>?> getDailyStats(DateTime date) async {
    // Si el storage no está disponible, retorna null
    if (!_isInitialized) {
      logger.w('⚠️ Storage no disponible - estadísticas no disponibles');
      return null;
    }

    try {
      final key = 'stats_${date.toIso8601String().split('T')[0]}';
      final statsData = _statsBox.get(key);
      if (statsData == null) return null;
      return jsonDecode(statsData);
    } catch (e) {
      logger.e('❌ Error cargando estadísticas: $e');
      return null;
    }
  }

  /// Obtener estadísticas de últimos N días
  Future<List<Map<String, dynamic>>> getStatsLastDays(int days) async {
    try {
      final stats = <Map<String, dynamic>>[];
      for (int i = 0; i < days; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayStat = await getDailyStats(date);
        if (dayStat != null) {
          stats.add(dayStat);
        }
      }
      return stats;
    } catch (e) {
      logger.e('❌ Error obteniendo estadísticas históricas: $e');
      return [];
    }
  }

  /// Obtener estadísticas para una fecha concreta, incluyendo ceros si no existe registro.
  Future<Map<String, dynamic>> getDailyStatsOrEmpty(DateTime date) async {
    final stats = await getDailyStats(date);
    return stats ?? {
      'date': date.toIso8601String(),
      'offlineTime': 0,
      'screenTime': 0,
      'distractingApps': <String>[],
    };
  }

  /// Limpiar datos (para debug/reset)
  Future<void> clear() async {
    try {
      await _petBox.clear();
      await _statsBox.clear();
      logger.i('🗑️ Storage limpiado');
    } catch (e) {
      logger.e('❌ Error limpiando storage: $e');
    }
  }
}
