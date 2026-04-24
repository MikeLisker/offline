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

  Pet get pet => _pet;
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  List<String> get distractingApps => _distractingApps;
  
  // Getters for session statistics
  Duration get sessionOfflineTime {
    final mins = SharedPreferences.getInstance().then(
      (prefs) => prefs.getInt('session_offline_time') ?? 0,
    );
    return Duration(minutes: 0); // Placeholder
  }
  
  Duration get sessionScreenTime {
    return Duration(minutes: 0); // Placeholder
  }
  
  List<String> get distractingAppsUsed {
    return []; // Placeholder
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

      final prefs = await SharedPreferences.getInstance();
      _distractingApps = prefs.getStringList(AppConstants.distractingAppsKey) ?? [];
      
      _syncFromService(prefs);

      // Inicializar ScreenTimeMonitor
      _screenTimeMonitor = ScreenTimeMonitor();
      _screenTimeMonitor.loadCheckpoints(_pet.screenTimeCheckpoints);
      
      // Conectar callbacks
      _screenTimeMonitor.onDistractionDetected((packageName, screenTime) async {
        logger.w('🚨 Distracción detectada: $packageName (${screenTime.inMinutes}m)');
        _pet.energy = (_pet.energy - 5).clamp(0, 100);
        _pet.lastScreenTimeCheckpoint = DateTime.now();
        await _storageService.savePet(_pet);
        notifyListeners();
      });

      _screenTimeMonitor.onOfflineDetected((offlineTime) async {
        logger.i('✅ Tiempo offline detectado: ${offlineTime.inMinutes}m');
        // 4 minutos offline = 2 puntos de energía
        final energyGain = (offlineTime.inMinutes / 4 * 2).toInt();
        _pet.energy = (_pet.energy + energyGain).clamp(0, 100);
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
    await _storageService.savePet(_pet);
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _screenTimeMonitor.stopMonitoring();
    super.dispose();
  }
}
