import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';

/// Widget que muestra estadísticas
class StatsWidget extends StatelessWidget {
  const StatsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, petProvider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estadísticas de hoy',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _StatItem(
                  icon: '🟢',
                  label: 'Tiempo OFFLINE',
                  value: '${petProvider.sessionOfflineTime.inMinutes} min',
                ),
                const SizedBox(height: 12),
                _StatItem(
                  icon: '📱',
                  label: 'Tiempo en pantalla',
                  value: '${petProvider.sessionScreenTime.inMinutes} min',
                ),
                const SizedBox(height: 12),
                _StatItem(
                  icon: '⚠️',
                  label: 'Apps distractoras',
                  value: '${petProvider.distractingAppsUsed.length}',
                ),
                const SizedBox(height: 12),
                _StatItem(
                  icon: '⏱️',
                  label: 'Tiempo total OFFLINE',
                  value: '${petProvider.pet.totalOfflineTime.inHours}h ${petProvider.pet.totalOfflineTime.inMinutes % 60}m',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
