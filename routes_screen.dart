import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/track_session.dart';
import '../services/database_service.dart';

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
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseService.instance.getSessions();
    if (mounted) setState(() => sessions = rows);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Percorsi salvati')),
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
                        title: Text(DateFormat('dd/MM/yyyy HH:mm').format(s.startedAt)),
                        subtitle: Text('${(s.distanceMeters / 1000).toStringAsFixed(2)} km · +${s.ascentMeters.toStringAsFixed(0)} m · ${duration.inMinutes} min'),
                      ),
                    );
                  },
                ),
              ),
      );
}
