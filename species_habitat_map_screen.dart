import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../premium_ui.dart';
import '../services/habitat_map_service.dart';
import '../services/map_location_service.dart';
import 'map_position_marker_widget.dart';
import 'species_screen.dart';

class SpeciesHabitatMapScreen extends StatefulWidget {
  const SpeciesHabitatMapScreen(this.animal, {super.key, this.initialPosition, this.tileProvider, this.enableLocation = true, this.loader});
  final Animal animal;
  final LatLng? initialPosition;
  final TileProvider? tileProvider;
  final bool enableLocation;
  final Future<List<HabitatPatch>> Function(String, LatLng)? loader;
  @override
  State<SpeciesHabitatMapScreen> createState() => _SpeciesHabitatMapScreenState();
}

class _SpeciesHabitatMapScreenState extends State<SpeciesHabitatMapScreen> {
  final map = MapController();
  late final MapLocationService location;
  List<HabitatPatch> patches = [];
  bool ready = false, loading = false, centered = false;
  String? error;
  int request = 0;
  @override
  void initState() {
    super.initState();
    location = MapLocationService(initialPosition: widget.initialPosition)..addListener(_positionChanged);
  }
  void _positionChanged() {
    if (!mounted) return;
    setState(() {});
    if (ready && !centered && location.point != null) {
      centered = true;
      map.move(location.point!, 13);
      unawaited(_load(location.point!));
    }
  }
  Future<void> _load(LatLng center) async {
    final epoch = ++request;
    setState(() { loading = true; error = null; patches = []; });
    try {
      final result = await (widget.loader ?? HabitatMapService.instance.load)(widget.animal.name, center);
      if (mounted && epoch == request) setState(() { patches = result; });
    } catch (_) {
      if (mounted && epoch == request) setState(() { error = 'Habitat non disponibili. Controlla la rete e riprova.'; });
    } finally {
      if (mounted && epoch == request) setState(() { loading = false; });
    }
  }
  Future<void> _locate() async {
    await location.refresh();
    if (!mounted) return;
    if (location.point != null) { map.move(location.point!, 13); await _load(location.point!); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(location.error ?? 'Attiva il GPS per visualizzare la tua posizione.'))); }
  }
  @override
  void dispose() { request++; location.removeListener(_positionChanged); location.dispose(); map.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(title: Text('Habitat · ${widget.animal.name}'), actions: [IconButton(tooltip: 'La tua posizione', onPressed: ready ? _locate : null, icon: const Icon(Icons.my_location))]),
    body: Column(children: [
      Expanded(child: FlutterMap(
        mapController: map,
        options: MapOptions(initialCenter: widget.initialPosition ?? const LatLng(46.06, 12.39), initialZoom: 13, onMapReady: () {
          ready = true;
          if (location.point != null) _positionChanged();
          else unawaited(_load(map.camera.center));
          if (widget.enableLocation) unawaited(location.start());
        }),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'it.wildtrack.preview', tileProvider: widget.tileProvider),
          PolygonLayer(polygons: patches.map((patch) => Polygon(points: patch.points, holePointsList: patch.holes, color: WildColors.forest.withValues(alpha: .23), borderColor: WildColors.forest, borderStrokeWidth: 2)).toList()),
          if (location.point != null) MarkerLayer(markers: [premiumPositionMarker(location.point!)]),
          const Positioned(bottom: 3, right: 6, child: ColoredBox(color: Colors.white, child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)))),
        ],
      )),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(14), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ambienti compatibili · non presenza accertata', style: const TextStyle(fontWeight: FontWeight.w700, color: WildColors.forest)),
        const SizedBox(height: 5),
        Text((HabitatMapService.profiles[widget.animal.name] ?? {}).map((kind) => HabitatMapService.labels[kind]!).join(' · '), style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 5),
        if (loading) const LinearProgressIndicator()
        else Text(error ?? (patches.isEmpty ? 'Nessun habitat compatibile cartografato in questa zona. Sposta la mappa e cerca di nuovo.' : '${patches.length} aree evidenziate in verde · copertura OpenStreetMap incompleta.'), style: const TextStyle(fontSize: 12)),
        TextButton.icon(onPressed: ready ? () => _load(map.camera.center) : null, icon: const Icon(Icons.layers_outlined), label: const Text('Mostra habitat in questa zona')),
      ]))),
    ]),
  );
}
