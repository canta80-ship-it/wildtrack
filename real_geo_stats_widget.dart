import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'sighting_heatmap_screen.dart';

import 'package:flutter/cupertino.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sighting.dart';
import '../services/geo_insights_service.dart';
import '../premium_ui.dart';

class RealHeatmap extends StatelessWidget {
  const RealHeatmap({
    super.key,
    required this.sightings,
    this.tileProvider,
    this.expanded = false,
  });
  final List<Sighting> sightings;
  final TileProvider? tileProvider;
  final bool expanded;

  static Map<String, ({LatLng point, int count})> cells(List<Sighting> rows) {
    final out = <String, ({LatLng point, int count})>{};
    for (final row in rows.where(
      (s) =>
          s.hasPosition &&
          s.latitude!.isFinite &&
          s.longitude!.isFinite &&
          s.latitude!.abs() <= 90 &&
          s.longitude!.abs() <= 180,
    )) {
      final lat = (row.latitude! * 500).round() / 500;
      final lng = (row.longitude! * 500).round() / 500;
      final key = '$lat:$lng';
      out[key] = (point: LatLng(lat, lng), count: (out[key]?.count ?? 0) + 1);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final bins = cells(sightings).values.toList();
    if (bins.isEmpty)
      return SizedBox(
        height: expanded ? null : 150,
        child: const Center(
          child: Text(
            'La heatmap comparirà quando avrai avvistamenti con posizione.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    final maximum = bins.fold<int>(1, (n, cell) => math.max(n, cell.count));
    final bounds = LatLngBounds.fromPoints(bins.map((b) => b.point).toList());
    final map = FlutterMap(
      key: ValueKey(
        bins
            .map((b) => '${b.point.latitude}:${b.point.longitude}:${b.count}')
            .join('|'),
      ),
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(35),
          maxZoom: 14,
        ),
        interactionOptions: InteractionOptions(
          flags: expanded ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          tileProvider:
              tileProvider ?? NetworkTileProvider(silenceExceptions: true),
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'it.wildtrack.preview',
        ),
        CircleLayer(
          circles: [
            for (final bin in bins) ...[
              CircleMarker(
                point: bin.point,
                radius: 24 + 15 * bin.count / maximum,
                color: Colors.orange.withValues(alpha: .22),
                borderStrokeWidth: 0,
              ),
              CircleMarker(
                point: bin.point,
                radius: 14 + 10 * bin.count / maximum,
                color: Color.lerp(
                  const Color(0xFFFFCB45),
                  const Color(0xFFD8442F),
                  bin.count / maximum,
                )!.withValues(alpha: .65),
                borderStrokeWidth: 0,
              ),
            ],
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
        ),
      ],
    );
    return SizedBox(
      height: expanded ? null : 170,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(child: map),
            if (!expanded)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SightingHeatmapScreen(),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  expanded
                      ? '${bins.fold<int>(0, (n, b) => n + b.count)} avvistamenti con posizione · solo tu'
                      : 'Solo tu · apri mappa',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RealRegions extends StatefulWidget {
  const RealRegions({super.key, required this.sightings});
  final List<Sighting> sightings;

  @override
  State<RealRegions> createState() => _RealRegionsState();
}

class _RealRegionsState extends State<RealRegions> {
  late Future<Map<String, int>> data = _load();

  Future<Map<String, int>> _load() => GeoInsightsService.instance.aggregate(
    widget.sightings
        .where((s) => s.hasPosition)
        .map((s) => (lat: s.latitude!, lng: s.longitude!)),
  );

  bool _samePositions(List<Sighting> a, List<Sighting> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].latitude != b[i].latitude || a[i].longitude != b[i].longitude)
        return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant RealRegions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePositions(oldWidget.sightings, widget.sightings)) data = _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, int>>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const SizedBox(
          height: 125,
          child: Center(child: CircularProgressIndicator()),
        );
      final rows = snapshot.data?.entries.toList() ?? const [];
      if (rows.isEmpty)
        return const SizedBox(
          height: 125,
          child: Center(
            child: Text(
              'Nessuna area visitata ancora disponibile.',
              style: TextStyle(color: WildColors.muted),
            ),
          ),
        );
      final maxV = rows.fold<int>(1, (m, e) => math.max(m, e.value));
      return Column(
        children: [
          for (final e in rows.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${e.value}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: e.value / maxV,
                        minHeight: 7,
                        color: WildColors.forest,
                        backgroundColor: WildColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
