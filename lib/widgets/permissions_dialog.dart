import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permissions_service.dart';

class PermissionsDialog extends StatefulWidget {
  const PermissionsDialog({Key? key}) : super(key: key);

  @override
  State<PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<PermissionsDialog> {
  final _permissionsService = PermissionsService();
  late Future<Map<Permission, PermissionStatus>> _permissionsFuture;

  @override
  void initState() {
    super.initState();
    _permissionsFuture = _checkPermissions();
  }

  Future<Map<Permission, PermissionStatus>> _checkPermissions() async {
    final permissions = <Permission>[
      Permission.notification,
      Permission.scheduleExactAlarm,
    ];

    final statuses = <Permission, PermissionStatus>{};
    for (final permission in permissions) {
      statuses[permission] = await permission.status;
    }
    return statuses;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<Permission, PermissionStatus>>(
      future: _permissionsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final statuses = snapshot.data!;
        final allGranted = statuses.values.every(
          (status) => status.isGranted,
        );

        if (allGranted) {
          return const SizedBox.shrink();
        }

        return Dialog(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Se necesitan permisos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Para que OFFLINE funcione correctamente, necesitamos algunos permisos:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PermissionItemWidget(
                    icon: Icons.app_shortcut,
                    title: 'Usar datos de aplicaciones',
                    description: 'Necesario activar en Configuración → Aplicaciones → Permisos Especiales → "Usar datos de aplicaciones"',
                    status: PermissionStatus.granted,
                    isManual: true,
                  ),
                  const SizedBox(height: 12),
                  _PermissionItemWidget(
                    icon: Icons.notifications,
                    title: 'Notificaciones',
                    description: 'Te avisaremos sobre el estado de tu mascota',
                    status: statuses[Permission.notification]!,
                  ),
                  const SizedBox(height: 12),
                  _PermissionItemWidget(
                    icon: Icons.schedule,
                    title: 'Alarmas exactas',
                    description: 'Para revisar periódicamente el uso de apps',
                    status: statuses[Permission.scheduleExactAlarm]!,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                          ),
                          child: const Text(
                            'Después',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _permissionsService.requestAllPermissions();
                            if (mounted) {
                              setState(() {
                                _permissionsFuture = _checkPermissions();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                            'Aceptar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus status;
  final bool isManual;

  const _PermissionItemWidget({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    this.isManual = false,
  });

  @override
  Widget build(BuildContext context) {
    final isGranted = status.isGranted || isManual;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGranted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGranted ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isGranted ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isGranted ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isGranted ? Icons.check_circle : Icons.info,
            color: isGranted ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}
