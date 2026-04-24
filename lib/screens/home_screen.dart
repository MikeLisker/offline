import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';
import '../widgets/pet_visualizer.dart';
import '../widgets/stats_widget.dart';
import '../widgets/usage_access_dialog.dart';
import '../widgets/service_status_widget.dart';
import '../services/permissions_service.dart';
import 'app_selector_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionsDialogIfNeeded();
    });
  }

  Future<void> _showPermissionsDialogIfNeeded() async {
    final permissionsService = PermissionsService();
    final usageAccessEnabled = await permissionsService.isUsageAccessEnabled();
    
    if (!usageAccessEnabled && mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const UsageAccessDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rolana 🌱'),
        centerTitle: true,
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, _) {
          if (!petProvider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const ServiceStatusWidget(),
                const SizedBox(height: 20),
                PetVisualizer(),
                const SizedBox(height: 30),
                StatsWidget(),
                const SizedBox(height: 30),
                if (petProvider.pet.isAlive) ...[
                  _ActionButtons(petProvider: petProvider),
                ] else ...[
                  _ReviveButton(petProvider: petProvider),
                ],
                const SizedBox(height: 30),
                // DEBUG WIDGET
                _DebugAppsWidget(petProvider: petProvider),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final PetProvider petProvider;
  const _ActionButtons({super.key, required this.petProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (petProvider.pet.canLevelUp())
          ElevatedButton.icon(
            onPressed: () => petProvider.levelUpPet(),
            icon: const Icon(Icons.arrow_upward),
            label: const Text('Subir de Nivel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _showOptionsMenu(context, petProvider),
          icon: const Icon(Icons.settings),
          label: const Text('Opciones'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu(BuildContext context, PetProvider petProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('Apps distractoras'),
              subtitle: Text('${petProvider.distractingApps.length} seleccionadas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AppSelectorScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Renombrar mascota'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, petProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Resetear mascota'),
              onTap: () {
                Navigator.pop(context);
                _confirmReset(context, petProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PetProvider petProvider) {
    final controller = TextEditingController(text: petProvider.pet.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar'),
        content: TextField(controller: controller),
        actions: [
          ElevatedButton(
            onPressed: () {
              petProvider.renamePet(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, PetProvider petProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Resetear?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(onPressed: () {
            petProvider.resetPet();
            Navigator.pop(context);
          }, child: const Text('Sí')),
        ],
      ),
    );
  }
}

class _ReviveButton extends StatelessWidget {
  final PetProvider petProvider;
  const _ReviveButton({super.key, required this.petProvider});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => petProvider.revivePet(),
      child: const Text('Revivir Mascota'),
    );
  }
}

class _DebugAppsWidget extends StatelessWidget {
  final PetProvider petProvider;
  const _DebugAppsWidget({super.key, required this.petProvider});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('🔧 DEBUG: Apps Monitoreadas'),
      subtitle: Text('${petProvider.distractingApps.length} apps seleccionadas'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apps configuradas (${petProvider.distractingApps.length}):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (petProvider.distractingApps.isEmpty)
                const Text('❌ Ninguna app seleccionada')
              else
                ...petProvider.distractingApps.map((pkg) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('  • $pkg'),
                )),
              const SizedBox(height: 16),
              Text(
                'Apps usadas en sesión (${petProvider.distractingAppsUsed.length}):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (petProvider.distractingAppsUsed.isEmpty)
                const Text('Ninguna detectada')
              else
                ...petProvider.distractingAppsUsed.map((pkg) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('  ✓ $pkg'),
                )),
              const SizedBox(height: 16),
              Text(
                'Estadísticas:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('  Tiempo en apps: ${petProvider.sessionScreenTime.inMinutes}m'),
              Text('  Tiempo offline: ${petProvider.sessionOfflineTime.inMinutes}m'),
            ],
          ),
        ),
      ],
    );
  }
}
