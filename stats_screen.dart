import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/sighting.dart';
import '../models/track_session.dart';
import '../services/database_service.dart';

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
    setState(() {
      sightings = s;
      sessions = r;
    });
  }

  Set<String> get uniqueSpecies => sightings
      .where((s) => s.species.trim().isNotEmpty && s.species != 'Specie non identificata')
      .map((s) => s.species.trim())
      .toSet();

  double get distance => sessions.fold(0, (sum, e) => sum + e.distanceMeters);
  Duration get fieldTime => sessions.fold(Duration.zero, (sum, e) => sum + e.endedAt.difference(e.startedAt));

  String get mostObserved {
    if (sightings.isEmpty) return '—';
    final counts = <String, int>{};
    for (final s in sightings) {
      counts[s.species] = (counts[s.species] ?? 0) + s.count;
    }
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
    appBar: AppBar(title: const Text('Diario e statistiche')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          const Text('I tuoi avvistamenti, i tuoi luoghi, la tua crescita.', style: TextStyle(color: Color(0xFF657064))),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _Stat(icon: Icons.eco_outlined, label: 'Specie uniche', value: '${uniqueSpecies.length}'),
              _Stat(icon: Icons.route_outlined, label: 'Km percorsi', value: '${(distance / 1000).toStringAsFixed(1)} km'),
              _Stat(icon: Icons.schedule_outlined, label: 'Tempo sul campo', value: '${fieldTime.inHours} h'),
              _Stat(icon: Icons.visibility_outlined, label: 'Avvistamenti', value: '${sightings.length}'),
            ],
          ),
          const SizedBox(height: 22),
          _Section(
            title: 'Avvistamenti per mese',
            child: _MonthlyChart(values: monthly),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _InsightCard(icon: Icons.pets_outlined, title: 'Specie più osservata', value: mostObserved)),
            const SizedBox(width: 10),
            Expanded(child: _InsightCard(icon: Icons.workspace_premium_outlined, title: 'Nuovi lifer', value: '${uniqueSpecies.length}')),
          ]),
          const SizedBox(height: 12),
          _Section(
            title: 'Heatmap privata',
            subtitle: 'Solo tu puoi vederla',
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFFDDE8DA), Color(0xFFEADCC8)]),
              ),
              child: Stack(children: [
                const Positioned.fill(child: Icon(Icons.map_outlined, size: 80, color: Color(0x55254D38))),
                for (var i = 0; i < math.min(8, sightings.where((s) => s.hasPosition).length); i++)
                  Positioned(
                    left: 24.0 + ((i * 47) % 230),
                    top: 20.0 + ((i * 31) % 90),
                    child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(0xAA9A6B34), shape: BoxShape.circle)),
                  ),
                const Positioned(left: 14, bottom: 12, child: Text('Anteprima locale degli avvistamenti geolocalizzati', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Regioni / province visitate',
            subtitle: 'In arrivo con geocodifica locale',
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.public),
              title: Text('Passaporto naturalistico'),
              subtitle: Text('La struttura è pronta; i nomi territoriali verranno calcolati senza pubblicare le tue coordinate.'),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Ultime uscite',
            child: sessions.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Nessuna uscita registrata.'))
                : Column(children: [
                    for (final s in sessions.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(backgroundColor: Color(0xFFDDE8DA), child: Icon(Icons.hiking, color: Color(0xFF254D38))),
                        title: Text('${(s.distanceMeters / 1000).toStringAsFixed(1)} km · ${s.endedAt.difference(s.startedAt).inMinutes} min'),
                        subtitle: Text('${s.startedAt.day}/${s.startedAt.month}/${s.startedAt.year}'),
                      ),
                  ]),
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF254D38)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Color(0xFF657064), fontSize: 12)),
      ]),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: const TextStyle(color: Color(0xFF657064), fontSize: 12))],
        const SizedBox(height: 14),
        child,
      ]),
    ),
  );
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF254D38)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Color(0xFF657064), fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
    ),
  );
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.values});
  final List<int> values;
  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1, values.fold<int>(0, math.max));
    return SizedBox(
      height: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Expanded(child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: values[i] / maxValue,
                      child: Container(decoration: BoxDecoration(color: const Color(0xFF5C7A60), borderRadius: BorderRadius.circular(6))),
                    ),
                  )),
                  const SizedBox(height: 5),
                  Text('${i + 1}', style: const TextStyle(fontSize: 9, color: Color(0xFF657064))),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
