import 'expedition_service.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'preferences_service.dart';
import 'database_service.dart';
import 'location_service.dart';
import 'media_storage_service.dart';
import 'privacy_service.dart';

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
  String? _syncedProfile;
  Future<void> syncProfile() async {
    final p = PreferencesService.instance;
    final signature = jsonEncode([p.token, p.nickname, p.avatarBase64]);
    if (_syncedProfile == signature) return;
    await api('profile', method: 'POST', body: {'nickname': p.nickname, 'avatar': p.avatarBase64});
    _syncedProfile = signature;
    notifyListeners();
  }
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
      if (res.statusCode >= 400)
        throw Exception(data['error'] ?? 'Servizio non disponibile');
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
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception('GPS disattivato');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
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
      if (generation != presenceGeneration || !canShare) return;
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
    final protected = item['groupId'] == null
        ? WildlifePrivacyService.instance.protectPayload(item)
        : Map<String, dynamic>.from(item);
    protected.putIfAbsent('authorName', () => PreferencesService.instance.nickname);
    final index = pending.indexWhere((s) => s['id'] == protected['id']);
    if (index >= 0 && syncing) {
      throw Exception(
        'Invio in corso. Attendi che termini prima di modificare la segnalazione.',
      );
    }
    final previous = index >= 0 ? pending[index] : null;
    if (index >= 0) {
      pending[index] = protected;
    } else {
      pending.add(protected);
    }
    try {
      await saveQueue();
    } catch (_) {
      if (previous != null) {
        pending[index] = previous;
      } else {
        pending.remove(protected);
      }
      rethrow;
    }
    if (protected['groupId'] == null) {
      await DatabaseService.instance.retainPublicSighting(
        protected,
        state: 'queued',
      );
    }
    error = null;
    notifyListeners();
    unawaited(refresh());
  }

  bool _readyForPublication(Map<String, dynamic> item) {
    final value = item['publishAfter'];
    if (value == null) return true;
    final due = DateTime.tryParse('$value')?.toLocal();
    return due == null || !DateTime.now().isBefore(due);
  }

  Duration? get nextPendingDelay {
    DateTime? next;
    for (final item in pending) {
      final due = DateTime.tryParse('${item['publishAfter'] ?? ''}')?.toLocal();
      if (due != null &&
          due.isAfter(DateTime.now()) &&
          (next == null || due.isBefore(next)))
        next = due;
    }
    return next == null ? null : next.difference(DateTime.now());
  }

  Future<void> refresh({bool more = false}) async {
    if (syncing) return;
    syncing = true;
    try {
      await syncProfile();
      while (pending.isNotEmpty) {
        final readyIndex = pending.indexWhere(_readyForPublication);
        if (readyIndex < 0) break;
        final item = pending[readyIndex];
        final payload = Map<String, dynamic>.from(item)..remove('publishAfter');
        await api('sightings', method: 'POST', body: payload);
        if (item['groupId'] == null) {
          await DatabaseService.instance.retainPublicSighting(item);
        }
        pending.removeAt(readyIndex);
        try {
          await saveQueue();
        } catch (_) {
          pending.insert(readyIndex, item);
          rethrow;
        }
      }
      await restoreMySightings();
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
      for (final row in rows) {
        if (row['mine'] == 1 && row['groupId'] == null) {
          await DatabaseService.instance.retainPublicSighting(row);
        }
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

  bool isMine(Map<String, dynamic> row) => row['mine'] == 1 || row['mine'] == true;

  Future<void> restoreMySightings() async {
    int? offset = 0;
    do {
      final data = await api('sightings?mine=1&offset=$offset');
      for (final raw in data['items'] as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        if (isMine(row)) {
          await DatabaseService.instance.retainPublicSighting(row);
          await restorePhoto(row);
        }
      }
      final next = data['nextOffset'] as int?;
      if (next != null && next <= offset!) throw StateError('Paginazione non valida');
      offset = next;
    } while (offset != null);
  }

  Future<void> restorePhoto(Map<String, dynamic> row) async {
    if (row['photo'] == null) return;
    final id = '${row['id']}';
    final existing = await DatabaseService.instance.getSightingPhotos(id);
    for (final path in existing) {
      if (await File(path).exists()) return;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse('$communityUrl/api/photo?id=${Uri.encodeQueryComponent(id)}'));
      req.headers.set('Authorization', 'Bearer ${PreferencesService.instance.token}');
      final response = await req.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return;
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        bytes.addAll(chunk);
        if (bytes.length > 1000000) throw StateError('Foto troppo grande');
      }
      if (bytes.length < 8 || !listEquals(bytes.take(8).toList(), [137,80,78,71,13,10,26,10])) return;
      final dir = await MediaStorageService.instance.mediaDirectory;
      // Never use a remote identifier as a filesystem path.
      final safe = base64Url.encode(utf8.encode(id)).replaceAll('=', '');
      final target = File('${dir.path}/community-$safe.png');
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(target.path);
      await DatabaseService.instance.attachRecoveredPhoto(id, target.path);
    } catch (_) {
      // Keep the diary record. A later refresh retries unavailable photos.
    } finally { client.close(force: true); }
  }

  Future<void> deleteGroup(Map<String, dynamic> group) async {
    if (group['mine'] != 1)
      throw Exception('Operazione riservata al proprietario');
    if (syncing) throw Exception('Attendi la fine della sincronizzazione');
    final id = '${group['id']}';
    syncing = true;
    notifyListeners();
    try {
      await api(
        'maps',
        method: 'POST',
        body: {'action': 'delete', 'mapId': id},
      );
      final previous = List<Map<String, dynamic>>.from(pending);
      pending.removeWhere((row) => row['groupId'] == id);
      try {
        await saveQueue();
      } catch (_) {
        pending
          ..clear()
          ..addAll(previous);
        rethrow;
      }
      sightings.removeWhere((row) => row['groupId'] == id);
      final state = await ExpeditionService.instance.get(id);
      if (state?.positionSharing == true) await hide();
      await ExpeditionService.instance.delete(id);
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> deleteSighting(String id, {bool keepDiary = false}) async {
    if (syncing) throw Exception('Attendi la fine della sincronizzazione');
    // The server checks the authenticated owner even if no feed page is cached.
    final cached = sightings.where((s) => s['id'] == id);
    if (cached.isNotEmpty && !isMine(cached.first)) {
      throw Exception('Solo il creatore può eliminare questo post.');
    }
    final result = await api('sightings?id=${Uri.encodeQueryComponent(id)}', method: 'DELETE');
    if (result['deleted'] != true) throw Exception('Eliminazione non confermata');
    sightings.removeWhere((s) => s['id'] == id);
    if (keepDiary) {
      await DatabaseService.instance.makeSightingPrivate(id);
    } else {
      await DatabaseService.instance.deleteSighting(id);
    }
    notifyListeners();
  }

  Future<void> cancelPending(String id) async {
    if (syncing) throw Exception('Attendi la fine della sincronizzazione');
    final previous = List<Map<String, dynamic>>.from(pending);
    pending.removeWhere((s) => s['id'] == id);
    try {
      await saveQueue();
    } catch (_) {
      pending
        ..clear()
        ..addAll(previous);
      rethrow;
    }
    notifyListeners();
  }
}
