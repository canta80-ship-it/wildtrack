import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';

import 'community_service.dart';
import 'preferences_service.dart';

class NatureTrail {
  NatureTrail(this.data);
  final Map<String, dynamic> data;
  String get id => '${data['id']}';
  String get name => data['name'] as String? ?? 'Itinerario';
  List<List<LatLng>> get segments => (data['segments'] as List)
      .map(
        (s) => (s as List)
            .map(
              (p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
            )
            .toList(),
      )
      .toList();
  double get length {
    double n = 0;
    const d = Distance();
    for (final s in segments) {
      for (var i = 1; i < s.length; i++) {
        n += d(s[i - 1], s[i]);
      }
    }
    return n;
  }

  LatLng get center => segments.first.first;
}

class ExplorationService {
  static final instance = ExplorationService();
  Future<Map<String, dynamic>> bundled() async =>
      jsonDecode(await rootBundle.loadString('nature_assets.json'))
          as Map<String, dynamic>;
  Future<List<NatureTrail>> presets() async {
    final d = await bundled();
    return (d['trails'] as List)
        .map((x) => NatureTrail(Map<String, dynamic>.from(x as Map)))
        .toList();
  }

  File get file => File(
    '${PreferencesService.instance.file.parent.path}/wildtrack_trails.json',
  );
  Future<List<NatureTrail>> saved() async {
    try {
      return (jsonDecode(await file.readAsString()) as List)
          .map((x) => NatureTrail(Map<String, dynamic>.from(x as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(NatureTrail t) async {
    final rows = await saved();
    rows.removeWhere((r) => r.id == t.id);
    rows.add(t);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode(rows.map((r) => r.data).toList()),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  Future<void> remove(String id) async {
    final rows = await saved();
    rows.removeWhere((r) => r.id == id);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode(rows.map((r) => r.data).toList()),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  Future<List<NatureTrail>> nearby(LatLng p) async {
    if (p.latitude < 35 ||
        p.latitude > 48 ||
        p.longitude < 6 ||
        p.longitude > 19) {
      throw Exception('Scegli un’area in Italia.');
    }
    // Bound returned geometry: long national relations otherwise return megabytes.
    final south = p.latitude - 0.045, north = p.latitude + 0.045;
    final west = p.longitude - 0.065, east = p.longitude + 0.065;
    final query =
        '[out:json][timeout:18];relation["route"~"^(hiking|foot)\$"]'
        '(around:5000,${p.latitude},${p.longitude});'
        'out body geom($south,$west,$north,$east);';
    for (final host in ['overpass-api.de', 'overpass.private.coffee']) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      try {
        final req = await client.postUrl(Uri.https(host, '/api/interpreter'));
        req.headers.contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
        );
        req.write('data=${Uri.encodeQueryComponent(query)}');
        final res = await req.close().timeout(const Duration(seconds: 25));
        if (res.statusCode != 200) continue;
        final text = await res
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 15));
        final data = jsonDecode(text) as Map<String, dynamic>;
        if (data['remark'] != null || data['elements'] is! List) continue;
        return (data['elements'] as List)
            .where((e) => e['type'] == 'relation')
            .map((e) {
              final tags = e['tags'] as Map? ?? {};
              final segments = <List<List<double>>>[];
              for (final member in e['members'] as List? ?? []) {
                var part = <List<double>>[];
                for (final point in member['geometry'] as List? ?? []) {
                  if (point is Map &&
                      point['lat'] is num &&
                      point['lon'] is num) {
                    part.add([
                      (point['lat'] as num).toDouble(),
                      (point['lon'] as num).toDouble(),
                    ]);
                  } else {
                    if (part.length > 1) segments.add(part);
                    part = [];
                  }
                }
                if (part.length > 1) segments.add(part);
              }
              return NatureTrail({
                'id': e['id'],
                'name':
                    tags['name'] ?? tags['ref'] ?? 'Itinerario OSM ${e['id']}',
                'difficulty': tags['sac_scale'] ?? 'Non indicata',
                'segments': segments,
                'source': 'https://www.openstreetmap.org/relation/${e['id']}',
              });
            })
            .where((t) => t.segments.isNotEmpty)
            .toList();
      } catch (_) {
        // Retry another provider; never substitute unrelated bundled routes.
      } finally {
        client.close(force: true);
      }
    }
    // The server may still have a cached response when public providers are busy.
    try {
      final d = await CommunityService.instance.api(
        'trails?lat=${p.latitude}&lng=${p.longitude}',
      );
      return (d['items'] as List)
          .map((x) => NatureTrail(Map<String, dynamic>.from(x as Map)))
          .toList();
    } catch (_) {
      throw Exception(
        'Ricerca sentieri temporaneamente non disponibile. Riprova tra poco; i tracciati già presenti restano disponibili.',
      );
    }
  }
}
