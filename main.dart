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
import 'screens/private_maps_screen.dart';
import 'screens/exploration_screen.dart';
import 'services/preferences_service.dart';
import 'services/community_service.dart';
import 'services/database_service.dart';
import 'services/photo_service.dart';
import 'services/lifecycle_service.dart';
import 'screens/premium_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StartupGate());
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});
  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<void> ready = initialize();
  Future<void> initialize() async {
    await PreferencesService.instance.load();
    await CommunityService.instance.load();
    await DatabaseService.instance.database;
    try {
      await PhotoService.recoverLost();
    } catch (_) {
      /* Retry remains available in the editor. */
    }
    unawaited(PhotoService.sweep().catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: ready,
    builder: (context, state) {
      if (state.connectionState == ConnectionState.done && !state.hasError)
        return const WildTrackApp();
      return MaterialApp(
        theme: wildTrackTheme(Brightness.light),
        debugShowCheckedModeBanner: false,
        home: PremiumScaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: state.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_off_outlined, size: 46),
                          const SizedBox(height: 20),
                          const Text(
                            'Impossibile aprire gli archivi. I dati esistenti sono conservati. Non cancellare i dati dell’app.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () =>
                                setState(() => ready = initialize()),
                            child: const Text('Riprova'),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 24),
                          Text('WildTrack'),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    },
  );
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PreferencesService.instance,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WildTrack',
      navigatorObservers: [wildTrackRoutes],
      theme: wildTrackTheme(Brightness.light),
      darkTheme: wildTrackTheme(Brightness.dark),
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

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  late final tabs = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  int index = 0;
  final pages = const [
    MapScreen(),
    SpeciesScreen(),
    CommunityScreen(),
    GuideScreen(),
    MoreScreen(),
  ];
  @override
  Widget build(BuildContext context) => PremiumScaffold(
    body: FadeTransition(
      opacity: tabs.drive(Tween(begin: .4, end: 1.0)),
      child: IndexedStack(
        index: index,
        children: [
          for (var i = 0; i < pages.length; i++)
            TickerMode(enabled: i == index, child: pages[i]),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        if (i == index) return;
        setState(() => index = i);
        if (!MediaQuery.disableAnimationsOf(context)) tabs.forward(from: 0);
      },
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
  Widget build(BuildContext context) => PremiumScaffold(
    appBar: AppBar(title: const Text('WildTrack')),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const PremiumHeading(
          'Il tuo mondo\noutdoor.',
          eyebrow: 'Tutti gli strumenti',
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            for (final item in <(String, IconData, Widget)>[
              (
                'Registra percorso',
                Icons.radio_button_checked,
                const RecordScreen(),
              ),
              ('Italia e itinerari', Icons.hiking, const ExplorationScreen()),
              ('Mappe private', Icons.lock_outline, const PrivateMapsScreen()),
              ('Percorsi salvati', Icons.route, const RoutesScreen()),
              ('Taccuino offline', Icons.bookmark, const SightingsScreen()),
              ('Statistiche', Icons.bar_chart, const StatsScreen()),
              ('Impostazioni', Icons.settings, const SettingsScreen()),
            ])
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(21),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => item.$3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          item.$2,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Flexible(
                          child: Text(
                            item.$1,
                            maxLines: 3,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
