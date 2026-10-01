import 'package:latlong2/latlong.dart';

import '../models/track_session.dart';
import 'database_service.dart';

class ActivityMapEntry {
  const ActivityMapEntry({required this.session, required this.route});
  final TrackSession session;
  final List<LatLng> route;
}

class ActivityMapService {
  static final instance = ActivityMapService();

  Future<List<ActivityMapEntry>> load() async {
    final sessions = await DatabaseService.instance.getSessions();
    final result = <ActivityMapEntry>[];
    for (final session in sessions) {
      final rows = await DatabaseService.instance.getTrackPoints(session.id);
      final route = rows
          .map((r) => LatLng((r['latitude'] as num).toDouble(), (r['longitude'] as num).toDouble()))
          .toList();
      if (route.length > 1) result.add(ActivityMapEntry(session: session, route: route));
    }
    return result;
  }
}
