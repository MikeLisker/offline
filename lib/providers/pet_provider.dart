import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../models/pet.dart';
import '../core/constants.dart';
import '../services/foreground/service_manager.dart';
import '../services/pet_storage_service.dart';
import '../services/screen_time_monitor.dart';

class PetProvider extends ChangeNotifier {
  static final logger = Logger();

  late Pet _pet;
  late PetStorageService _storageService;
  late ScreenTimeMonitor _screenTimeMonitor;
  bool _isInitialized = false;
  bool _isMonitoring = false;
  Timer? _syncTimer;

  List<String> _distractingApps = [];
  
  // Session statistics tracking
  Duration _sessionOfflineTime = Duration.zero;
  Duration _sessionScreenTime = Duration.zero;
  Set<String> _distractingAppsUsedInSession = {};
  int _sessionDistractingSeconds = 0;
  int _sessionDistractingPenaltyApplied = 0;
  List<int> _todayOfflineSecondsByHour = List.filled(24, 0);
  DateTime _hourlyBucketsDate = DateTime.now();

  Pet get pet => _pet;
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  List<String> get distractingApps => _distractingApps;
  
  // Getters for session statistics
  Duration get sessionOfflineTime => _sessionOfflineTime;
  
  Duration get sessionScreenTime => _sessionScreenTime;
  
  List<String> get distractingAppsUsed => _distractingAppsUsedInSession.toList();

  Future<List<Map<String, dynamic>>> getWeeklyOfflineStats() async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final results = <Map<String, dynamic>>[];

    for (int offset = 6; offset >= 0; offset--) {
      final date = startOfToday.subtract(Duration(days: offset));
      final stats = await _storageService.getDailyStatsOrEmpty(date);
      results.add(stats);
    }

