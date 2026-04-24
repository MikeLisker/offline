import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';

/// Widget que muestra la mascota virtual
class PetVisualizer extends StatefulWidget {
  const PetVisualizer({Key? key}) : super(key: key);

  @override
  State<PetVisualizer> createState() => _PetVisualizerState();
}

class _PetVisualizerState extends State<PetVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, petProvider, _) {
        final pet = petProvider.pet;
        final state = pet.getState();

        return Column(
          children: [
            // Nombre de la mascota
            Text(
              pet.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            // Visualización de la mascota (emoji animado)
            ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.05)
                  .animate(_animationController),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getBackgroundColor(state),
                  boxShadow: [
                    BoxShadow(
                      color: _getStateColor(state).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Text(
                  _getEmojiForState(state, pet.isAlive),
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nivel
            Text(
              'Nivel ${pet.level}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),

            // Barra de energía
            _EnergyBar(energy: pet.energy),
            const SizedBox(height: 20),

            // Monedas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💰', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '${pet.coins}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),

            // Estado del usuario
            const SizedBox(height: 20),
            _UserStatusIndicator(),
          ],
        );
      },
    );
  }

  String _getEmojiForState(String state, bool isAlive) {
    if (!isAlive) return '💀';
    switch (state) {
      case 'dead':
        return '💀';
      case 'sad':
        return '😢';
      case 'neutral':
        return '😐';
      case 'happy':
        return '😊';
      case 'very_happy':
        return '😄';
      default:
        return '🤖';
    }
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'dead':
        return Colors.grey;
      case 'sad':
        return Colors.red;
      case 'neutral':
        return Colors.orange;
      case 'happy':
        return Colors.yellow;
      case 'very_happy':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getBackgroundColor(String state) {
    return _getStateColor(state).withOpacity(0.1);
  }
}

/// Barra de energía
class _EnergyBar extends StatelessWidget {
  final int energy;

  const _EnergyBar({Key? key, required this.energy}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Energía'),
            Text('$energy/100'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: energy / 100,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              energy < 20
                  ? Colors.red
                  : energy < 50
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
        ),
      ],
    );
  }
}

/// Indicador de estado del usuario
class _UserStatusIndicator extends StatelessWidget {
  const _UserStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, petProvider, _) {
        return FutureBuilder<bool>(
          future: petProvider.isScreenOn(),
          builder: (context, snapshot) {
            final isScreenOn = snapshot.data ?? false;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isScreenOn ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isScreenOn ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isScreenOn ? 'Usando pantalla' : 'OFFLINE ✨',
                    style: TextStyle(
                      color: isScreenOn ? Colors.red.shade700 : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
