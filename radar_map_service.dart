import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'habitat_map_service.dart';
import 'radar_profile_service.dart';

class RadarPossibleSpecies {
  const RadarPossibleSpecies(this.name, this.patches, this.bestWindow, this.recentCount);
  final String name, bestWindow;
  final List<HabitatPatch> patches;
  final int recentCount;
  String get habitat => patches.map((p) => HabitatMapService.labels[p.kind] ?? p.kind).toSet().join(' · ');
}

/// A habitat match is a suggestion, never an observation or a probability.
class RadarMapService {
  static const distance = Distance();
  static LatLng? observationPoint(Map<String, dynamic> row) {
    final lat = row['lat'], lng = row['lng'];
    if (lat is! num || lng is! num || !lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  static List<Map<String, dynamic>> observations(Iterable<Map<String, dynamic>> rows, LatLng center, double radiusKm, DateTime now, {String? species}) {
    final result = rows.where((row) {
      final point = observationPoint(row);
      final at = DateTime.tryParse('${row['observedAt'] ?? ''}');
      if (row['groupId'] != null || point == null || at == null) return false;
      final age = now.difference(at);
      return age >= Duration.zero && age <= const Duration(days: 7) && distance.as(LengthUnit.Kilometer, center, point) <= radiusKm && (species == null || row['species'] == species);
    }).toList();
    result.sort((a, b) => '${b['observedAt']}'.compareTo('${a['observedAt']}'));
    return result;
  }

  static List<RadarPossibleSpecies> possible(List<HabitatPatch> patches, List<Map<String, dynamic>> observations, DateTime now, {String? species}) {
    final result = <RadarPossibleSpecies>[];
    for (final entry in radarProfiles.entries) {
      if (species != null && entry.key != species) continue;
      final profile = entry.value;
      if (profile.dormant.contains(now.month) || (profile.months.isNotEmpty && !profile.months.contains(now.month))) continue;
      final count = observations.where((s) => s['species'] == entry.key).length;
      // Habitat alone cannot establish the local range of these species.
      if ((profile.localised || profile.alpine) && count == 0) continue;
      final matches = patches.where((p) {
        final kind = p.kind == 'grass' ? 'meadow' : p.kind;
        // Generic water polygons do not establish breeding ponds.
        if (entry.key == 'Tritone' && kind == 'water') return false;
        return profile.habitats.contains(kind);
      }).toList();
      if (matches.isEmpty) continue;
      final window = switch (profile.cycle) {
        'diurnal' => 'Ore di luce',
        'nocturnal' => 'Crepuscolo e notte',
        _ => 'Alba e tramonto',
      };
      result.add(RadarPossibleSpecies(entry.key, matches, window, count));
    }
    result.sort((a,b) {
      final count = b.recentCount.compareTo(a.recentCount);
      return count != 0 ? count : a.name.compareTo(b.name);
    });
    return result;
  }

  /// Rounded display boundary. Source geometry remains untouched for matching.
  /// Limit each corner to 45 m so the styling cannot turn small habitats into blobs.
  static List<LatLng> softRing(List<LatLng> ring) {
    if (ring.length < 4) return ring;
    final vertices = List<LatLng>.from(ring);
    if (vertices.first == vertices.last) vertices.removeLast();
    final result = <LatLng>[];
    LatLng interpolate(LatLng a, LatLng b, double t) => LatLng(a.latitude + (b.latitude-a.latitude)*t, a.longitude + (b.longitude-a.longitude)*t);
    for (var i = 0; i < vertices.length; i++) {
      final previous = vertices[(i-1+vertices.length)%vertices.length], corner = vertices[i], next = vertices[(i+1)%vertices.length];
      final incoming = distance.as(LengthUnit.Meter, previous, corner), outgoing = distance.as(LengthUnit.Meter, corner, next);
      if (incoming < .1 || outgoing < .1) { result.add(corner); continue; }
      final a = interpolate(corner,previous,(45/incoming).clamp(0,.22).toDouble());
      final b = interpolate(corner,next,(45/outgoing).clamp(0,.22).toDouble());
      for (var step = 0; step <= 5; step++) {
        final t = step/5;
        result.add(interpolate(interpolate(a,corner,t),interpolate(corner,b,t),t));
      }
    }
    if (result.isNotEmpty) result.add(result.first);
    return result;
  }

  static bool _inside(LatLng point, List<LatLng> ring) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i], b = ring[j];
      if ((a.latitude > point.latitude) != (b.latitude > point.latitude) && point.longitude < (b.longitude-a.longitude)*(point.latitude-a.latitude)/(b.latitude-a.latitude)+a.longitude) inside = !inside;
    }
    return inside;
  }
  static bool _crosses(LatLng a, LatLng b, LatLng c, LatLng d) {
    double side(LatLng p, LatLng q, LatLng r) => (q.longitude-p.longitude)*(r.latitude-p.latitude)-(q.latitude-p.latitude)*(r.longitude-p.longitude);
    return side(a,b,c)*side(a,b,d)<0 && side(c,d,a)*side(c,d,b)<0;
  }
  static bool onRoute(HabitatPatch patch, List<List<LatLng>> segments) {
    if (patch.points.isEmpty) return false;
    final minLat = patch.points.map((p) => p.latitude).reduce(math.min), maxLat = patch.points.map((p) => p.latitude).reduce(math.max);
    final minLng = patch.points.map((p) => p.longitude).reduce(math.min), maxLng = patch.points.map((p) => p.longitude).reduce(math.max);
    for (final segment in segments) {
      for (var i = 0; i < segment.length; i++) {
        final point = segment[i];
        if (point.latitude >= minLat && point.latitude <= maxLat && point.longitude >= minLng && point.longitude <= maxLng && _inside(point, patch.points) && !patch.holes.any((h) => _inside(point,h))) return true;
        if (i == 0) continue;
        final previous = segment[i-1];
        if (math.max(previous.latitude,point.latitude) < minLat || math.min(previous.latitude,point.latitude) > maxLat || math.max(previous.longitude,point.longitude) < minLng || math.min(previous.longitude,point.longitude) > maxLng) continue;
        for (var j = 1; j < patch.points.length; j++) {
          if (_crosses(segment[i-1], point, patch.points[j-1], patch.points[j])) return true;
        }
      }
    }
    return false;
  }
}
