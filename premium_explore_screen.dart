import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/activity_map_service.dart';
import '../services/community_service.dart';
import '../services/database_service.dart';
import '../services/exploration_service.dart';
import '../services/location_service.dart';
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
  NatureTrail? selectedTrail;
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
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> searchCaiHere({bool openResults = true}) async {
    if (loadingCai) return;
    setState(() {
      loadingCai = true;
      showCai = true;
      selectedTrail = null;
    });
    try {
      final rows = await ExplorationService.instance.caiNearby(
        map.camera.center,
      );
      if (!mounted) return;
      setState(() => caiTrails = rows);
      if (openResults) await _showCaiResults(rows);
    } catch (e) {
      if (mounted) {
        setState(() {
          caiTrails = [];
          showCai = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sentieri CAI in questa zona', style: WildText.h1),
                const SizedBox(height: 4),
                Text(
                  rows.isEmpty
                      ? 'Nessun percorso verificabile trovato.'
                      : '${rows.length} percorsi trovati attorno al centro della mappa',
                  style: const TextStyle(color: WildColors.muted),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final trail = rows[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        tileColor: Colors.white,
                        leading: const WildIconDisc(
                          Icons.hiking,
                          size: 48,
                          background: Color(0xFFB3312D),
                          foreground: Colors.white,
                        ),
                        title: Text(
                          trail.ref.isNotEmpty
                              ? 'CAI ${trail.ref} · ${trail.name}'
                              : trail.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '${(trail.length / 1000).toStringAsFixed(1)} km · ${trail.difficulty}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _selectTrail(trail);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectTrail(NatureTrail trail) {
    setState(() {
      selectedTrail = trail;
      showCai = trail.isCai || showCai;
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

    final trail = [...trails, ...caiTrails]
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
            content: Text('Nessun luogo, specie o sentiero trovato.'),
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

  Future<void> toggleCai() async {
    if (showCai) {
      setState(() {
        showCai = false;
        selectedTrail = null;
      });
      return;
    }
    if (caiTrails.isEmpty)
      await searchCaiHere(openResults: false);
    else
      setState(() => showCai = true);
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
                SwitchListTile(
                  value: showCai,
                  onChanged: (_) async {
                    await toggleCai();
                    if (mounted) modalSetState(() {});
                  },
                  secondary: const Icon(Icons.hiking, color: Color(0xFFB3312D)),
                  title: const Text('Sentieri CAI'),
                  subtitle: Text('${caiTrails.length} percorsi caricati'),
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
    final showTrails = filter == 0;
    final showSpecies = filter == 1;
    final showCommunity = filter == 2;
    final showRadar = filter == 3;
    final activeTrail = selectedTrail ?? (trails.isEmpty ? null : trails.first);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            FlutterMap(
              mapController: map,
              options: MapOptions(
                initialCenter: const LatLng(46.061, 12.403),
                initialZoom: 12.3,
                onLongPress: (_, point) => _recordHere(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                if (showCai && caiTrails.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      for (final trail in caiTrails)
                        for (final segment in trail.segments)
                          Polyline(
                            points: segment,
                            strokeWidth: identical(trail, selectedTrail)
                                ? 7
                                : 4.5,
                            color: identical(trail, selectedTrail)
                                ? const Color(0xFF8F1F1B)
                                : const Color(0xFFB3312D),
                            borderStrokeWidth: 1.5,
                            borderColor: Colors.white,
                          ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
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
                    if (showCai)
                      for (final trail in caiTrails)
                        Marker(
                          point: trail.center,
                          width: 84,
                          height: 38,
                          child: InkWell(
                            onTap: () => _selectTrail(trail),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFB3312D),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.hiking,
                                    size: 14,
                                    color: Color(0xFFB3312D),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      trail.ref.isNotEmpty
                                          ? 'CAI ${trail.ref}'
                                          : 'CAI',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF8F2825),
                                      ),
                                    ),
                                  ),
                                ],
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
                        hintText: 'Cerca sentieri, specie, luoghi…',
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: loadingCai ? null : () => searchCaiHere(),
                          icon: loadingCai
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.travel_explore),
                          label: const Text('Cerca CAI qui'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: .95,
                            ),
                            foregroundColor: const Color(0xFF8F2825),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: loadingCai ? null : toggleCai,
                        icon: Icon(
                          showCai
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: showCai
                              ? const Color(0xFFB3312D)
                              : Colors.white,
                          foregroundColor: showCai
                              ? Colors.white
                              : const Color(0xFF8F2825),
                        ),
                      ),
                    ],
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
                onPressed: nearby,
                backgroundColor: Colors.white,
                foregroundColor: WildColors.forest,
                child: const Icon(Icons.refresh),
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
    (Icons.hiking, 'Sentieri'),
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
