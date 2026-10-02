import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/activity_map_service.dart';
import '../services/community_service.dart';
import '../services/database_service.dart';
import '../services/exploration_service.dart';
import '../services/map_location_service.dart';
import 'map_position_marker_widget.dart';
import '../services/place_search_service.dart';
import '../services/radar_service.dart';
import '../premium_ui.dart';
import 'offline_maps_screen.dart';
import 'outing_diary_screen.dart';
import 'premium_animal_screen.dart';
import 'species_screen.dart';
import 'premium_sighting_screen.dart';
import 'map_position_screen.dart';

class PremiumExploreScreen extends StatefulWidget {
  const PremiumExploreScreen({super.key, this.initialPosition, this.tileProvider, this.enableLocation = true});
  final LatLng? initialPosition;
  final TileProvider? tileProvider;
  final bool enableLocation;

  @override
  State<PremiumExploreScreen> createState() => _PremiumExploreScreenState();
}

class _PremiumExploreScreenState extends State<PremiumExploreScreen> {
  final MapController map = MapController();
  final TextEditingController search = TextEditingController();
  late Future<RadarSnapshot> radar;
  List<NatureTrail> trails = [];
  List<ActivityMapEntry> activities = [];
  NatureTrail? selectedTrail;
  bool loading = false;
  bool showActivities = true;
  int filter = 0;
  late final MapLocationService location;
  bool mapReady = false;
  bool centeredOnPosition = false;

  @override
  void initState() {
    super.initState();
    location = MapLocationService(initialPosition: widget.initialPosition)..addListener(_positionChanged);
    radar = RadarService.instance.load();
    DatabaseService.instance.changes.addListener(_loadActivities);
    _loadPresets();
    _loadActivities();
  }

  @override
  void dispose() {
    DatabaseService.instance.changes.removeListener(_loadActivities);
    location.removeListener(_positionChanged);
    location.dispose();
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



  void _selectTrail(NatureTrail trail) {
    setState(() {
      selectedTrail = trail;
    });
    map.move(trail.center, 14.5);
  }

  Future<void> _search() async {
    final q = search.text.trim();
    if (q.isEmpty) return;
    final lower = q.toLowerCase();

    final animal = animals
        .where(
          (a) =>
              a.name.toLowerCase().contains(lower) ||
              a.latin.toLowerCase().contains(lower),
        )
        .firstOrNull;
    if (animal != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => PremiumAnimalScreen(animal)),
      );
      return;
    }

    final trail = trails
        .where(
          (t) =>
              t.name.toLowerCase().contains(lower) ||
              t.ref.toLowerCase() == lower,
        )
        .firstOrNull;
    if (trail != null) {
      _selectTrail(trail);
      return;
    }

