import 'package:latlong2/latlong.dart';

import '../models/track_session.dart';
import 'database_service.dart';

class ActivityMapEntry {
  const ActivityMapEntry({required this.session, required this.route, this.segments = const []});
  final TrackSession session;
  final List<LatLng> route;
  final List<List<LatLng>> segments;
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
      final segments = <List<LatLng>>[];
      int? previous;
      for (var i = 0; i < rows.length; i++) {
        final segment = (rows[i]['segment'] as num?)?.toInt() ?? 0;
        if (previous != segment) segments.add([]);
        segments.last.add(route[i]);
        previous = segment;
      }
      if (route.length > 1) result.add(ActivityMapEntry(session: session, route: route, segments: segments));
    }
    return result;
  }
}
