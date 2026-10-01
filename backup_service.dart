import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';
import 'preferences_service.dart';
import 'media_storage_service.dart';
import 'expedition_service.dart';

class BackupFolderInfo {
  const BackupFolderInfo({required this.label, required this.uri});
  final String label;
  final String uri;
}

class WildTrackBackupService {
  static final instance = WildTrackBackupService();
  static const MethodChannel _channel = MethodChannel('wildtrack/backup');
  static const int backupVersion = 1;
  static const Duration automaticInterval = Duration(hours: 12);

  Future<File> get _stateFile async => File('${await getDatabasesPath()}/wildtrack_backup_state.json');

  Future<BackupFolderInfo?> folderInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('folderInfo');
    if (result == null) return null;
    return BackupFolderInfo(
      label: '${result['label'] ?? 'Cartella backup'}',
      uri: '${result['uri'] ?? ''}',
    );
  }

  Future<BackupFolderInfo?> chooseFolder() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('pickFolder');
    if (result == null) return null;
    return BackupFolderInfo(
      label: '${result['label'] ?? 'Cartella backup'}',
      uri: '${result['uri'] ?? ''}',
    );
  }

  Future<DateTime?> lastBackupAt() async {
    try {
      final raw = jsonDecode(await (await _stateFile).readAsString()) as Map<String, dynamic>;
      return DateTime.tryParse('${raw['lastBackupAt'] ?? ''}')?.toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _markBackup(DateTime value) async {
    final f = await _stateFile;
    await f.parent.create(recursive: true);
    await f.writeAsString(jsonEncode({'lastBackupAt': value.toUtc().toIso8601String()}), flush: true);
  }

  Future<Map<String, dynamic>> _preferencesSnapshot() async {
    final prefs = PreferencesService.instance;
    return {
      'theme': prefs.theme.name,
      'soundPanel': prefs.soundPanel,
      'repeats': prefs.repeats,
      'visible': prefs.visible,
      'backgroundSharing': prefs.backgroundSharing,
      'chatNotifications': prefs.chatNotifications,
      'sightingNotifications': prefs.sightingNotifications,
      'fieldSilence': prefs.fieldSilence,
      'nickname': prefs.nickname,
    };
  }

  Future<Map<String, dynamic>> _expeditionsSnapshot() async {
    final file = await ExpeditionService.instance.file;
    if (!await file.exists()) return const {};
    try {
      final data = jsonDecode(await file.readAsString());
      return data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return const {};
    }
  }

  Future<List<Map<String, dynamic>>> _mediaSnapshot() async {
    final dir = await MediaStorageService.instance.mediaDirectory;
    if (!await dir.exists()) return const [];
    final result = <Map<String, dynamic>>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final bytes = await entity.readAsBytes();
      result.add({'name': p.basename(entity.path), 'data': base64Encode(bytes)});
    }
    return result;
  }

  Future<Uint8List> buildBackup() async {
    final payload = {
      'format': 'wildtrack-backup',
      'backupVersion': backupVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'appData': {
        'database': await DatabaseService.instance.exportSnapshot(),
        'profileAndSettings': await _preferencesSnapshot(),
        'expeditions': await _expeditionsSnapshot(),
        'media': await _mediaSnapshot(),
      },
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  Future<String> backupNow() async {
    final folder = await folderInfo();
    if (folder == null) throw StateError('Scegli prima una destinazione cloud o locale.');
    final bytes = await buildBackup();
    final now = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    final name = 'WildTrack-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}.wildtrack';
    await _channel.invokeMethod('writeBackup', {'name': name, 'data': bytes});
    await _markBackup(DateTime.now());
    return name;
  }

  Future<bool> autoBackupIfDue() async {
    if (await folderInfo() == null) return false;
    final last = await lastBackupAt();
    if (last != null && DateTime.now().difference(last) < automaticInterval) return false;
    await backupNow();
    return true;
  }

  Future<void> restoreLatest() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('readLatest');
    if (result == null || result['data'] == null) {
      throw StateError('Nessun backup WildTrack trovato nella cartella selezionata.');
    }
    final data = result['data'];
    final bytes = data is Uint8List ? data : Uint8List.fromList(List<int>.from(data as List));
    await restore(bytes);
  }

  Future<void> restore(Uint8List bytes) async {
    final root = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (root['format'] != 'wildtrack-backup') {
      throw const FormatException('File non riconosciuto come backup WildTrack');
    }
    final version = (root['backupVersion'] as num?)?.toInt() ?? 0;
    if (version != backupVersion) throw const FormatException('Versione backup non supportata');
    final appData = Map<String, dynamic>.from(root['appData'] as Map? ?? const {});

    final database = Map<String, dynamic>.from(appData['database'] as Map? ?? const {});
    await DatabaseService.instance.restoreSnapshot(database);

    final profile = Map<String, dynamic>.from(appData['profileAndSettings'] as Map? ?? const {});
    final prefs = PreferencesService.instance;
    if (profile['theme'] != null) {
      prefs.theme = ThemeMode.values.firstWhere(
        (x) => x.name == profile['theme'],
        orElse: () => prefs.theme,
      );
    }
    prefs.soundPanel = profile['soundPanel'] == true;
    prefs.repeats = ((profile['repeats'] as num?)?.toInt() ?? prefs.repeats).clamp(1, 5);
    prefs.visible = profile['visible'] == true;
    prefs.backgroundSharing = profile['backgroundSharing'] == true;
    prefs.chatNotifications = profile['chatNotifications'] != false;
    prefs.sightingNotifications = profile['sightingNotifications'] != false;
    prefs.fieldSilence = profile['fieldSilence'] == true;
    final nickname = '${profile['nickname'] ?? ''}'.trim();
    if (nickname.isNotEmpty) prefs.nickname = nickname;
    await prefs.save();

    final mediaDir = await MediaStorageService.instance.mediaDirectory;
    if (await mediaDir.exists()) {
      await for (final entity in mediaDir.list(followLinks: false)) {
        if (entity is File) {
          try { await entity.delete(); } catch (_) {}
        }
      }
    }
    for (final raw in (appData['media'] as List? ?? const [])) {
      final row = Map<String, dynamic>.from(raw as Map);
      final name = p.basename('${row['name'] ?? ''}');
      if (name.isEmpty) continue;
      final encoded = '${row['data'] ?? ''}';
      if (encoded.isEmpty) continue;
      await File(p.join(mediaDir.path, name)).writeAsBytes(base64Decode(encoded), flush: true);
    }

    final expeditionFile = await ExpeditionService.instance.file;
    final expeditions = Map<String, dynamic>.from(appData['expeditions'] as Map? ?? const {});
    await expeditionFile.writeAsString(jsonEncode(expeditions), flush: true);
    await ExpeditionService.instance.reloadFromDisk();
  }
}
