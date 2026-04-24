import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';

// Simple model to replace DeviceApps.Application
class _MockApplication {
  final String packageName;
  final String appName;
  
  _MockApplication({required this.packageName, required this.appName});
}

class AppSelectorScreen extends StatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  State<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends State<AppSelectorScreen> {
  List<_MockApplication> _allApps = [];
  List<_MockApplication> _filteredApps = [];
  final List<String> _selectedPackages = [];
  bool _isLoading = true;
  String _searchQuery = "";

  // Predefined list of common apps (distracting and system)
  static const List<Map<String, String>> _PREDEFINED_APPS = [
    {'packageName': 'com.instagram.android', 'appName': 'Instagram'},
    {'packageName': 'com.facebook.katana', 'appName': 'Facebook'},
    {'packageName': 'com.twitter.android', 'appName': 'Twitter'},
    {'packageName': 'com.zhiliaoapp.musically', 'appName': 'TikTok'},
    {'packageName': 'com.youtube.android', 'appName': 'YouTube'},
    {'packageName': 'com.snapchat.android', 'appName': 'Snapchat'},
    {'packageName': 'com.discord', 'appName': 'Discord'},
    {'packageName': 'com.reddit.frontpage', 'appName': 'Reddit'},
    {'packageName': 'com.whatsapp', 'appName': 'WhatsApp'},
    {'packageName': 'org.telegram.messenger', 'appName': 'Telegram'},
    {'packageName': 'com.android.chrome', 'appName': 'Chrome'},
    {'packageName': 'com.android.settings', 'appName': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    
    // Use predefined apps list instead of DeviceApps
    final apps = _PREDEFINED_APPS
        .map((app) => _MockApplication(
          packageName: app['packageName']!,
          appName: app['appName']!,
        ))
        .toList();

    if (mounted) {
      final petProvider = context.read<PetProvider>();
      _selectedPackages.clear();
      _selectedPackages.addAll(petProvider.distractingApps);
    }

    apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    if (mounted) {
      setState(() {
        _allApps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
    }
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      _filteredApps = _allApps
          .where((app) =>
              app.appName.toLowerCase().contains(query.toLowerCase()) ||
              app.packageName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps Distractoras'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar aplicación...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: _filterApps,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredApps.length,
              itemBuilder: (context, index) {
                final app = _filteredApps[index];
                final isSelected = _selectedPackages.contains(app.packageName);
                
                return CheckboxListTile(
                  value: isSelected,
                  title: Text(app.appName),
                  subtitle: Text(app.packageName),
                  secondary: const Icon(Icons.android),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedPackages.add(app.packageName);
                      } else {
                        _selectedPackages.remove(app.packageName);
                      }
                    });
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.read<PetProvider>().updateDistractingApps(_selectedPackages);
          if (mounted) Navigator.pop(context);
        },
        label: const Text('Guardar Selección'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
