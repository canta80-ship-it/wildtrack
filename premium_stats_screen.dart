import 'gpx_import_widget.dart';
import 'diary_metric_screen.dart';
import 'real_geo_stats_widget.dart';
import 'outing_diary_screen.dart';
import 'sighting_diary_screen.dart';

import 'package:flutter/cupertino.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sighting.dart';
import '../models/track_session.dart';
import '../services/database_service.dart';
import '../services/wildtrack_intelligence_service.dart';
import '../premium_ui.dart';

class PremiumStatsScreen extends StatefulWidget {
  const PremiumStatsScreen({super.key});
  @override
  State<PremiumStatsScreen> createState() => _PremiumStatsScreenState();
}

class _PremiumStatsScreenState extends State<PremiumStatsScreen> {
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
    final t = await DatabaseService.instance.getSessions();
    if (mounted)
      setState(() {
        sightings = s;
        sessions = t;
      });
  }

  Set<String> get uniqueSpecies => sightings
      .where(
        (e) => e.species.isNotEmpty && e.species != 'Specie non identificata',
      )
      .map((e) => e.species)
      .toSet();
  double get km =>
      sessions.where((s) => !s.imported).fold<double>(0, (a, b) => a + b.distanceMeters) / 1000;
  Duration get fieldTime => sessions.where((s) => !s.imported).fold(
    Duration.zero,
    (a, b) => a + b.endedAt.difference(b.startedAt),
  );

  Map<String, int> get speciesCounts {
    final out = <String, int>{};
    for (final s in sightings) {
      if (s.species == 'Specie non identificata') continue;
      out[s.species] = (out[s.species] ?? 0) + math.max(1, s.count);
    }
    return out;
  }

  String get mostObserved {
    final rows = speciesCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return rows.isEmpty ? '—' : rows.first.key;
  }

  List<int> get monthly {
    final now = DateTime.now();
    final out = List.filled(12, 0);
    for (final s in sightings) {
      final age =
          (now.year - s.timestamp.year) * 12 + now.month - s.timestamp.month;
      if (age >= 0 && age < 12) out[11 - age]++;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final lifers =
        WildTrackIntelligenceService.instance
            .firstSightings(sightings)
            .entries
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      backgroundColor: WildColors.ivory,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: WildHero(
                image: '',
                height: 146,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            WildLogo(compact: true),
                            Spacer(),

                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Diario e Statistiche',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'I tuoi avvistamenti, i tuoi luoghi, la tua crescita.',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: .78,
                    children: [
                      _Kpi(
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
                        value: '${uniqueSpecies.length}',
                        tint: WildColors.sageSoft,
                      ),
                      _Kpi(
                        icon: Icons.directions_walk,
                        label: 'Km percorsi',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const DiaryMetricScreen(
                              metric: DiaryMetric.distance,
                            ),
                          ),
                        ),
                        value: '${km.toStringAsFixed(0)} km',
                        tint: const Color(0xFFF3E9DB),
                      ),
                      _Kpi(
                        icon: Icons.schedule,
                        label: 'Tempo sul campo',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const DiaryMetricScreen(
                              metric: DiaryMetric.time,
                            ),
                          ),
                        ),
                        value: '${fieldTime.inHours} h',
                        tint: const Color(0xFFF1E8D8),
                      ),
                      _Kpi(
                        icon: WildIcons.binoculars,
                        label: 'Avvistamenti',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SightingDiaryScreen(),
                          ),
                        ),
                        value: '${sightings.length}',
                        tint: WildColors.sageSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _Panel(
                          title: 'Avvistamenti per mese',
                          child: _Monthly(values: monthly),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _Panel(
                          title: 'Specie più osservata',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WildAnimalIllustration(mostObserved, size: 120),
                              const SizedBox(height: 8),
                              Text(
                                mostObserved,
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                '${speciesCounts[mostObserved] ?? 0} individui',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: WildColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Panel(
                          title: 'Nuovi lifer',
                          child: SizedBox(
                            height: 150,
                            child: lifers.isEmpty
                                ? const Center(
                                    child: Text(
                                      'I primi avvistamenti appariranno qui.',
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Row(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < math.min(3, lifers.length);
                                        i++
                                      ) ...[
                                        if (i > 0) const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: WildAnimalIllustration(
                                                  lifers[i].key,
                                                  size: 90,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                lifers[i].key,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Panel(
                          title: 'Heatmap privata',
                          child: RealHeatmap(sightings: sightings),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Panel(
                    title: 'Regioni / province visitate',
                    child: RealRegions(sightings: sightings),
                  ),
                  const SizedBox(height: 10),
                  WildPrimaryButton(
                    label: 'Gestisci avvistamenti',
                    icon: WildIcons.binoculars,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SightingDiaryScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Panel(
                    title: 'Lista uscite',
                    onTitleTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const DiaryMetricScreen(
                          metric: DiaryMetric.outings,
                        ),
                      ),
                    ),
                    child: Column(children: [const Align(alignment: Alignment.centerRight, child: GpxImportButton()), sessions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Text('Nessuna uscita registrata.'),
                          )
                        : Column(
                            children: [
                              for (final s in sessions.take(5))
                                InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          OutingDiaryScreen(session: s),
                                    ),
                                  ),
                                  child: _TripRow(session: s),
                                ),
                            ],
                          )]),
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

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.onTap,
  });
  final IconData icon;
  final String label, value;
  final Color tint;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: WildColors.forest, size: 23),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          const Text(
            'tutti i dati salvati',
            style: TextStyle(fontSize: 7.5, color: WildColors.forest),
          ),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.onTitleTap});
  final String title;
  final Widget child;
  final VoidCallback? onTitleTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 15,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTitleTap,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onTitleTap != null)
                const Icon(Icons.chevron_right, color: WildColors.forest),
            ],
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _Monthly extends StatelessWidget {
  const _Monthly({required this.values});
  final List<int> values;
  @override
  Widget build(BuildContext context) {
    final maxV = math.max(1, values.fold<int>(0, math.max));
    const months = ['N', 'D', 'G', 'F', 'M', 'A', 'M', 'G', 'L', 'A', 'S', 'O'];
    return SizedBox(
      height: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: math.max(.08, values[i] / maxV),
                          child: Container(
                            decoration: BoxDecoration(
                              color: i == values.length - 1
                                  ? WildColors.forest
                                  : const Color(0xFF91B28B),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(months[i], style: const TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeatmapIllustration extends StatelessWidget {
  const _HeatmapIllustration();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 150,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        children: [
          const Positioned.fill(child: WildLandscape(height: 150)),
          for (final p in const [
            Offset(.18, .68),
            Offset(.32, .54),
            Offset(.49, .62),
            Offset(.64, .42),
            Offset(.78, .58),
          ])
            Positioned(
              left: p.dx * 220,
              top: p.dy * 120,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withValues(alpha: .48),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: .35),
                      blurRadius: 18,
                      spreadRadius: 7,
                    ),
                  ],
                ),
              ),
            ),
          const Positioned(
            left: 10,
            bottom: 8,
            child: Row(
              children: [
                Icon(WildIcons.binoculars, size: 13, color: WildColors.forest),
                SizedBox(width: 4),
                Text(
                  'Solo tu puoi vederla',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RegionsIllustration extends StatelessWidget {
  const _RegionsIllustration();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 110,
        height: 125,
        decoration: BoxDecoration(
          color: WildColors.sageSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.map_outlined,
          size: 68,
          color: WildColors.forest,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          children: const [
            _RegionRow('Trentino-Alto Adige', .92),
            _RegionRow('Veneto', .76),
            _RegionRow('Piemonte', .65),
            _RegionRow('Lombardia', .56),
            _RegionRow('Toscana', .38),
            _RegionRow('Altre regioni', .29),
          ],
        ),
      ),
    ],
  );
}

class _RegionRow extends StatelessWidget {
  const _RegionRow(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 10)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              color: WildColors.forest,
              backgroundColor: WildColors.cream,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.session});
  final TrackSession session;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const SizedBox(
          width: 76,
          height: 54,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            child: WildLandscape(height: 54),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.name.isNotEmpty ? session.name : 'Uscita del ${session.startedAt.day}/${session.startedAt.month}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${(session.distanceMeters / 1000).toStringAsFixed(1)} km · ${session.endedAt.difference(session.startedAt).inMinutes} min',
                style: const TextStyle(fontSize: 10, color: WildColors.muted),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}
