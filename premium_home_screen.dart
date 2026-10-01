import 'package:flutter/material.dart';

import '../services/radar_service.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../models/sighting.dart';
import '../models/track_session.dart';
import '../premium_ui.dart';
import 'book_widget.dart';
import 'premium_explore_screen.dart';
import 'record_screen.dart';
import 'premium_sighting_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'outing_diary_screen.dart';

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
    final results = await Future.wait<dynamic>([
      DatabaseService.instance.getSightings(),
      DatabaseService.instance.getSessions(),
    ]);
    if (!mounted) return;
    setState(() {
      sightings = results[0] as List<Sighting>;
      sessions = results[1] as List<TrackSession>;
    });
  }

  Future<void> refresh() async {
    final next = RadarService.instance.load();
    setState(() => radar = next);
    await Future.wait([next, _reloadLocal()]);
  }

  String _duration(TrackSession s) {
    final d = s.endedAt.difference(s.startedAt);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  void _openLastOuting() {
    final session = lastSession;
    if (session == null) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const StatsScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OutingDiaryScreen(session: session)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nickname = PreferencesService.instance.nickname.trim().isEmpty
        ? 'Esploratore'
        : PreferencesService.instance.nickname.trim();

    return Scaffold(
      backgroundColor: WildColors.ivory,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BookHero(
                asset: 'intro_cervo.jpg',
                height: 355,
                alignment: Alignment.center,
                bottomStrength: .66,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const WildLogo(compact: true, light: true),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
                              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white70, width: 1.3),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: const BookPhoto(asset: 'intro_cervo.jpg', alignment: Alignment.topCenter),
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
                            fontSize: 42,
                            height: .91,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white, size: 20),
                            SizedBox(width: 4),
                            Text('La tua zona', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FutureBuilder<RadarSnapshot>(
                          future: radar,
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            final activity = data?.activity ?? '…';
                            return Row(
                              children: [
                                Expanded(child: _HeroPill(icon: Icons.bar_chart_rounded, label: 'Attività fauna: $activity', green: true)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _HeroPill(
                                    icon: Icons.wb_twilight_outlined,
                                    label: data?.weatherAvailable == true
                                        ? '${data!.temperature?.toStringAsFixed(0) ?? '—'}° · alba ideale'
                                        : 'Condizioni locali',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          background: WildColors.sageSoft,
                          icon: Icons.map_outlined,
                          title: 'Esplora zona',
                          body: 'Sentieri, punti di interesse e attività fauna',
                          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PremiumExploreScreen())),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          background: const Color(0xFFF4E9D7),
                          icon: Icons.visibility_outlined,
                          title: 'Registra\navvistamento',
                          body: 'Aggiungi una specie, foto e posizione',
                          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PremiumSightingScreen())),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          background: WildColors.forest,
                          icon: Icons.hiking,
                          title: 'Avvia uscita',
                          body: 'Traccia il percorso e monitora l’attività',
                          dark: true,
                          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RecordScreen())),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const BookSectionTitle('Specie probabili adesso'),
                  const SizedBox(height: 10),
                  FutureBuilder<RadarSnapshot>(
                    future: radar,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const SizedBox(height: 160, child: Center(child: Text('Radar temporaneamente non disponibile')));
                      }
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
                      }
                      final rows = snapshot.data!.species.take(8).toList();
                      return SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 9),
                          itemBuilder: (_, i) => _SpeciesCard(name: rows[i].name, score: rows[i].score),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  BookSectionTitle(
                    'Ultima uscita',
                    action: lastSession == null ? 'Diario' : 'Vedi dettagli',
                    onAction: _openLastOuting,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _openLastOuting,
                    child: BookCard(
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        height: 145,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                              child: const SizedBox(
                                width: 145,
                                height: 145,
                                child: BookPhoto(asset: 'intro_cervo.jpg', alignment: Alignment.center),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: lastSession == null
                                    ? const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Nessuna uscita registrata', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
                                          SizedBox(height: 5),
                                          Text('Avvia una registrazione GPS e costruisci il tuo diario sul campo.', style: TextStyle(fontSize: 11, color: WildColors.muted)),
                                          Spacer(),
                                          Row(children: [Icon(Icons.play_circle_outline, size: 17, color: WildColors.forest), SizedBox(width: 6), Text('Avvia la prima uscita', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: WildColors.forest))]),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Ultima uscita registrata', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 5),
                                          Text('${(lastSession!.distanceMeters / 1000).toStringAsFixed(1)} km · ${_duration(lastSession!)} · +${lastSession!.ascentMeters.toStringAsFixed(0)} m', style: const TextStyle(fontSize: 11, color: WildColors.muted)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                            decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(10)),
                                            child: const Row(children: [Icon(Icons.auto_stories_outlined, size: 16, color: WildColors.forest), SizedBox(width: 6), Expanded(child: Text('Apri riepilogo e note dell’uscita', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))]),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BookSectionTitle(
                    'Il tuo diario',
                    action: 'Vedi tutto',
                    onAction: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const StatsScreen())),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DiaryMetric(
                          icon: Icons.eco_outlined,
                          label: 'Specie uniche',
                          value: '${sightings.map((e) => e.species).where((e) => e.isNotEmpty && e != 'Specie non identificata').toSet().length}',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: _DiaryMetric(icon: Icons.schedule_outlined, label: 'Uscite', value: '${sessions.length}')),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label, this.green = false});
  final IconData icon;
  final String label;
  final bool green;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: green ? const Color(0xE0173F2B) : const Color(0xA64C463A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white38),
        ),
        child: Row(
          children: [
            Icon(icon, color: green ? const Color(0xFF8BE278) : const Color(0xFFF3C96F), size: 21),
            const SizedBox(width: 7),
            Expanded(child: Text(label, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.background, required this.icon, required this.title, required this.body, required this.onTap, this.dark = false});
  final Color background;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            height: 176,
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: dark ? Colors.white12 : Colors.white60, shape: BoxShape.circle),
                  child: Icon(icon, color: dark ? Colors.white : WildColors.forest),
                ),
                const Spacer(),
                Text(title, style: TextStyle(fontFamily: 'serif', color: dark ? Colors.white : WildColors.ink, fontSize: 17, height: 1, fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, height: 1.25, color: dark ? const Color(0xFFDCE5DD) : WildColors.muted)),
              ],
            ),
          ),
        ),
      );
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({required this.name, required this.score});
  final String name;
  final int score;

  @override
  Widget build(BuildContext context) => Container(
        width: 142,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookAnimalThumb(name, width: 126, height: 116),
            const SizedBox(height: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text('$score%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                color: score > 65 ? const Color(0xFF5E9B55) : score > 45 ? const Color(0xFF8EAA63) : WildColors.amber,
                backgroundColor: const Color(0xFFE8E6DF),
              ),
            ),
          ],
        ),
      );
}

class _DiaryMetric extends StatelessWidget {
  const _DiaryMetric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => BookCard(
        tint: WildColors.sageSoft,
        child: Row(
          children: [
            Icon(icon, color: WildColors.forest, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: WildColors.muted)),
                  Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: WildColors.forest),
          ],
        ),
      );
}
