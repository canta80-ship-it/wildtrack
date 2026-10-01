import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

import '../models/sighting.dart';
import '../models/track_session.dart';
import 'database_service.dart';
import 'wildtrack_intelligence_service.dart';

class OutingWeather {
  const OutingWeather({this.temperature, this.wind, this.precipitation});
  final double? temperature;
  final double? wind;
  final double? precipitation;

  String get label {
    final bits = <String>[];
    if (temperature != null) bits.add('${temperature!.toStringAsFixed(0)} °C');
    if (wind != null) bits.add('vento ${wind!.toStringAsFixed(0)} km/h');
    if (precipitation != null && precipitation! > .1) bits.add('pioggia ${precipitation!.toStringAsFixed(1)} mm');
    return bits.isEmpty ? 'meteo non disponibile' : bits.join(' · ');
  }
}

class OutingDiary {
  const OutingDiary({
    required this.session,
    required this.route,
    required this.sightings,
    required this.species,
    required this.lifers,
    required this.weather,
    required this.narrative,
  });
  final TrackSession session;
  final List<LatLng> route;
  final List<Sighting> sightings;
  final Set<String> species;
  final Set<String> lifers;
  final OutingWeather weather;
  final String narrative;
}

class OutingDiaryService {
  static final instance = OutingDiaryService();

  Future<OutingDiary> build(TrackSession session) async {
    final allSightings = await DatabaseService.instance.getSightings();
    final rows = await DatabaseService.instance.getTrackPoints(session.id);
    final route = rows
        .map((r) => LatLng((r['latitude'] as num).toDouble(), (r['longitude'] as num).toDouble()))
        .toList();
    final sightings = allSightings.where((s) {
      final afterStart = !s.timestamp.isBefore(session.startedAt.subtract(const Duration(minutes: 20)));
      final beforeEnd = !s.timestamp.isAfter(session.endedAt.add(const Duration(minutes: 20)));
      return afterStart && beforeEnd;
    }).toList();
    final species = sightings.map((s) => s.species).where((s) => s.isNotEmpty && s != 'Specie non identificata').toSet();
    final first = WildTrackIntelligenceService.instance.firstSightings(allSightings);
    final lifers = <String>{};
    for (final name in species) {
      final t = first[name];
      if (t != null && !t.isBefore(session.startedAt.subtract(const Duration(minutes: 20))) && !t.isAfter(session.endedAt.add(const Duration(minutes: 20)))) {
        lifers.add(name);
      }
    }
    final weather = route.isEmpty ? const OutingWeather() : await _weather(route.first, session.startedAt);
    final duration = session.endedAt.difference(session.startedAt);
    final hours = duration.inMinutes / 60;
    final narrative = _narrative(
      distanceKm: session.distanceMeters / 1000,
      hours: hours,
      ascent: session.ascentMeters,
      species: species,
      sightings: sightings,
      lifers: lifers,
      weather: weather,
    );
    return OutingDiary(
      session: session,
      route: route,
      sightings: sightings,
      species: species,
      lifers: lifers,
      weather: weather,
      narrative: narrative,
    );
  }

  String _narrative({
    required double distanceKm,
    required double hours,
    required double ascent,
    required Set<String> species,
    required List<Sighting> sightings,
    required Set<String> lifers,
    required OutingWeather weather,
  }) {
    final buffer = StringBuffer();
    buffer.write('Uscita di ${distanceKm.toStringAsFixed(1)} km in ${hours.toStringAsFixed(1)} ore');
    if (ascent > 20) buffer.write(', con ${ascent.toStringAsFixed(0)} m di dislivello positivo');
    buffer.write('. ');
    if (species.isEmpty) {
      buffer.write('Nessuna specie identificata è stata registrata durante la sessione.');
    } else {
      buffer.write('Hai documentato ${species.length} ${species.length == 1 ? 'specie' : 'specie'} in ${sightings.length} osservazioni: ${species.take(6).join(', ')}.');
    }
    if (lifers.isNotEmpty) buffer.write(' Nuovi lifer: ${lifers.join(', ')}.');
    if (weather.label != 'meteo non disponibile') buffer.write(' Condizioni indicative: ${weather.label}.');
    return buffer.toString();
  }

  Future<OutingWeather> _weather(LatLng point, DateTime date) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final day = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final uri = Uri.https('archive-api.open-meteo.com', '/v1/archive', {
        'latitude': '${point.latitude}',
        'longitude': '${point.longitude}',
        'start_date': day,
        'end_date': day,
        'hourly': 'temperature_2m,precipitation,wind_speed_10m',
        'timezone': 'auto',
      });
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7');
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const OutingWeather();
      final data = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>? ?? const {};
      final times = (hourly['time'] as List? ?? const []).map((e) => DateTime.tryParse('$e')).toList();
      var index = 0;
      var best = const Duration(days: 999);
      for (var i = 0; i < times.length; i++) {
        final t = times[i];
        if (t == null) continue;
        final d = t.difference(date).abs();
        if (d < best) { best = d; index = i; }
      }
      double? at(String key) {
        final values = hourly[key] as List?;
        if (values == null || values.isEmpty || index >= values.length) return null;
        return (values[index] as num?)?.toDouble();
      }
      return OutingWeather(temperature: at('temperature_2m'), wind: at('wind_speed_10m'), precipitation: at('precipitation'));
    } catch (_) {
      return const OutingWeather();
    } finally {
      client.close(force: true);
    }
  }
}
