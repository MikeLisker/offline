import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import 'providers/pet_provider.dart';
import 'screens/home_screen.dart';
import 'services/permissions_service.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final permissionsService = PermissionsService();
    await permissionsService.requestAllPermissions();
  } catch (e) {
    logger.e('Error permisos: $e');
  }

  runApp(const OfflineApp());
}

class OfflineApp extends StatelessWidget {
  const OfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PetProvider()),
      ],
      child: MaterialApp(
        title: 'Rolana',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        home: const _InitializationWrapper(),
      ),
    );
  }
}

class _InitializationWrapper extends StatefulWidget {
  const _InitializationWrapper({super.key});
  @override
  State<_InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<_InitializationWrapper> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    final petProvider = context.read<PetProvider>();
    await petProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return const HomeScreen();
      },
    );
  }
}