    return results;
  }
  List<int> get offlineMinutesByHourToday {
    _ensureHourlyBucketsForToday(DateTime.now());
    return _todayOfflineSecondsByHour.map((s) => (s / 60).floor()).toList();
  }
  
  Future<bool> isScreenOn() async {
    return true; // Placeholder - siempre true
  }

  Future<void> init() async {
    try {
      logger.i('⚙️ Inicializando PetProvider');

      _storageService = PetStorageService();
      await _storageService.init();

      _pet = await _storageService.loadPet();

      await _loadTodayStats();

      final prefs = await SharedPreferences.getInstance();
      _distractingApps = prefs.getStringList(AppConstants.distractingAppsKey) ?? [];
      
      _syncFromService(prefs);

      // Inicializar ScreenTimeMonitor
      _screenTimeMonitor = ScreenTimeMonitor();
      _screenTimeMonitor.loadCheckpoints(_pet.screenTimeCheckpoints);
      
      // 🔑 CRUCIAL: Pasar las apps distractoras seleccionadas al monitor
      _screenTimeMonitor.setDistractionApps(_distractingApps);
      await _screenTimeMonitor.resetDistractingAppsBaselines();
      _pet.screenTimeCheckpoints = _screenTimeMonitor.getCheckpoints();
      await _storageService.savePet(_pet);
      logger.i('📲 Apps distractoras sincronizadas: ${_distractingApps.length}');
      
      // Conectar callbacks
      _screenTimeMonitor.onDistractionDetected((packageName, screenTime) async {
        logger.w('🚨 ¡CALLBACK DISTRACCIÓN! $packageName (${screenTime.inMinutes}m ${screenTime.inSeconds % 60}s)');
        
        // Actualizar estadísticas de sesión
        _sessionScreenTime += screenTime;
        _distractingAppsUsedInSession.add(packageName);
        await _storageService.saveDailyStats(
          date: DateTime.now(),
          offlineTime: Duration.zero,
          screenTime: screenTime,
          distractingAppsUsed: [packageName],
        );
        
        // Mecánica solicitada: cada 5 minutos acumulados de distractoras = -2 energía.
        // Se acumula en segundos para no depender de "rangos" por callback.
        _sessionDistractingSeconds += screenTime.inSeconds;
        final totalPenaltyShouldBe = ((_sessionDistractingSeconds / 300) * 2).floor();
        final energyPenalty = totalPenaltyShouldBe - _sessionDistractingPenaltyApplied;
        _sessionDistractingPenaltyApplied = totalPenaltyShouldBe;

        if (energyPenalty <= 0) {
          logger.i('⏳ Distracción acumulada: ${_sessionDistractingSeconds}s, aún sin penalización nueva');
          return;
        }

        for (int i = 0; i < (energyPenalty ~/ 2); i++) {
          await ScreenTimeMonitor.platform.invokeMethod('showReminderNotification', {
            'title': 'Rolana',
            'text': 'Estas pasando mucho tiempo en esta app, recuerda cuidar tu jardin.',
          });
        }

        final oldEnergy = _pet.energy;
        _pet.energy = (_pet.energy - energyPenalty).clamp(0, 100);
        logger.w('⚡ Energía reducida: $oldEnergy → ${_pet.energy} (-$energyPenalty por ${_sessionDistractingSeconds}s distractoras acumulados)');
        
        _pet.lastScreenTimeCheckpoint = DateTime.now();
        await _storageService.savePet(_pet);
        notifyListeners();
      });

      _screenTimeMonitor.onOfflineDetected((offlineTime) async {
        logger.i('✅ CALLBACK OFFLINE DETECTADO: ${offlineTime.inMinutes}m ${offlineTime.inSeconds % 60}s');
        
        // Actualizar estadísticas de sesión
        _sessionOfflineTime += offlineTime;
        _addOfflineDurationToHourlyBuckets(offlineTime, DateTime.now());
        await _storageService.saveDailyStats(
          date: DateTime.now(),
          offlineTime: offlineTime,
          screenTime: Duration.zero,
          distractingAppsUsed: const [],
        );
        
        // Fórmula solicitada:
        // Punto1 = TiempoOffline(min) / 4
        // PuntoOffline = Punto1 * 2
        final punto1 = offlineTime.inMinutes ~/ 4;
        final energyGain = punto1 * 2;
        final oldEnergy = _pet.energy;
        _pet.energy = (_pet.energy + energyGain).clamp(0, 100);
        logger.i('⚡ ENERGÍA AUMENTADA: $oldEnergy → ${_pet.energy} (+$energyGain por ${offlineTime.inMinutes}m offline; punto1=$punto1)');
        logger.i('💾 Guardando... (offline time: ${_sessionOfflineTime.inMinutes}m acumulados en sesión)');
        
        _pet.lastScreenTimeCheckpoint = DateTime.now();
        await _storageService.savePet(_pet);
        notifyListeners();
      });

      // Iniciar monitoreo
      _screenTimeMonitor.startMonitoring();
      _isMonitoring = true;

      await ServiceManager.startService();

      _syncTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        final p = await SharedPreferences.getInstance();
        _syncFromService(p);
        // Sincronizar checkpoints con storage
        _pet.screenTimeCheckpoints = _screenTimeMonitor.getCheckpoints();
        await _storageService.savePet(_pet);
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      logger.e('❌ Error inicializando PetProvider: $e');
      _pet = Pet();
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _syncFromService(SharedPreferences prefs) {
    int? energy = prefs.getInt('pet_energy');
    int? coins = prefs.getInt('pet_coins');

    bool changed = false;
    if (energy != null && energy != _pet.energy) {
      _pet.energy = energy;
      changed = true;
    }
    if (coins != null && coins != _pet.coins) {
      _pet.coins = coins;
      changed = true;
    }

    if (changed) {
      _storageService.savePet(_pet);
      notifyListeners();
    }
  }

  Future<void> updateDistractingApps(List<String> packages) async {
    _distractingApps = packages;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.distractingAppsKey, packages);
    
    // 🔑 CRUCIAL: Actualizar la lista en ScreenTimeMonitor en tiempo real
    _screenTimeMonitor.setDistractionApps(packages);
    await _screenTimeMonitor.resetDistractingAppsBaselines();
    _pet.screenTimeCheckpoints = _screenTimeMonitor.getCheckpoints();
    await _storageService.savePet(_pet);
    _sessionDistractingSeconds = 0;
    _sessionDistractingPenaltyApplied = 0;
    logger.i('🎯 Apps distractoras actualizadas en monitor: ${packages.length}');
    
    await ServiceManager.stopService();
    await ServiceManager.startService();
    
    notifyListeners();
  }

  Future<void> levelUpPet() async {
    if (_pet.canLevelUp()) {
      _pet.levelUp();
      await _storageService.savePet(_pet);
      notifyListeners();
    }
  }

  Future<void> revivePet() async {
    _pet.revive();
    await _storageService.savePet(_pet);
    notifyListeners();
  }

  Future<void> renamePet(String newName) async {
    _pet.name = newName;
    await _storageService.savePet(_pet);
    notifyListeners();
  }

  Future<void> resetPet() async {
    await _storageService.clear();
    _pet = Pet();
    _sessionOfflineTime = Duration.zero;
    _sessionScreenTime = Duration.zero;
    _distractingAppsUsedInSession.clear();
    _sessionDistractingSeconds = 0;
    _sessionDistractingPenaltyApplied = 0;
    _todayOfflineSecondsByHour = List.filled(24, 0);
    _hourlyBucketsDate = DateTime.now();
    await _storageService.savePet(_pet);
    notifyListeners();
  }
  
  /// Resetear estadísticas de sesión (para nuevo día)
  void resetSessionStats() {
    _sessionOfflineTime = Duration.zero;
    _sessionScreenTime = Duration.zero;
    _distractingAppsUsedInSession.clear();
    _sessionDistractingSeconds = 0;
    _sessionDistractingPenaltyApplied = 0;
    _todayOfflineSecondsByHour = List.filled(24, 0);
    _hourlyBucketsDate = DateTime.now();
    notifyListeners();
  }

  void _ensureHourlyBucketsForToday(DateTime reference) {
    if (!_isSameDay(_hourlyBucketsDate, reference)) {
      _todayOfflineSecondsByHour = List.filled(24, 0);
      _hourlyBucketsDate = reference;
    }
  }

  Future<void> _loadTodayStats() async {
    final todayStats = await _storageService.getDailyStatsOrEmpty(DateTime.now());

    _sessionOfflineTime = Duration(seconds: todayStats['offlineTime'] as int? ?? 0);
    _sessionScreenTime = Duration(seconds: todayStats['screenTime'] as int? ?? 0);

    final appsUsed = todayStats['distractingApps'];
    _distractingAppsUsedInSession = appsUsed is List
        ? appsUsed.map((item) => item.toString()).toSet()
        : <String>{};

    _sessionDistractingSeconds = _sessionScreenTime.inSeconds;
    _sessionDistractingPenaltyApplied = ((_sessionDistractingSeconds / 300) * 2).floor();
  }

  void _addOfflineDurationToHourlyBuckets(Duration duration, DateTime endTime) {
    if (duration.inSeconds <= 0) return;

    _ensureHourlyBucketsForToday(endTime);

    final startOfToday = DateTime(endTime.year, endTime.month, endTime.day);
    int remainingSeconds = duration.inSeconds;
    DateTime cursor = endTime;

    while (remainingSeconds > 0 && cursor.isAfter(startOfToday)) {
      final hourStart = DateTime(cursor.year, cursor.month, cursor.day, cursor.hour);
      int secondsInCurrentHour = cursor.difference(hourStart).inSeconds;

      if (secondsInCurrentHour == 0) {
        cursor = cursor.subtract(const Duration(seconds: 1));
        continue;
      }

      final alloc = remainingSeconds < secondsInCurrentHour
          ? remainingSeconds
          : secondsInCurrentHour;
      _todayOfflineSecondsByHour[cursor.hour] += alloc;
      remainingSeconds -= alloc;
      cursor = cursor.subtract(Duration(seconds: alloc));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _screenTimeMonitor.stopMonitoring();
    super.dispose();
  }
}
