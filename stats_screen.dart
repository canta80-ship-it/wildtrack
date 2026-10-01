import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/sighting.dart';
import '../models/track_session.dart';
import '../services/database_service.dart';
import '../premium_ui.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Sighting> sightings = [];
  List<TrackSession> sessions = [];

  @override
  void initState() {
    super.initState();
    DatabaseService.instance.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    DatabaseService.instance.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final s = await DatabaseService.instance.getSightings();
    final r = await DatabaseService.instance.getSessions();
    if (!mounted) return;
    setState(() { sightings = s; sessions = r; });
  }

  Set<String> get uniqueSpecies => sightings.where((s) => s.species.trim().isNotEmpty && s.species != 'Specie non identificata').map((s) => s.species.trim()).toSet();
  double get distance => sessions.fold(0, (sum, e) => sum + e.distanceMeters);
  Duration get fieldTime => sessions.fold(Duration.zero, (sum, e) => sum + e.endedAt.difference(e.startedAt));

  String get mostObserved {
    if (sightings.isEmpty) return '—';
    final counts = <String, int>{};
    for (final s in sightings) counts[s.species] = (counts[s.species] ?? 0) + s.count;
    final rows = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return rows.first.key;
  }

  List<int> get monthly {
    final now = DateTime.now();
    final out = List.filled(12, 0);
    for (final s in sightings) {
      final age = (now.year - s.timestamp.year) * 12 + now.month - s.timestamp.month;
      if (age >= 0 && age < 12) out[11 - age]++;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: WildHero(
          image: 'intro_cervo.jpg',
          height: 235,
          alignment: const Alignment(.1, -.25),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [WildLogo(compact: true, light: true), Spacer(), Icon(Icons.notifications_none, color: Colors.white)]),
              const Spacer(),
              const Text('Diario e Statistiche', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('I tuoi avvistamenti, i tuoi luoghi, la tua crescita.', style: TextStyle(color: Colors.white, fontSize: 14)),
            ]),
          )),
        )),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
          sliver: SliverList(delegate: SliverChildListDelegate([
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: .72,
              children: [
                _Kpi(icon: Icons.eco_outlined, label: 'Specie uniche', value: '${uniqueSpecies.length}', tint: WildColors.sageSoft),
                _Kpi(icon: Icons.directions_walk, label: 'Km percorsi', value: '${(distance / 1000).toStringAsFixed(0)} km', tint: const Color(0xFFF3E9DB)),
                _Kpi(icon: Icons.schedule_outlined, label: 'Tempo sul campo', value: '${fieldTime.inHours} h', tint: const Color(0xFFF1E8D8)),
                _Kpi(icon: Icons.binoculars_outlined, label: 'Totale avvistamenti', value: '${sightings.length}', tint: WildColors.sageSoft),
              ],
            ),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _Panel(title: 'Avvistamenti per mese', child: _MonthlyChart(values: monthly))),
              const SizedBox(width: 9),
              Expanded(flex: 2, child: _Panel(title: 'Specie più osservata', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset('intro_cervo.jpg', height: 115, width: double.infinity, fit: BoxFit.cover)),
                const SizedBox(height: 8),
                Text(mostObserved, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
              ]))),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _Panel(title: 'Nuovi lifer', child: SizedBox(height: 145, child: Row(children: [
                _Lifer(asset: 'intro_cervo.jpg', label: uniqueSpecies.isEmpty ? '—' : uniqueSpecies.first),
                const SizedBox(width: 7),
                const _Lifer(asset: 'intro_gufo.jpg', label: 'Picchio nero'),
                const SizedBox(width: 7),
                const _Lifer(asset: 'intro_marmotta.jpg', label: 'Marmotta'),
              ])))),
              const SizedBox(width: 9),
              Expanded(child: _Panel(title: 'Heatmap privata', subtitle: 'Solo tu puoi vederla', child: _Heatmap(points: sightings.where((s) => s.hasPosition).length))),
            ]),
            const SizedBox(height: 10),
            _Panel(title: 'Regioni / province visitate', child: Row(children: [
              const SizedBox(width: 112, height: 150, child: Icon(Icons.public, color: WildColors.forest, size: 90)),
              const SizedBox(width: 14),
              Expanded(child: Column(children: const [
                _Region(name: 'Friuli-Venezia Giulia', value: .9),
                _Region(name: 'Veneto', value: .72),
                _Region(name: 'Trentino-Alto Adige', value: .56),
                _Region(name: 'Altre regioni', value: .35),
              ])),
            ])),
            const SizedBox(height: 10),
            _Panel(title: 'Ultime uscite', child: sessions.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Nessuna uscita registrata.'))
                : Column(children: [for (final s in sessions.take(4)) _Trip(session: s)])),
          ])),
        ),
      ]),
    ),
  );
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.label, required this.value, required this.tint});
  final IconData icon; final String label; final String value; final Color tint;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(21)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: WildColors.forest, size: 23), const Spacer(),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3), const Text('↑ rispetto al periodo', style: TextStyle(fontSize: 8, color: WildColors.forest)),
    ]),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.subtitle});
  final String title; final String? subtitle; final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 15, offset: Offset(0, 5))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
      if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 10, color: WildColors.muted)),
      const SizedBox(height: 10), child,
    ]),
  );
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.values});
  final List<int> values;
  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1, values.fold<int>(0, math.max));
    return SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (var i = 0; i < values.length; i++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Expanded(child: Align(alignment: Alignment.bottomCenter, child: FractionallySizedBox(heightFactor: math.max(.08, values[i] / maxValue), child: Container(decoration: BoxDecoration(color: i == 8 ? WildColors.forest : const Color(0xFF92B78C), borderRadius: BorderRadius.circular(5)))))),
        const SizedBox(height: 4), Text('GFMAMGLASOND'[i], style: const TextStyle(fontSize: 8)),
      ]))),
    ]));
  }
}

