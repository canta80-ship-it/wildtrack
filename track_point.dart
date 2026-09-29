class TrackPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;

  const TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
  });

  Map<String, Object?> toMap(String sessionId) => {
    'session_id': sessionId,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'timestamp': timestamp.toIso8601String(),
  };
}
