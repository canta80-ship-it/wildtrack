import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/sighting.dart';
import '../models/track_session.dart';
import '../services/database_service.dart';
import '../services/geo_insights_service.dart';
import '../services/wildtrack_intelligence_service.dart';
import '../premium_ui.dart';
import 'outing_diary_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Sighting> sightings = [];
  List<TrackSession> sessions = [];
  Map<String, int> regions = {};
  bool loadingRegions = false;

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
    await _loadRegions();
  }

  Future<void> _loadRegions() async {
    if (loadingRegions) return;
    loadingRegions = true;
    final points = <({double lat, double lng})>[];
    for (final s in sightings.where((e) => e.hasPosition)) {
      points.add((lat: s.latitude!, lng: s.longitude!));
    }
    for (final session in sessions.take(20)) {
      final rows = await DatabaseService.instance.getTrackPoints(session.id);
      if (rows.isNotEmpty) {
        points.add((lat: (rows.first['latitude'] as num).toDouble(), lng: (rows.first['longitude'] as num).toDouble()));
      }
    }
    final value = await GeoInsightsService.instance.aggregate(points);
    if (mounted) setState(() => regions = value);
    loadingRegions = false;
  }

  Set<String> get uniqueSpecies => sightings
      .where((s) => s.species.trim().isNotEmpty && s.species != 'Specie non identificata')
      .map((s) => s.species.trim())
      .toSet();

  double get distance => sessions.fold(0, (sum, e) => sum + e.distanceMeters);
  Duration get fieldTime => sessions.fold(Duration.zero, (sum, e) => sum + e.endedAt.difference(e.startedAt));

  Map<String, int> get speciesCounts {
    final out = <String, int>{};
    for (final s in sightings) {
      if (s.species == 'Specie non identificata') continue;
      out[s.species] = (out[s.species] ?? 0) + math.max(1, s.count);
    }
    return out;
  }

  String get mostObserved {
    final rows = speciesCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return rows.isEmpty ? '—' : rows.first.key;
  }

  int get mostObservedCount => speciesCounts[mostObserved] ?? 0;

  List<int> get monthly {
    final now = DateTime.now();
    final out = List.filled(12, 0);
    for (final s in sightings) {
      final age = (now.year - s.timestamp.year) * 12 + now.month - s.timestamp.month;
      if (age >= 0 && age < 12) out[11 - age] += 1;
    }
    return out;
  }

  double _distanceFor(DateTime from, DateTime to) => sessions
      .where((s) => !s.startedAt.isBefore(from) && s.startedAt.isBefore(to))
      .fold(0.0, (a, b) => a + b.distanceMeters);

  int _minutesFor(DateTime from, DateTime to) => sessions
      .where((s) => !s.startedAt.isBefore(from) && s.startedAt.isBefore(to))
      .fold(0, (a, b) => a + b.endedAt.difference(b.startedAt).inMinutes);

  int _sightingsFor(DateTime from, DateTime to) => sightings
      .where((s) => !s.timestamp.isBefore(from) && s.timestamp.isBefore(to))
      .length;

  int _speciesFor(DateTime from, DateTime to) => sightings
      .where((s) => !s.timestamp.isBefore(from) && s.timestamp.isBefore(to) && s.species != 'Specie non identificata')
      .map((s) => s.species)
      .toSet()
      .length;

  String _delta(num current, num previous) {
    if (previous == 0) return current == 0 ? '0%' : 'nuovo';
    final value = ((current - previous) / previous * 100).round();
    return '${value >= 0 ? '+' : ''}$value%';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentFrom = DateTime(now.year - 1, now.month, now.day);
    final previousFrom = DateTime(now.year - 2, now.month, now.day);
    final previousTo = currentFrom;
    final currentDistance = _distanceFor(currentFrom, now);
    final previousDistance = _distanceFor(previousFrom, previousTo);
    final currentMinutes = _minutesFor(currentFrom, now);
    final previousMinutes = _minutesFor(previousFrom, previousTo);
    final currentSightings = _sightingsFor(currentFrom, now);
    final previousSightings = _sightingsFor(previousFrom, previousTo);
    final currentSpecies = _speciesFor(currentFrom, now);
    final previousSpecies = _speciesFor(previousFrom, previousTo);
    final first = WildTrackIntelligenceService.instance.firstSightings(sightings).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final points = sightings.where((s) => s.hasPosition).map((s) => LatLng(s.latitude!, s.longitude!)).toList();

    return Scaffold(
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
                const Row(children: [WildLogo(compact: true, light: true), Spacer(), Icon(Icons.notifications_none, color: Colors.white)]),
                const Spacer(),
                const Text('Diario e Statistiche', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Dati reali dal tuo archivio privato e dalle uscite GPS.', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                childAspectRatio: .68,
                children: [
                  _Kpi(icon: Icons.eco_outlined, label: 'Specie uniche', value: '${uniqueSpecies.length}', delta: _delta(currentSpecies, previousSpecies), tint: WildColors.sageSoft),
                  _Kpi(icon: Icons.directions_walk, label: 'Km percorsi', value: '${(distance / 1000).toStringAsFixed(0)} km', delta: _delta(currentDistance, previousDistance), tint: const Color(0xFFF3E9DB)),
                  _Kpi(icon: Icons.schedule_outlined, label: 'Tempo sul campo', value: '${fieldTime.inHours} h', delta: _delta(currentMinutes, previousMinutes), tint: const Color(0xFFF1E8D8)),
                  _Kpi(icon: Icons.visibility_outlined, label: 'Avvistamenti', value: '${sightings.length}', delta: _delta(currentSightings, previousSightings), tint: WildColors.sageSoft),
                ],
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: _Panel(title: 'Avvistamenti per mese', child: _MonthlyChart(values: monthly))),
                const SizedBox(width: 9),
                Expanded(flex: 2, child: _Panel(title: 'Specie più osservata', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(_assetFor(mostObserved), height: 115, width: double.infinity, fit: BoxFit.cover)),
                  const SizedBox(height: 8),
                  Text(mostObserved, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('$mostObservedCount individui registrati', style: const TextStyle(fontSize: 10, color: WildColors.muted)),
                ]))),
              ]),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _Panel(title: 'Nuovi lifer', child: SizedBox(height: 155, child: first.isEmpty
                    ? const Center(child: Text('I lifer appariranno con il primo avvistamento di ogni specie.'))
                    : Row(children: [for (var i = 0; i < math.min(3, first.length); i++) ...[
                        if (i > 0) const SizedBox(width: 7),
                        _Lifer(asset: _assetFor(first[i].key), label: first[i].key, date: '${first[i].value.day}/${first[i].value.month}/${first[i].value.year}'),
                      ]])))),
                const SizedBox(width: 9),
                Expanded(child: _Panel(title: 'Heatmap privata', subtitle: 'Coordinate mai inviate per questa vista', child: _Heatmap(points: points))),
              ]),
              const SizedBox(height: 10),
              _Panel(
                title: 'Regioni / province visitate',
                child: loadingRegions && regions.isEmpty
                    ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                    : regions.isEmpty
                        ? const Text('Registra posizioni GPS per costruire la mappa geografica del tuo passaporto.')
                        : Column(children: [
                            for (final e in regions.entries.take(7))
                              _Region(name: e.key, value: e.value / math.max(1, regions.values.fold<int>(0, math.max))),
                          ]),
              ),
              const SizedBox(height: 10),
              _Panel(title: 'Ultime uscite', child: sessions.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Nessuna uscita registrata.'))
                  : Column(children: [for (final s in sessions.take(6)) _Trip(session: s)])),
            ])),
          ),
        ]),
      ),
    );
  }

  String _assetFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('lupo') || n.contains('volpe')) return 'intro_lupo.jpg';
    if (n.contains('marmotta') || n.contains('stambecco') || n.contains('camoscio')) return 'intro_marmotta.jpg';
    if (n.contains('gufo') || n.contains('allocco') || n.contains('poiana') || n.contains('picchio')) return 'intro_gufo.jpg';
    return 'intro_cervo.jpg';
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.label, required this.value, required this.delta, required this.tint});
  final IconData icon; final String label; final String value; final String delta; final Color tint;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(21)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: WildColors.forest, size: 23), const Spacer(),
      Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3), Text('$delta vs 12 mesi prec.', style: const TextStyle(fontSize: 7.5, color: WildColors.forest)),
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
    const months = ['N','D','G','F','M','A','M','G','L','A','S','O'];
    return SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (var i = 0; i < values.length; i++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Expanded(child: Align(alignment: Alignment.bottomCenter, child: FractionallySizedBox(heightFactor: math.max(.08, values[i] / maxValue), child: Container(decoration: BoxDecoration(color: i == values.length - 1 ? WildColors.forest : const Color(0xFF92B78C), borderRadius: BorderRadius.circular(5)))))),
        const SizedBox(height: 4), Text(months[i], style: const TextStyle(fontSize: 8)),
      ]))),
    ]));
  }
}

