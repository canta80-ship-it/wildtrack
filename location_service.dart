import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'storage_service.dart';

class LocationService {
  static Future<bool>? _permission;
  static final _changes = SerialExecutor();
  static final _consumers = <StreamController<Position>, String>{};
  static StreamSubscription<Position>? _hardware;
  static int? _interval;
  static int? _distance;
  static Future<bool> ensurePermission() =>
      _permission ??= _check().whenComplete(() => _permission = null);
  static Future<bool> _check() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied)
      p = await Geolocator.requestPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  static Future<Position?> currentPosition({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!await ensurePermission()) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeout,
      ),
    );
  }

  static Stream<Position> positionStream({String purpose = 'tracking'}) {
    late StreamController<Position> controller;
    controller = StreamController<Position>(
      onListen: () {
        _consumers[controller] = purpose;
        unawaited(_reconfigure());
      },
      onCancel: () async {
        _consumers.remove(controller);
        await _reconfigure();
      },
    );
    return controller.stream;
  }

  static Future<void> _reconfigure() => _changes.run(() async {
    final purposes = _consumers.values;
    final interval = purposes.isEmpty
        ? null
        : purposes
              .map(
                (p) => p == 'navigation'
                    ? 3
                    : p == 'sharing'
                    ? 15
                    : 10,
              )
              .reduce(math.min);
    final distance = purposes.isEmpty
        ? null
        : purposes
              .map(
                (p) => p == 'sharing'
                    ? 0
                    : p == 'navigation'
                    ? 3
                    : 5,
              )
              .reduce(math.min);
    if (interval == _interval &&
        distance == _distance &&
        (interval == null || _hardware != null))
      return;
    await _hardware?.cancel();
    _hardware = null;
    _interval = interval;
    _distance = distance;
    if (interval == null) return;
    _hardware =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: distance!,
            intervalDuration: Duration(seconds: interval),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'WildTrack · GPS attivo',
              notificationText:
                  'Registrazione, navigazione o condivisione attiva. Apri WildTrack per fermarla.',
              enableWakeLock: true,
              setOngoing: true,
            ),
          ),
        ).listen(
          (p) {
            for (final c in List.of(_consumers.keys)) {
              if (!c.isClosed) c.add(p);
            }
          },
          onError: (Object e, StackTrace stack) {
            for (final c in List.of(_consumers.keys)) {
              if (!c.isClosed) c.addError(e, stack);
            }
          },
        );
  });
}
