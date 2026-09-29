import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'preferences_service.dart';

const communityUrl = 'https://wildtrack-community.fun-bard-3414.chatgpt.site';

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

  Future<void> saveQueue() async {
    final f = File('${queueFile.path}.tmp');
    await f.writeAsString(jsonEncode(pending), flush: true);
    await f.rename(queueFile.path);
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
      final res = await req.close().timeout(const Duration(seconds: 20));
      final text = await res
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
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
    unawaited(refresh());
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (foreground) unawaited(refresh());
    });
  }

  Future<void> pause() async {
    foreground = false;
    timer?.cancel();
    await hide();
  }

  Future<void> hide() async {
    presenceGeneration++;
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
    if (!prefs.visible || !foreground) return;
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
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (generation != presenceGeneration || !prefs.visible || !foreground) {
        return;
      }
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
      if (generation != presenceGeneration || !prefs.visible || !foreground) {
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
    }
  }

  Future<void> add(Map<String, dynamic> item) async {
    pending.add(item);
    await saveQueue();
    notifyListeners();
    await refresh();
  }

  Future<void> refresh({bool more = false}) async {
    if (syncing) return;
    syncing = true;
    try {
      while (pending.isNotEmpty) {
        final item = pending.first;
        await api('sightings', method: 'POST', body: item);
        pending.removeAt(0);
        await saveQueue();
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
