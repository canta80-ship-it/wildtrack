import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../premium_ui.dart';

LatLng? communitySightingPosition(Map<String, dynamic> sighting) {
  double? number(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
  final lat = number(sighting['lat']), lng = number(sighting['lng']);
  if (lat == null || lng == null || !lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) return null;
  return LatLng(lat, lng);
}

class CommunitySightingMapButton extends StatelessWidget {
  const CommunitySightingMapButton({super.key, required this.sighting});
  final Map<String, dynamic> sighting;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: WildColors.forest, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      icon: const Icon(Icons.map_outlined, size: 20),
      label: const Text('Vedi su mappa'),
      onPressed: () {
        final point = communitySightingPosition(sighting);
        if (point == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posizione non disponibile per questo avvistamento.')));
          return;
        }
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CommunitySightingMapScreen(sighting: sighting, position: point)));
      },
    ),
  );
}

class CommunitySightingMapScreen extends StatelessWidget {
  const CommunitySightingMapScreen({super.key, required this.sighting, required this.position, this.tileProvider});
  final Map<String, dynamic> sighting;
  final LatLng position;
  final TileProvider? tileProvider;
  @override
  Widget build(BuildContext context) {
    final approximate = sighting['approximate'] == 1 || sighting['approximate'] == true;
    return Scaffold(
      backgroundColor: WildColors.ivory,
      appBar: AppBar(title: Text('${sighting['species'] ?? 'Avvistamento'}')),
      body: Column(children: [
        Expanded(child: FlutterMap(
          options: MapOptions(initialCenter: position, initialZoom: approximate ? 13 : 15),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'it.wildtrack.preview', tileProvider: tileProvider),
            if (approximate) CircleLayer(circles: [CircleMarker(point: position, radius: 1000, useRadiusInMeter: true, color: WildColors.forest.withValues(alpha: 0.12), borderColor: WildColors.forest, borderStrokeWidth: 2)]),
            MarkerLayer(markers: [Marker(point: position, width: 64, height: 64, child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: WildColors.forest, width: 3)), child: WildAnimalIllustration('${sighting['species'] ?? 'Animale'}', size: 48)))]),
            const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
          ],
        )),
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(16), child: Text(approximate ? 'Posizione condivisa approssimata a circa 1 km.' : 'Posizione condivisa dalla community.', style: const TextStyle(color: WildColors.forest)))),
      ]),
    );
  }
}
