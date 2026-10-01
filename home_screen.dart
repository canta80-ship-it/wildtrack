import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/radar_service.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../models/sighting.dart';
import '../models/track_session.dart';
import 'exploration_screen.dart';
import 'record_screen.dart';
import 'sightings_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'field_tools_screen.dart';
import 'did_you_know_widget.dart';
import 'outing_diary_screen.dart';
import '../premium_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> _showAllRadar() async {
    final snapshot = await radar;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: WildColors.ivory,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Specie probabili adesso', style: WildText.h1),
            const SizedBox(height: 6),
            const Text('Stima indicativa, non certezza di presenza.', style: TextStyle(color: WildColors.muted)),
            const SizedBox(height: 12),
            Flexible(child: ListView.separated(
              shrinkWrap: true,
              itemCount: snapshot.species.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = snapshot.species[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    WildAnimalIllustration(s.name, size: 58),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.name, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800))),
                    Text('${s.score}%', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: WildColors.forest)),
                  ]),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  void _openLastOuting() {
    final s = lastSession;
    if (s == null) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const StatsScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OutingDiaryScreen(session: s)));
    }
  }

  String _duration(TrackSession s) {
    final d = s.endedAt.difference(s.startedAt);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    final nickname = PreferencesService.instance.nickname.trim().isEmpty ? 'Esploratore' : PreferencesService.instance.nickname.trim();
    return Scaffold(
      backgroundColor: WildColors.ivory,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: WildHero(
              image: '',
              height: 360,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 13, 20, 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const WildLogo(compact: true, light: true),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.notifications_none, color: Colors.white)),
                      Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .18), border: Border.all(color: Colors.white54)), child: const Icon(Icons.person_outline, color: Colors.white)),
                    ]),
                    const Spacer(),
                    Text('Buongiorno,\n$nickname', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 40, height: .92, fontWeight: FontWeight.w700, letterSpacing: -1.2)),
                    const SizedBox(height: 8),
                    const Row(children: [Icon(Icons.location_on, color: Colors.white, size: 20), SizedBox(width: 4), Text('La tua zona', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))]),
                    const SizedBox(height: 14),
                    FutureBuilder<RadarSnapshot>(
                      future: radar,
                      builder: (context, snapshot) {
                        final data = snapshot.data;
                        final activity = data?.activity ?? '…';
                        return Row(children: [
                          Expanded(child: _HeroPill(icon: Icons.bar_chart_rounded, label: 'Attività fauna: $activity', green: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _HeroPill(icon: Icons.wb_twilight_outlined, label: data?.weatherAvailable == true ? '${data!.temperature?.toStringAsFixed(0) ?? '—'}° · ${data.habitat}' : 'Condizioni locali in calcolo')),
                        ]);
                      },
                    ),
                  ]),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            sliver: SliverList(delegate: SliverChildListDelegate([
              Row(children: [
                Expanded(child: _QuickAction(background: WildColors.sageSoft, icon: Icons.map_outlined, title: 'Esplora zona', body: 'Sentieri, punti di interesse e attività fauna', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ExplorationScreen())))),
                const SizedBox(width: 9),
                Expanded(child: _QuickAction(background: const Color(0xFFF4E9D7), icon: WildIcons.binoculars, title: 'Registra\navvistamento', body: 'Aggiungi una specie, foto e posizione', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SightingEditorScreen())))),
                const SizedBox(width: 9),
                Expanded(child: _QuickAction(background: WildColors.forest, icon: Icons.hiking, title: 'Avvia uscita', body: 'Traccia il percorso e monitora l’attività', dark: true, onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RecordScreen())))),
              ]),
              const SizedBox(height: 24),
              WildSectionTitle('Specie probabili adesso', action: 'Vedi tutte', onAction: _showAllRadar),
              const SizedBox(height: 8),
              FutureBuilder<RadarSnapshot>(
                future: radar,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const SizedBox(height: 120, child: Center(child: Text('Radar temporaneamente non disponibile')));
                  if (!snapshot.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                  final rows = snapshot.data!.species.take(8).toList();
                  return SizedBox(
                    height: 202,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 9),
                      itemBuilder: (context, i) => _SpeciesCard(name: rows[i].name, score: rows[i].score, confidence: rows[i].confidence),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const DidYouKnowCarousel(),
              const SizedBox(height: 24),
              WildSectionTitle('Ultima uscita', action: lastSession == null ? 'Diario' : 'Vedi dettagli', onAction: _openLastOuting),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _openLastOuting,
                child: WildGlass(
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: 145,
                    child: Row(children: [
                      const ClipRRect(borderRadius: BorderRadius.horizontal(left: Radius.circular(24)), child: SizedBox(width: 145, height: 145, child: WildLandscape(height: 145, animal: 'Cervo'))),
                      Expanded(child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: lastSession == null
                            ? const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Nessuna uscita registrata', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
                                SizedBox(height: 5),
                                Text('Avvia una registrazione GPS: qui troverai il riepilogo dell’ultima attività.', style: TextStyle(fontSize: 11, color: WildColors.muted)),
                                Spacer(),
                                Row(children: [Icon(Icons.play_circle_outline, size: 17, color: WildColors.forest), SizedBox(width: 6), Text('Avvia la prima uscita', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: WildColors.forest))]),
                              ])
                            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Ultima uscita registrata', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text('${(lastSession!.distanceMeters / 1000).toStringAsFixed(1)} km · ${_duration(lastSession!)} · +${lastSession!.ascentMeters.toStringAsFixed(0)} m', style: const TextStyle(fontSize: 11, color: WildColors.muted)),
                                const Spacer(),
                                Wrap(spacing: 10, children: [
                                  _MiniMetric(Icons.route_outlined, '${(lastSession!.distanceMeters / 1000).toStringAsFixed(1)} km'),
                                  _MiniMetric(Icons.schedule_outlined, _duration(lastSession!)),
                                ]),
                                const Spacer(),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.auto_stories_outlined, size: 16, color: WildColors.forest), SizedBox(width: 6), Expanded(child: Text('Apri riepilogo e note dell’uscita', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))])),
                              ]),
                      )),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              WildSectionTitle('Il tuo diario', action: 'Vedi tutto', onAction: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const StatsScreen()))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _DiaryMetric(icon: Icons.eco_outlined, label: 'Specie uniche', value: '${sightings.map((e) => e.species).where((e) => e.isNotEmpty && e != 'Specie non identificata').toSet().length}')),
                const SizedBox(width: 9),
                Expanded(child: _DiaryMetric(icon: Icons.hiking, label: 'Uscite', value: '${sessions.length}')),
              ]),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FieldToolsScreen())),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: WildColors.forest, borderRadius: BorderRadius.circular(22)),
                  child: const Row(children: [WildIconDisc(Icons.auto_awesome_outlined, size: 48, background: Color(0x22FFFFFF), foreground: Colors.white), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Esplora+', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('Missioni, biodiversità, passaporto, fotografia e timeline.', style: TextStyle(color: Color(0xFFD7E2D8), fontSize: 10))])), Icon(Icons.chevron_right, color: Colors.white)]),
                ),
              ),
            ])),
          ),
        ]),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label, this.green = false});
  final IconData icon; final String label; final bool green;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), decoration: BoxDecoration(color: green ? const Color(0xDD173F2B) : const Color(0x994C463A), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white38)), child: Row(children: [Icon(icon, color: green ? const Color(0xFF8BE278) : const Color(0xFFF3C96F), size: 21), const SizedBox(width: 7), Expanded(child: Text(label, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))]));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.background, required this.icon, required this.title, required this.body, required this.onTap, this.dark = false});
  final Color background; final IconData icon; final String title; final String body; final VoidCallback onTap; final bool dark;
  @override
  Widget build(BuildContext context) => Material(color: background, borderRadius: BorderRadius.circular(24), child: InkWell(borderRadius: BorderRadius.circular(24), onTap: onTap, child: Container(height: 175, padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [WildIconDisc(icon, background: dark ? Colors.white12 : Colors.white54, foreground: dark ? Colors.white : WildColors.forest, size: 44), const Spacer(), Text(title, style: TextStyle(fontFamily: 'serif', color: dark ? Colors.white : WildColors.ink, fontSize: 16, height: 1, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, height: 1.25, color: dark ? const Color(0xFFDCE5DD) : WildColors.muted))]))));
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({required this.name, required this.score, required this.confidence});
  final String name; final int score; final int confidence;
  @override
  Widget build(BuildContext context) => Container(width: 142, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 16, offset: Offset(0, 5))]), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Padding(padding: const EdgeInsets.all(8), child: WildAnimalIllustration(name, size: 126))), Padding(padding: const EdgeInsets.fromLTRB(11, 6, 11, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Row(children: [Text('$score%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), const Spacer(), Text('conf. $confidence%', style: const TextStyle(fontSize: 8, color: WildColors.muted))]), const SizedBox(height: 5), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: score / 100, minHeight: 6, color: score > 65 ? const Color(0xFF5E9B55) : score > 45 ? const Color(0xFF8EAA63) : WildColors.amber, backgroundColor: const Color(0xFFE8E6DF)))]))])));
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.icon, this.label); final IconData icon; final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: WildColors.ink), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11))]);
}

class _DiaryMetric extends StatelessWidget {
  const _DiaryMetric({required this.icon, required this.label, required this.value}); final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(19)), child: Row(children: [Icon(icon, color: WildColors.forest, size: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: WildColors.muted)), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))])), const Icon(Icons.chevron_right, color: WildColors.forest)]));
}
