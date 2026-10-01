import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/track_session.dart';
import 'community_service.dart';
import 'database_service.dart';
import 'preferences_service.dart';

class ActivityShareService {
  static final instance = ActivityShareService();

  Future<List<LatLng>> routeFor(TrackSession session) async {
    final rows = await DatabaseService.instance.getTrackPoints(session.id);
    return rows.map((r) => LatLng((r['latitude'] as num).toDouble(), (r['longitude'] as num).toDouble())).toList();
  }

  List<LatLng> _simplify(List<LatLng> route, {int maxPoints = 180}) {
    if (route.length <= maxPoints) return route;
    final step = math.max(1, (route.length / maxPoints).ceil());
    final out = <LatLng>[];
    for (var i = 0; i < route.length; i += step) { out.add(route[i]); }
    if (out.last != route.last) out.add(route.last);
    return out;
  }

  List<LatLng> _trimEnds(List<LatLng> route) {
    if (route.length < 8) return route;
    // Nasconde una piccola porzione iniziale/finale per ridurre il rischio di
    // pubblicare domicilio o parcheggio preciso. La traccia privata resta integra.
    final cut = math.max(1, (route.length * .03).round());
    if (route.length <= cut * 2 + 2) return route;
    return route.sublist(cut, route.length - cut);
  }

  Future<TrackSession> publish(TrackSession session) async {
    final raw = await routeFor(session);
    if (raw.length < 2) throw Exception('Percorso insufficiente per la pubblicazione.');
    final route = _simplify(_trimEnds(raw));
    await CommunityService.instance.api('activities', method: 'POST', body: {
      'id': session.id,
      'nickname': PreferencesService.instance.nickname,
      'startedAt': session.startedAt.toUtc().toIso8601String(),
      'endedAt': session.endedAt.toUtc().toIso8601String(),
      'distanceM': session.distanceMeters,
      'ascentM': session.ascentMeters,
      'descentM': session.descentMeters,
      'notes': session.notes,
      'route': route.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    });
    final updated = session.copyWith(isPublic: true, publishedAt: DateTime.now());
    await DatabaseService.instance.updateSession(updated);
    return updated;
  }

  Future<TrackSession> makePrivate(TrackSession session) async {
    try { await CommunityService.instance.api('activities/${session.id}', method: 'DELETE'); } catch (_) {}
    final updated = session.copyWith(isPublic: false, clearPublishedAt: true);
    await DatabaseService.instance.updateSession(updated);
    return updated;
  }
}
