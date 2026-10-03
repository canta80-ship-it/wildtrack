import 'dart:async';
import 'community_service.dart';
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
import 'outdoor_tools_service.dart';

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

  Future<File> get _stateFile async =>
      File('${await getDatabasesPath()}/wildtrack_backup_state.json');

  Future<BackupFolderInfo?> folderInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'folderInfo',
    );
    if (result == null) return null;
    return BackupFolderInfo(
      label: '${result['label'] ?? 'Cartella backup'}',
      uri: '${result['uri'] ?? ''}',
    );
  }

  Future<BackupFolderInfo?> chooseFolder() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'pickFolder',
    );
    if (result == null) return null;
    return BackupFolderInfo(
      label: '${result['label'] ?? 'Cartella backup'}',
      uri: '${result['uri'] ?? ''}',
    );
  }

  Future<DateTime?> lastBackupAt() async {
    try {
      final raw = jsonDecode(
        await (await _stateFile).readAsString(),
      ) as Map<String, dynamic>;
      return DateTime.tryParse('${raw['lastBackupAt'] ?? ''}')?.toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _markBackup(DateTime value) async {
    final f = await _stateFile;
    await f.parent.create(recursive: true);
    await f.writeAsString(
      jsonEncode({'lastBackupAt': value.toUtc().toIso8601String()}),
      flush: true,
    );
  }

  Future<Map<String, dynamic>> _preferencesSnapshot() async {
    final prefs = PreferencesService.instance;
    await prefs.save();
    final data = Map<String, dynamic>.from(
      jsonDecode(await prefs.file.readAsString()) as Map,
    );
    data.remove('loginIdentifier');
    data.remove('token'); // Device identity is never transferred by a backup.
    return data;
  }

  Future<Map<String, dynamic>> _expeditionsSnapshot() async {
    final file = await ExpeditionService.instance.file;
    if (!await file.exists()) return const {};
    try {
      final data = jsonDecode(await file.readAsString());
      return data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
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
      result.add({
        'name': p.basename(entity.path),
        'data': base64Encode(bytes),
      });
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
        'outdoorTools': await OutdoorToolsStore.instance.exportSnapshot(),
        'media': await _mediaSnapshot(),
      },
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  Future<String> backupNow() async {
    final folder = await folderInfo();
    if (folder == null)
      throw StateError('Scegli prima una destinazione cloud o locale.');
    final bytes = await buildBackup();
    final now = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    final name =
        'WildTrack-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}.wildtrack';
    await _channel.invokeMethod('writeBackup', {'name': name, 'data': bytes});
    await _markBackup(DateTime.now());
    return name;
  }

  Future<bool> autoBackupIfDue() async {
    if (await folderInfo() == null) return false;
    final last = await lastBackupAt();
    if (last != null && DateTime.now().difference(last) < automaticInterval)
      return false;
    await backupNow();
    return true;
  }

  Future<bool> restoreFile() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('pickBackupFile');
    if (result == null) return false;
    final data = result['data'];
    if (data == null) throw const FormatException('Backup vuoto o non leggibile');
    await restore(data is Uint8List ? data : Uint8List.fromList(List<int>.from(data as List)));
    return true;
  }

  Future<void> restoreLatest() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'readLatest',
    );
    if (result == null || result['data'] == null) {
      throw StateError(
        'Nessun backup WildTrack trovato nella cartella selezionata.',
      );
    }
    final data = result['data'];
    final bytes = data is Uint8List
        ? data
        : Uint8List.fromList(List<int>.from(data as List));
    await restore(bytes);
  }

  bool _restoring = false;

  Future<void> restore(Uint8List bytes) async {
    if (_restoring) throw StateError('Un ripristino è già in corso.');
    _restoring = true;
    final community = CommunityService.instance;
    final wasRunning = community.timer?.isActive == true;
    community.backupPaused = true;
    community.timer?.cancel();
    try {
      final limit = DateTime.now().add(const Duration(seconds: 45));
      while (community.syncing || community.presenceBusy) {
        if (DateTime.now().isAfter(limit)) throw StateError('Sincronizzazione ancora in corso. Riprova tra poco.');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await _restore(bytes);
    } finally {
      _restoring = false;
      community.backupPaused = false;
      if (wasRunning) community.start();
    }
  }

  Future<void> _restore(Uint8List bytes) async {
    final root = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (root['format'] != 'wildtrack-backup') {
      throw const FormatException(
        'File non riconosciuto come backup WildTrack',
      );
    }
    final version = (root['backupVersion'] as num?)?.toInt() ?? 0;
    if (version != backupVersion)
      throw const FormatException('Versione backup non supportata');
    final appData = Map<String, dynamic>.from(
      root['appData'] as Map? ?? const {},
    );

    final database = Map<String, dynamic>.from(
      appData['database'] as Map? ?? const {},
    );
    final profile = Map<String, dynamic>.from(
      appData['profileAndSettings'] as Map? ?? const {},
    );
    final expeditions = Map<String, dynamic>.from(
      appData['expeditions'] as Map? ?? const {},
    );
    final outdoor = appData['outdoorTools'] == null ? null : OutdoorToolsStore.validate(Map<String, dynamic>.from(appData['outdoorTools'] as Map));
    final previousOutdoor = await OutdoorToolsStore.instance.exportSnapshot();
    var outdoorChanged = false;
    final prefs = PreferencesService.instance;
    final mediaDir = await MediaStorageService.instance.mediaDirectory;
    final stage = await mediaDir.parent.createTemp('.restore-stage-');
    final previousMedia = Directory('${stage.path}-previous');
    final expeditionFile = await ExpeditionService.instance.file;
    final previousDatabase = await DatabaseService.instance.exportSnapshot();
    final previousPrefs = await prefs.file.readAsBytes();
    final previousExpeditions = await expeditionFile.exists()
        ? await expeditionFile.readAsBytes()
        : null;
    var mediaSwapped = false;
    var databaseChanged = false;
    var discardPreviousMedia = false;
    try {
      // Decode and stage every file before touching the live archive.
      final names = <String>{};
      for (final raw in (appData['media'] as List? ?? const [])) {
        final row = Map<String, dynamic>.from(raw as Map);
        final name = row['name'];
        final encoded = row['data'];
        if (name is! String ||
            name.isEmpty ||
            name == '.' ||
            name == '..' ||
            p.basename(name) != name ||
            name.contains('\\') ||
            !names.add(name) ||
            encoded is! String) {
          throw const FormatException('Media backup non valido');
        }
        await File(p.join(stage.path, name))
            .writeAsBytes(base64Decode(encoded), flush: true);
      }
      String? relocate(Object? raw) {
        if (raw == null) return null;
        if (raw is! String)
          throw const FormatException('Percorso foto non valido');
        final name = p.basename(raw);
        return names.contains(name) ? p.join(mediaDir.path, name) : raw;
      }

      for (final raw in (database['sightings'] as List? ?? const [])) {
        final row = raw as Map;
        row['photo_path'] = relocate(row['photo_path']);
      }
      for (final raw in (database['sightingPhotos'] as List? ?? const [])) {
        final row = raw as Map;
        row['path'] = relocate(row['path']);
      }
      final settings = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(previousPrefs)) as Map,
      )..addAll(profile);
      settings['token'] = prefs.token;
      final previousSettings = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(previousPrefs)) as Map,
      );
      // Check supported value types before changing database or files.
      for (final entry in profile.entries) {
        final old = previousSettings[entry.key];
        final value = entry.value;
        if (entry.key == 'avatarBase64' && (value == null || value is String)) continue;
        if ((old is String && value is! String) ||
            (old is bool && value is! bool) ||
            (old is int && value is! int) ||
            (old is num && value is! num) ||
            (old is List &&
                (value is! List || value.any((v) => v is! String)))) {
          throw const FormatException('Impostazioni backup non valide');
        }
      }
      final stagedSettings = File('${stage.path}.prefs');
      final stagedExpeditions = File('${stage.path}.expeditions');
      await stagedSettings.writeAsString(jsonEncode(settings), flush: true);
      await stagedExpeditions.writeAsString(
        jsonEncode(expeditions),
        flush: true,
      );
      try {
        await mediaDir.rename(previousMedia.path);
        await stage.rename(mediaDir.path);
        mediaSwapped = true;
        await DatabaseService.instance.restoreSnapshot(database);
        databaseChanged = true;
        await stagedSettings.rename(prefs.file.path);
        await stagedExpeditions.rename(expeditionFile.path);
        await prefs.load();
        await prefs.save();
        await ExpeditionService.instance.reloadFromDisk();
        if (outdoor != null) {
          await OutdoorToolsStore.instance.restoreSnapshot(outdoor);
          outdoorChanged = true;
        }
        discardPreviousMedia = true;
      } catch (_) {
        if (outdoorChanged) await OutdoorToolsStore.instance.restoreSnapshot(previousOutdoor);
        if (databaseChanged)
          await DatabaseService.instance.restoreSnapshot(previousDatabase);
        if (mediaSwapped && await mediaDir.exists())
          await mediaDir.delete(recursive: true);
        if (await previousMedia.exists())
          await previousMedia.rename(mediaDir.path);
        await prefs.file.writeAsBytes(previousPrefs, flush: true);
        if (previousExpeditions != null) {
          await expeditionFile.writeAsBytes(previousExpeditions, flush: true);
        } else if (await expeditionFile.exists()) {
          await expeditionFile.delete();
        }
        await prefs.load();
        await prefs.save();
        await ExpeditionService.instance.reloadFromDisk();
        discardPreviousMedia = true;
        rethrow;
      } finally {
        if (await stagedSettings.exists()) await stagedSettings.delete();
        if (await stagedExpeditions.exists()) await stagedExpeditions.delete();
      }
    } finally {
      if (await stage.exists()) await stage.delete(recursive: true);
      if (discardPreviousMedia && await previousMedia.exists())
        await previousMedia.delete(recursive: true);
    }
  }
}