class _Lifer extends StatelessWidget {
  const _Lifer({required this.asset, required this.label, required this.date});
  final String asset; final String label; final String date;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(asset, fit: BoxFit.cover, width: double.infinity))),
    const SizedBox(height: 5), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
    Text(date, style: const TextStyle(fontSize: 8, color: WildColors.muted)),
  ]));
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.points});
  final List<LatLng> points;
  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox(height: 145, child: Center(child: Text('Nessun punto GPS.')));
    return SizedBox(
      height: 145,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: points.first,
            initialZoom: 7,
            initialCameraFit: points.length > 1 ? CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: const EdgeInsets.all(18)) : null,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'it.wildtrack.wildtrack_v6'),
            CircleLayer(circles: [for (final p in points) CircleMarker(point: p, radius: 18, color: const Color(0x66E05C23), borderColor: const Color(0x44D9C934), borderStrokeWidth: 9)]),
          ],
        ),
      ),
    );
  }
}

class _Region extends StatelessWidget {
  const _Region({required this.name, required this.value});
  final String name; final double value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 10))), Expanded(flex: 2, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 7, color: WildColors.forest, backgroundColor: WildColors.sageSoft)))]));
}

class _Trip extends StatelessWidget {
  const _Trip({required this.session});
  final TrackSession session;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OutingDiaryScreen(session: session))),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('intro_cervo.jpg', width: 82, height: 52, fit: BoxFit.cover)),
          const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Uscita naturalistica', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('${(session.distanceMeters / 1000).toStringAsFixed(1)} km · ${session.endedAt.difference(session.startedAt).inMinutes} min · +${session.ascentMeters.toStringAsFixed(0)} m', style: const TextStyle(fontSize: 11, color: WildColors.muted)),
          ])), const Icon(Icons.chevron_right),
        ]),
      ),
    ),
  );
}