class _Lifer extends StatelessWidget {
  const _Lifer({required this.asset, required this.label});
  final String asset; final String label;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(asset, fit: BoxFit.cover, width: double.infinity))),
    const SizedBox(height: 5), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
  ]));
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.points});
  final int points;
  @override
  Widget build(BuildContext context) => Container(height: 145, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(colors: [Color(0xFFC8DDBE), Color(0xFFD8D2B2)])), child: Stack(children: [
    const Positioned.fill(child: Icon(Icons.map_outlined, size: 75, color: Color(0x55254D38))),
    for (var i = 0; i < math.min(9, math.max(3, points)); i++) Positioned(left: 18.0 + ((i * 41) % 180), top: 20.0 + ((i * 27) % 90), child: Container(width: 22, height: 22, decoration: BoxDecoration(color: i.isEven ? const Color(0xCCEA6A2A) : const Color(0xCCD7C936), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x66FF6A00), blurRadius: 15)]))),
  ]));
}

class _Region extends StatelessWidget {
  const _Region({required this.name, required this.value});
  final String name; final double value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(name, style: const TextStyle(fontSize: 10))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value, minHeight: 7, color: WildColors.forest, backgroundColor: WildColors.sageSoft)))]));
}

class _Trip extends StatelessWidget {
  const _Trip({required this.session});
  final TrackSession session;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [
    ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('intro_cervo.jpg', width: 82, height: 52, fit: BoxFit.cover)),
    const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Uscita naturalistica', style: TextStyle(fontWeight: FontWeight.w800)),
      Text('${(session.distanceMeters / 1000).toStringAsFixed(1)} km · ${session.endedAt.difference(session.startedAt).inMinutes} min', style: const TextStyle(fontSize: 11, color: WildColors.muted)),
    ])), const Icon(Icons.chevron_right),
  ]));
}
