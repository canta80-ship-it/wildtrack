import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'database_service.dart';

class RadarSpecies {
  const RadarSpecies(this.name, this.score);
  final String name;
  final int score;
}

class RadarSnapshot {
  const RadarSnapshot({
    required this.activity,
    required this.species,
    this.temperature,
    this.wind,
    this.weatherAvailable = false,
  });
  final String activity;
  final List<RadarSpecies> species;
  final double? temperature;
  final double? wind;
  final bool weatherAvailable;
}

class RadarService {
  static final instance = RadarService();

  Future<Position?> _authorizedPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<RadarSnapshot> load() async {
    final now = DateTime.now();
    final sightings = await DatabaseService.instance.getSightings();
    final position = await _authorizedPosition();

    double? temperature;
    double? wind;
    if (position != null) {
      try {
        final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
          'latitude': '${position.latitude}',
          'longitude': '${position.longitude}',
          'current': 'temperature_2m,wind_speed_10m,weather_code',
          'timezone': 'auto',
        });
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
        try {
          final req = await client.getUrl(uri);
          req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.6');
          final res = await req.close().timeout(const Duration(seconds: 8));
          if (res.statusCode == HttpStatus.ok) {
            final data = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
            final current = data['current'] as Map<String, dynamic>?;
            temperature = (current?['temperature_2m'] as num?)?.toDouble();
            wind = (current?['wind_speed_10m'] as num?)?.toDouble();
          }
        } finally {
          client.close(force: true);
        }
      } catch (_) {
        // Meteo opzionale: il Radar continua con ora, stagione e storico locale.
      }
    }

    final nearbyHistory = <String, int>{};
    if (position != null) {
      const d = Distance();
      for (final s in sightings) {
        if (!s.hasPosition) continue;
        final km = d.as(
          LengthUnit.Kilometer,
          LatLng(position.latitude, position.longitude),
          LatLng(s.latitude!, s.longitude!),
        );
        if (km <= 25) nearbyHistory[s.species] = (nearbyHistory[s.species] ?? 0) + 1;
      }
    } else {
      for (final s in sightings) {
        nearbyHistory[s.species] = (nearbyHistory[s.species] ?? 0) + 1;
      }
    }

    final hour = now.hour;
    final dawnDusk = hour <= 8 || hour >= 17;
    final night = hour >= 21 || hour <= 5;
    final autumn = now.month >= 9 && now.month <= 11;
    final winter = now.month == 12 || now.month <= 2;

    final scores = <String, double>{
      'Cervo': 46 + (dawnDusk ? 25 : 0) + (autumn ? 16 : 0),
      'Capriolo': 44 + (dawnDusk ? 23 : 0),
      'Volpe': 34 + (night || dawnDusk ? 24 : 0),
      'Poiana': 35 + (!night && hour >= 9 && hour <= 16 ? 22 : 0),
      'Picchio nero': 30 + (!night && hour >= 6 && hour <= 11 ? 20 : 0),
      'Cinghiale': 28 + (night ? 30 : dawnDusk ? 16 : 0),
      'Allocco': 20 + (night ? 45 : 0),
      'Marmotta': 30 + (!winter && !night ? 22 : -15),
    };

    for (final entry in nearbyHistory.entries) {
      if (scores.containsKey(entry.key)) {
        scores[entry.key] = scores[entry.key]! + math.min(15, entry.value * 3);
      }
    }
    if ((wind ?? 0) > 30) {
      for (final k in scores.keys.toList()) scores[k] = scores[k]! - 8;
    }

    final ranked = scores.entries
        .map((e) => RadarSpecies(e.key, e.value.round().clamp(5, 95)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final best = ranked.first.score;
    final activity = best >= 75 ? 'ALTA' : best >= 55 ? 'MEDIA' : 'BASSA';

    return RadarSnapshot(
      activity: activity,
      species: ranked.take(4).toList(),
      temperature: temperature,
      wind: wind,
      weatherAvailable: temperature != null || wind != null,
    );
  }
}
