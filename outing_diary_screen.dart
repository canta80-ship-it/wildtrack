import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/track_session.dart';
import '../services/outing_diary_service.dart';
import '../premium_ui.dart';

class OutingDiaryScreen extends StatefulWidget {
  const OutingDiaryScreen({super.key, required this.session});
  final TrackSession session;

  @override
  State<OutingDiaryScreen> createState() => _OutingDiaryScreenState();
}

class _OutingDiaryScreenState extends State<OutingDiaryScreen> {
  late Future<OutingDiary> diary;

  @override
  void initState() {
    super.initState();
    diary = OutingDiaryService.instance.build(widget.session);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(title: const Text('Diario dell’uscita')),
    body: FutureBuilder<OutingDiary>(
      future: diary,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) return Center(child: Text('Diario non disponibile: ${snapshot.error}'));
          return const Center(child: CircularProgressIndicator());
        }
        final d = snapshot.data!;
        final duration = d.session.endedAt.difference(d.session.startedAt);
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
          children: [
            WildHero(
              image: 'intro_cervo.jpg',
              height: 225,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      DateFormat('EEEE d MMMM yyyy', 'it').format(d.session.startedAt),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text('La tua uscita', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 9),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _Pill(Icons.route, '${(d.session.distanceMeters / 1000).toStringAsFixed(1)} km'),
                      _Pill(Icons.schedule, '${duration.inHours}h ${duration.inMinutes.remainder(60)}m'),
                      _Pill(Icons.terrain, '+${d.session.ascentMeters.toStringAsFixed(0)} m'),
                      _Pill(Icons.pets, '${d.species.length} specie'),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              title: 'Riepilogo automatico',
              child: Text(d.narrative, style: const TextStyle(height: 1.45)),
            ),
            const SizedBox(height: 12),
            if (d.route.isNotEmpty)
              _Card(
                title: 'Percorso',
                child: SizedBox(
                  height: 260,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: d.route.first,
                        initialZoom: 13,
                        initialCameraFit: CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(d.route),
                          padding: const EdgeInsets.all(35),
                        ),
                      ),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'it.wildtrack.wildtrack_v6'),
                        PolylineLayer(polylines: [Polyline(points: d.route, strokeWidth: 5, color: WildColors.forest)]),
                        MarkerLayer(markers: [
                          Marker(point: d.route.first, width: 34, height: 34, child: const Icon(Icons.play_circle_fill, color: WildColors.forest, size: 32)),
                          Marker(point: d.route.last, width: 34, height: 34, child: const Icon(Icons.flag_circle, color: WildColors.earth, size: 32)),
                        ]),
                        const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _Card(
              title: 'Meteo',
              child: Row(children: [
                const WildIconDisc(Icons.cloud_outlined, size: 46),
                const SizedBox(width: 12),
                Expanded(child: Text(d.weather.label, style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
            const SizedBox(height: 12),
            _Card(
              title: 'Specie osservate',
              child: d.species.isEmpty
                  ? const Text('Nessuna specie identificata durante questa sessione.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in d.species)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                            decoration: BoxDecoration(color: d.lifers.contains(s) ? const Color(0xFFF2E2B9) : WildColors.sageSoft, borderRadius: BorderRadius.circular(16)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(d.lifers.contains(s) ? Icons.workspace_premium : Icons.pets, size: 16, color: WildColors.forest),
                              const SizedBox(width: 5),
                              Text(d.lifers.contains(s) ? '$s · LIFER' : s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                      ],
                    ),
            ),
            if (d.sightings.any((s) => s.photoPath != null)) ...[
              const SizedBox(height: 12),
              _Card(
                title: 'Fotografie',
                child: SizedBox(
                  height: 145,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: d.sightings.where((s) => s.photoPath != null).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final rows = d.sightings.where((s) => s.photoPath != null).toList();
                      final s = rows[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(File(s.photoPath!), width: 180, height: 145, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 180, child: Center(child: Icon(Icons.broken_image_outlined)))),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xAA173F2B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white30)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 15), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))]),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 15, offset: Offset(0, 5))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 10), child]),
  );
}
