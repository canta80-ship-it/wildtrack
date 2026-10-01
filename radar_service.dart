import 'package:geolocator/geolocator.dart';

import 'wildtrack_intelligence_service.dart';

class RadarSpecies {
  const RadarSpecies(
    this.name,
    this.score, {
    this.confidence = 0,
    this.reason = '',
    this.bestWindow = '',
  });
  final String name;
  final int score;
  final int confidence;
  final String reason;
  final String bestWindow;
}

class RadarSnapshot {
  const RadarSnapshot({
    required this.activity,
    required this.species,
    this.temperature,
    this.wind,
    this.precipitation,
    this.humidity,
    this.habitat = 'unknown',
    this.elevation,
    this.weatherAvailable = false,
    this.hasPosition = false,
    this.generatedAt,
  });
  final String activity;
  final List<RadarSpecies> species;
  final double? temperature;
  final double? wind;
  final double? precipitation;
  final double? humidity;
  final String habitat;
  final double? elevation;
  final bool weatherAvailable;
  final bool hasPosition;
  final DateTime? generatedAt;
}

class RadarService {
  static final instance = RadarService();

  Future<RadarSnapshot> load({Position? position}) async {
    final advanced = await WildTrackIntelligenceService.instance.load(position: position);
    return RadarSnapshot(
      activity: advanced.activity,
      species: advanced.species
          .map(
            (s) => RadarSpecies(
              s.name,
              s.score,
              confidence: s.confidence,
              reason: s.reason,
              bestWindow: s.bestWindow,
            ),
          )
          .toList(),
      temperature: advanced.weather.temperature,
      wind: advanced.weather.wind,
      precipitation: advanced.weather.precipitation,
      humidity: advanced.weather.humidity,
      habitat: advanced.habitat.primary,
      elevation: advanced.habitat.elevation,
      weatherAvailable:
          advanced.weather.temperature != null ||
          advanced.weather.wind != null ||
          advanced.weather.precipitation != null,
      hasPosition: advanced.hasPosition,
      generatedAt: advanced.generatedAt,
    );
  }
}
