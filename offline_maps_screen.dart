import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../premium_ui.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key, required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  ml.MapLibreMapController? controller;
  List<ml.OfflineRegion> regions = [];
  double radiusKm = 5;
  double progress = 0;
  bool downloading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final rows = await ml.getListOfRegions();
      if (mounted) setState(() { regions = rows; error = null; });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  ml.LatLngBounds _bounds() {
    final latDelta = radiusKm / 111.32;
    final lngScale = math.max(.2, math.cos(widget.latitude * math.pi / 180));
    final lngDelta = radiusKm / (111.32 * lngScale);
    return ml.LatLngBounds(
      southwest: ml.LatLng(widget.latitude - latDelta, widget.longitude - lngDelta),
      northeast: ml.LatLng(widget.latitude + latDelta, widget.longitude + lngDelta),
    );
  }

  Future<void> _download() async {
    if (downloading) return;
    final nameController = TextEditingController(text: 'Mappa ${widget.latitude.toStringAsFixed(3)}, ${widget.longitude.toStringAsFixed(3)}');
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Salva area offline'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome area')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(c, nameController.text.trim()), child: const Text('Scarica')),
        ],
      ),
    );
    nameController.dispose();
    if (name == null || name.isEmpty || !mounted) return;

    setState(() { downloading = true; progress = 0; error = null; });
    try {
      final definition = ml.OfflineRegionDefinition(
        bounds: _bounds(),
        minZoom: 10,
        maxZoom: 16,
        mapStyleUrl: ml.MapLibreStyles.openfreemapLiberty,
        includeIdeographs: false,
      );
      await ml.downloadOfflineRegion(
        definition,
        metadata: {
          'name': name,
          'createdAt': DateTime.now().toIso8601String(),
          'radiusKm': radiusKm,
          'centerLat': widget.latitude,
          'centerLng': widget.longitude,
        },
        onEvent: (status) {
          if (!mounted) return;
          if (status is ml.InProgress) {
            setState(() => progress = status.downloadProgress / 100);
          } else if (status is ml.Success) {
            setState(() => progress = 1);
          }
        },
      );
      await _loadRegions();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Area offline scaricata.')));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  Future<void> _delete(ml.OfflineRegion region) async {
    final name = '${region.metadata['name'] ?? 'Area offline'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminare la mappa?'),
        content: Text('Rimuovere “$name” dal telefono?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Elimina')),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    await ml.deleteOfflineRegion(region.id);
    try { await ml.clearAmbientCache(); } catch (_) {}
    await _loadRegions();
  }

  Future<void> _deleteAll() async {
    if (regions.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminare tutte le mappe offline?'),
        content: Text('Verranno eliminate ${regions.length} aree scaricate.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Elimina tutte')),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    for (final r in List<ml.OfflineRegion>.from(regions)) {
      await ml.deleteOfflineRegion(r.id);
    }
    try { await ml.clearAmbientCache(); } catch (_) {}
    await _loadRegions();
  }

  String _regionName(ml.OfflineRegion region) => '${region.metadata['name'] ?? 'Area offline #${region.id}'}';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(
      title: const Text('Mappe offline'),
      actions: [
        if (regions.isNotEmpty) IconButton(onPressed: _deleteAll, tooltip: 'Elimina tutte', icon: const Icon(Icons.delete_sweep_outlined)),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
      children: [
        Container(
          height: 330,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 16)]),
          child: ml.MapLibreMap(
            styleString: ml.MapLibreStyles.openfreemapLiberty,
            initialCameraPosition: ml.CameraPosition(target: ml.LatLng(widget.latitude, widget.longitude), zoom: 12),
            myLocationEnabled: true,
            myLocationTrackingMode: ml.MyLocationTrackingMode.none,
            onMapCreated: (c) => controller = c,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Scarica questa zona', style: WildText.h2),
            const SizedBox(height: 5),
            const Text('La regione viene salvata sul telefono e resta navigabile senza rete.', style: TextStyle(fontSize: 11, color: WildColors.muted)),
            const SizedBox(height: 14),
            Row(children: [
              const Text('Raggio', style: TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${radiusKm.toStringAsFixed(0)} km', style: const TextStyle(fontWeight: FontWeight.w900, color: WildColors.forest)),
            ]),
            Slider(value: radiusKm, min: 2, max: 10, divisions: 4, label: '${radiusKm.toStringAsFixed(0)} km', onChanged: downloading ? null : (v) => setState(() => radiusKm = v)),
            if (downloading) ...[
              LinearProgressIndicator(value: progress <= 0 ? null : progress),
              const SizedBox(height: 6),
              Text(progress > 0 ? '${(progress * 100).toStringAsFixed(0)}%' : 'Preparazione download…', style: const TextStyle(fontSize: 10, color: WildColors.muted)),
              const SizedBox(height: 10),
            ],
            WildPrimaryButton(label: downloading ? 'Download in corso…' : 'Scarica area offline', icon: Icons.download_for_offline_outlined, onPressed: downloading ? null : _download),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
            ],
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          const Text('Mappe scaricate', style: WildText.h2),
          const Spacer(),
          Text('${regions.length}', style: const TextStyle(color: WildColors.muted)),
        ]),
        const SizedBox(height: 9),
        if (regions.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(22)),
            child: const Text('Nessuna mappa offline. Scarica una zona prima di partire se prevedi poca copertura.', textAlign: TextAlign.center),
          )
        else
          for (final region in regions) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                const WildIconDisc(Icons.offline_map_outlined, size: 52),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_regionName(region), style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text('Zoom ${region.definition.minZoom.toStringAsFixed(0)}–${region.definition.maxZoom.toStringAsFixed(0)} · disponibile offline', style: const TextStyle(fontSize: 10, color: WildColors.muted)),
                ])),
                IconButton(onPressed: () => _delete(region), tooltip: 'Elimina mappa', icon: const Icon(Icons.delete_outline)),
              ]),
            ),
          ],
        const SizedBox(height: 8),
        const Text('Cartografia: © OpenStreetMap contributors · OpenMapTiles · OpenFreeMap', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: WildColors.muted)),
      ],
    ),
  );
}
