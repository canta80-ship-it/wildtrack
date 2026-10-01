import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/activity_map_service.dart';
import '../services/database_service.dart';
import '../services/exploration_service.dart';
import '../services/location_service.dart';
import '../services/radar_service.dart';
import '../premium_ui.dart';
import 'offline_maps_screen.dart';
import 'outing_diary_screen.dart';
import 'premium_animal_screen.dart';
import 'species_screen.dart';

class PremiumExploreScreen extends StatefulWidget {
  const PremiumExploreScreen({super.key});

  @override
  State<PremiumExploreScreen> createState() => _PremiumExploreScreenState();
}

class _PremiumExploreScreenState extends State<PremiumExploreScreen> {
  final MapController map = MapController();
  final TextEditingController search = TextEditingController();
  late Future<RadarSnapshot> radar;
  List<NatureTrail> trails = [];
  List<NatureTrail> caiTrails = [];
  List<ActivityMapEntry> activities = [];
  NatureTrail? selectedCai;
  bool loading = false;
  bool loadingCai = false;
  bool showCai = false;
  bool showActivities = true;
  int filter = 0;

  @override
  void initState() {
    super.initState();
    radar = RadarService.instance.load();
    DatabaseService.instance.changes.addListener(_loadActivities);
    _loadPresets();
    _loadActivities();
  }

