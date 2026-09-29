import 'dart:async';

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
  double distanceMeters = 0, ascentMeters = 0;
  bool isTracking = false, busy = false;

  TrackSession session(DateTime endedAt) => TrackSession(
    id: _id!,
    startedAt: _startedAt!,
    endedAt: endedAt,
    distanceMeters: distanceMeters,
    ascentMeters: ascentMeters,
  );

  Future<bool> start() async {
    if (busy || isTracking) return isTracking;
    busy = true;
    notifyListeners();
    try {
      if (!await LocationService.ensurePermission()) return false;
      points.clear();
      distanceMeters = 0;
      ascentMeters = 0;
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
          if (points.isNotEmpty) {
            final prev = points.last;
            if (!position.timestamp.isAfter(prev.timestamp)) return;
            distanceMeters += Geolocator.distanceBetween(
              prev.latitude,
              prev.longitude,
              position.latitude,
              position.longitude,
            );
            final climb = position.altitude - prev.altitude;
            if (climb > 0) ascentMeters += climb;
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
