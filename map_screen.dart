import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _position;
  List<Marker> _sightings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await LocationService.currentPosition();
    final sightings = await DatabaseService.instance.getSightings();
    if (!mounted) return;
    setState(() {
      if (p != null) _position = LatLng(p.latitude, p.longitude);
      _sightings = sightings
          .map((s) => Marker(
                point: LatLng(s.latitude, s.longitude),
                width: 44,
                height: 44,
                child: Tooltip(
                  message: '${s.species} (${s.count})',
                  child: const Icon(Icons.pets, size: 34),
                ),
              ))
          .toList();
    });
    if (_position != null) _mapController.move(_position!, 14);
  }

  @override
  Widget build(BuildContext context) {
    final center = _position ?? const LatLng(46.06, 12.40);
    return Scaffold(
      appBar: AppBar(title: const Text('Mappa')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: center, initialZoom: 11),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'it.wildtrack.wildtrack_mvp',
          ),
          MarkerLayer(markers: [
            ..._sightings,
            if (_position != null)
              Marker(
                point: _position!,
                width: 36,
                height: 36,
                child: const Icon(Icons.my_location, size: 30),
              ),
          ]),
          RichAttributionWidget(attributions: const [
            TextSourceAttribution('OpenStreetMap contributors'),
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }
}