  @override
  void dispose() {
    DatabaseService.instance.changes.removeListener(_loadActivities);
    search.dispose();
    map.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      final rows = await ActivityMapService.instance.load();
      if (mounted) setState(() => activities = rows);
    } catch (_) {}
  }

  Future<void> _loadPresets() async {
    try {
      final rows = await ExplorationService.instance.presets();
      if (mounted) setState(() => trails = rows);
    } catch (_) {}
  }

  Future<void> nearby() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final rows = await ExplorationService.instance.nearby(map.camera.center);
      if (mounted) setState(() => trails = rows);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> searchCaiHere({bool openResults = true}) async {
    if (loadingCai) return;
    final center = map.camera.center;
    setState(() {
      loadingCai = true;
      showCai = true;
      selectedCai = null;
    });
    try {
      final rows = await ExplorationService.instance.caiNearby(center);
      if (!mounted) return;
      setState(() => caiTrails = rows);
      if (openResults) await _showCaiResults(rows);
    } catch (e) {
      if (mounted) {
        setState(() { showCai = false; caiTrails = []; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => loadingCai = false);
    }
  }

  Future<void> _showCaiResults(List<NatureTrail> rows) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: WildColors.ivory,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .62,
          minChildSize: .35,
          maxChildSize: .88,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Sentieri CAI in questa zona', style: WildText.h1),
              const SizedBox(height: 4),
              Text('${rows.length} percorsi trovati attorno al centro della mappa', style: const TextStyle(color: WildColors.muted)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final trail = rows[i];
                    return InkWell(
                      onTap: () { Navigator.pop(sheetContext); _selectCai(trail); },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const WildIconDisc(Icons.hiking, size: 50, background: Color(0xFFB3312D), foreground: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(trail.ref.isNotEmpty ? 'CAI ${trail.ref} · ${trail.name}' : trail.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif', fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('${(trail.length / 1000).toStringAsFixed(1)} km · ${trail.difficulty}', style: const TextStyle(fontSize: 11, color: WildColors.muted)),
                            if (trail.operatorName.isNotEmpty || trail.network.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text([trail.operatorName, trail.network].where((e) => e.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 9, color: WildColors.muted)),
                            ],
                          ])),
                          const Icon(Icons.chevron_right),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _selectCai(NatureTrail trail) {
    setState(() { selectedCai = trail; showCai = true; });
    map.move(trail.center, 14.5);
  }

  Future<void> toggleCai() async {
    if (showCai) {
      setState(() { showCai = false; selectedCai = null; });
      return;
    }
    if (caiTrails.isEmpty) {
      await searchCaiHere(openResults: false);
    } else {
      setState(() => showCai = true);
    }
  }

  Future<void> locate() async {
    final p = await LocationService.currentPosition();
    if (p == null || !mounted) return;
    map.move(LatLng(p.latitude, p.longitude), 14);
  }

  Future<void> _openLayers() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: WildColors.ivory,
      builder: (sheet) => StatefulBuilder(
        builder: (context, modalSetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Livelli mappa', style: WildText.h1),
              const SizedBox(height: 10),
              SwitchListTile(
                value: showActivities,
                onChanged: (v) { setState(() => showActivities = v); modalSetState(() {}); },
                secondary: const Icon(Icons.route_outlined),
                title: const Text('Le mie attività', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${activities.length} tracce salvate'),
              ),
              SwitchListTile(
                value: showCai,
                onChanged: (_) async { await toggleCai(); if (mounted) modalSetState(() {}); },
                secondary: const Icon(Icons.hiking, color: Color(0xFFB3312D)),
                title: const Text('Sentieri CAI', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${caiTrails.length} percorsi caricati nella zona'),
              ),
              const Divider(),
              ListTile(
                leading: const WildIconDisc(Icons.offline_map_outlined),
                title: const Text('Mappe offline', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Scarica, usa e cancella aree per navigare senza rete.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final c = map.camera.center;
                  Navigator.pop(sheet);
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OfflineMapsScreen(latitude: c.latitude, longitude: c.longitude)));
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void openSpecies(String name) {
    final animal = animals.firstWhere((a) => a.name == name);
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PremiumAnimalScreen(animal)));
  }

  List<Marker> get wildlifeMarkers => [
    Marker(point: const LatLng(46.070, 12.420), width: 54, height: 54, child: _AnimalMarker(icon: Icons.pets, onTap: () => openSpecies('Cervo'))),
    Marker(point: const LatLng(46.040, 12.450), width: 54, height: 54, child: _AnimalMarker(icon: Icons.pets, onTap: () => openSpecies('Capriolo'))),
    Marker(point: const LatLng(46.030, 12.390), width: 54, height: 54, child: _AnimalMarker(icon: Icons.visibility_outlined, earth: true, onTap: () => openSpecies('Volpe'))),
    Marker(point: const LatLng(46.085, 12.460), width: 54, height: 54, child: _AnimalMarker(icon: Icons.flutter_dash, earth: true, onTap: () => openSpecies('Poiana'))),
  ];

  @override
  Widget build(BuildContext context) {
    final active = selectedCai ?? (trails.isEmpty ? null : trails.first);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(children: [
          FlutterMap(
            mapController: map,
            options: const MapOptions(initialCenter: LatLng(46.061, 12.403), initialZoom: 12.3),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'it.wildtrack.wildtrack_mvp'),
              if (selectedCai == null && active != null)
                PolylineLayer(polylines: [for (final segment in active.segments) Polyline(points: segment, strokeWidth: 4, color: WildColors.forest)]),
              if (showActivities && activities.isNotEmpty)
                PolylineLayer(polylines: [
                  for (final entry in activities)
                    Polyline(points: entry.route, strokeWidth: entry.session.isPublic ? 5.5 : 4, color: entry.session.isPublic ? WildColors.earth : const Color(0xFF386A53), borderStrokeWidth: 1.5, borderColor: Colors.white),
                ]),
              if (showCai && caiTrails.isNotEmpty)
                PolylineLayer(polylines: [
                  for (final trail in caiTrails)
                    for (final segment in trail.segments)
                      Polyline(points: segment, strokeWidth: identical(trail, selectedCai) ? 7 : 4.5, color: identical(trail, selectedCai) ? const Color(0xFF8F1F1B) : const Color(0xFFB3312D), borderStrokeWidth: identical(trail, selectedCai) ? 2.5 : 1.5, borderColor: Colors.white),
                ]),
              MarkerLayer(markers: [
                ...wildlifeMarkers,
                if (showActivities)
                  for (final entry in activities)
                    Marker(
                      point: entry.route.first,
                      width: 38,
                      height: 38,
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OutingDiaryScreen(session: entry.session))),
                        child: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.route, size: 19, color: entry.session.isPublic ? WildColors.earth : WildColors.forest)),
                      ),
                    ),
                if (showCai)
                  for (final trail in caiTrails)
                    Marker(point: trail.center, width: 82, height: 40, child: _CaiMarker(trail: trail)),
              ]),
              const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
            ],
          ),
          Positioned(
            top: 8,
            left: 14,
            right: 14,
            child: Column(children: [
              const Row(children: [WildLogo(compact: true), Spacer(), Icon(Icons.notifications_none, color: WildColors.forest), SizedBox(width: 10), CircleAvatar(radius: 18, backgroundImage: AssetImage('intro_cervo.jpg'))]),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .96), borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 15)]),
                child: TextField(controller: search, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Cerca sentieri, specie, luoghi…', suffixIcon: IconButton(onPressed: nearby, icon: const Icon(Icons.tune)), border: InputBorder.none)),
              ),
              const SizedBox(height: 9),
              _Filters(selected: filter, onTap: (i) => setState(() => filter = i)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: FilledButton.tonalIcon(onPressed: loadingCai ? null : () => searchCaiHere(), icon: loadingCai ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore), label: const Text('Cerca CAI qui'), style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .95), foregroundColor: const Color(0xFF8F2825), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))))),
                const SizedBox(width: 8),
                IconButton.filledTonal(onPressed: loadingCai ? null : toggleCai, tooltip: showCai ? 'Nascondi sentieri CAI' : 'Mostra sentieri CAI', icon: Icon(showCai ? Icons.visibility : Icons.visibility_off_outlined), style: IconButton.styleFrom(backgroundColor: showCai ? const Color(0xFFB3312D) : Colors.white, foregroundColor: showCai ? Colors.white : const Color(0xFF8F2825))),
              ]),
              const SizedBox(height: 9),
              FutureBuilder<RadarSnapshot>(
                future: radar,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final top = data?.species.take(2).map((e) => e.name.toLowerCase()).join(', ') ?? 'calcolo in corso';
                  return InkWell(
                    onTap: () => setState(() => radar = RadarService.instance.load()),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .95), borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 15)]),
                      child: Row(children: [
                        const WildIconDisc(Icons.radar, size: 50, background: WildColors.forest, foreground: Colors.white),
                        const SizedBox(width: 11),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('WildTrack Radar', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800, fontSize: 18)),
                          Text('Probabilità ${data?.activity.toLowerCase() ?? '…'}: $top', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const Text('Stima basata su ora, stagione, meteo e storico privato', style: TextStyle(fontSize: 9, color: WildColors.muted)),
                        ])),
                        const Icon(Icons.chevron_right),
                      ]),
                    ),
                  );
                },
              ),
            ]),
          ),
          Positioned(right: 14, bottom: 215, child: Column(children: [
            _MapButton(icon: Icons.layers_outlined, onTap: _openLayers),
            const SizedBox(height: 8),
            _MapButton(icon: Icons.download_for_offline_outlined, onTap: () { final c = map.camera.center; Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OfflineMapsScreen(latitude: c.latitude, longitude: c.longitude))); }),
            const SizedBox(height: 8),
            _MapButton(icon: Icons.my_location, onTap: locate),
          ])),
          Positioned(left: 14, right: 14, bottom: 20, child: _TrailCard(trail: active, onRefresh: selectedCai != null ? () => searchCaiHere() : nearby)),
          if (loading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
        ]),
      ),
    );
  }
}

