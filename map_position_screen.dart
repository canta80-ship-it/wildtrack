import 'premium_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../premium_ui.dart';
import '../services/location_service.dart';

class MapPositionScreen extends StatefulWidget {
  const MapPositionScreen({super.key, this.initialPosition, this.tileProvider});
  final LatLng? initialPosition;
  final TileProvider? tileProvider;
  @override
  State<MapPositionScreen> createState() => _MapPositionScreenState();
}

class _MapPositionScreenState extends State<MapPositionScreen> {
  final map = MapController();
  late LatLng? selected = widget.initialPosition;
  bool locating = false;
  @override
  void dispose() {
    map.dispose();
    super.dispose();
  }

  Future<void> locate() async {
    setState(() => locating = true);
    try {
      final position = await LocationService.currentPosition();
      if (!mounted) return;
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'GPS non disponibile. Puoi scegliere il punto sulla mappa.',
            ),
          ),
        );
      } else {
        final point = LatLng(position.latitude, position.longitude);
        setState(() => selected = point);
        map.move(point, 16);
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Posizione non rilevata. Seleziona il punto sulla mappa.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(
      title: const Text('Scegli posizione'),
      actions: [
        IconButton(
          tooltip: 'Centra sul GPS',
          onPressed: locating ? null : locate,
          icon: const Icon(Icons.my_location),
        ),
      ],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Tocca la mappa nel punto in cui hai osservato l’animale. Poi conferma la posizione.',
          ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: map,
            options: MapOptions(
              initialCenter:
                  widget.initialPosition ?? const LatLng(46.061, 12.403),
              initialZoom: 14,
              onTap: (_, point) => setState(() => selected = point),
              onLongPress: (_, point) => setState(() => selected = point),
            ),
            children: [
              PremiumMapSurface(child: TileLayer(
                tileProvider:
                    widget.tileProvider ??
                    NetworkTileProvider(silenceExceptions: true),
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'it.wildtrack.preview',
              )),
              MarkerLayer(
                markers: [
                  if (selected != null)
                    Marker(
                      point: selected!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        size: 44,
                        color: WildColors.forest,
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
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  selected == null
                      ? 'Nessun punto selezionato'
                      : '${selected!.latitude.toStringAsFixed(5)}, ${selected!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: selected == null
                        ? null
                        : () => Navigator.pop(context, selected),
                    icon: const Icon(Icons.check),
                    label: const Text('Usa questo punto'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
