import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

class PlaceSearchResult {
  const PlaceSearchResult({required this.name, required this.point});
  final String name;
  final LatLng point;
}

class PlaceSearchService {
  static final instance = PlaceSearchService();

  Future<List<PlaceSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 7);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'jsonv2',
        'limit': '6',
        'countrycodes': 'it',
        'addressdetails': '0',
      });
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7.1 (nature navigation app)');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];
      final rows = jsonDecode(await res.transform(utf8.decoder).join()) as List;
      return rows.map((raw) {
        final row = raw as Map;
        final lat = double.tryParse('${row['lat']}');
        final lon = double.tryParse('${row['lon']}');
        if (lat == null || lon == null) return null;
        return PlaceSearchResult(name: '${row['display_name'] ?? q}', point: LatLng(lat, lon));
      }).whereType<PlaceSearchResult>().toList();
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }
}