class _CaiMarker extends StatelessWidget {
  const _CaiMarker({required this.trail});
  final NatureTrail trail;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFB3312D), width: 1.5), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)]),
    child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.hiking, size: 14, color: Color(0xFFB3312D)), const SizedBox(width: 4), Flexible(child: Text(trail.ref.isNotEmpty ? 'CAI ${trail.ref}' : 'CAI', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF8F2825))))]),
  );
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onTap});
  final int selected;
  final ValueChanged<int> onTap;
  static const data = [(Icons.hiking, 'Sentieri'), (Icons.pets, 'Specie'), (Icons.groups_outlined, 'Community'), (Icons.radar, 'Radar')];
  @override
  Widget build(BuildContext context) => Row(children: [for (var i = 0; i < data.length; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == data.length - 1 ? 0 : 6), child: InkWell(onTap: () => onTap(i), borderRadius: BorderRadius.circular(20), child: Container(height: 43, decoration: BoxDecoration(color: selected == i ? WildColors.forest : Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(data[i].$1, size: 17, color: selected == i ? Colors.white : WildColors.forest), const SizedBox(width: 4), Text(data[i].$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected == i ? Colors.white : WildColors.ink))])))))]);
}

class _AnimalMarker extends StatelessWidget {
  const _AnimalMarker({required this.icon, required this.onTap, this.earth = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool earth;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: CircleAvatar(backgroundColor: Colors.white, child: CircleAvatar(radius: 20, backgroundColor: earth ? WildColors.earth : WildColors.forest, child: Icon(icon, color: Colors.white, size: 21))));
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(17), elevation: 3, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: SizedBox(width: 52, height: 52, child: Icon(icon, color: WildColors.forest))));
}

class _TrailCard extends StatelessWidget {
  const _TrailCard({required this.trail, required this.onRefresh});
  final NatureTrail? trail;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Container(
    height: 175,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .97), borderRadius: BorderRadius.circular(25), boxShadow: const [BoxShadow(color: Color(0x25000000), blurRadius: 22, offset: Offset(0, 7))]),
    child: trail == null
        ? Center(child: FilledButton.icon(onPressed: onRefresh, icon: const Icon(Icons.hiking), label: const Text('Carica sentieri qui')))
        : Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('intro_cervo.jpg', width: 135, height: 145, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trail!.name, style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800, fontSize: 19), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(10)), child: Text(trail!.isCai ? 'Sentiero CAI${trail!.ref.isNotEmpty ? ' · ${trail!.ref}' : ''}' : 'Sentiero OSM', style: TextStyle(fontSize: 9, color: trail!.isCai ? const Color(0xFFB3312D) : WildColors.forest, fontWeight: FontWeight.w700))),
              const Spacer(),
              Text(trail!.difficulty == 'Non indicata' ? 'Tra boschi e paesaggi naturali, con possibilità di osservazione.' : 'Difficoltà: ${trail!.difficulty}', style: const TextStyle(fontSize: 10, color: WildColors.muted, height: 1.25)),
              const Spacer(),
              Row(children: [const Icon(Icons.route, size: 15), const SizedBox(width: 4), Text('${(trail!.length / 1000).toStringAsFixed(1)} km', style: const TextStyle(fontSize: 10)), const Spacer(), const Icon(Icons.chevron_right)]),
            ])),
          ]),
  );
}
