import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/track_point.dart';
import '../models/track_session.dart';
import 'database_service.dart';
import 'location_service.dart';

class TrackingService extends ChangeNotifier {
  TrackingService._();
  static final instance = TrackingService._();

  final List<TrackPoint> points = [];
  StreamSubscription<Position>? _subscription;
  Future<void> _writes = Future<void>.value();
  DateTime? _startedAt;
  String? _id;
  String? error;

  double distanceMeters = 0;
  double ascentMeters = 0;
  double descentMeters = 0;
  double? currentAltitudeMeters;
  double? minAltitudeMeters;
  double? maxAltitudeMeters;
  double? currentGradePercent;
  double? currentSpeedMps;
  double? gpsAccuracyMeters;
  double? altitudeAccuracyMeters;

  bool isTracking = false, busy = false;

  DateTime? get startedAt => _startedAt;
  String? get activeSessionId => _id;
  Duration get elapsed => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);
  double get averageSpeedMps =>
      elapsed.inSeconds <= 0 ? 0 : distanceMeters / elapsed.inSeconds;
  double? get averageGradePercent {
    if (distanceMeters < 10) return null;
    return ((ascentMeters - descentMeters) / distanceMeters) * 100;
  }

  TrackSession session(DateTime endedAt) => TrackSession(
    id: _id!,
    startedAt: _startedAt!,
    endedAt: endedAt,
    distanceMeters: distanceMeters,
    ascentMeters: ascentMeters,
    descentMeters: descentMeters,
  );

  Future<bool> start() async {
    if (busy || isTracking) return isTracking;
    busy = true;
    notifyListeners();
    try {
      if (!await LocationService.ensurePermission()) {
        error = 'Attiva il GPS e autorizza la posizione precisa per registrare l’uscita.';
        return false;
      }
      await LocationService.requestTrackingNotification();
      points.clear();
      distanceMeters = 0;
      ascentMeters = 0;
      descentMeters = 0;
      currentAltitudeMeters = null;
      minAltitudeMeters = null;
      maxAltitudeMeters = null;
      currentGradePercent = null;
      currentSpeedMps = null;
      gpsAccuracyMeters = null;
      altitudeAccuracyMeters = null;
      error = null;
      _startedAt = DateTime.now();
      _id = const Uuid().v4();
      await DatabaseService.instance.appendTrackPoint(
        session(_startedAt!),
        null,
      );
      isTracking = true;
      _subscription = LocationService.positionStream().listen(
        (position) {
          if (!isTracking ||
              position.accuracy > 100 ||
              !position.accuracy.isFinite)
            return;

          gpsAccuracyMeters = position.accuracy;
          altitudeAccuracyMeters = position.altitudeAccuracy.isFinite
              ? position.altitudeAccuracy
              : null;
          currentSpeedMps = position.speed.isFinite && position.speed >= 0
              ? position.speed
              : null;
          currentAltitudeMeters = position.altitude.isFinite
              ? position.altitude
              : null;

          if (currentAltitudeMeters != null) {
            minAltitudeMeters = minAltitudeMeters == null
                ? currentAltitudeMeters
                : math.min(minAltitudeMeters!, currentAltitudeMeters!);
            maxAltitudeMeters = maxAltitudeMeters == null
                ? currentAltitudeMeters
                : math.max(maxAltitudeMeters!, currentAltitudeMeters!);
          }

          if (points.isNotEmpty) {
            final prev = points.last;
            if (!position.timestamp.isAfter(prev.timestamp)) return;
            final segmentDistance = Geolocator.distanceBetween(
              prev.latitude,
              prev.longitude,
              position.latitude,
              position.longitude,
            );
            if (segmentDistance >= 1.5 && segmentDistance < 500) {
              distanceMeters += segmentDistance;
              final climb = position.altitude - prev.altitude;
              if (climb.abs() >= 1.2 && climb.abs() <= 80) {
                if (climb > 0)
                  ascentMeters += climb;
                else
                  descentMeters += -climb;
              }
              currentGradePercent = segmentDistance >= 4
                  ? ((climb / segmentDistance) * 100).clamp(-60.0, 60.0)
                  : currentGradePercent;
            }
          }

          final p = TrackPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            altitude: position.altitude,
            timestamp: position.timestamp,
          );
          points.add(p);
          final snapshot = session(position.timestamp);
          _writes = _writes
              .then(
                (_) => DatabaseService.instance.appendTrackPoint(snapshot, p),
              )
              .catchError((Object e) {
                error =
                    'Registrazione fermata: impossibile salvare il tracciato. $e';
                isTracking = false;
                unawaited(_subscription?.cancel());
                notifyListeners();
              });
          notifyListeners();
        },
        onError: (Object e) {
          error = 'GPS interrotto: $e. I punti già acquisiti restano salvati.';
          isTracking = false;
          unawaited(_subscription?.cancel());
          notifyListeners();
        },
      );
      return true;
    } catch (e) {
      error = '$e';
      isTracking = false;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<TrackSession?> stop() async {
    if (busy || _startedAt == null || _id == null) return null;
    busy = true;
    isTracking = false;
    notifyListeners();
    try {
      await _subscription?.cancel();
      _subscription = null;
      await _writes;
      if (error != null) throw Exception(error);
      final saved = session(DateTime.now());
      await DatabaseService.instance.appendTrackPoint(saved, null);
      return saved;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
