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
  String get ref => '${data['ref'] ?? ''}'.trim();
  String get network => '${data['network'] ?? ''}'.trim();
  String get operatorName => '${data['operator'] ?? ''}'.trim();
  String get difficulty => '${data['difficulty'] ?? 'Non indicata'}';
  bool get isCai => data['is_cai'] == true;
  List<List<LatLng>> get segments => (data['segments'] as List)
      .map((s) => (s as List).map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList())
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
  LatLng get center {
    final points = segments.expand((e) => e).toList();
    if (points.isEmpty) return const LatLng(46.0, 12.0);
    final lat = points.fold<double>(0, (sum, p) => sum + p.latitude) / points.length;
    final lng = points.fold<double>(0, (sum, p) => sum + p.longitude) / points.length;
    return LatLng(lat, lng);
  }
}

class ExplorationService {
  static final instance = ExplorationService();
  static const _overpassHosts = <String>[
    'overpass-api.de',
    'overpass.kumi.systems',
    'overpass.private.coffee',
  ];

  Future<Map<String, dynamic>> bundled() async => jsonDecode(await rootBundle.loadString('nature_assets.json')) as Map<String, dynamic>;

  Future<List<NatureTrail>> presets() async {
    final d = await bundled();
    return (d['trails'] as List).map((x) => NatureTrail(Map<String, dynamic>.from(x as Map))).toList();
  }

  File get file => File('${PreferencesService.instance.file.parent.path}/wildtrack_trails.json');

  Future<List<NatureTrail>> saved() async {
    try {
      return (jsonDecode(await file.readAsString()) as List).map((x) => NatureTrail(Map<String, dynamic>.from(x as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(NatureTrail t) async {
    final rows = await saved();
    rows.removeWhere((r) => r.id == t.id);
    rows.add(t);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(rows.map((r) => r.data).toList()), flush: true);
    await tmp.rename(file.path);
  }

  Future<void> remove(String id) async {
    final rows = await saved();
    rows.removeWhere((r) => r.id == id);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(rows.map((r) => r.data).toList()), flush: true);
    await tmp.rename(file.path);
  }

  bool _isCaiTags(Map tags) {
    final text = [
      tags['operator'], tags['network'], tags['name'], tags['ref'], tags['symbol'],
      tags['osmc:symbol'], tags['description'], tags['note'], tags['source'], tags['maintainer'],
    ].whereType<Object>().map((e) => '$e'.toLowerCase()).join(' ');
    final ref = '${tags['ref'] ?? ''}'.toLowerCase();
    return text.contains('club alpino italiano') ||
        text.contains('sentiero italia cai') ||
        RegExp(r'(^|[^a-z])cai([^a-z]|$)').hasMatch(text) ||
        RegExp(r'^(cai[- /]?)?\d{1,4}[a-z]?$').hasMatch(ref);
  }

  List<NatureTrail> _parse(Map<String, dynamic> data) {
    if (data['remark'] != null || data['elements'] is! List) return [];
    final result = <NatureTrail>[];
    for (final raw in data['elements'] as List) {
      if (raw is! Map || raw['type'] != 'relation') continue;
      final tags = raw['tags'] as Map? ?? {};
      final segments = <List<List<double>>>[];
      for (final memberRaw in raw['members'] as List? ?? const []) {
        if (memberRaw is! Map) continue;
        var part = <List<double>>[];
        for (final point in memberRaw['geometry'] as List? ?? const []) {
          if (point is Map && point['lat'] is num && point['lon'] is num) {
            part.add([(point['lat'] as num).toDouble(), (point['lon'] as num).toDouble()]);
          } else {
            if (part.length > 1) segments.add(part);
            part = [];
          }
        }
        if (part.length > 1) segments.add(part);
      }
      if (segments.isEmpty) continue;
      final cai = _isCaiTags(tags);
      final ref = '${tags['ref'] ?? ''}'.trim();
      result.add(NatureTrail({
        'id': raw['id'],
        'name': tags['name'] ?? (cai && ref.isNotEmpty ? 'Sentiero CAI $ref' : ref.isNotEmpty ? 'Sentiero $ref' : 'Itinerario OSM ${raw['id']}'),
        'ref': ref,
        'network': tags['network'] ?? '',
        'operator': tags['operator'] ?? tags['maintainer'] ?? '',
        'difficulty': tags['sac_scale'] ?? 'Non indicata',
        'is_cai': cai,
        'segments': segments,
        'source': 'https://www.openstreetmap.org/relation/${raw['id']}',
      }));
    }
    return result;
  }

  Future<List<NatureTrail>> _queryOverpass(LatLng p, {required bool caiOnly}) async {
    final radius = caiOnly ? 12000 : 6000;
    final query = '[out:json][timeout:25];(relation["route"~"^(hiking|foot)$"](around:$radius,${p.latitude},${p.longitude}););out body geom;';
    Object? lastError;
    for (final host in _overpassHosts) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      try {
        final req = await client.postUrl(Uri.https(host, '/api/interpreter'));
        req.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
        req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7.1');
        req.write('data=${Uri.encodeQueryComponent(query)}');
        final res = await req.close().timeout(const Duration(seconds: 25));
        if (res.statusCode != HttpStatus.ok) {
          lastError = 'HTTP ${res.statusCode} da $host';
          continue;
        }
        final text = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 18));
        var rows = _parse(jsonDecode(text) as Map<String, dynamic>);
        if (caiOnly) rows = rows.where((t) => t.isCai).toList();
        if (rows.isNotEmpty) return rows;
        lastError = 'Nessun percorso compatibile restituito da $host';
      } catch (e) {
        lastError = e;
      } finally {
        client.close(force: true);
      }
    }
    throw Exception(lastError ?? 'Provider cartografici non raggiungibili');
  }

