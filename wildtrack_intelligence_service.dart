import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/sighting.dart';
import '../models/track_session.dart';
import 'database_service.dart';

class HabitatContext {
  const HabitatContext({required this.primary, required this.tags, this.elevation});
  final String primary;
  final Set<String> tags;
  final double? elevation;
}

class WeatherContext {
  const WeatherContext({
    this.temperature,
    this.wind,
    this.precipitation,
    this.humidity,
    this.weatherCode,
    this.sunrise,
    this.sunset,
  });
  final double? temperature;
  final double? wind;
  final double? precipitation;
  final double? humidity;
  final int? weatherCode;
  final DateTime? sunrise;
  final DateTime? sunset;
}

class SpeciesForecast {
  const SpeciesForecast({
    required this.name,
    required this.score,
    required this.confidence,
    required this.reason,
    required this.bestWindow,
  });
  final String name;
  final int score;
  final int confidence;
  final String reason;
  final String bestWindow;
}

class IntelligenceSnapshot {
  const IntelligenceSnapshot({
    required this.activity,
    required this.species,
    required this.habitat,
    required this.weather,
    required this.generatedAt,
    required this.hasPosition,
  });
  final String activity;
  final List<SpeciesForecast> species;
  final HabitatContext habitat;
  final WeatherContext weather;
  final DateTime generatedAt;
  final bool hasPosition;
}

class BiodiversityReport {
  const BiodiversityReport({
    required this.score,
    required this.richness,
    required this.evenness,
    required this.spatialCoverage,
    required this.seasonCoverage,
    required this.effort,
    required this.uniqueSpecies,
    required this.geoCells,
    required this.seasons,
  });
  final int score;
  final double richness;
  final double evenness;
  final double spatialCoverage;
  final double seasonCoverage;
  final double effort;
  final int uniqueSpecies;
  final int geoCells;
  final int seasons;
}

class DynamicMission {
  const DynamicMission({
    required this.title,
    required this.description,
    required this.progress,
    required this.iconKey,
  });
  final String title;
  final String description;
  final double progress;
  final String iconKey;
}

class NatureTimelineInsight {
  const NatureTimelineInsight(this.title, this.body, this.date);
  final String title;
  final String body;
  final DateTime date;
}

class _SpeciesProfile {
  const _SpeciesProfile({
    required this.activeHours,
    required this.peakMonths,
    required this.habitats,
    required this.altitude,
    required this.temperature,
  });
  final List<int> activeHours;
  final Set<int> peakMonths;
  final Set<String> habitats;
  final (double, double) altitude;
  final (double, double) temperature;
}

class WildTrackIntelligenceService {
  static final instance = WildTrackIntelligenceService();
  static const Distance _distance = Distance();

