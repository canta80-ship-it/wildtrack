class TrackPoint {
  final int segment;
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;

  const TrackPoint({
    this.segment = 0,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
  });

  Map<String, Object?> toMap(String sessionId) => {
    'segment': segment,
    'session_id': sessionId,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'timestamp': timestamp.toIso8601String(),
  };
}
