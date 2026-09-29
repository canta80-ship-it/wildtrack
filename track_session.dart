class TrackSession {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceMeters;
  final double ascentMeters;

  const TrackSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceMeters,
    required this.ascentMeters,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'started_at': startedAt.toIso8601String(),
    'ended_at': endedAt.toIso8601String(),
    'distance_m': distanceMeters,
    'ascent_m': ascentMeters,
  };

  static TrackSession fromMap(Map<String, Object?> map) => TrackSession(
    id: map['id'] as String,
    startedAt: DateTime.parse(map['started_at'] as String),
    endedAt: DateTime.parse(map['ended_at'] as String),
    distanceMeters: (map['distance_m'] as num).toDouble(),
    ascentMeters: (map['ascent_m'] as num).toDouble(),
  );
}
