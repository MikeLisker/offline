import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/pet_provider.dart';

class ServiceStatusWidget extends StatefulWidget {
  const ServiceStatusWidget({Key? key}) : super(key: key);

  @override
  State<ServiceStatusWidget> createState() => _ServiceStatusWidgetState();
}

class _ServiceStatusWidgetState extends State<ServiceStatusWidget> {
  bool _isMonitoring = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    // Chequear estado cada 10 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    
    try {
      final provider = context.read<PetProvider>();
      if (provider.isInitialized && provider.isMonitoring) {
        setState(() => _isMonitoring = true);
      } else {
        setState(() => _isMonitoring = false);
      }
    } catch (e) {
      setState(() => _isMonitoring = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isMonitoring ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isMonitoring ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isMonitoring ? Icons.shield : Icons.shield_outlined,
            size: 16,
            color: _isMonitoring ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            _isMonitoring ? 'Monitoreo Activo' : 'Monitoreo Detenido',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _isMonitoring ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
