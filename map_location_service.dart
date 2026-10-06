import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'location_service.dart';

/// Foreground display only: never records or shares a position.
class MapLocationService extends ChangeNotifier with WidgetsBindingObserver {
  MapLocationService({this.initialPosition, Future<bool> Function()? permission, Future<Position?> Function()? current, Stream<Position> Function()? stream})
      : _permission = permission ?? LocationService.ensurePermission,
        _current = current ?? LocationService.currentPosition,
        _stream = stream ?? (() => Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5))) {
    point = initialPosition;
    WidgetsBinding.instance.addObserver(this);
  }
  final LatLng? initialPosition;
  final Future<bool> Function() _permission;
  final Future<Position?> Function() _current;
  final Stream<Position> Function() _stream;
  StreamSubscription<Position>? _subscription;
  LatLng? point;
  String? error;
  bool _active = false, _disposed = false;
  int _epoch = 0;
  DateTime? _lastFix;

  void _accept(Position position) {
    if (!_active || _disposed || !position.latitude.isFinite || !position.longitude.isFinite || position.latitude.abs() > 90 || position.longitude.abs() > 180) return;
    if (_lastFix != null && position.timestamp.isBefore(_lastFix!)) return;
    _lastFix = position.timestamp;
    point = LatLng(position.latitude, position.longitude);
    error = null;
    notifyListeners();
  }
  Future<void> start() async {
    if (_active || _disposed) return;
    _active = true;
    final epoch = ++_epoch;
    try {
      if (!await _permission()) {
        if (_disposed || epoch != _epoch) return;
        _active = false;
        error = 'Posizione non disponibile. Attiva il GPS e autorizza WildTrack.';
        notifyListeners();
        return;
      }
      if (!_active || _disposed || epoch != _epoch) return;
      _subscription = _stream().listen(_accept, onError: (_) {
        if (_active && !_disposed) { error = 'Segnale GPS non disponibile. Riprova.'; notifyListeners(); }
      });
      final position = await _current();
      if (!_disposed && epoch == _epoch && position != null) _accept(position);
    } catch (_) {
      if (!_disposed && epoch == _epoch) { error = 'Posizione non disponibile. Riprova con il GPS attivo.'; notifyListeners(); }
    }
  }
  Future<void> refresh() async {
    if (!_active) { await start(); return; }
    try { final position = await _current(); if (position != null) _accept(position); } catch (_) { if (!_disposed) { error = 'Segnale GPS non disponibile. Riprova.'; notifyListeners(); } }
  }
  void pause() {
    _active = false;
    _epoch++;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { unawaited(start()); }
    else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) { pause(); }
  }
  @override
  void dispose() {
    _disposed = true;
    pause();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
