import 'package:flutter/material.dart';

import '../services/radar_service.dart';
import '../services/database_service.dart';
import '../models/sighting.dart';
import 'exploration_screen.dart';
import 'record_screen.dart';
import 'sightings_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'field_tools_screen.dart';
import '../premium_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<RadarSnapshot> radar;
  List<Sighting> sightings = [];

  @override
  void initState() {
    super.initState();
    radar = RadarService.instance.load();
    _loadSightings();
  }

  Future<void> _loadSightings() async {
    final rows = await DatabaseService.instance.getSightings();
    if (mounted) setState(() => sightings = rows);
  }

  Future<void> refresh() async {
    final next = RadarService.instance.load();
    setState(() => radar = next);
    await Future.wait([next, _loadSightings()]);
  }

  String _assetFor(String name) {
    final value = name.toLowerCase();
    if (value.contains('lupo') || value.contains('volpe')) return 'intro_lupo.jpg';
    if (value.contains('marmotta')) return 'intro_marmotta.jpg';
    if (value.contains('gufo') || value.contains('allocco') || value.contains('poiana')) return 'intro_gufo.jpg';
    return 'intro_cervo.jpg';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: RefreshIndicator(
      onRefresh: refresh,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: WildHero(
            image: 'intro_cervo.jpg',
            height: 360,
            alignment: const Alignment(.15, -.22),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 13, 20, 22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const WildLogo(compact: true, light: true),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.notifications_none, color: Colors.white)),
                    const CircleAvatar(radius: 19, backgroundImage: AssetImage('intro_cervo.jpg')),
                  ]),
                  const Spacer(),
                  const Text('Buongiorno,\nStefano', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 40, height: .92, fontWeight: FontWeight.w700, letterSpacing: -1.2)),
                  const SizedBox(height: 8),
                  const Row(children: [Icon(Icons.location_on, color: Colors.white, size: 20), SizedBox(width: 4), Text('Cansiglio', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))]),
                  const SizedBox(height: 14),
                  FutureBuilder<RadarSnapshot>(
                    future: radar,
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      final activity = data?.activity ?? '…';
                      return Row(children: [
                        Expanded(child: _HeroPill(icon: Icons.bar_chart_rounded, label: 'Attività fauna: $activity', green: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _HeroPill(icon: Icons.wb_twilight_outlined, label: data?.weatherAvailable == true ? '${data!.temperature?.toStringAsFixed(0) ?? '—'}° · alba ideale' : 'Alba ideale per osservazione')),
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
              Expanded(child: _QuickAction(background: const Color(0xFFF4E9D7), icon: Icons.visibility_outlined, title: 'Registra\navvistamento', body: 'Aggiungi una specie, foto e posizione', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SightingEditorScreen())))),
              const SizedBox(width: 9),
              Expanded(child: _QuickAction(background: WildColors.forest, icon: Icons.hiking, title: 'Avvia uscita', body: 'Traccia il percorso e monitora l’attività', dark: true, onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RecordScreen())))),
            ]),
            const SizedBox(height: 24),
            WildSectionTitle('Specie probabili adesso', action: 'Vedi tutte', onAction: refresh),
            const SizedBox(height: 8),
            FutureBuilder<RadarSnapshot>(
              future: radar,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                final rows = snapshot.data!.species;
                return SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 9),
                    itemBuilder: (context, i) {
                      final s = rows[i];
                      return _SpeciesCard(name: s.name, score: s.score, asset: _assetFor(s.name));
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            WildSectionTitle('Ultima uscita', action: 'Vedi dettagli', onAction: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const StatsScreen()))),
            const SizedBox(height: 8),
            WildGlass(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 145,
                child: Row(children: [
                  ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)), child: Image.asset('intro_cervo.jpg', width: 145, height: 145, fit: BoxFit.cover)),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Cansiglio', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Ultima attività registrata', style: TextStyle(fontSize: 11, color: WildColors.muted)),
                      const Spacer(),
                      const Wrap(spacing: 12, runSpacing: 8, children: [
                        _MiniMetric(Icons.route_outlined, '8,4 km'),
                        _MiniMetric(Icons.schedule_outlined, '3 h 12m'),
                        _MiniMetric(Icons.pets_outlined, '6 specie'),
                      ]),
                      const Spacer(),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.workspace_premium, size: 16, color: WildColors.forest), SizedBox(width: 6), Expanded(child: Text('Nuovo lifer: Picchio nero', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))])),
                    ]),
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            WildSectionTitle('Il tuo diario', action: 'Vedi tutto', onAction: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const StatsScreen()))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _DiaryMetric(icon: Icons.eco_outlined, label: 'Specie uniche', value: '${sightings.map((e) => e.species).where((e) => e.isNotEmpty).toSet().length}')),
              const SizedBox(width: 9),
              const Expanded(child: _DiaryMetric(icon: Icons.schedule_outlined, label: 'Tempo sul campo', value: '64 h')),
            ]),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FieldToolsScreen())),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: WildColors.forest, borderRadius: BorderRadius.circular(22)),
                child: const Row(children: [
                  WildIconDisc(Icons.auto_awesome_outlined, size: 48, background: Color(0x22FFFFFF), foreground: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Esplora+', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Missioni, biodiversità, passaporto, modalità fotografica e timeline.', style: TextStyle(color: Color(0xFFD7E2D8), fontSize: 10)),
                  ])),
                  Icon(Icons.chevron_right, color: Colors.white),
                ]),
              ),
            ),
          ])),
        ),
      ]),
    ),
  );
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label, this.green = false});
  final IconData icon;
  final String label;
  final bool green;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(color: green ? const Color(0xDD173F2B) : const Color(0x994C463A), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white38)),
    child: Row(children: [Icon(icon, color: green ? const Color(0xFF8BE278) : const Color(0xFFF3C96F), size: 21), const SizedBox(width: 7), Expanded(child: Text(label, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))]),
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
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 175,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WildIconDisc(icon, background: dark ? Colors.white12 : Colors.white54, foreground: dark ? Colors.white : WildColors.forest, size: 44),
          const Spacer(),
          Text(title, style: TextStyle(fontFamily: 'serif', color: dark ? Colors.white : WildColors.ink, fontSize: 16, height: 1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, height: 1.25, color: dark ? const Color(0xFFDCE5DD) : WildColors.muted)),
        ]),
      ),
    ),
  );
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({required this.name, required this.score, required this.asset});
  final String name;
  final int score;
  final String asset;
  @override
  Widget build(BuildContext context) => Container(
    width: 135,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 16, offset: Offset(0, 5))]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Image.asset(asset, width: double.infinity, fit: BoxFit.cover)),
        Padding(padding: const EdgeInsets.fromLTRB(11, 9, 11, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text('$score%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: score / 100, minHeight: 6, color: score > 65 ? const Color(0xFF5E9B55) : score > 45 ? const Color(0xFF8EAA63) : WildColors.amber, backgroundColor: const Color(0xFFE8E6DF))),
        ])),
      ]),
    ),
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: WildColors.ink), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11))]);
}

class _DiaryMetric extends StatelessWidget {
  const _DiaryMetric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(19)),
    child: Row(children: [Icon(icon, color: WildColors.forest, size: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: WildColors.muted)), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))])), const Icon(Icons.chevron_right, color: WildColors.forest)]),
  );
}
