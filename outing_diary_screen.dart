import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/track_session.dart';
import '../services/activity_share_service.dart';
import '../services/database_service.dart';
import '../services/outing_diary_service.dart';
import '../premium_ui.dart';

class OutingDiaryScreen extends StatefulWidget {
  const OutingDiaryScreen({super.key, required this.session, this.justCompleted = false});
  final TrackSession session;
  final bool justCompleted;

  @override
  State<OutingDiaryScreen> createState() => _OutingDiaryScreenState();
}

class _OutingDiaryScreenState extends State<OutingDiaryScreen> {
  late TrackSession session;
  late Future<OutingDiary> diary;
  late TextEditingController notes;
  bool saving = false;
  bool publishing = false;

  @override
  void initState() {
    super.initState();
    session = widget.session;
    notes = TextEditingController(text: session.notes);
    diary = OutingDiaryService.instance.build(session);
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> saveNotes() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      session = session.copyWith(notes: notes.text.trim());
      await DatabaseService.instance.updateSession(session);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota attività salvata.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> toggleCommunity(bool value) async {
    if (publishing) return;
    await saveNotes();
    setState(() => publishing = true);
    try {
      session = value
          ? await ActivityShareService.instance.publish(session)
          : await ActivityShareService.instance.makePrivate(session);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'Attività condivisa con la Community.' : 'Attività resa privata.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Condivisione non riuscita: ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(title: Text(widget.justCompleted ? 'Riepilogo attività' : 'Diario dell’uscita')),
    body: FutureBuilder<OutingDiary>(
      future: diary,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) return Center(child: Text('Diario non disponibile: ${snapshot.error}'));
          return const Center(child: CircularProgressIndicator());
        }
        final d = snapshot.data!;
        final duration = session.endedAt.difference(session.startedAt);
        final speed = duration.inSeconds <= 0 ? 0 : session.distanceMeters / duration.inSeconds * 3.6;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
          children: [
            WildHero(
              image: 'intro_cervo.jpg',
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Spacer(),
                  Text(DateFormat('EEEE d MMMM yyyy', 'it').format(session.startedAt), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(widget.justCompleted ? 'Attività completata' : 'La tua uscita', style: const TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _Pill(Icons.route, '${(session.distanceMeters / 1000).toStringAsFixed(1)} km'),
                    _Pill(Icons.schedule, '${duration.inHours}h ${duration.inMinutes.remainder(60)}m'),
                    _Pill(Icons.terrain, '+${session.ascentMeters.toStringAsFixed(0)} m'),
                    _Pill(Icons.trending_down, '-${session.descentMeters.toStringAsFixed(0)} m'),
                    _Pill(Icons.speed, '${speed.toStringAsFixed(1)} km/h'),
                    _Pill(Icons.pets, '${d.species.length} specie'),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              title: 'Come è andata?',
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: notes,
                  minLines: 3,
                  maxLines: 7,
                  decoration: const InputDecoration(hintText: 'Sensazioni, condizioni del sentiero, fauna osservata, cosa vuoi ricordare di questa uscita…'),
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: FilledButton.tonalIcon(onPressed: saving ? null : saveNotes, icon: const Icon(Icons.save_outlined), label: Text(saving ? 'Salvataggio…' : 'Salva nota'))),
              ]),
            ),
            const SizedBox(height: 12),
            _Card(title: 'Riepilogo automatico', child: Text(d.narrative, style: const TextStyle(height: 1.45))),
            const SizedBox(height: 12),
            if (d.route.isNotEmpty)
              _Card(
                title: 'Percorso',
                child: SizedBox(
                  height: 285,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: d.route.first,
                        initialZoom: 13,
                        initialCameraFit: CameraFit.bounds(bounds: LatLngBounds.fromPoints(d.route), padding: const EdgeInsets.all(35)),
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
              title: 'Community',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: session.isPublic,
                  onChanged: publishing ? null : toggleCommunity,
                  title: const Text('Rendi visibile questa attività', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('La condivisione è volontaria per ogni uscita. Il percorso pubblico viene alleggerito e una piccola parte iniziale/finale viene rimossa per ridurre il rischio di mostrare luoghi privati.'),
                ),
                if (session.isPublic && session.publishedAt != null)
                  Text('Pubblicata ${DateFormat('d MMM HH:mm', 'it').format(session.publishedAt!)}', style: const TextStyle(fontSize: 10, color: WildColors.muted)),
              ]),
            ),
            const SizedBox(height: 12),
            _Card(
              title: 'Meteo',
              child: Row(children: [const WildIconDisc(Icons.cloud_outlined, size: 46), const SizedBox(width: 12), Expanded(child: Text(d.weather.label, style: const TextStyle(fontWeight: FontWeight.w700)))]),
            ),
            const SizedBox(height: 12),
            _Card(
              title: 'Specie osservate',
              child: d.species.isEmpty
                  ? const Text('Nessuna specie identificata durante questa sessione.')
                  : Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final s in d.species)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                          decoration: BoxDecoration(color: d.lifers.contains(s) ? const Color(0xFFF2E2B9) : WildColors.sageSoft, borderRadius: BorderRadius.circular(16)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(d.lifers.contains(s) ? Icons.workspace_premium : Icons.pets, size: 16, color: WildColors.forest), const SizedBox(width: 5), Text(d.lifers.contains(s) ? '$s · LIFER' : s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
                        ),
                    ]),
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
                      return ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(s.photoPath!), width: 180, height: 145, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 180, child: Center(child: Icon(Icons.broken_image_outlined)))));
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
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: const Color(0xAA173F2B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white30)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 15), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))]));
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 15, offset: Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 10), child]));
}