  static const Map<String, _SpeciesProfile> _profiles = {
    'Cervo': _SpeciesProfile(activeHours: [5, 6, 7, 17, 18, 19, 20], peakMonths: {9, 10, 11}, habitats: {'forest', 'meadow'}, altitude: (200, 2200), temperature: (-8, 24)),
    'Capriolo': _SpeciesProfile(activeHours: [5, 6, 7, 18, 19, 20], peakMonths: {4, 5, 6, 9}, habitats: {'forest', 'meadow', 'edge'}, altitude: (0, 1800), temperature: (-5, 25)),
    'Volpe': _SpeciesProfile(activeHours: [0, 1, 2, 4, 5, 20, 21, 22, 23], peakMonths: {1, 2, 3, 10, 11}, habitats: {'forest', 'meadow', 'edge', 'farmland'}, altitude: (0, 2200), temperature: (-10, 26)),
    'Cinghiale': _SpeciesProfile(activeHours: [0, 1, 2, 3, 4, 20, 21, 22, 23], peakMonths: {9, 10, 11, 12}, habitats: {'forest', 'edge', 'farmland'}, altitude: (0, 1800), temperature: (-5, 24)),
    'Lupo': _SpeciesProfile(activeHours: [0, 1, 2, 3, 4, 5, 20, 21, 22, 23], peakMonths: {1, 2, 10, 11, 12}, habitats: {'forest', 'meadow', 'rock'}, altitude: (100, 2400), temperature: (-15, 22)),
    'Orso bruno': _SpeciesProfile(activeHours: [4, 5, 6, 18, 19, 20, 21, 22], peakMonths: {4, 5, 6, 9, 10}, habitats: {'forest', 'edge'}, altitude: (200, 2200), temperature: (-5, 22)),
    'Poiana': _SpeciesProfile(activeHours: [9, 10, 11, 12, 13, 14, 15, 16], peakMonths: {2, 3, 4, 9, 10}, habitats: {'meadow', 'farmland', 'edge'}, altitude: (0, 1800), temperature: (0, 28)),
    'Picchio nero': _SpeciesProfile(activeHours: [6, 7, 8, 9, 10, 11], peakMonths: {2, 3, 4, 5}, habitats: {'forest'}, altitude: (100, 2200), temperature: (-5, 24)),
    'Allocco': _SpeciesProfile(activeHours: [0, 1, 2, 3, 4, 21, 22, 23], peakMonths: {1, 2, 3, 10, 11, 12}, habitats: {'forest', 'edge'}, altitude: (0, 1700), temperature: (-8, 22)),
    'Gufo reale': _SpeciesProfile(activeHours: [0, 1, 2, 3, 4, 20, 21, 22, 23], peakMonths: {1, 2, 3, 10, 11}, habitats: {'rock', 'forest', 'meadow'}, altitude: (0, 2400), temperature: (-10, 22)),
    'Marmotta': _SpeciesProfile(activeHours: [7, 8, 9, 10, 11, 15, 16, 17], peakMonths: {5, 6, 7, 8, 9}, habitats: {'meadow', 'rock'}, altitude: (900, 2800), temperature: (2, 24)),
    'Camoscio alpino': _SpeciesProfile(activeHours: [5, 6, 7, 8, 17, 18, 19], peakMonths: {5, 6, 9, 10, 11}, habitats: {'rock', 'meadow', 'forest'}, altitude: (600, 3000), temperature: (-12, 20)),
    'Stambecco': _SpeciesProfile(activeHours: [6, 7, 8, 9, 17, 18], peakMonths: {5, 6, 7, 9, 10}, habitats: {'rock', 'meadow'}, altitude: (1200, 3300), temperature: (-15, 18)),
    'Germano reale': _SpeciesProfile(activeHours: [6, 7, 8, 17, 18, 19], peakMonths: {1, 2, 3, 10, 11, 12}, habitats: {'water', 'wetland'}, altitude: (0, 1800), temperature: (-5, 28)),
    'Airone cenerino': _SpeciesProfile(activeHours: [6, 7, 8, 9, 16, 17, 18], peakMonths: {2, 3, 4, 9, 10}, habitats: {'water', 'wetland', 'farmland'}, altitude: (0, 1200), temperature: (-3, 28)),
  };

