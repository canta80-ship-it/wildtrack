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
  double distanceMeters = 0, ascentMeters = 0;
  bool isTracking = false, busy = false;
  bool _storageFailed = false;
  int _generation = 0;
  Position? _last;
  double? _altitudeBaseline;
  final _altitudes = <double>[];

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
      await _subscription?.cancel();
      _subscription = null;
      await _writes;
      if (!await LocationService.ensurePermission()) {
        error = 'GPS non disponibile o permesso non concesso.';
        return false;
      }
      final generation = ++_generation;
      points.clear();
      _altitudes.clear();
      _last = null;
      _altitudeBaseline = null;
      distanceMeters = ascentMeters = 0;
      error = null;
      _storageFailed = false;
      _startedAt = DateTime.now();
      _id = const Uuid().v4();
      await DatabaseService.instance.appendTrackPoint(
        session(_startedAt!),
        null,
      );
      isTracking = true;
      _subscription = LocationService.positionStream().listen(
        (position) {
          if (!isTracking || generation != _generation) return;
          _writes = _writes
              .then((_) async {
                if (_storageFailed || generation != _generation) return;
                if (!position.accuracy.isFinite ||
                    position.accuracy > 50 ||
                    !position.latitude.isFinite ||
                    !position.longitude.isFinite ||
                    !position.altitude.isFinite)
                  return;
                final previous = _last;
                if (previous != null &&
                    (!position.timestamp.isAfter(previous.timestamp) ||
                        position.timestamp
                                .difference(previous.timestamp)
                                .inSeconds <
                            10))
                  return;
                var distance = distanceMeters, ascent = ascentMeters;
                if (previous != null) {
                  final moved = Geolocator.distanceBetween(
                    previous.latitude,
                    previous.longitude,
                    position.latitude,
                    position.longitude,
                  );
                  final noise = math.max(
                    3.0,
                    (previous.accuracy + position.accuracy) / 3,
                  );
                  if (moved >= noise) distance += moved;
                }
                if (position.altitudeAccuracy.isFinite &&
                    position.altitudeAccuracy >= 0 &&
                    position.altitudeAccuracy <= 15) {
                  _altitudes.add(position.altitude);
                  if (_altitudes.length > 3) _altitudes.removeAt(0);
                  _altitudeBaseline ??= position.altitude;
                  if (_altitudes.length == 3) {
                    final sorted = List<double>.of(_altitudes)..sort();
                    final height = sorted[1];
                    final delta = height - _altitudeBaseline!;
                    if (delta.abs() >=
                        math.max(3.0, position.altitudeAccuracy)) {
                      if (delta > 0) ascent += delta;
                      _altitudeBaseline = height;
                    }
                  }
                }
                final point = TrackPoint(
                  latitude: position.latitude,
                  longitude: position.longitude,
                  altitude: position.altitude,
                  timestamp: position.timestamp,
                );
                final snapshot = TrackSession(
                  id: _id!,
                  startedAt: _startedAt!,
                  endedAt: position.timestamp,
                  distanceMeters: distance,
                  ascentMeters: ascent,
                );
                await DatabaseService.instance.appendTrackPoint(
                  snapshot,
                  point,
                );
                _last = position;
                points.add(point);
                distanceMeters = distance;
                ascentMeters = ascent;
                notifyListeners();
              })
              .catchError((Object e) {
                if (generation != _generation) return;
                _storageFailed = true;
                error =
                    'Registrazione fermata: impossibile salvare il tracciato. $e';
                isTracking = false;
                final stream = _subscription;
                _subscription = null;
                unawaited(stream?.cancel());
                notifyListeners();
              });
        },
        onError: (Object e) {
          if (generation != _generation) return;
          error = 'GPS interrotto: $e. I punti già acquisiti restano salvati.';
          isTracking = false;
          final stream = _subscription;
          _subscription = null;
          unawaited(stream?.cancel());
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
      if (_storageFailed) throw Exception(error);
      final saved = session(DateTime.now());
      await DatabaseService.instance.appendTrackPoint(saved, null);
      return saved;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
