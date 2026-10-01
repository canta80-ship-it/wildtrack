import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

class GeoLabel {
  const GeoLabel({required this.region, required this.province, required this.country});
  final String region;
  final String province;
  final String country;

  String get display => province.isNotEmpty ? '$province · $region' : region;

  Map<String, dynamic> toJson() => {'region': region, 'province': province, 'country': country};
  factory GeoLabel.fromJson(Map<String, dynamic> json) => GeoLabel(
    region: '${json['region'] ?? ''}',
    province: '${json['province'] ?? ''}',
    country: '${json['country'] ?? ''}',
  );
}

class GeoInsightsService {
  static final instance = GeoInsightsService();
  final Map<String, GeoLabel> _cache = {};
  bool _loaded = false;
  late File _file;

  String _key(double lat, double lng) => '${(lat * 20).round() / 20}:${(lng * 20).round() / 20}';

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    _file = File('${await getDatabasesPath()}/wildtrack_geo_cache.json');
    try {
      final raw = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      for (final e in raw.entries) {
        _cache[e.key] = GeoLabel.fromJson(Map<String, dynamic>.from(e.value as Map));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(_cache.map((k, v) => MapEntry(k, v.toJson()))), flush: true);
    await tmp.rename(_file.path);
  }

  Future<GeoLabel?> resolve(double lat, double lng) async {
    await _load();
    final key = _key(lat, lng);
    if (_cache.containsKey(key)) return _cache[key];
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '$lat',
        'lon': '$lng',
        'zoom': '10',
        'addressdetails': '1',
      });
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7 wildlife-journal');
      final res = await req.close().timeout(const Duration(seconds: 7));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>? ?? const {};
      final region = '${address['state'] ?? address['region'] ?? ''}';
      final province = '${address['province'] ?? address['county'] ?? address['state_district'] ?? ''}';
      final country = '${address['country'] ?? ''}';
      if (region.isEmpty && province.isEmpty) return null;
      final label = GeoLabel(region: region, province: province, country: country);
      _cache[key] = label;
      await _save();
      return label;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, int>> aggregate(Iterable<({double lat, double lng})> points) async {
    final cells = <String, ({double lat, double lng})>{};
    for (final p in points) {
      cells[_key(p.lat, p.lng)] = p;
    }
    final result = <String, int>{};
    for (final p in cells.values.take(30)) {
      final label = await resolve(p.lat, p.lng);
      final name = label?.display ?? 'Area ${p.lat.toStringAsFixed(1)}, ${p.lng.toStringAsFixed(1)}';
      result[name] = (result[name] ?? 0) + 1;
    }
    final sorted = result.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }
}
