import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/cupertino.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/intro_screen.dart';
import 'screens/session_gate_screen.dart';
import 'screens/premium_home_screen.dart';
import 'screens/premium_sighting_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/premium_community_screen.dart';
import 'screens/community_screen.dart' show ChatScreen;
import 'services/preferences_service.dart';
import 'services/community_service.dart';
import 'services/push_service.dart';
import 'services/backup_service.dart';
import 'screens/species_screen.dart';
import 'premium_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');
  Intl.defaultLocale = 'it_IT';
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
    unawaited(PushService.instance.initialize());
    unawaited(_safeAutoBackup());
  }

  Future<void> _safeAutoBackup() async {
    try {
      await WildTrackBackupService.instance.autoBackupIfDue();
    } catch (_) {}
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
      unawaited(PushService.instance.syncPreferences());
      unawaited(PushService.instance.consumeNativeChat());
      unawaited(_safeAutoBackup());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(AudioService.instance.stop());
      unawaited(CommunityService.instance.pause());
      unawaited(_safeAutoBackup());
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PreferencesService.instance,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WildTrack',
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: wildTrackTheme(Brightness.light),
      darkTheme: wildTrackTheme(Brightness.dark),
      themeMode: PreferencesService.instance.theme,
      home: const SessionGate(
        home: HomeShell(),
        welcome: IntroScreen(home: HomeShell()),
      ),
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
  @override
  void initState() {
    super.initState();
    PushService.instance.addListener(_openNotificationChat);
    _openNotificationChat();
  }
  @override
  void dispose() {
    PushService.instance.removeListener(_openNotificationChat);
    super.dispose();
  }
  void _openNotificationChat() {
    final chat = PushService.instance.pendingChat;
    if (chat == null) return;
    PushService.instance.pendingChat = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(peer: chat['peer']!, nickname: chat['nickname']!)));
    });
  }
  final pages = const [
    PremiumHomeScreen(),
    PremiumSightingScreen(),
    StatsScreen(),
    PremiumCommunityScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: SafeArea(
      minimum: EdgeInsets.zero,
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .97),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 28,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.explore_outlined,
              selected: Icons.explore,
              label: 'Esplora',
              active: index == 0,
              onTap: () => setState(() => index = 0),
            ),
            _NavItem(
              icon: WildIcons.binoculars,
              selected: WildIcons.binoculars,
              label: 'Avvista',
              active: index == 1,
              emphasized: true,
              onTap: () => setState(() => index = 1),
            ),
            _NavItem(
              icon: Icons.menu_book_outlined,
              selected: Icons.menu_book,
              label: 'Diario',
              active: index == 2,
              onTap: () => setState(() => index = 2),
            ),
            _NavItem(
              icon: Icons.groups_outlined,
              selected: Icons.groups,
              label: 'Community',
              active: index == 3,
              onTap: () => setState(() => index = 3),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.label,
    required this.active,
    required this.onTap,
    this.emphasized = false,
  });
  final IconData icon;
  final IconData selected;
  final String label;
  final bool active;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: emphasized && active ? 44 : 36,
            height: emphasized && active ? 45 : 34,
            decoration: BoxDecoration(
              color: active
                  ? (emphasized ? WildColors.forest : WildColors.sageSoft)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              active ? selected : icon,
              color: active && emphasized
                  ? Colors.white
                  : active
                  ? WildColors.forest
                  : const Color(0xFF333833),
              size: emphasized && active ? 26 : 23,
            ),
          ),
          ...[
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? WildColors.forest : const Color(0xFF333833),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

ThemeData wildTrackTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: WildColors.forest,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFFB8D1AE) : WildColors.forest,
        onPrimary: dark ? WildColors.ink : Colors.white,
        surface: dark ? const Color(0xFF142018) : WildColors.ivory,
        surfaceContainerLow: dark
            ? const Color(0xFF202D24)
            : const Color(0xFFFFFEFA),
        surfaceContainer: dark ? const Color(0xFF26342A) : WildColors.sage,
        onSurface: dark ? const Color(0xFFEAF0E7) : WildColors.ink,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'sans-serif',
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'serif',
        color: scheme.onSurface,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF202D24) : const Color(0xFFFFFEFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x16000000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: dark ? Colors.white12 : const Color(0x18000000),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WildColors.forest,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? WildColors.forest2 : null,
      ),
    ),
    dividerColor: const Color(0x18000000),
  );
}
