import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

class ExpeditionEvent {
  const ExpeditionEvent({required this.type, required this.text, required this.at});
  final String type;
  final String text;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
        'at': at.toUtc().toIso8601String(),
      };

  factory ExpeditionEvent.fromJson(Map<String, dynamic> json) => ExpeditionEvent(
        type: '${json['type'] ?? 'info'}',
        text: '${json['text'] ?? ''}',
        at: DateTime.tryParse('${json['at'] ?? ''}')?.toLocal() ?? DateTime.now(),
      );
}

class ExpeditionState {
  const ExpeditionState({
    required this.mapId,
    required this.name,
    required this.startedAt,
    required this.expiresAt,
    required this.positionSharing,
    required this.events,
  });

  final String mapId;
  final String name;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool positionSharing;
  final List<ExpeditionEvent> events;

  bool get expired => DateTime.now().isAfter(expiresAt);
  Duration get remaining => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toJson() => {
        'mapId': mapId,
        'name': name,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'positionSharing': positionSharing,
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory ExpeditionState.fromJson(Map<String, dynamic> json) => ExpeditionState(
        mapId: '${json['mapId'] ?? ''}',
        name: '${json['name'] ?? 'Spedizione'}',
        startedAt: DateTime.tryParse('${json['startedAt'] ?? ''}')?.toLocal() ?? DateTime.now(),
        expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}')?.toLocal() ?? DateTime.now(),
        positionSharing: json['positionSharing'] == true,
        events: (json['events'] as List? ?? const [])
            .map((e) => ExpeditionEvent.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  ExpeditionState copyWith({DateTime? expiresAt, bool? positionSharing, List<ExpeditionEvent>? events}) => ExpeditionState(
        mapId: mapId,
        name: name,
        startedAt: startedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        positionSharing: positionSharing ?? this.positionSharing,
        events: events ?? this.events,
      );
}

class ExpeditionService {
  static final instance = ExpeditionService();
  File? _file;
  final Map<String, ExpeditionState> _states = {};
  bool _loaded = false;

  Future<File> get file async => _file ??= File('${await getDatabasesPath()}/wildtrack_expeditions.json');

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    _states.clear();
    try {
      final raw = jsonDecode(await (await file).readAsString()) as Map<String, dynamic>;
      for (final entry in raw.entries) {
        _states[entry.key] = ExpeditionState.fromJson(Map<String, dynamic>.from(entry.value as Map));
      }
    } catch (_) {}
  }

  Future<void> reloadFromDisk() async {
    _loaded = false;
    _states.clear();
    await _load();
  }

  Future<void> _save() async {
    final f = await file;
    await f.parent.create(recursive: true);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(_states.map((k, v) => MapEntry(k, v.toJson()))), flush: true);
    await tmp.rename(f.path);
  }

  Future<ExpeditionState> ensure({required String mapId, required String name}) async {
    await _load();
    final current = _states[mapId];
    if (current != null && !current.expired) return current;
    final now = DateTime.now();
    final created = ExpeditionState(
      mapId: mapId,
      name: name,
      startedAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      positionSharing: false,
      events: [ExpeditionEvent(type: 'created', text: 'Spedizione creata', at: now)],
    );
    _states[mapId] = created;
    await _save();
    return created;
  }

  Future<ExpeditionState?> get(String mapId) async {
    await _load();
    return _states[mapId];
  }

  Future<ExpeditionState> setDuration(String mapId, Duration duration) async {
    await _load();
    final current = _states[mapId];
    if (current == null) throw StateError('Spedizione non trovata');
    final max = duration > const Duration(days: 14) ? const Duration(days: 14) : duration;
    final next = current.copyWith(
      expiresAt: DateTime.now().add(max),
      events: [...current.events, ExpeditionEvent(type: 'expiry', text: 'Durata aggiornata a ${max.inHours} ore', at: DateTime.now())],
    );
    _states[mapId] = next;
    await _save();
    return next;
  }

  Future<ExpeditionState> setPositionSharing(String mapId, bool enabled) async {
    await _load();
    final current = _states[mapId];
    if (current == null) throw StateError('Spedizione non trovata');
    if (current.expired && enabled) throw StateError('La spedizione è scaduta');
    final next = current.copyWith(
      positionSharing: enabled,
      events: [...current.events, ExpeditionEvent(type: 'location', text: enabled ? 'Condivisione posizione attivata' : 'Condivisione posizione disattivata', at: DateTime.now())],
    );
    _states[mapId] = next;
    await _save();
    return next;
  }

  Future<ExpeditionState> addEvent(String mapId, String type, String text) async {
    await _load();
    final current = _states[mapId];
    if (current == null) throw StateError('Spedizione non trovata');
    final next = current.copyWith(events: [...current.events, ExpeditionEvent(type: type, text: text, at: DateTime.now())]);
    _states[mapId] = next;
    await _save();
    return next;
  }

  Future<void> expireNow(String mapId) async {
    await _load();
    final current = _states[mapId];
    if (current == null) return;
    _states[mapId] = current.copyWith(
      expiresAt: DateTime.now(),
      positionSharing: false,
      events: [...current.events, ExpeditionEvent(type: 'ended', text: 'Spedizione terminata', at: DateTime.now())],
    );
    await _save();
  }

  Future<void> purgeExpiredSharing() async {
    await _load();
    var changed = false;
    for (final entry in _states.entries.toList()) {
      final state = entry.value;
      if (state.expired && state.positionSharing) {
        _states[entry.key] = state.copyWith(positionSharing: false);
        changed = true;
      }
    }
    if (changed) await _save();
  }
}
