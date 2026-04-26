import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pet_provider.dart';

class OfflineHoursChart extends StatelessWidget {
  const OfflineHoursChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, petProvider, _) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: petProvider.getWeeklyOfflineStats(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final weeklyStats = snapshot.data!;
            final offlineHours = weeklyStats.map((day) {
              final seconds = day['offlineTime'] as int? ?? 0;
              return seconds / 3600.0;
            }).toList();
            final screenHours = weeklyStats.map((day) {
              final seconds = day['screenTime'] as int? ?? 0;
              return seconds / 3600.0;
            }).toList();
            final dayLabels = weeklyStats.map((day) {
              final rawDate = day['date']?.toString();
              final parsed = rawDate != null ? DateTime.tryParse(rawDate) : null;
              return _weekdayLabel(parsed ?? DateTime.now());
            }).toList();
            final maxHours = [...offlineHours, ...screenHours]
                .fold<double>(0, (max, value) => value > max ? value : max);
            final chartMax = maxHours < 1 ? 1.0 : maxHours;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline semanal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Comparativa diaria entre tiempo en pantalla y tiempo offline',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _LegendDot(color: Colors.orange.shade400, label: 'Pantalla'),
                        const SizedBox(width: 14),
                        _LegendDot(color: Colors.green.shade500, label: 'Offline'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 240,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (index) {
                                final offline = offlineHours[index];
                                final screen = screenHours[index];
                                final offlineHeight = ((offline / chartMax) * 150).clamp(4, 150).toDouble();
                                final screenHeight = ((screen / chartMax) * 150).clamp(4, 150).toDouble();

                                return Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${offline.toStringAsFixed(1)}h',
                                        style: const TextStyle(fontSize: 10),
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            height: screenHeight,
                                            width: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade400,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            height: offlineHeight,
                                            width: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade500,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        dayLabels[index],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

String _weekdayLabel(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return 'L';
    case DateTime.tuesday:
      return 'M';
    case DateTime.wednesday:
      return 'X';
    case DateTime.thursday:
      return 'J';
    case DateTime.friday:
      return 'V';
    case DateTime.saturday:
      return 'S';
    case DateTime.sunday:
      return 'D';
    default:
      return '?';
  }
}
