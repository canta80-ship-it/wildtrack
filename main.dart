import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/map_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/record_screen.dart';
import 'screens/routes_screen.dart';
import 'screens/sightings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/species_screen.dart';
import 'screens/community_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/guide_screen.dart';
import 'services/preferences_service.dart';
import 'services/community_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService.instance.load();
  await CommunityService.instance.load();
  runApp(const WildTrackApp());
}

class WildTrackApp extends StatefulWidget {
  const WildTrackApp({super.key});
  @override
  State<WildTrackApp> createState() => _WildTrackAppState();
}

class _WildTrackAppState extends State<WildTrackApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CommunityService.instance.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(CommunityService.instance.pause());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      CommunityService.instance.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(AudioService.instance.stop());
      unawaited(CommunityService.instance.pause());
    }
  }

  ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF405D36),
          brightness: brightness,
        ).copyWith(
          surface: dark ? const Color(0xFF17251B) : const Color(0xFFCCD5B5),
          surfaceContainerLow: dark
              ? const Color(0xFF213225)
              : const Color(0xFFD8DFC6),
          primary: dark ? const Color(0xFFB4CD91) : const Color(0xFF29452E),
          onSurface: dark ? const Color(0xFFE5EBDC) : const Color(0xFF1A2A1B),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(color: scheme.surfaceContainerLow, elevation: 0),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PreferencesService.instance,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WildTrack',
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: PreferencesService.instance.theme,
      home: const IntroScreen(home: HomeShell()),
    ),
  );
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
    SpeciesScreen(),
    CommunityScreen(),
    GuideScreen(),
    MoreScreen(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mappa'),
        NavigationDestination(icon: Icon(Icons.pets_outlined), label: 'Specie'),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: 'Comunità',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          label: 'Guida',
        ),
        NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Altro'),
      ],
    ),
  );
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('WildTrack')),
    body: ListView(
      children: [
        for (final item in <(String, IconData, Widget)>[
          (
            'Registra percorso',
            Icons.radio_button_checked,
            const RecordScreen(),
          ),
          ('Percorsi salvati', Icons.route, const RoutesScreen()),
          (
            'Taccuino offline e posizioni da completare',
            Icons.bookmark,
            const SightingsScreen(),
          ),
          ('Statistiche', Icons.bar_chart, const StatsScreen()),
          ('Impostazioni', Icons.settings, const SettingsScreen()),
        ])
          ListTile(
            leading: Icon(item.$2),
            title: Text(item.$1),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => item.$3),
            ),
          ),
      ],
    ),
  );
}