  Future<Position?> authorizedPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final p = await Geolocator.checkPermission();
      if (p != LocationPermission.always && p != LocationPermission.whileInUse) return null;
      return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 8)));
    } catch (_) {
      return null;
    }
  }

  Future<IntelligenceSnapshot> load({Position? position}) async {
    final sightings = await DatabaseService.instance.getSightings();
    final pos = position ?? await authorizedPosition();
    final now = DateTime.now();
    WeatherContext weather = const WeatherContext();
    HabitatContext habitat = const HabitatContext(primary: 'unknown', tags: {'unknown'});
    if (pos != null) {
      final results = await Future.wait<Object>([
        _weather(pos).catchError((_) => const WeatherContext()),
        _habitat(pos).catchError((_) => HabitatContext(primary: 'unknown', tags: const {'unknown'}, elevation: pos.altitude)),
      ]);
      weather = results[0] as WeatherContext;
      habitat = results[1] as HabitatContext;
    }
    final forecasts = <SpeciesForecast>[];
    for (final entry in _profiles.entries) {
      forecasts.add(_forecast(entry.key, entry.value, now, pos, weather, habitat, sightings));
    }
    forecasts.sort((a, b) => b.score.compareTo(a.score));
    final best = forecasts.isEmpty ? 0 : forecasts.first.score;
    return IntelligenceSnapshot(
      activity: best >= 75 ? 'ALTA' : best >= 55 ? 'MEDIA' : 'BASSA',
      species: forecasts,
      habitat: habitat,
      weather: weather,
      generatedAt: now,
      hasPosition: pos != null,
    );
  }

  SpeciesForecast _forecast(String name, _SpeciesProfile p, DateTime now, Position? position, WeatherContext w, HabitatContext h, List<Sighting> history) {
    var score = 26.0;
    var confidence = 38.0;
    final hourDistance = p.activeHours.map((x) {
      final d = (x - now.hour).abs();
      return math.min(d, 24 - d);
    }).reduce(math.min);
    score += math.max(0, 27 - hourDistance * 4.5);
    if (p.peakMonths.contains(now.month)) score += 17; else if (p.peakMonths.any((m) => (m - now.month).abs() == 1 || (m == 12 && now.month == 1) || (m == 1 && now.month == 12))) score += 7;
    if (h.tags.any(p.habitats.contains)) { score += 17; confidence += 12; } else if (!h.tags.contains('unknown')) { score -= 7; confidence += 8; }
    final elevation = h.elevation ?? (position == null ? null : position.altitude);
    if (elevation != null && elevation.isFinite) {
      confidence += 7;
      if (elevation >= p.altitude.$1 && elevation <= p.altitude.$2) score += 9; else score -= 8;
    }
    if (w.temperature != null) {
      confidence += 8;
      if (w.temperature! >= p.temperature.$1 && w.temperature! <= p.temperature.$2) score += 7; else score -= 5;
    }
    if ((w.wind ?? 0) > 35) score -= 12; else if ((w.wind ?? 0) > 20) score -= 5;
    if ((w.precipitation ?? 0) > 3 && const {'Poiana', 'Picchio nero', 'Marmotta'}.contains(name)) score -= 7;

    var localMatches = 0;
    for (final s in history) {
      if (s.species != name) continue;
      var weight = 1;
      if (s.timestamp.month == now.month) weight++;
      final hd = (s.timestamp.hour - now.hour).abs();
      if (hd <= 2 || hd >= 22) weight++;
      if (position != null && s.hasPosition) {
        final km = _distance.as(LengthUnit.Kilometer, LatLng(position.latitude, position.longitude), LatLng(s.latitude!, s.longitude!));
        if (km <= 25) weight += 2; else if (km > 80) weight = 0;
      }
      localMatches += weight;
    }
    if (localMatches > 0) {
      score += math.min(20, localMatches * 2.2);
      confidence += math.min(28, localMatches * 3.0);
    }

    final reason = <String>[];
    if (hourDistance <= 1) reason.add('finestra oraria favorevole');
    if (p.peakMonths.contains(now.month)) reason.add('periodo stagionale favorevole');
    if (h.tags.any(p.habitats.contains)) reason.add('habitat compatibile');
    if (localMatches > 0) reason.add('storico personale coerente');
    if ((w.wind ?? 0) > 30) reason.add('vento penalizzante');
    final window = p.activeHours.take(4).map((e) => '${e.toString().padLeft(2, '0')}:00').join(' · ');
    return SpeciesForecast(
      name: name,
      score: score.round().clamp(3, 97),
      confidence: confidence.round().clamp(25, 95),
      reason: reason.isEmpty ? 'stima basata su ciclo giornaliero e fenologia' : reason.join(', '),
      bestWindow: window,
    );
  }

  Future<WeatherContext> _weather(Position p) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${p.latitude}',
      'longitude': '${p.longitude}',
      'current': 'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
      'daily': 'sunrise,sunset',
      'forecast_days': '1',
      'timezone': 'auto',
    });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7');
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const WeatherContext();
      final data = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      final c = data['current'] as Map<String, dynamic>? ?? const {};
      final d = data['daily'] as Map<String, dynamic>? ?? const {};
      DateTime? firstDate(String key) {
        final rows = d[key] as List?;
        return rows == null || rows.isEmpty ? null : DateTime.tryParse('${rows.first}');
      }
      return WeatherContext(
        temperature: (c['temperature_2m'] as num?)?.toDouble(),
        wind: (c['wind_speed_10m'] as num?)?.toDouble(),
        precipitation: (c['precipitation'] as num?)?.toDouble(),
        humidity: (c['relative_humidity_2m'] as num?)?.toDouble(),
        weatherCode: (c['weather_code'] as num?)?.toInt(),
        sunrise: firstDate('sunrise'),
        sunset: firstDate('sunset'),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<HabitatContext> _habitat(Position p) async {
    final query = '[out:json][timeout:6];(way(around:1400,${p.latitude},${p.longitude})[natural];way(around:1400,${p.latitude},${p.longitude})[landuse];way(around:1400,${p.latitude},${p.longitude})[leisure=nature_reserve];);out tags 45;';
    final endpoints = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
      'https://overpass.private.coffee/api/interpreter',
    ];
    Set<String> tags = {};
    for (final endpoint in endpoints) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      try {
        final req = await client.postUrl(Uri.parse(endpoint));
        req.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
        req.write('data=${Uri.encodeQueryComponent(query)}');
        final res = await req.close().timeout(const Duration(seconds: 7));
        if (res.statusCode != 200) continue;
        final data = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
        for (final raw in (data['elements'] as List? ?? const [])) {
          final map = raw as Map<String, dynamic>;
          final t = map['tags'] as Map<String, dynamic>? ?? const {};
          final natural = '${t['natural'] ?? ''}';
          final landuse = '${t['landuse'] ?? ''}';
          if (const {'wood', 'forest'}.contains(natural) || landuse == 'forest') tags.add('forest');
          if (const {'grassland', 'heath', 'scrub'}.contains(natural) || const {'meadow', 'grass', 'pasture'}.contains(landuse)) tags.add('meadow');
          if (const {'wetland', 'marsh'}.contains(natural)) tags.add('wetland');
          if (const {'water', 'bay'}.contains(natural) || landuse == 'reservoir') tags.add('water');
          if (const {'bare_rock', 'scree', 'shingle', 'cliff'}.contains(natural)) tags.add('rock');
          if (const {'farmland', 'orchard', 'vineyard'}.contains(landuse)) tags.add('farmland');
          if (const {'residential', 'commercial', 'industrial'}.contains(landuse)) tags.add('urban');
        }
        if (tags.isNotEmpty) break;
      } catch (_) {
        // provider successivo
      } finally {
        client.close(force: true);
      }
    }
    if (tags.isEmpty) {
      tags = {p.altitude > 1500 ? 'rock' : p.altitude > 700 ? 'forest' : 'edge'};
    }
    final primary = ['forest', 'meadow', 'rock', 'wetland', 'water', 'farmland', 'urban', 'edge'].firstWhere(tags.contains, orElse: () => tags.first);
    return HabitatContext(primary: primary, tags: tags, elevation: p.altitude.isFinite ? p.altitude : null);
  }

  BiodiversityReport biodiversity(List<Sighting> sightings, List<TrackSession> sessions) {
    final valid = sightings.where((s) => s.species.trim().isNotEmpty && s.species != 'Specie non identificata').toList();
    final counts = <String, int>{};
    for (final s in valid) counts[s.species] = (counts[s.species] ?? 0) + math.max(1, s.count);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    var shannon = 0.0;
    if (total > 0) {
      for (final c in counts.values) {
        final p = c / total;
        shannon -= p * math.log(p);
      }
    }
    final evenness = counts.length <= 1 ? (counts.isEmpty ? 0.0 : 1.0) : (shannon / math.log(counts.length)).clamp(0.0, 1.0);
    final cells = <String>{};
    final seasons = <int>{};
    for (final s in valid) {
      if (s.hasPosition) cells.add('${(s.latitude! * 20).floor()}:${(s.longitude! * 20).floor()}');
      seasons.add(((s.timestamp.month - 1) ~/ 3));
    }
    final richness = (counts.length / 30).clamp(0.0, 1.0);
    final spatial = (cells.length / 20).clamp(0.0, 1.0);
    final seasonal = (seasons.length / 4).clamp(0.0, 1.0);
    final effort = (sessions.length / 20).clamp(0.0, 1.0);
    final score = (100 * (richness * .35 + evenness * .25 + spatial * .15 + seasonal * .15 + effort * .10)).round().clamp(0, 100);
    return BiodiversityReport(score: score, richness: richness, evenness: evenness, spatialCoverage: spatial, seasonCoverage: seasonal, effort: effort, uniqueSpecies: counts.length, geoCells: cells.length, seasons: seasons.length);
  }

  Map<String, DateTime> firstSightings(List<Sighting> sightings) {
    final out = <String, DateTime>{};
    for (final s in sightings.where((e) => e.species.isNotEmpty && e.species != 'Specie non identificata')) {
      final current = out[s.species];
      if (current == null || s.timestamp.isBefore(current)) out[s.species] = s.timestamp;
    }
    return out;
  }

  List<NatureTimelineInsight> timeline(List<Sighting> sightings) {
    final now = DateTime.now();
    final out = <NatureTimelineInsight>[];
    final first = firstSightings(sightings);
    for (final e in first.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) {
      out.add(NatureTimelineInsight('Primo ${e.key}', 'La prima osservazione registrata di ${e.key} nel tuo archivio.', e.value));
    }
    final priorYears = sightings.where((s) => s.timestamp.year < now.year && s.timestamp.month == now.month).toList();
    if (priorYears.isNotEmpty) {
      final bySpecies = <String, int>{};
      for (final s in priorYears) bySpecies[s.species] = (bySpecies[s.species] ?? 0) + 1;
      final top = bySpecies.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      out.insert(0, NatureTimelineInsight('In questo periodo negli anni scorsi', 'Nel mese di ${now.month} hai registrato soprattutto ${top.take(3).map((e) => e.key).join(', ')}.', DateTime(now.year, now.month, 1)));
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out.take(20).toList();
  }

  List<DynamicMission> missions(IntelligenceSnapshot snapshot, List<Sighting> sightings, List<TrackSession> sessions) {
    final report = biodiversity(sightings, sessions);
    final out = <DynamicMission>[];
    final top = snapshot.species.isEmpty ? null : snapshot.species.first;
    if (top != null) {
      out.add(DynamicMission(title: 'Finestra ${top.name}', description: 'Osservazione non invasiva: ${top.bestWindow}. ${top.reason}.', progress: sightings.any((s) => s.species == top.name && DateTime.now().difference(s.timestamp).inDays < 30) ? 1 : 0.15, iconKey: 'species'));
    }
    if ((snapshot.weather.precipitation ?? 0) > .5) {
      out.add(const DynamicMission(title: 'Tracce dopo la pioggia', description: 'Cerca impronte, fatte e passaggi su fango o terreno umido. Fotografa con riferimento metrico, senza seguire l’animale.', progress: .1, iconKey: 'tracks'));
    }
    if (snapshot.habitat.tags.contains('forest')) {
      out.add(DynamicMission(title: 'Lettura del bosco', description: 'Registra tre segni di presenza diversi nello stesso habitat: impronta, sfregamento, penna, fatta o verso.', progress: math.min(1, sightings.where((s) => const {'Impronta', 'Traccia', 'Fatta', 'Verso'}.contains(s.kind)).length / 3), iconKey: 'forest'));
    }
    if (report.seasons < 4) {
      out.add(DynamicMission(title: 'Completa le stagioni', description: 'Il tuo passaporto copre ${report.seasons}/4 stagioni. Documenta un’uscita nella stagione meno rappresentata.', progress: report.seasons / 4, iconKey: 'season'));
    }
    if (report.geoCells < 8) {
      out.add(DynamicMission(title: 'Habitat nuovo', description: 'Esplora responsabilmente una nuova area e registra almeno un habitat diverso dai tuoi luoghi abituali.', progress: (report.geoCells / 8).clamp(0, 1), iconKey: 'map'));
    }
    return out.take(5).toList();
  }
}
