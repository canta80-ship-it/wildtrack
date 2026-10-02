import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<void> requestTrackingNotification() async {
    if (!Platform.isAndroid) return;
    // Denial does not stop the location foreground service; Android shows it in
    // active apps instead. The app still asks so the user can see GPS activity.
    await Permission.notification.request();
  }

  static Future<Position?> currentPosition() async {
    if (!await ensurePermission()) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  static Stream<Position> positionStream() => Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 10),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'WildTrack · GPS attivo',
        notificationChannelName: 'Registrazione GPS',
        notificationText: 'Registrazione o condivisione in corso. Apri WildTrack per fermarla.',
        enableWakeLock: true,
        setOngoing: true,
      ),
    ),
  );
}
