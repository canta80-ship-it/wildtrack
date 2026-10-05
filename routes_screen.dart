import 'gpx_import_widget.dart';
import 'outing_delete_widget.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/track_session.dart';
import '../services/database_service.dart';
import '../services/exploration_service.dart';
import 'exploration_screen.dart';
import 'community_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});
  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
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
    final rows = await DatabaseService.instance.getSessions();
    if (mounted) setState(() => sessions = rows);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lista uscite'), actions: const [GpxImportButton()]),
    body: sessions.isEmpty
        ? const Center(child: Text('Nessun percorso registrato.'))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sessions.length,
              itemBuilder: (context, i) {
                final s = sessions[i];
                final duration = s.endedAt.difference(s.startedAt);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.route),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutingDeleteButton(session: s),
                        const Icon(Icons.map_outlined),
                      ],
                    ),
                    onTap: () async {
                      try {
                        final points = await DatabaseService.instance
                            .getTrackPoints(s.id);
                        if (!context.mounted) return;
                        if (points.length < 2) {
                          message(
                            context,
                            'Questo percorso non contiene abbastanza punti GPS.',
                          );
                          return;
                        }
                        final trail = NatureTrail({
                          'id': 'recorded_${s.id}',
                          'name': s.name.isNotEmpty ? s.name : 'Percorso del ${DateFormat('dd/MM/yyyy').format(s.startedAt)}',
                          'difficulty': 'Registrato da te',
                          'source': null,
                          'segments': [
                            for(final segment in points.map((p) => p['segment'] ?? 0).toSet())
                              points.where((p) => (p['segment'] ?? 0) == segment).map((p) => [p['latitude'], p['longitude']]).toList(),
                          ],
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ExplorationScreen(trail: trail),
                          ),
                        );
                      } catch (e) {
                        if (context.mounted) message(context, e);
                      }
                    },
                    title: Text(
                      s.name.isNotEmpty ? s.name : DateFormat('dd/MM/yyyy HH:mm').format(s.startedAt),
                    ),
                    subtitle: Text(
                      '${(s.distanceMeters / 1000).toStringAsFixed(2)} km · +${s.ascentMeters.toStringAsFixed(0)} m · ${duration.inMinutes} min',
                    ),
                  ),
                );
              },
            ),
          ),
  );
}
