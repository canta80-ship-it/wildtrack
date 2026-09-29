import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'screens/record_screen.dart';
import 'screens/routes_screen.dart';
import 'screens/sightings_screen.dart';
import 'screens/stats_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WildTrackApp());
}

class WildTrackApp extends StatelessWidget {
  const WildTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WildTrack',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF415D43),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [
    MapScreen(),
    RecordScreen(),
    SightingsScreen(),
    RoutesScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mappa'),
          NavigationDestination(icon: Icon(Icons.radio_button_checked), label: 'Registra'),
          NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Fauna'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Percorsi'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Dati'),
        ],
      ),
    );
  }
}
