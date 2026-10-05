import 'premium_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/community_service.dart';
import '../premium_ui.dart';
import 'community_screen.dart';

class ExpeditionMessagesScreen extends StatefulWidget {
  const ExpeditionMessagesScreen({super.key, required this.mapId, required this.mapName});
  final String mapId;
  final String mapName;

  @override
  State<ExpeditionMessagesScreen> createState() => _ExpeditionMessagesScreenState();
}

class _ExpeditionMessagesScreenState extends State<ExpeditionMessagesScreen> {
  List<Map<String, dynamic>> members = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await CommunityService.instance.api('maps');
      final rows = (data['members'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => '${e['mapId']}' == widget.mapId && e['approved'] == 1)
          .toList();
      if (mounted) setState(() { members = rows; error = null; });
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(title: Text('Messaggi · ${widget.mapName}')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('Scrivi ai membri approvati della spedizione.', style: TextStyle(color: WildColors.muted)),
          const SizedBox(height: 12),
          if (loading) const LinearProgressIndicator(),
          if (error != null) _Notice(error!),
          if (!loading && members.isEmpty) const _Notice('Nessun altro membro approvato in questa spedizione.'),
          for (final m in members)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: WildColors.sage, child: Text('${m['nickname'] ?? '?'}'.characters.first.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: WildColors.forest))),
                title: Text('${m['nickname'] ?? 'Esploratore'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Membro della spedizione'),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () {
                  final id = '${m['memberId'] ?? m['id'] ?? ''}';
                  if (id.isEmpty) return;
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(peer: id, nickname: '${m['nickname'] ?? 'Esploratore'}')));
                },
              ),
            ),
        ],
      ),
    ),
  );
}

class ExpeditionSightingsScreen extends StatefulWidget {
  const ExpeditionSightingsScreen({super.key, required this.mapId, required this.mapName});
  final String mapId;
  final String mapName;

  @override
  State<ExpeditionSightingsScreen> createState() => _ExpeditionSightingsScreenState();
}

class _ExpeditionSightingsScreenState extends State<ExpeditionSightingsScreen> {
  @override
  void initState() {
    super.initState();
    CommunityService.instance.refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(title: Text('Avvistamenti · ${widget.mapName}')),
    body: ListenableBuilder(
      listenable: CommunityService.instance,
      builder: (context, _) {
        final c = CommunityService.instance;
        final rows = c.sightings.where((e) => '${e['groupId'] ?? ''}' == widget.mapId).toList();
        return RefreshIndicator(
          onRefresh: () => c.refresh(),
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              if (c.syncing) const LinearProgressIndicator(),
              if (rows.isEmpty) const _Notice('Nessun avvistamento condiviso in questa spedizione.'),
              for (final s in rows)
                InkWell(
                  onTap: () => showSighting(context, s),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      WildAnimalIllustration('${s['species'] ?? 'Fauna'}', size: 58),
                      const SizedBox(width: 11),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${s['species'] ?? 'Avvistamento'}', style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('${s['count'] ?? 1} individui · ${timeLabel(s['observedAt'])}', style: const TextStyle(fontSize: 11, color: WildColors.muted)),
                        if ('${s['notes'] ?? ''}'.isNotEmpty) Text('${s['notes']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class ExpeditionMapScreen extends StatefulWidget {
  const ExpeditionMapScreen({super.key, required this.mapId, required this.mapName});
  final String mapId;
  final String mapName;

  @override
  State<ExpeditionMapScreen> createState() => _ExpeditionMapScreenState();
}

class _ExpeditionMapScreenState extends State<ExpeditionMapScreen> {
  final MapController map = MapController();
  List<Map<String, dynamic>> members = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await CommunityService.instance.api('maps');
      final rows = (data['members'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => '${e['mapId']}' == widget.mapId && e['approved'] == 1)
          .toList();
      if (mounted) setState(() => members = rows);
    } catch (_) {
      if (mounted) setState(() => members = []);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<LatLng> get points {
    final result = <LatLng>[];
    for (final m in members) {
      if (m['lat'] is num && m['lng'] is num) result.add(LatLng((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()));
    }
    final p = CommunityService.instance.position;
    if (p != null) result.add(LatLng(p.latitude, p.longitude));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final pts = points;
    final initial = pts.isEmpty ? const LatLng(46.0, 12.0) : pts.first;
    return Scaffold(
      appBar: AppBar(title: Text('Mappa · ${widget.mapName}')),
      body: Stack(children: [
        FlutterMap(
          mapController: map,
          options: MapOptions(initialCenter: initial, initialZoom: 13, initialCameraFit: pts.length > 1 ? CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(50)) : null),
          children: [
            PremiumMapSurface(child: TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'it.wildtrack.app')),
            MarkerLayer(markers: [
              for (var i = 0; i < pts.length; i++)
                Marker(point: pts[i], width: 48, height: 48, child: CircleAvatar(backgroundColor: WildColors.forest, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
            ]),
            const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
          ],
        ),
        if (loading) const Positioned(top: 10, left: 14, right: 14, child: LinearProgressIndicator()),
        if (!loading && pts.isEmpty) Positioned(left: 16, right: 16, bottom: 24, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Text('Nessuna posizione di membro disponibile. Le posizioni compaiono solo quando la condivisione temporanea è attiva.', textAlign: TextAlign.center))),
      ]),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(18)), child: Text(text));
}
