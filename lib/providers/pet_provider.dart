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

  Pet get pet => _pet;
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  List<String> get distractingApps => _distractingApps;
  
  // Getters for session statistics
  Duration get sessionOfflineTime => _sessionOfflineTime;
  
  Duration get sessionScreenTime => _sessionScreenTime;
  
  List<String> get distractingAppsUsed => _distractingAppsUsedInSession.toList();
  
  Future<bool> isScreenOn() async {
    return true; // Placeholder - siempre true
  }

  Future<void> init() async {
    try {
      logger.i('⚙️ Inicializando PetProvider');

      _storageService = PetStorageService();
      await _storageService.init();

      _pet = await _storageService.loadPet();

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
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _screenTimeMonitor.stopMonitoring();
    super.dispose();
  }
}
