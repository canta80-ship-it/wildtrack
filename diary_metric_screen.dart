import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sighting.dart';
import '../models/track_session.dart';
import '../premium_ui.dart';
import '../services/database_service.dart';
import 'species_screen.dart';
import 'premium_animal_screen.dart';
import 'outing_diary_screen.dart';
import 'sighting_diary_screen.dart';

enum DiaryMetric { species, distance, time }

class DiaryMetricScreen extends StatefulWidget {
  const DiaryMetricScreen({super.key, required this.metric});
  final DiaryMetric metric;
  @override
  State<DiaryMetricScreen> createState() => _DiaryMetricScreenState();
}

class _DiaryMetricScreenState extends State<DiaryMetricScreen> {
  List<Sighting> sightings = [];
  List<TrackSession> sessions = [];
  bool loading = true;
  String get title => switch (widget.metric) {
    DiaryMetric.species => 'Le tue specie uniche',
    DiaryMetric.distance => 'Km percorsi',
    DiaryMetric.time => 'Tempo sul campo',
  };
  @override
  void initState() {
    super.initState();
    DatabaseService.instance.changes.addListener(load);
    load();
  }

  @override
  void dispose() {
    DatabaseService.instance.changes.removeListener(load);
    super.dispose();
  }

  Future<void> load() async {
    final s = await DatabaseService.instance.getSightings();
    final t = await DatabaseService.instance.getSessions();
    if (mounted)
      setState(() {
        sightings = s;
        sessions = t;
        loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final s in sightings) {
      if (s.species.isNotEmpty && s.species != 'Specie non identificata') {
        counts[s.species] = (counts[s.species] ?? 0) + 1;
      }
    }
    final names = counts.keys.toList()..sort();
    final minutes = sessions.fold<int>(
      0,
      (sum, s) => sum + s.endedAt.difference(s.startedAt).inMinutes,
    );
    final km =
        sessions.fold<double>(0, (sum, s) => sum + s.distanceMeters) / 1000;
    return Scaffold(
      backgroundColor: WildColors.ivory,
      appBar: AppBar(title: Text(title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    widget.metric == DiaryMetric.species
                        ? '${names.length} specie registrate'
                        : widget.metric == DiaryMetric.distance
                        ? '${km.toStringAsFixed(2)} km totali'
                        : '${minutes ~/ 60} h ${minutes % 60} min totali',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.metric == DiaryMetric.species
                        ? 'Apri una specie per consultare la sua scheda.'
                        : 'Apri un’uscita per consultare il report completo.',
                  ),
                  const SizedBox(height: 16),
                  if (widget.metric == DiaryMetric.species) ...[
                    if (names.isEmpty)
                      const Text(
                        'Registra il primo avvistamento per iniziare il tuo elenco.',
                      ),
                    for (final name in names)
                      Card(
                        child: ListTile(
                          leading: WildAnimalIllustration(name, size: 56),
                          title: Text(name),
                          subtitle: Text('${counts[name]} avvistamenti'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final matching = animals.where(
                              (a) => a.name == name,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => matching.isEmpty
                                    ? const SightingDiaryScreen()
                                    : PremiumAnimalScreen(matching.first),
                              ),
                            );
                          },
                        ),
                      ),
                  ] else ...[
                    if (sessions.isEmpty)
                      const Text('Non hai ancora registrato uscite.'),
                    for (final s in sessions)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            widget.metric == DiaryMetric.distance
                                ? Icons.directions_walk
                                : Icons.schedule,
                            color: WildColors.forest,
                          ),
                          title: Text(
                            DateFormat('d MMM yyyy · HH:mm')
                                .format(s.startedAt),
                          ),
                          subtitle: Text(
                            '${(s.distanceMeters / 1000).toStringAsFixed(2)} km · ${s.endedAt.difference(s.startedAt).inMinutes ~/ 60} h ${s.endedAt.difference(s.startedAt).inMinutes % 60} min',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => OutingDiaryScreen(session: s),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
