class TrackSession {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceMeters;
  final double ascentMeters;
  final double descentMeters;
  final String notes;
  final bool isPublic;
  final DateTime? publishedAt;

  const TrackSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceMeters,
    required this.ascentMeters,
    this.descentMeters = 0,
    this.notes = '',
    this.isPublic = false,
    this.publishedAt,
  });

  Duration get duration => endedAt.difference(startedAt);
  double get averageSpeedMps => duration.inSeconds <= 0 ? 0 : distanceMeters / duration.inSeconds;

  TrackSession copyWith({
    double? descentMeters,
    String? notes,
    bool? isPublic,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
  }) => TrackSession(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    distanceMeters: distanceMeters,
    ascentMeters: ascentMeters,
    descentMeters: descentMeters ?? this.descentMeters,
    notes: notes ?? this.notes,
    isPublic: isPublic ?? this.isPublic,
    publishedAt: clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'started_at': startedAt.toIso8601String(),
    'ended_at': endedAt.toIso8601String(),
    'distance_m': distanceMeters,
    'ascent_m': ascentMeters,
    'descent_m': descentMeters,
    'notes': notes,
    'is_public': isPublic ? 1 : 0,
    'published_at': publishedAt?.toIso8601String(),
  };

  static TrackSession fromMap(Map<String, Object?> map) => TrackSession(
    id: map['id'] as String,
    startedAt: DateTime.parse(map['started_at'] as String),
    endedAt: DateTime.parse(map['ended_at'] as String),
    distanceMeters: (map['distance_m'] as num).toDouble(),
    ascentMeters: (map['ascent_m'] as num).toDouble(),
    descentMeters: (map['descent_m'] as num?)?.toDouble() ?? 0,
    notes: map['notes'] as String? ?? '',
    isPublic: ((map['is_public'] as num?)?.toInt() ?? 0) == 1,
    publishedAt: map['published_at'] == null ? null : DateTime.tryParse(map['published_at'] as String),
  );
}
