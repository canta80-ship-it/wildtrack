import 'outing_preparation_screen.dart';
import 'return_point_screen.dart';
import 'dart:async';
import 'radar_panel_widget.dart';
import 'diary_metric_screen.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/sighting.dart';
import '../models/track_session.dart';
import '../premium_ui.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../services/radar_service.dart';
import '../services/solar_context_service.dart';
import 'outing_diary_screen.dart';
import 'premium_explore_screen.dart';
import 'premium_sighting_screen.dart';
import 'record_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'species_screen.dart';
import 'premium_animal_screen.dart';
import 'did_you_know_widget.dart';
import 'sos_screen.dart';

class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({super.key});

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen> with WidgetsBindingObserver {
  Timer? _radarTimer;
  Timer? _clockTimer;
  bool _radarBusy = false;
  late Future<RadarSnapshot> radar;
  List<Sighting> sightings = [];
  List<TrackSession> sessions = [];

  TrackSession? get lastSession => sessions.isEmpty ? null : sessions.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _radarTimer = Timer.periodic(const Duration(minutes: 2), (_) { if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) unawaited(_refresh()); });
    radar = RadarService.instance.load();
    DatabaseService.instance.changes.addListener(_onDatabaseChanged);
    _reloadLocal();
    _scheduleClockTick();
  }

  void _scheduleClockTick() {
    _clockTimer?.cancel();
    final now = DateTime.now();
    _clockTimer = Timer(Duration(milliseconds: 60000 - now.second * 1000 - now.millisecond), () {
      if (!mounted) return;
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        setState(() {});
        _scheduleClockTick();
      }
    });
  }

  @override
  void dispose() {
    DatabaseService.instance.changes.removeListener(_onDatabaseChanged);
    _radarTimer?.cancel();
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onDatabaseChanged() { unawaited(_refresh()); }

  Future<void> _reloadLocal() async {
    final values = await Future.wait<dynamic>([
      DatabaseService.instance.getSightings(),
      DatabaseService.instance.getSessions(),
    ]);
    if (!mounted) return;
    setState(() {
      sightings = values[0] as List<Sighting>;
      sessions = values[1] as List<TrackSession>;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleClockTick();
      unawaited(_refresh());
    } else {
      _clockTimer?.cancel();
    }
  }

  Future<void> _refresh() async {
    if (_radarBusy || !mounted) return;
    _radarBusy = true;
    try {
    final next = RadarService.instance.load();
    setState(() => radar = next);
    await Future.wait([next, _reloadLocal()]);
    } catch (_) { } finally { _radarBusy = false; }
  }

  void _openLastOuting() {
    final s = lastSession;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            s == null ? const StatsScreen() : OutingDiaryScreen(session: s),
      ),
    );
  }

  String _duration(TrackSession s) {
    final d = s.endedAt.difference(s.startedAt);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    final saved = PreferencesService.instance.nickname.trim();
    final nickname = saved.isEmpty ? 'Esploratore' : saved;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5ED),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<RadarSnapshot>(
          future: radar,
          builder: (context, radarSnapshot) {
            final data = radarSnapshot.data;
            final now = DateTime.now();
            final freshPosition = data?.hasPosition == true && data?.generatedAt != null && now.difference(data!.generatedAt!).abs() <= const Duration(minutes: 5);
            final sun = freshPosition && data?.latitude != null && data?.longitude != null
                ? SolarContext.at(now, data!.latitude!, data.longitude!)
                : null;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PremiumHomeHero(
                    nickname: nickname,
                    activity: data?.activity ?? 'IN AGGIORNAMENTO',
                    phase: sun?.label ?? 'Fase solare non disponibile',
                    phaseCode: sun?.phase,
                    clockTime: now,
                    hasPosition: freshPosition,
                    temperature: data?.temperature,
                    onBell: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ActionRow(
                          onExplore: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PremiumExploreScreen(),
                            ),
                          ),
                          onSighting: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PremiumSightingScreen(),
                            ),
                          ),
                          onTrack: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const RecordScreen(),
                            ),
                          ),
                      ),
                      const SizedBox(height: 18),
                      Card(child: ListTile(leading: const Icon(Icons.checklist_rtl), title: const Text('Prepara l’uscita'), subtitle: const Text('Checklist per specie, stagione e attività'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OutingPreparationScreen())))),
                      Card(child: ListTile(leading: const Icon(Icons.near_me_outlined), title: const Text('Torna al mio punto'), subtitle: const Text('Salva auto, bivio o postazione'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ReturnPointScreen())))),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Catalogo animali',
                        action: 'Vedi tutte',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SpeciesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      RadarPanel(snapshot: data, onRefresh: _refresh, loading: radarSnapshot.connectionState == ConnectionState.waiting, error: radarSnapshot.hasError),
                      const SizedBox(height: 14),
                      const DidYouKnowCarousel(),
                      const SizedBox(height: 14),
                      _SectionHeader(
                        title: 'Ultima uscita',
                        action: 'Vedi dettagli',
                        onTap: _openLastOuting,
                      ),
                      const SizedBox(height: 8),
                      _LastOutingCard(
                        session: lastSession,
                        duration: lastSession == null
                            ? null
                            : _duration(lastSession!),
                        onTap: _openLastOuting,
                      ),
                      const SizedBox(height: 14),
                      _SectionHeader(
                        title: 'Il tuo diario',
                        action: 'Vedi tutto',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const StatsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DiaryCard(
                              icon: Icons.eco_outlined,
                              label: 'Specie uniche',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const DiaryMetricScreen(
                                    metric: DiaryMetric.species,
                                  ),
                                ),
                              ),
                              value:
                                  '${sightings.map((e) => e.species).where((e) => e.isNotEmpty && e != 'Specie non identificata').toSet().length}',
                              tint: const Color(0xFFE7F0E1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DiaryCard(
                              icon: Icons.schedule_outlined,
                              label: 'Tempo sul campo',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const DiaryMetricScreen(
                                    metric: DiaryMetric.time,
                                  ),
                                ),
                              ),
                              value:
                                  '${sessions.fold<int>(0, (sum, s) => sum + s.endedAt.difference(s.startedAt).inMinutes) ~/ 60} h',
                              tint: const Color(0xFFF3E7D5),
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PremiumHomeHero extends StatelessWidget {
  const PremiumHomeHero({
    required this.nickname,
    required this.activity,
    required this.onBell,
    this.temperature,
    required this.phase, required this.hasPosition,
    this.phaseCode, this.clockTime,
  });
  final String nickname;
  final String activity;
  final String phase;
  final String? phaseCode;
  final DateTime? clockTime;
  final bool hasPosition;
  final double? temperature;
  final VoidCallback onBell;

  static String greeting(DateTime now) => now.hour >= 5 && now.hour < 12 ? 'Buongiorno' : now.hour >= 12 && now.hour < 18 ? 'Buon pomeriggio' : 'Buonasera';
  static IconData phaseIcon(String? phase) => switch (phase) {
    'day' => Icons.wb_sunny_outlined,
    'dawn' || 'dusk' => Icons.wb_twilight_outlined,
    'night' => Icons.nightlight_round,
    _ => Icons.help_outline,
  };
  static Color phaseColor(String? phase) => switch (phase) {
    'day' => const Color(0xFFEEC16A),
    'dawn' || 'dusk' => const Color(0xFFF0AA74),
    'night' => const Color(0xFFB9D8F3),
    _ => const Color(0xFFD5D9D5),
  };

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('home-hero'),
    constraints: const BoxConstraints(minHeight: 270),
    child: Stack(children: [
      Positioned.fill(child: Image.asset('assets/approved/access_land2.jpg', fit: BoxFit.cover, filterQuality: FilterQuality.high)),
      const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x12FFFFFF), Color(0xAD102619)])))),
      SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Align(alignment: Alignment.centerLeft, child: FittedBox(fit: BoxFit.scaleDown, child: WildLogo(compact: true)))),
            IconButton.filledTonal(onPressed: onBell, tooltip: 'Impostazioni', icon: const Icon(Icons.settings_outlined, color: WildColors.forest)),
            const SizedBox(width: 6),
            Semantics(button: true, label: 'SOS · Emergenza', child: Material(color: const Color(0xFF9F3F32), shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SosScreen())), child: const SizedBox(width: 44, height: 44, child: Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))))))),
          ]),
          const SizedBox(height: 22),
          Text('${greeting(clockTime ?? DateTime.now())},\n$nickname', style: const TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 27, height: 1.08, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.location_on, color: Colors.white, size: 19), const SizedBox(width: 4), Text(hasPosition ? 'La tua zona' : 'Posizione da acquisire', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _HeroChip(icon: Icons.bar_chart_rounded, iconColor: const Color(0xFF94D571), text: 'Condizioni: $activity', fill: WildColors.forest)),
            const SizedBox(width: 8),
            Expanded(child: _HeroChip(icon: phaseIcon(phaseCode), iconColor: phaseColor(phaseCode), text: temperature == null ? phase : '${temperature!.toStringAsFixed(0)}° · $phase', fill: const Color(0x805C5847))),
          ]),
        ]),
      )),
    ]),
  );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.fill,
  });
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color fill;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 40),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white38),
    ),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 23),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              height: 1.1,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onExplore,
    required this.onSighting,
    required this.onTrack,
  });
  final VoidCallback onExplore;
  final VoidCallback onSighting;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ActionCard(
            key: const ValueKey('home-action-explore'),
            icon: Icons.map_outlined,
            title: 'Esplora zona',
            body: 'Sentieri, punti di interesse e attività fauna',
            tint: const Color(0xFFE6F0E0),
            onTap: onExplore,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionCard(
            key: const ValueKey('home-action-sighting'),
            icon: WildIcons.binoculars,
            title: 'Registra\navvistamento',
            body: 'Aggiungi una specie, foto e posizione',
            tint: const Color(0xFFF4E7D3),
            onTap: onSighting,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionCard(
            key: const ValueKey('home-action-record'),
            icon: Icons.hiking,
            title: 'Avvia uscita',
            body: 'Traccia il percorso e monitora l’attività',
            tint: WildColors.forest,
            dark: true,
            onTap: onTrack,
          ),
        ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.tint,
    required this.onTap,
    this.dark = false,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color tint;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => Material(
    color: tint,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 145),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: dark ? Colors.white12 : Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: dark ? Colors.white : WildColors.forest,
                      size: 25,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: dark ? Colors.white : WildColors.ink,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1,
                  color: dark ? Colors.white : WildColors.ink,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                body,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.15,
                  color: dark ? const Color(0xFFE5EEE6) : WildColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 19,
            height: 1,
            fontWeight: FontWeight.w800,
            color: WildColors.ink,
            letterSpacing: -.6,
          ),
        ),
      ),
      TextButton(
        onPressed: onTap,
        child: Row(
          children: [
            Text(
              action,
              style: const TextStyle(
                color: WildColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: WildColors.muted),
          ],
        ),
      ),
    ],
  );
}

class _LastOutingCard extends StatelessWidget {
  const _LastOutingCard({
    required this.session,
    required this.duration,
    required this.onTap,
  });
  final TrackSession? session;
  final String? duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            height: 112,
            child: Image.asset(
              'assets/approved/outing_scene.jpg',
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: session == null
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nessuna uscita registrata',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Avvia una registrazione GPS per costruire il tuo diario sul campo.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: WildColors.muted,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ultima uscita',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${(session!.distanceMeters / 1000).toStringAsFixed(1)} km   ·   $duration',
                          style: const TextStyle(
                            fontSize: 11,
                            color: WildColors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0E3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.auto_stories_outlined,
                                size: 16,
                                color: WildColors.forest,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Apri diario uscita',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: WildColors.forest,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: WildColors.forest, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: WildColors.muted),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: WildColors.forest),
        ],
      ),
    ),
  );
}
