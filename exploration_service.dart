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
    final d = await CommunityService.instance.api(
      'trails?lat=${p.latitude}&lng=${p.longitude}',
    );
    return (d['items'] as List)
        .map((x) => NatureTrail(Map<String, dynamic>.from(x as Map)))
        .toList();
  }
}
