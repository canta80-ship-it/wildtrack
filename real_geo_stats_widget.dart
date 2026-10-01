import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sighting.dart';
import '../services/geo_insights_service.dart';
import '../premium_ui.dart';

class RealHeatmap extends StatelessWidget {
  const RealHeatmap({super.key, required this.sightings});
  final List<Sighting> sightings;

  @override
  Widget build(BuildContext context) {
    final rows = sightings.where((s) => s.hasPosition).toList();
    if (rows.isEmpty) {
      return const SizedBox(height: 150, child: Center(child: Text('La heatmap comparirà quando avrai avvistamenti con posizione.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: WildColors.muted))));
    }
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: WildColors.sageSoft)),
          Positioned.fill(child: CustomPaint(painter: _HeatPainter(rows))),
          const Positioned(left: 10, bottom: 8, child: Row(children: [Icon(WildIcons.binoculars, size: 13, color: WildColors.forest), SizedBox(width: 4), Text('Solo tu puoi vederla', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700))])),
        ]),
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter(this.rows);
  final List<Sighting> rows;

  @override
  void paint(Canvas canvas, Size size) {
    final lats = rows.map((e) => e.latitude!).toList();
    final lngs = rows.map((e) => e.longitude!).toList();
    var minLat = lats.reduce(math.min), maxLat = lats.reduce(math.max);
    var minLng = lngs.reduce(math.min), maxLng = lngs.reduce(math.max);
    if ((maxLat - minLat).abs() < .001) { minLat -= .005; maxLat += .005; }
    if ((maxLng - minLng).abs() < .001) { minLng -= .005; maxLng += .005; }

    final grid = <String, int>{};
    for (final s in rows) {
      final x = ((s.longitude! - minLng) / (maxLng - minLng) * 18).floor().clamp(0, 18);
      final y = ((s.latitude! - minLat) / (maxLat - minLat) * 10).floor().clamp(0, 10);
      final key = '$x:$y';
      grid[key] = (grid[key] ?? 0) + 1;
    }
    final maxCount = grid.values.fold<int>(1, math.max);

    final line = Paint()..color = WildColors.forest.withValues(alpha: .08)..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      canvas.drawLine(Offset(0, size.height * i / 5), Offset(size.width, size.height * i / 5), line);
      canvas.drawLine(Offset(size.width * i / 5, 0), Offset(size.width * i / 5, size.height), line);
    }

    for (final entry in grid.entries) {
      final parts = entry.key.split(':');
      final gx = int.parse(parts[0]);
      final gy = int.parse(parts[1]);
      final intensity = entry.value / maxCount;
      final x = (gx + .5) / 19 * size.width;
      final y = size.height - (gy + .5) / 11 * size.height;
      final radius = 9 + 14 * intensity;
      canvas.drawCircle(Offset(x, y), radius * 1.8, Paint()..color = Colors.orange.withValues(alpha: .10 + .16 * intensity));
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = Color.lerp(const Color(0xFFFFC857), const Color(0xFFD84A30), intensity)!.withValues(alpha: .45 + .35 * intensity));
    }
  }

  @override
  bool shouldRepaint(covariant _HeatPainter oldDelegate) => oldDelegate.rows.length != rows.length;
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
    widget.sightings.where((s) => s.hasPosition).map((s) => (lat: s.latitude!, lng: s.longitude!)),
  );

  @override
  void didUpdateWidget(covariant RealRegions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sightings.length != widget.sightings.length) data = _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, int>>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const SizedBox(height: 125, child: Center(child: CircularProgressIndicator()));
      final rows = snapshot.data?.entries.toList() ?? const [];
      if (rows.isEmpty) return const SizedBox(height: 125, child: Center(child: Text('Nessuna area visitata ancora disponibile.', style: TextStyle(color: WildColors.muted))));
      final maxV = rows.fold<int>(1, (m, e) => math.max(m, e.value));
      return Column(children: [
        for (final e in rows.take(8)) Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(flex: 3, child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
            const SizedBox(width: 8),
            SizedBox(width: 24, child: Text('${e.value}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: e.value / maxV, minHeight: 7, color: WildColors.forest, backgroundColor: WildColors.cream))),
          ]),
        ),
      ]);
    },
  );
}
