import 'premium_map_widget.dart';
import 'profile_avatar_widget.dart';
import 'community_screen.dart' show ChatScreen, showSighting;
import 'radar_map_widget.dart';
import '../services/habitat_map_service.dart';
import '../services/radar_map_service.dart';
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
import '../premium_ui.dart';
import 'offline_maps_screen.dart';
import 'outing_diary_screen.dart';
import 'premium_animal_screen.dart';
import 'species_screen.dart';
import 'premium_sighting_screen.dart';
import 'map_position_screen.dart';

class PremiumExploreScreen extends StatefulWidget {
  const PremiumExploreScreen({super.key, this.initialPosition, this.tileProvider, this.enableLocation = true, this.initialCommunity = false});
  final LatLng? initialPosition;
  final TileProvider? tileProvider;
  final bool enableLocation;
  final bool initialCommunity;

  @override
  State<PremiumExploreScreen> createState() => _PremiumExploreScreenState();
}

class _PremiumExploreScreenState extends State<PremiumExploreScreen> {
  final MapController map = MapController();
  final TextEditingController search = TextEditingController();
  List<NatureTrail> trails = [];
  List<ActivityMapEntry> activities = [];
  NatureTrail? selectedTrail;
  bool loading = false;
  bool searchOpen = false;
  bool showActivities = true;
  int filter = 0;
  late final MapLocationService location;
  bool mapReady = false;
  double labelZoom = 12.3;
  bool centeredOnPosition = false;
  int radarMode = 2, radarGeneration = 0;
  double radarRadius = 5;
  bool radarBusy = false;
  String? radarError, radarSpecies;
  LatLng? radarCenter;
  List<HabitatPatch> radarPatches = [];
  List<Map<String,dynamic>> radarObservations = [];
  ActivityMapEntry? radarRoute;
  List<HabitatPatch>? matchedRoutePatches;
  Timer? radarTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialCommunity) {filter = 1; centeredOnPosition = true;}
    CommunityService.instance.addListener(_communityChanged);
    unawaited(CommunityService.instance.updatePresence());
    location = MapLocationService(initialPosition: widget.initialPosition)..addListener(_positionChanged);
    DatabaseService.instance.changes.addListener(_loadActivities);
    _loadPresets();
    _loadActivities();
    radarTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (filter == 2 && !radarBusy) unawaited(_refreshRadar());
    });
  }

  @override
  void dispose() {
    DatabaseService.instance.changes.removeListener(_loadActivities);
    location.removeListener(_positionChanged);
    location.dispose();
    radarTimer?.cancel();
    search.dispose();
    map.dispose();
    CommunityService.instance.removeListener(_communityChanged);
    super.dispose();
  }

  void _communityChanged() {
    if (!mounted) return;
    setState(() {
      final ids = radarObservations.map((r) => r['id']).toSet();
      radarObservations.addAll(CommunityService.instance.sightings.where((r) => !ids.contains(r['id'])));
    });
  }

  List<Map<String,dynamic>> get _radarObserved => radarCenter == null ? [] : RadarMapService.observations(radarObservations, radarCenter!, radarRadius, DateTime.now(), species: radarSpecies);
  List<HabitatPatch> get _routePatches => radarRoute == null ? radarPatches : (matchedRoutePatches ??= radarPatches.where((p) => RadarMapService.onRoute(p, radarRoute!.segments)).toList());
  List<RadarPossibleSpecies> get _radarPossible => RadarMapService.possible(_routePatches, _radarObserved, DateTime.now(), species: radarSpecies);

  void _changeFilter(int value) {
    setState(() => filter = value);
    if (value == 2 && radarCenter == null) unawaited(_refreshRadar());
  }

  Future<List<Map<String,dynamic>>> _loadRadarObservations(int generation) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    final rows = <Map<String,dynamic>>[];
    int? offset = 0;
    for (var page = 0; page < 20 && offset != null; page++) {
      final data = await CommunityService.instance.api('sightings?offset=$offset');
      if (!mounted || generation != radarGeneration) return [];
      rows.addAll((data['items'] as List).map((r) => Map<String,dynamic>.from(r as Map)).where((r) => r['groupId'] == null));
      final next = data['nextOffset'] as int?;
      if (next != null && next <= offset) break;
      offset = next;
      if (DateTime.now().isAfter(deadline)) break;
    }
    return rows;
  }

  Future<void> _refreshRadar({LatLng? center, bool frame = true}) async {
    if (!mapReady) return;
    final area = center ?? map.camera.center;
    final generation = ++radarGeneration;
    final radius = radarRadius;
    setState(() {
      radarBusy = true; radarError = null; radarCenter = area;
      radarPatches = []; matchedRoutePatches = null; radarObservations = [];
    });
    // Run both sources independently so observations remain available if OSM fails.
    final results = await Future.wait<Object>([
      HabitatMapService.instance.load('__radar__', area, radiusKm: radius, forceRefresh: true).then<Object>((v) => v).catchError((Object e) => e),
      _loadRadarObservations(generation).then<Object>((v) => v).catchError((Object e) => e),
    ]);
    if (!mounted || generation != radarGeneration) return;
    setState(() {
      radarBusy = false; matchedRoutePatches = null;
      radarPatches = results[0] is List<HabitatPatch> ? results[0] as List<HabitatPatch> : [];
      radarObservations = results[1] is List<Map<String,dynamic>> ? results[1] as List<Map<String,dynamic>> : List.from(CommunityService.instance.sightings);
      radarError = [if (results[0] is! List<HabitatPatch>) 'Zone habitat non disponibili: riprova con una connessione attiva.', if (results[1] is! List<Map<String,dynamic>>) 'Avvistamenti non aggiornati: sono mostrati quelli già caricati.'].join(' ');
      if (radarError!.isEmpty) radarError = null;
    });
    if (frame && filter == 2) {
      final points = [for (final p in displayedPatchesForFrame()) ...p.points, for (final row in _radarObserved) RadarMapService.observationPoint(row)!];
      if (points.length > 1) map.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: _radarPadding, maxZoom: 14));
    }
  }

  EdgeInsets get _radarPadding {
    final height = MediaQuery.sizeOf(context).height;
    return EdgeInsets.fromLTRB(30, searchOpen ? 222 : 165, 30, height * .14);
  }

  List<HabitatPatch> displayedPatchesForFrame() => _radarPossible.expand((s) => s.patches).where((p) => p.points.every((point) => RadarMapService.distance.as(LengthUnit.Kilometer, radarCenter!, point) <= radarRadius * 1.5)).toList();

  void _expandRadar() {
    setState(() => radarRadius = radarRadius < 5 ? 5 : 10);
    unawaited(_refreshRadar(center: radarCenter));
  }

  void _showPossible(RadarPossibleSpecies species) {
    setState(() { radarSpecies = species.name; radarMode = 0; });
    if (species.patches.isNotEmpty) map.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(species.patches.expand((p) => p.points).toList()), padding: _radarPadding, maxZoom: 15));
  }

  void _showObserved(Map<String,dynamic> row) {
    final point = RadarMapService.observationPoint(row);
    if (point != null) map.move(point, 15);
    unawaited(showSighting(context, row));
  }

  Future<void> _openActivity(ActivityMapEntry entry) async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true, backgroundColor: WildColors.ivory, builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.book_outlined), title: const Text('Apri diario e modifica traccia'), onTap: () { Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OutingDiaryScreen(session: entry.session))); }),
      ListTile(leading: const Icon(Icons.radar), title: const Text('Radar lungo questa traccia'), subtitle: const Text('Habitat attraversati · area entro 10 km dall’inizio'), onTap: () { Navigator.pop(sheet); setState(() { filter = 2; radarRoute = entry; matchedRoutePatches = null; radarRadius = 10; radarSpecies = null; }); unawaited(_refreshRadar(center: entry.route.first)); }),
    ])));
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
      setState(() { filter = 2; radarSpecies = animal.name; radarRoute = null; });
      if (radarCenter == null) unawaited(_refreshRadar());
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
        if (filter == 2) unawaited(_refreshRadar(center: results.first.point));
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
                      if (filter == 2) unawaited(_refreshRadar(center: r.point));
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
      if (filter == 2) unawaited(_refreshRadar(center: location.point));
    }
  }

  Future<void> locate() async {
    await location.refresh();
    if (!mounted) return;
    if (location.point != null && mapReady) { map.move(location.point!, 14); if (filter == 2) unawaited(_refreshRadar(center: location.point)); }
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
          width: 110,
          height: 65,
          child: GestureDetector(
            onTap: () => showModalBottomSheet<void>(context: context, builder: (sheet) => SafeArea(child: ListTile(leading: ProfileAvatar(url: p['avatarUrl'] as String?), title: Text('${p['nickname'] ?? 'Esploratore'}'), subtitle: const Text('Posizione condivisa · entro 15 km'), trailing: const Icon(Icons.chat_bubble_outline), onTap: () {Navigator.pop(sheet);Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(peer: '${p['id']}', nickname: '${p['nickname'] ?? 'Esploratore'}')));}))),
            child: Column(children: [ProfileAvatar(url: p['avatarUrl'] as String?, radius: 18), Container(padding: const EdgeInsets.symmetric(horizontal: 4), color: Colors.white, child: Text('${p['nickname'] ?? 'Esploratore'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WildColors.forest)))]),
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
    final possible = showRadar ? _radarPossible : <RadarPossibleSpecies>[];
    final observed = showRadar ? _radarObserved : <Map<String,dynamic>>[];
    final displayedPatches = <String,HabitatPatch>{for (final species in possible) for (final patch in species.patches) patch.id: patch}.values.toList();
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
                onPositionChanged: (camera, _) { if ((camera.zoom - labelZoom).abs() >= .5 && mounted) setState(() => labelZoom = camera.zoom); },
                onLongPress: (_, point) => _recordHere(point),
              ),
              children: [
                PremiumMapSurface(child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: widget.tileProvider,
                  userAgentPackageName: 'it.wildtrack.app',
                )),
                if (showRadar && radarMode != 1)
                  PolygonLayer(polygons: [for (final patch in displayedPatches) Polygon(points: RadarMapService.softRing(patch.points), holePointsList: patch.holes.map(RadarMapService.softRing).toList(), color: radarSage.withValues(alpha: .34), borderColor: WildColors.forest.withValues(alpha: .85), borderStrokeWidth: 2.2, pattern: StrokePattern.dashed(segments: [7, 5]))]),
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
                        for (final segment in entry.segments) Polyline(
                          points: segment,
                          strokeWidth: entry.session.isPublic ? 5.5 : 4,
                          color: entry.session.isPublic
                              ? WildColors.earth
                              : const Color(0xFF386A53),
                          borderStrokeWidth: 1.5,
                          borderColor: Colors.white,
                        ),
                    ],
                  ),
                if (showRadar && radarMode != 0)
                  CircleLayer(circles: [for (final row in observed.where((r) => r['approximate'] == 1 || r['approximate'] == true)) CircleMarker(point: RadarMapService.observationPoint(row)!, radius: ((row['privacyRadiusM'] as num?)?.toDouble() ?? 1000).clamp(100,10000).toDouble(), useRadiusInMeter: true, color: radarAmber.withValues(alpha: .06), borderColor: radarAmber.withValues(alpha: .25), borderStrokeWidth: 1)]),
                MarkerLayer(
                  markers: [
                    if (showSpecies) ..._speciesMarkers(),
                    if (showRadar && radarMode != 1)
                      for (final patch in RadarMapService.labelPatches(displayedPatches, radarCenter!, labelZoom))
                        Marker(point: RadarMapService.labelAnchor(patch, radarCenter!), width: 112,height: 77,child: RadarPossiblePin(possible.firstWhere((s) => s.patches.any((p) => p.id == patch.id)).name, onTap: () => _showPossible(possible.firstWhere((s) => s.patches.any((p) => p.id == patch.id))))),
                    if (showRadar && radarMode != 0)
                      for (final row in observed.take(100)) Marker(point: RadarMapService.observationPoint(row)!,width:56,height:60,child:RadarObservedPin(row,onTap:()=>_showObserved(row))),
                    if (showCommunity) ..._peopleMarkers(),
                    if (showActivities)
                      for (final entry in activities)
                        Marker(
                          point: entry.route.first,
                          width: 38,
                          height: 38,
                          child: InkWell(
                            onTap: () => _openActivity(entry),
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
                    if (location.point != null) premiumPositionMarker(location.point!),
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
                      const Expanded(child: Align(alignment: Alignment.centerLeft, child: FittedBox(fit: BoxFit.scaleDown, child: WildLogo(compact: true)))),
                      IconButton.filledTonal(tooltip: 'Cerca specie o luoghi', onPressed: () => setState(() => searchOpen = !searchOpen), icon: Icon(searchOpen ? Icons.close : Icons.search)),
                      IconButton.filledTonal(
                        tooltip: 'Nuovo avvistamento dalla mappa',
                        onPressed: _newSightingFromMap,
                        icon: const Icon(WildIcons.binoculars),
                      ),
                      IconButton.filledTonal(
                        onPressed: _openLayers,
                        icon: const Icon(Icons.layers_outlined),
                      ),

                    ],
                  ),
                  if (searchOpen) ...[
                  const SizedBox(height: 6),
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
                  ],
                  const SizedBox(height: 6),
                  _Filters(
                    selected: filter,
                    onTap: _changeFilter,
                  ),
                  if (showRadar) ...[
                    const SizedBox(height: 9),
                    RadarMapHeader(mode: radarMode, onMode: (v) => setState(() => radarMode = v), busy: radarBusy, radius: radarRadius, onRefresh: () => unawaited(_refreshRadar()), onExpand: _expandRadar, species: radarSpecies, onClearSpecies: () => setState(() { radarSpecies = null; search.clear(); }), routeName: radarRoute == null ? null : (radarRoute!.session.name.isNotEmpty ? radarRoute!.session.name : 'la tua traccia'), onClearRoute: () => setState(() => radarRoute = null)),
                  ],
                ],
              ),
            ),
            if (showRadar) RadarResultsSheet(possible: possible, observed: observed, mode: radarMode, busy: radarBusy, error: radarError, onPossible: _showPossible, onObserved: _showObserved, onExpand: _expandRadar),
            Positioned(
              right: 14,
              bottom: showRadar ? MediaQuery.sizeOf(context).height * .11 + 12 : 34,
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

