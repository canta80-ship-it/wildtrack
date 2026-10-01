import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'community_service.dart';
import 'preferences_service.dart';

const _firebaseApiKey = String.fromEnvironment('WILDTRACK_FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('WILDTRACK_FIREBASE_APP_ID');
const _firebaseProjectId = String.fromEnvironment('WILDTRACK_FIREBASE_PROJECT_ID');
const _firebaseSenderId = String.fromEnvironment('WILDTRACK_FIREBASE_SENDER_ID');

FirebaseOptions? get _firebaseOptions {
  if (_firebaseApiKey.isEmpty ||
      _firebaseAppId.isEmpty ||
      _firebaseProjectId.isEmpty ||
      _firebaseSenderId.isEmpty) {
    return null;
  }
  return const FirebaseOptions(
    apiKey: _firebaseApiKey,
    appId: _firebaseAppId,
    messagingSenderId: _firebaseSenderId,
    projectId: _firebaseProjectId,
  );
}

@pragma('vm:entry-point')
Future<void> wildTrackFirebaseBackgroundHandler(RemoteMessage message) async {
  final options = _firebaseOptions;
  if (options == null) return;
  try {
    await Firebase.initializeApp(options: options);
  } catch (_) {}
  // Le notifiche con payload `notification` vengono mostrate dal sistema
  // Android anche quando l'app è terminata. Il data payload resta disponibile
  // quando l'utente apre WildTrack dalla notifica.
}

class PushStatus {
  const PushStatus({
    required this.configured,
    required this.permissionGranted,
    required this.registered,
    this.error,
  });
  final bool configured;
  final bool permissionGranted;
  final bool registered;
  final String? error;
}

class PushService extends ChangeNotifier {
  static final instance = PushService();

  bool configured = false;
  bool permissionGranted = false;
  bool registered = false;
  String? token;
  String? error;
  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _foregroundMessages;
  StreamSubscription<RemoteMessage>? _openedMessages;
  RemoteMessage? lastMessage;

  PushStatus get status => PushStatus(
        configured: configured,
        permissionGranted: permissionGranted,
        registered: registered,
        error: error,
      );

  Future<void> initialize() async {
    final options = _firebaseOptions;
    configured = options != null;
    if (options == null) {
      error = 'Push non configurate: mancano i parametri Firebase del progetto.';
      notifyListeners();
      return;
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      FirebaseMessaging.onBackgroundMessage(wildTrackFirebaseBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!permissionGranted) {
        error = 'Notifiche non autorizzate sul dispositivo.';
        notifyListeners();
        return;
      }
      token = await messaging.getToken();
      await _registerToken();
      await _tokenRefresh?.cancel();
      _tokenRefresh = messaging.onTokenRefresh.listen((value) async {
        token = value;
        await _registerToken();
      });
      await _foregroundMessages?.cancel();
      _foregroundMessages = FirebaseMessaging.onMessage.listen((message) {
        lastMessage = message;
        notifyListeners();
      });
      await _openedMessages?.cancel();
      _openedMessages = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        lastMessage = message;
        notifyListeners();
      });
      final initial = await messaging.getInitialMessage();
      if (initial != null) lastMessage = initial;
      error = null;
      notifyListeners();
    } catch (e) {
      registered = false;
      error = 'Push: ${e.toString().replaceFirst('Exception: ', '')}';
      notifyListeners();
    }
  }

  Future<void> syncPreferences() async {
    if (!configured || token == null) return;
    await _registerToken();
  }

  Future<void> _registerToken() async {
    final value = token;
    if (value == null || value.isEmpty) return;
    final prefs = PreferencesService.instance;
    try {
      await CommunityService.instance.api(
        'push/register',
        method: 'POST',
        body: {
          'token': value,
          'platform': 'android',
          'chat': prefs.chatNotifications,
          'sightings': prefs.sightingNotifications,
          'nickname': prefs.nickname,
        },
      );
      registered = true;
      error = null;
    } catch (e) {
      registered = false;
      error = 'Registrazione push non confermata dal server: ${e.toString().replaceFirst('Exception: ', '')}';
    }
    notifyListeners();
  }

  Future<void> unregister() async {
    final value = token;
    if (value == null) return;
    try {
      await CommunityService.instance.api(
        'push/register',
        method: 'DELETE',
        body: {'token': value},
      );
    } catch (_) {}
    registered = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_tokenRefresh?.cancel());
    unawaited(_foregroundMessages?.cancel());
    unawaited(_openedMessages?.cancel());
    super.dispose();
  }
}
