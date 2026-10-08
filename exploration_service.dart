import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';

import 'community_service.dart';
import 'preferences_service.dart';
import 'storage_service.dart';
import 'network_service.dart';

class NatureTrail {
  NatureTrail(Map<String, dynamic> value)
    : data = Map.unmodifiable(
        jsonDecode(jsonEncode(value)) as Map<String, dynamic>,
      ) {
    if (data['segments'] is! List ||
        segments.length != (data['segments'] as List).length) {
      throw const FormatException('Geometria itinerario non valida');
    }
    final source = data['source'];
    if (source != null) {
      final uri = source is String ? Uri.tryParse(source) : null;
      if (uri == null ||
          uri.scheme != 'https' ||
          !{'www.openstreetmap.org', 'openstreetmap.org'}.contains(uri.host)) {
        throw const FormatException('Fonte itinerario non valida');
      }
    }
  }
  final Map<String, dynamic> data;
  String get id => '${data['id']}';
  String get name =>
      data['name'] is String ? data['name'] as String : 'Itinerario';
  late final List<List<LatLng>> segments = List.unmodifiable(
    (data['segments'] as List)
        .map(
          (s) => List<LatLng>.unmodifiable(
            (s as List).map((p) {
              if (!validCoordinates(p[0], p[1]))
                throw const FormatException('Coordinate itinerario non valide');
              return LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble());
            }),
          ),
        )
        .where((s) => s.length > 1),
  );
  late final double length = _length();
  double _length() {
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
  final _writes = SerialExecutor();
  Future<Map<String, dynamic>>? _bundle;
  Future<Map<String, dynamic>> bundled() => _bundle ??= _loadBundle();
  Future<Map<String, dynamic>> _loadBundle() async =>
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
    final value = await JsonStorage.read(file, empty: <Object>[]);
    if (value is! List)
      throw const FormatException('Archivio itinerari non valido');
    return value
        .map((x) => NatureTrail(Map<String, dynamic>.from(x as Map)))
        .toList();
  }

  Future<void> save(NatureTrail t) => _writes.run(() async {
    final rows = await saved();
    rows.removeWhere((r) => r.id == t.id);
    rows.add(t);
    await JsonStorage.write(file, rows.map((r) => r.data).toList());
  });
  Future<void> remove(String id) => _writes.run(() async {
    final rows = await saved();
    rows.removeWhere((r) => r.id == id);
    await JsonStorage.write(file, rows.map((r) => r.data).toList());
  });

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
      try {
        final data = await JsonNetwork.request(
          Uri.https(host, '/api/interpreter'),
          method: 'POST',
          body: 'data=${Uri.encodeQueryComponent(query)}',
          form: true,
          timeout: const Duration(seconds: 40),
        );
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