  Future<List<NatureTrail>> _backendFallback(LatLng p, {required bool caiOnly}) async {
    try {
      final d = await CommunityService.instance.api('trails?lat=${p.latitude}&lng=${p.longitude}${caiOnly ? '&cai=1' : ''}');
      var rows = (d['items'] as List? ?? const []).map((x) => NatureTrail(Map<String, dynamic>.from(x as Map))).toList();
      if (caiOnly) rows = rows.where((t) => t.isCai || _isCaiTags(t.data)).toList();
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<List<NatureTrail>> _localFallback(LatLng p, {required bool caiOnly}) async {
    final rows = await presets();
    const distance = Distance();
    return rows.where((t) {
      if (caiOnly && !t.isCai) return false;
      return distance(p, t.center) <= (caiOnly ? 30000 : 20000);
    }).toList();
  }

  Future<List<NatureTrail>> _nearbyInternal(LatLng p, {bool caiOnly = false}) async {
    if (p.latitude < 35 || p.latitude > 48 || p.longitude < 6 || p.longitude > 19) throw Exception('Scegli un’area in Italia.');

    Object? lastError;
    try {
      final rows = await _queryOverpass(p, caiOnly: caiOnly);
      if (rows.isNotEmpty) return rows;
    } catch (e) {
      lastError = e;
    }

    final backend = await _backendFallback(p, caiOnly: caiOnly);
    if (backend.isNotEmpty) return backend;

    final local = await _localFallback(p, caiOnly: caiOnly);
    if (local.isNotEmpty) return local;

    throw Exception(caiOnly
        ? 'Nessun sentiero CAI verificabile trovato in questa zona. Sposta leggermente la mappa e riprova. ${lastError == null ? '' : 'Dettaglio: $lastError'}'
        : 'Ricerca sentieri temporaneamente non disponibile. I tracciati già salvati restano utilizzabili. ${lastError == null ? '' : 'Dettaglio: $lastError'}');
  }

  Future<List<NatureTrail>> nearby(LatLng p) => _nearbyInternal(p);
  Future<List<NatureTrail>> caiNearby(LatLng p) => _nearbyInternal(p, caiOnly: true);
}
