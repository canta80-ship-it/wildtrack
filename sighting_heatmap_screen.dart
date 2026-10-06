import 'package:flutter/material.dart';

import '../models/sighting.dart';
import '../premium_ui.dart';
import '../services/database_service.dart';
import 'real_geo_stats_widget.dart';

class SightingHeatmapScreen extends StatefulWidget {
  const SightingHeatmapScreen({super.key});
  @override
  State<SightingHeatmapScreen> createState() => _SightingHeatmapScreenState();
}

class _SightingHeatmapScreenState extends State<SightingHeatmapScreen> {
  List<Sighting>? rows;
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
    final saved = await DatabaseService.instance.getSightings();
    if (mounted) setState(() => rows = saved);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(title: const Text('Heatmap privata')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Le aree più calde indicano più avvistamenti registrati. La mappa comprende solo gli avvistamenti del tuo diario con una posizione valida.',
          ),
        ),
        Expanded(
          child: rows == null
              ? const Center(child: CircularProgressIndicator())
              : RealHeatmap(sightings: rows!, expanded: true),
        ),
      ],
    ),
  );
}
