import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/sighting.dart';
import '../models/track_session.dart';
import '../premium_ui.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../services/radar_service.dart';
import 'outing_diary_screen.dart';
import 'premium_explore_screen.dart';
import 'premium_sighting_screen.dart';
import 'record_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'species_screen.dart';
import 'premium_animal_screen.dart';
import 'did_you_know_widget.dart';

class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({super.key});

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen> {
  late Future<RadarSnapshot> radar;
  List<Sighting> sightings = [];
  List<TrackSession> sessions = [];

  TrackSession? get lastSession => sessions.isEmpty ? null : sessions.first;

  @override
  void initState() {
    super.initState();
    radar = RadarService.instance.load();
    DatabaseService.instance.changes.addListener(_reloadLocal);
    _reloadLocal();
  }

  @override
  void dispose() {
    DatabaseService.instance.changes.removeListener(_reloadLocal);
    super.dispose();
  }

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

  Future<void> _refresh() async {
    final next = RadarService.instance.load();
    setState(() => radar = next);
    await Future.wait([next, _reloadLocal()]);
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
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Hero(
                    nickname: nickname,
                    activity: data?.activity ?? 'ALTA',
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
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: _ActionRow(
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
                      ),
                      const SizedBox(height: 4),
                      _SectionHeader(
                        title: 'Specie probabili adesso',
                        action: 'Vedi tutte',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SpeciesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SpeciesStrip(snapshot: data),
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.nickname,
    required this.activity,
    required this.onBell,
    this.temperature,
  });
  final String nickname;
  final String activity;
  final double? temperature;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 238,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/approved/access_land2.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x10FFFFFF),
                  Color(0x12000000),
                  Color(0x7F102619),
                ],
                stops: [0, .55, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const WildLogo(compact: true),
                      const Spacer(),
                      IconButton(
                        onPressed: onBell,
                        tooltip: 'Impostazioni',
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: WildColors.forest,
                          size: 28,
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/approved/access_land2.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Buongiorno,\n$nickname',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white,
                      fontSize: 30,
                      height: .92,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      shadows: [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 21),
                      SizedBox(width: 5),
                      Text(
                        'La tua zona',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroChip(
                          icon: Icons.bar_chart_rounded,
                          iconColor: const Color(0xFF8DE67D),
                          text: 'Attività fauna: ${activity.toUpperCase()}',
                          fill: const Color(0xE51A4B35),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroChip(
                          icon: Icons.wb_twilight_outlined,
                          iconColor: const Color(0xFFFFC65C),
                          text: temperature == null
                              ? 'Alba ideale\nper osservazione'
                              : '${temperature!.round()}° · alba ideale',
                          fill: const Color(0xA34B453A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 14),
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
            maxLines: 2,
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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ActionCard(
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
          icon: Icons.hiking,
          title: 'Avvia uscita',
          body: 'Traccia il percorso e monitora l’attività',
          tint: WildColors.forest,
          dark: true,
          onTap: onTrack,
        ),
      ),
    ],
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
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
      child: SizedBox(
        height: 123,
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
              const Spacer(),
              Text(
                title,
                maxLines: 2,
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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

class _SpeciesStrip extends StatelessWidget {
  const _SpeciesStrip({required this.snapshot});
  final RadarSnapshot? snapshot;

  int _score(String name, int fallback) {
    final rows = snapshot?.species ?? const [];
    for (final row in rows) {
      if (row.name.toLowerCase() == name.toLowerCase()) return row.score;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Cervo', _score('Cervo', 82), 'assets/approved/cervo_thumb.jpg'),
      (
        'Capriolo',
        _score('Capriolo', 64),
        'assets/approved/capriolo_thumb.jpg',
      ),
      ('Volpe', _score('Volpe', 41), 'assets/approved/volpe_thumb.jpg'),
      ('Poiana', _score('Poiana', 37), 'assets/approved/poiana_thumb.jpg'),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: _SpeciesCard(
              name: items[i].$1,
              score: items[i].$2,
              asset: items[i].$3,
            ),
          ),
        ],
      ],
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({
    required this.name,
    required this.score,
    required this.asset,
  });
  final String name;
  final int score;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final bar = score >= 60 ? const Color(0xFF62A958) : const Color(0xFFB98233);
    return Semantics(
      button: true,
      label: 'Apri scheda $name',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PremiumAnimalScreen(
              animals.firstWhere((animal) => animal.name == name),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCF7),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  height: 73,
                  width: double.infinity,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                '$score%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 6,
                  color: bar,
                  backgroundColor: const Color(0xFFE2E0D9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
      height: 112,
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
              fit: BoxFit.cover,
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
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
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
  );
}
