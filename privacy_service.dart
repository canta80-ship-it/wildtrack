import 'dart:math' as math;

class PublicSightingPrivacy {
  const PublicSightingPrivacy({
    required this.latitude,
    required this.longitude,
    required this.approximate,
    required this.radiusMeters,
    this.publishAfter,
    required this.reason,
  });
  final double latitude;
  final double longitude;
  final bool approximate;
  final int radiusMeters;
  final DateTime? publishAfter;
  final String reason;
}

class WildlifePrivacyService {
  static final instance = WildlifePrivacyService();
  static const _critical = {
    'Orso bruno',
    'Lupo',
    'Lince',
    'Gufo reale',
    'Aquila reale',
  };
  static const _sensitive = {
    'Sciacallo dorato',
    'Gallo cedrone',
    'Allocco',
    'Barbagianni',
    'Camoscio alpino',
    'Stambecco',
  };

  bool isSensitive(String species) =>
      _critical.contains(species) || _sensitive.contains(species);

  PublicSightingPrivacy protect({
    required String species,
    required double latitude,
    required double longitude,
    required DateTime observedAt,
    bool userRequestedApproximation = true,
  }) {
    final now = DateTime.now();
    final critical = _critical.contains(species);
    final sensitive = critical || _sensitive.contains(species);
    final age = now.difference(observedAt);

    int radius;
    Duration delay;
    if (critical) {
      radius = age.inDays < 7 ? 10000 : 5000;
      delay = age.inDays < 2 ? const Duration(hours: 48) : Duration.zero;
    } else if (sensitive) {
      radius = age.inDays < 3 ? 4000 : 2000;
      delay = age.inHours < 24 ? const Duration(hours: 12) : Duration.zero;
    } else if (userRequestedApproximation) {
      radius = 1000;
      delay = Duration.zero;
    } else {
      radius = 0;
      delay = Duration.zero;
    }

    if (radius == 0) {
      return PublicSightingPrivacy(
        latitude: latitude,
        longitude: longitude,
        approximate: false,
        radiusMeters: 0,
        publishAfter: null,
        reason: 'posizione esatta scelta dall’utente',
      );
    }

    // Offset deterministico rispetto a specie+giorno, così lo stesso punto non
    // “salta” a ogni refresh e non rivela la coordinata precisa.
    final seed = Object.hash(species, observedAt.year, observedAt.month, observedAt.day, latitude.toStringAsFixed(3), longitude.toStringAsFixed(3));
    final random = math.Random(seed);
    final distance = radius * (.55 + random.nextDouble() * .4);
    final bearing = random.nextDouble() * math.pi * 2;
    final dLat = (distance * math.cos(bearing)) / 111320.0;
    final scale = 111320.0 * math.cos(latitude * math.pi / 180).abs().clamp(.2, 1.0);
    final dLon = (distance * math.sin(bearing)) / scale;

    return PublicSightingPrivacy(
      latitude: latitude + dLat,
      longitude: longitude + dLon,
      approximate: true,
      radiusMeters: radius,
      publishAfter: delay == Duration.zero ? null : now.add(delay),
      reason: critical
          ? 'specie altamente sensibile: area anonimizzata e pubblicazione ritardata'
          : sensitive
              ? 'specie sensibile: posizione degradata e possibile ritardo'
              : 'posizione approssimata per scelta privacy',
    );
  }

  Map<String, dynamic> protectPayload(Map<String, dynamic> input) {
    if (input['groupId'] != null) return Map<String, dynamic>.from(input);
    final lat = (input['lat'] as num?)?.toDouble();
    final lng = (input['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return Map<String, dynamic>.from(input);
    final species = '${input['species'] ?? ''}';
    final observedAt = DateTime.tryParse('${input['observedAt'] ?? ''}')?.toLocal() ?? DateTime.now();
    final result = protect(
      species: species,
      latitude: lat,
      longitude: lng,
      observedAt: observedAt,
      userRequestedApproximation: input['approximate'] != false,
    );
    return {
      ...input,
      'lat': result.latitude,
      'lng': result.longitude,
      'approximate': result.approximate,
      'privacyRadiusM': result.radiusMeters,
      'privacyReason': result.reason,
      if (result.publishAfter != null)
        'publishAfter': result.publishAfter!.toUtc().toIso8601String(),
    };
  }
}
