import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/track_point.dart';
import '../models/track_session.dart';
import 'database_service.dart';
import 'location_service.dart';

class TrackingService {
  final List<TrackPoint> points = [];
  StreamSubscription<Position>? _subscription;
  DateTime? _startedAt;
  double distanceMeters = 0;
  double ascentMeters = 0;
  bool isTracking = false;

  Future<bool> start(void Function() onUpdate) async {
    if (!await LocationService.ensurePermission()) return false;
    points.clear();
    distanceMeters = 0;
    ascentMeters = 0;
    _startedAt = DateTime.now();
    isTracking = true;

    _subscription = LocationService.positionStream().listen((position) {
      if (points.isNotEmpty) {
        final prev = points.last;
        distanceMeters += Geolocator.distanceBetween(
          prev.latitude,
          prev.longitude,
          position.latitude,
          position.longitude,
        );
        final climb = position.altitude - prev.altitude;
        if (climb > 0) ascentMeters += climb;
      }
      points.add(
        TrackPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          timestamp: position.timestamp,
        ),
      );
      onUpdate();
    });
    return true;
  }

  Future<TrackSession?> stop() async {
    if (!isTracking || _startedAt == null) return null;
    await _subscription?.cancel();
    _subscription = null;
    isTracking = false;
    final session = TrackSession(
      id: const Uuid().v4(),
      startedAt: _startedAt!,
      endedAt: DateTime.now(),
      distanceMeters: distanceMeters,
      ascentMeters: ascentMeters,
    );
    await DatabaseService.instance.saveSession(session, List.of(points));
    return session;
  }

  void dispose() => _subscription?.cancel();
}
