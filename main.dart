import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/intro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sightings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/community_screen.dart';
import 'services/preferences_service.dart';
import 'services/community_service.dart';
import 'screens/species_screen.dart';

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
    const forest = Color(0xFF254D38);
    const sage = Color(0xFFDDE8DA);
    const ivory = Color(0xFFF8F6EF);
    const ink = Color(0xFF203126);
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFFB8D1AE) : forest,
      onPrimary: dark ? const Color(0xFF17301F) : Colors.white,
      surface: dark ? const Color(0xFF152019) : ivory,
      surfaceContainerLow: dark ? const Color(0xFF202D24) : const Color(0xFFF3F0E7),
      surfaceContainer: dark ? const Color(0xFF26342A) : sage,
      onSurface: dark ? const Color(0xFFE7EDE5) : ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 23,
          fontWeight: FontWeight.w700,
          letterSpacing: -.4,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: dark ? const Color(0xFF365543) : sage,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        )),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 1.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
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
    HomeScreen(),
    SightingsScreen(),
    StatsScreen(),
    CommunityScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Esplora'),
        NavigationDestination(icon: Icon(Icons.add_a_photo_outlined), selectedIcon: Icon(Icons.add_a_photo), label: 'Avvista'),
        NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Diario'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Community'),
      ],
    ),
  );
}
