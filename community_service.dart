import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'preferences_service.dart';
import 'location_service.dart';

const communityUrl = 'https://wildtrack-community.canta80.chatgpt.site';

class CommunityService extends ChangeNotifier {
  static final instance = CommunityService();
  final List<Map<String, dynamic>> pending = [];
  List<Map<String, dynamic>> sightings = [], people = [];
  String? error;
  bool syncing = false;
  int? nextOffset;
  Position? position;
  late File queueFile;
  Timer? timer;
  bool foreground = true;
  int presenceGeneration = 0;
  StreamSubscription<Position>? backgroundLocation;
  bool presenceBusy = false;
  Future<void> queueWrites = Future<void>.value();
  bool get canShare =>
      PreferencesService.instance.visible &&
      (foreground ||
          (PreferencesService.instance.backgroundSharing &&
              backgroundLocation != null));

  Future<void> configureBackgroundSharing() async {
    final prefs = PreferencesService.instance;
    if (!prefs.visible || !prefs.backgroundSharing) {
      await backgroundLocation?.cancel();
      backgroundLocation = null;
      return;
    }
    if (!foreground || backgroundLocation != null) return;
    if (!await LocationService.ensurePermission()) {
      throw Exception(
        'Autorizza la posizione per attivare la condivisione a schermo spento.',
      );
    }
    // Start while the activity is visible. Android then keeps the location
    // foreground service alive when the user switches apps or locks the screen.
    backgroundLocation =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            intervalDuration: const Duration(seconds: 15),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'WildTrack · posizione condivisa',
              notificationText: 'Condivisione attiva anche a schermo spento. Apri WildTrack per disattivarla.',
              enableWakeLock: true,
              setOngoing: true,
            ),
          ),
        ).listen(
          (p) {
            if (!canShare) return;
            position = p;
            notifyListeners();
            unawaited(updatePresence());
          },
          onError: (Object e) {
            error = 'Condivisione GPS interrotta: $e';
            final stream = backgroundLocation;
            backgroundLocation = null;
            unawaited(stream?.cancel());
            notifyListeners();
          },
        );
  }

  Future<void> load() async {
    queueFile = File(
      '${PreferencesService.instance.file.parent.path}/wildtrack_outbox.json',
    );
    try {
      pending.addAll(
        (jsonDecode(await queueFile.readAsString()) as List).map(
          (x) => Map<String, dynamic>.from(x as Map),
        ),
      );
    } catch (_) {}
  }

  Future<void> saveQueue() {
    final snapshot = jsonEncode(pending);
    final write = queueWrites.then((_) async {
      final f = File('${queueFile.path}.tmp');
      await f.writeAsString(snapshot, flush: true);
      await f.rename(queueFile.path);
    });
    queueWrites = write.catchError((Object _) {});
    return write;
  }

  Future<Map<String, dynamic>> api(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.openUrl(
        method,
        Uri.parse('$communityUrl/api/$path'),
      );
      req.headers.set(
        'Authorization',
        'Bearer ${PreferencesService.instance.token}',
      );
      req.headers.set('Accept', 'application/json');
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final res = await req.close().timeout(const Duration(seconds: 40));
      final text = await res
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 40));
      final data = jsonDecode(text) as Map<String, dynamic>;
      if (res.statusCode >= 400) {
        throw Exception(data['error'] ?? 'Servizio non disponibile');
      }
      return data;
    } finally {
      client.close(force: true);
    }
  }

  void start() {
    timer?.cancel();
    foreground = true;
    unawaited(
      configureBackgroundSharing().catchError((Object e) {
        error = e.toString();
        notifyListeners();
      }),
    );
    unawaited(refresh());
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (foreground) {
        unawaited(refresh());
      } else if (canShare) {
        unawaited(updatePresence());
      }
    });
  }

  Future<void> pause() async {
    foreground = false;
    if (!canShare) {
      timer?.cancel();
      await hide();
    }
  }

  Future<void> hide() async {
    presenceGeneration++;
    await backgroundLocation?.cancel();
    backgroundLocation = null;
    position = null;
    people = [];
    notifyListeners();
    try {
      await api('community', method: 'DELETE');
    } catch (_) {
      error =
          'Rimozione della posizione non confermata: scadrà entro 3 minuti.';
      notifyListeners();
    }
  }

  Future<void> updatePresence() async {
    final prefs = PreferencesService.instance;
    if (!canShare || presenceBusy) return;
    presenceBusy = true;
    final generation = presenceGeneration;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('GPS disattivato');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception('Autorizza il GPS per condividere la posizione');
      }
      final p = backgroundLocation != null
          ? position
          : await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 15),
              ),
            );
      if (generation != presenceGeneration || !canShare) {
        return;
      }
      if (p == null || DateTime.now().difference(p.timestamp).inSeconds > 90)
        return;
      position = p;
      await api(
        'community',
        method: 'POST',
        body: {
          'nickname': prefs.nickname,
          'lat': p.latitude,
          'lng': p.longitude,
        },
      );
      if (generation != presenceGeneration || !canShare) {
        await hide();
        return;
      }
      final data = await api('community');
      people = (data['items'] as List)
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
      notifyListeners();
    } catch (e) {
      error = 'Persone vicine: ${e.toString().replaceFirst('Exception: ', '')}';
      people = [];
      notifyListeners();
    } finally {
      presenceBusy = false;
    }
  }

  Future<void> add(Map<String, dynamic> item) async {
    if (pending.any((s) => s['id'] == item['id'])) return;
    pending.add(Map<String, dynamic>.from(item));
    try {
      await saveQueue();
    } catch (_) {
      pending.removeWhere((s) => s['id'] == item['id']);
      rethrow;
    }
    notifyListeners();
    // Saving never waits for Internet. Publishing resumes after durable storage.
    unawaited(refresh());
  }

  Future<void> refresh({bool more = false}) async {
    if (syncing) return;
    syncing = true;
    try {
      while (pending.isNotEmpty) {
        final item = pending.first;
        await api('sightings', method: 'POST', body: item);
        pending.removeAt(0);
        try {
          await saveQueue();
        } catch (_) {
          pending.insert(0, item);
          rethrow;
        }
      }
      final data = await api(
        'sightings?offset=${more ? (nextOffset ?? 0) : 0}',
      );
      final rows = (data['items'] as List)
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
      if (more) {
        final ids = sightings.map((x) => x['id']).toSet();
        sightings.addAll(rows.where((x) => !ids.contains(x['id'])));
      } else {
        sightings = rows;
      }
      nextOffset = data['nextOffset'] as int?;
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      syncing = false;
      notifyListeners();
    }
    await updatePresence();
  }

  Future<void> deleteSighting(String id) async {
    await api('sightings?id=${Uri.encodeQueryComponent(id)}', method: 'DELETE');
    sightings.removeWhere((s) => s['id'] == id);
    notifyListeners();
  }

  Future<void> cancelPending(String id) async {
    if (syncing) throw Exception('Attendi la fine della sincronizzazione');
    pending.removeWhere((s) => s['id'] == id);
    await saveQueue();
    notifyListeners();
  }
}
