import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'preferences_service.dart';
import 'database_service.dart';
import 'location_service.dart';
import 'storage_service.dart';
import 'network_service.dart';

const communityUrl = 'https://wildtrack-community.canta80.chatgpt.site';

class CommunityService extends ChangeNotifier {
  CommunityService({this.transport});
  final Future<Map<String, dynamic>> Function(
    String path,
    String method,
    Map<String, dynamic>? body,
  )?
  transport;
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
  final _queue = SerialExecutor();
  final _locationChanges = SerialExecutor();
  DateTime? _presenceAt;
  bool get canShare =>
      PreferencesService.instance.visible &&
      (foreground ||
          (PreferencesService.instance.backgroundSharing &&
              backgroundLocation != null));

  Future<void> configureBackgroundSharing() => _locationChanges.run(() async {
    final prefs = PreferencesService.instance;
    if (!prefs.visible || !prefs.backgroundSharing) {
      await backgroundLocation?.cancel();
      backgroundLocation = null;
      return;
    }
    if (!foreground || backgroundLocation != null) return;
    final generation = presenceGeneration;
    if (!await LocationService.ensurePermission()) {
      throw Exception(
        'Autorizza la posizione per attivare la condivisione a schermo spento.',
      );
    }
    if (generation != presenceGeneration ||
        !foreground ||
        !prefs.visible ||
        !prefs.backgroundSharing)
      return;
    backgroundLocation = LocationService.positionStream(purpose: 'sharing')
        .listen(
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
  });

  Future<void> load() async {
    queueFile = File(
      '${PreferencesService.instance.file.parent.path}/wildtrack_outbox.json',
    );
    final value = await JsonStorage.read(queueFile, empty: <Object>[]);
    if (value is! List) throw const FormatException('Coda di invio non valida');
    final restored = value
        .map((x) => Map<String, dynamic>.from(x as Map))
        .toList();
    if (restored.any(
      (x) =>
          x['id'] is! String ||
          x['species'] is! String ||
          !validCoordinates(x['lat'], x['lng']),
    )) {
      throw const FormatException('Coda di invio non valida: dati conservati');
    }
    for (final item in restored) {
      if (item['approximate'] == true || item['approximate'] == 1) {
        item['lat'] = ((item['lat'] as num) * 100).round() / 100;
        item['lng'] = ((item['lng'] as num) * 100).round() / 100;
      }
    }
    if (restored.isNotEmpty) await JsonStorage.write(queueFile, restored);
    pending
      ..clear()
      ..addAll(restored);
  }

  Future<void> _commit(List<Map<String, dynamic>> rows) async {
    await JsonStorage.write(queueFile, rows);
    pending
      ..clear()
      ..addAll(rows);
  }

  Future<Map<String, dynamic>> api(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$communityUrl/api/$path');
    final data = transport != null
        ? await transport!(path, method, body)
        : await JsonNetwork.request(
            uri,
            method: method,
            headers: {
              'Authorization': 'Bearer ${PreferencesService.instance.token}',
            },
            body: body,
          );
    final endpoint = uri.pathSegments.last;
    if (data.containsKey('items')) {
      final raw = data['items'];
      final valid = records(raw, endpoint);
      if (raw is List && raw.isNotEmpty && valid.isEmpty)
        throw const FormatException(
          'Risposta incompatibile: ultimo elenco conservato',
        );
      data['items'] = valid;
    }
    if (data.containsKey('members'))
      data['members'] = records(data['members'], 'members');
    return data;
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
    await _locationChanges.run(() async {
      await backgroundLocation?.cancel();
      backgroundLocation = null;
    });
    _presenceAt = null;
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
      if (_presenceAt != null &&
          DateTime.now().difference(_presenceAt!).inSeconds < 15)
        return;
      final p = backgroundLocation != null
          ? position
          : await LocationService.currentPosition(
              timeout: const Duration(seconds: 15),
            );
      if (generation != presenceGeneration || !canShare) {
        return;
      }
      if (p == null || DateTime.now().difference(p.timestamp).inSeconds > 90) {
        return;
      }
      position = p;
      _presenceAt = DateTime.now();
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
        await api('community', method: 'DELETE');
        return;
      }
      final data = await api('community');
      if (generation != presenceGeneration || !canShare) return;
      people = records(data['items'], 'community');
      notifyListeners();
    } catch (e) {
      if (generation != presenceGeneration) return;
      error = 'Persone vicine: ${e.toString().replaceFirst('Exception: ', '')}';
      people = [];
      notifyListeners();
    } finally {
      presenceBusy = false;
    }
  }

  Future<void> add(Map<String, dynamic> item) async {
    await _queue.run(() async {
      final index = pending.indexWhere((s) => s['id'] == item['id']);
      if (index >= 0 && syncing)
        throw Exception(
          'Invio in corso. Attendi che termini prima di modificare la segnalazione.',
        );
      final rows = List<Map<String, dynamic>>.of(pending);
      final replacement = Map<String, dynamic>.from(item);
      if (index >= 0) {
        rows[index] = replacement;
      } else {
        rows.add(replacement);
      }
      await _commit(rows);
    });
    error = null;
    notifyListeners();
    if (foreground) unawaited(refresh());
  }

  Future<void> refresh({bool more = false}) async {
    if (syncing) return;
    syncing = true;
    try {
      while (pending.isNotEmpty) {
        final item = pending.first;
        final payload = Map<String, dynamic>.from(item)
          ..removeWhere((k, _) => k.startsWith('_'));
        await api('sightings', method: 'POST', body: payload);
        await _queue.run(() async {
          final rows = List<Map<String, dynamic>>.of(pending);
          rows.removeWhere((x) => identical(x, item));
          await _commit(rows);
        });
        if (item['groupId'] == null && item['_localSnapshot'] is Map) {
          await DatabaseService.instance.deleteIfUnchanged(
            item['_localId'] as String? ?? item['id'] as String,
            item['_localSnapshot'] as Map,
          );
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
      nextOffset = data['nextOffset'] is int ? data['nextOffset'] as int : null;
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
    await _queue.run(() async {
      if (syncing) throw Exception('Attendi la fine della sincronizzazione');
      final rows = List<Map<String, dynamic>>.of(pending)
        ..removeWhere((s) => s['id'] == id);
      await _commit(rows);
    });
    notifyListeners();
  }
}