    setState(() => loading = true);
    try {
      final results = await PlaceSearchService.instance.search(q);
      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nessun luogo o specie trovato.'),
          ),
        );
        return;
      }
      if (results.length == 1) {
        map.move(results.first.point, 14);
      } else {
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(
                  title: Text(
                    'Risultati',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final r in results)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(r.name),
                    onTap: () {
                      Navigator.pop(sheet);
                      map.move(r.point, 14);
                    },
                  ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _positionChanged() {
    if (!mounted) return;
    setState(() {});
    if (mapReady && !centeredOnPosition && location.point != null) {
      centeredOnPosition = true;
      map.move(location.point!, 14);
    }
  }

  Future<void> locate() async {
    await location.refresh();
    if (!mounted) return;
    if (location.point != null && mapReady) { map.move(location.point!, 14); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(location.error ?? 'Acquisizione della posizione in corso…'))); }
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Livelli mappa', style: WildText.h1),
                SwitchListTile(
                  value: showActivities,
                  onChanged: (v) {
                    setState(() => showActivities = v);
                    modalSetState(() {});
                  },
                  secondary: const Icon(Icons.route_outlined),
                  title: const Text('Le mie attività'),
                  subtitle: Text('${activities.length} tracce salvate'),
                ),
                const Divider(),
                ListTile(
                  leading: const WildIconDisc(Icons.map_outlined),
                  title: const Text(
                    'Mappe offline',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Scarica, usa e cancella aree per navigare senza rete.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final c = map.camera.center;
                    Navigator.pop(sheet);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => OfflineMapsScreen(
                          latitude: c.latitude,
                          longitude: c.longitude,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _speciesMarkers() {
    final rows = CommunityService.instance.sightings;
    return rows.where((s) => s['lat'] is num && s['lng'] is num).take(80).map((
      s,
    ) {
      final species = '${s['species'] ?? 'Fauna'}';
      return Marker(
        point: LatLng(
          (s['lat'] as num).toDouble(),
          (s['lng'] as num).toDouble(),
        ),
        width: 48,
        height: 48,
        child: InkWell(
          onTap: () {
            final a = animals.where((x) => x.name == species).firstOrNull;
            if (a != null)
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => PremiumAnimalScreen(a)),
              );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: WildColors.forest, width: 2),
            ),
            padding: const EdgeInsets.all(5),
            child: WildAnimalIllustration(species, size: 38),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _peopleMarkers() => CommunityService.instance.people
      .where((p) => p['lat'] is num && p['lng'] is num)
      .map(
        (p) => Marker(
          point: LatLng(
            (p['lat'] as num).toDouble(),
            (p['lng'] as num).toDouble(),
          ),
          width: 46,
          height: 46,
          child: CircleAvatar(
            backgroundColor: WildColors.sage,
            child: Text(
              '${p['nickname'] ?? '?'}'.characters.first.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: WildColors.forest,
              ),
            ),
          ),
        ),
      )
      .toList();

  void _recordHere(LatLng point) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PremiumSightingScreen(initialPosition: point),
      ),
    );
  }

  Future<void> _newSightingFromMap() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute<LatLng>(
        builder: (_) => MapPositionScreen(initialPosition: map.camera.center),
      ),
    );
    if (point != null && mounted) _recordHere(point);
  }

  @override
  Widget build(BuildContext context) {
    final showTrails = selectedTrail != null;
    final showSpecies = filter == 0;
    final showCommunity = filter == 1;
    final showRadar = filter == 2;
    final activeTrail = selectedTrail ?? (trails.isEmpty ? null : trails.first);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            FlutterMap(
              mapController: map,
              options: MapOptions(
                initialCenter: widget.initialPosition ?? const LatLng(46.061, 12.403),
                onMapReady: () {
                  mapReady = true;
                  if (widget.enableLocation) unawaited(location.start());
                  _positionChanged();
                },
                initialZoom: 12.3,
                onLongPress: (_, point) => _recordHere(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: widget.tileProvider,
                  userAgentPackageName: 'it.wildtrack.app',
                ),
                if (showTrails && activeTrail != null)
                  PolylineLayer(
                    polylines: [
                      for (final segment in activeTrail.segments)
                        Polyline(
                          points: segment,
                          strokeWidth: 4,
                          color: WildColors.forest,
                        ),
                    ],
                  ),
                if (showActivities && activities.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      for (final entry in activities)
                        Polyline(
                          points: entry.route,
                          strokeWidth: entry.session.isPublic ? 5.5 : 4,
                          color: entry.session.isPublic
                              ? WildColors.earth
                              : const Color(0xFF386A53),
                          borderStrokeWidth: 1.5,
                          borderColor: Colors.white,
                        ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (location.point != null) premiumPositionMarker(location.point!),
                    if (showSpecies) ..._speciesMarkers(),
                    if (showCommunity) ..._peopleMarkers(),
                    if (showActivities)
                      for (final entry in activities)
                        Marker(
                          point: entry.route.first,
                          width: 38,
                          height: 38,
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    OutingDiaryScreen(session: entry.session),
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.route,
                                size: 19,
                                color: entry.session.isPublic
                                    ? WildColors.earth
                                    : WildColors.forest,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 14,
              right: 14,
              child: Column(
                children: [
                  Row(
                    children: [
                      const WildLogo(compact: true),
                      const Spacer(),
                      IconButton.filledTonal(
                        tooltip: 'Nuovo avvistamento dalla mappa',
                        onPressed: _newSightingFromMap,
                        icon: const Icon(WildIcons.binoculars),
                      ),
                      IconButton.filledTonal(
                        onPressed: _openLayers,
                        icon: const Icon(Icons.layers_outlined),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: locate,
                        icon: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .96),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(color: Color(0x18000000), blurRadius: 15),
                      ],
                    ),
                    child: TextField(
                      controller: search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Cerca specie o luoghi…',
                        suffixIcon: IconButton(
                          onPressed: loading ? null : _search,
                          icon: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _Filters(
                    selected: filter,
                    onTap: (i) => setState(() => filter = i),
                  ),
                  if (showRadar) ...[
                    const SizedBox(height: 9),
                    FutureBuilder<RadarSnapshot>(
                      future: radar,
                      builder: (context, snapshot) {
                        final data = snapshot.data;
                        final top =
                            data?.species
                                .take(2)
                                .map((e) => e.name.toLowerCase())
                                .join(', ') ??
                            'calcolo in corso';
                        return InkWell(
                          onTap: () => setState(
                            () => radar = RadarService.instance.load(),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .95),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const WildIconDisc(
                                  Icons.radar,
                                  size: 50,
                                  background: WildColors.forest,
                                  foreground: Colors.white,
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'WildTrack Radar',
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        'Probabilità ${data?.activity.toLowerCase() ?? '…'}: $top',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Text(
                                        'Stima basata su ora, stagione, meteo e storico privato',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: WildColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.refresh),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              right: 14,
              bottom: 34,
              child: FloatingActionButton.small(
                onPressed: locate,
                backgroundColor: Colors.white,
                foregroundColor: WildColors.forest,
                child: const Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onTap});
  final int selected;
  final ValueChanged<int> onTap;
  static const data = [
    (Icons.pets, 'Specie'),
    (Icons.groups_outlined, 'Community'),
    (Icons.radar, 'Radar'),
  ];
  @override
  Widget build(BuildContext context) => Container(
    height: 47,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        for (var i = 0; i < data.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected == i ? WildColors.forest : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      data[i].$1,
                      size: 16,
                      color: selected == i ? Colors.white : WildColors.forest,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data[i].$2,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: selected == i ? Colors.white : WildColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
