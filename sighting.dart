class Sighting {
  final String id;
  final String species;
  final int count;
  final String notes;
  final double? latitude;
  final double? longitude;
  final String kind;
  final double? accuracy;
  final String positionSource;
  final DateTime timestamp;
  final String? photoPath;

  const Sighting({
    required this.id,
    required this.species,
    required this.count,
    required this.notes,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.photoPath,
    this.kind = 'Animale',
    this.accuracy,
    this.positionSource = 'gps',
  });

  bool get hasPosition => latitude != null && longitude != null;

  Map<String, Object?> toMap() => {
    'id': id,
    'species': species,
    'count': count,
    'notes': notes,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'photo_path': photoPath,
    'kind': kind,
    'accuracy': accuracy,
    'position_source': positionSource,
  };

  static Sighting fromMap(Map<String, Object?> map) => Sighting(
    id: map['id'] as String,
    species: map['species'] as String,
    count: map['count'] as int,
    notes: (map['notes'] as String?) ?? '',
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    timestamp: DateTime.parse(map['timestamp'] as String),
    photoPath: map['photo_path'] as String?,
    kind: map['kind'] as String? ?? 'Animale',
    accuracy: (map['accuracy'] as num?)?.toDouble(),
    positionSource: map['position_source'] as String? ?? 'gps',
  );
}
