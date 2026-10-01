import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class PreferencesService extends ChangeNotifier {
  static final instance = PreferencesService();
  ThemeMode theme = ThemeMode.light;
  bool soundPanel = false;
  int repeats = 1;
  bool visible = false;
  bool backgroundSharing = false;
  bool chatNotifications = true;
  bool sightingNotifications = true;
  bool fieldSilence = false;
  String nickname = 'Esploratore';
  String token = '';
  Set<String> favoriteSpecies = {};

  // Generic camera assistant profile. Brand/model are optional labels only.
  String cameraLabel = '';
  String cameraMode = 'M';
  String cameraShutter = '1/1000';
  String cameraAperture = 'f/5.6';
  bool cameraAutoIso = true;
  int cameraIso = 800;
  int cameraAutoIsoMax = 6400;
  String cameraFocus = 'AF-C';
  String cameraAfArea = 'Tracking / Zona';
  String cameraSubject = 'Animale / Uccello';
  String cameraDrive = 'Raffica alta';
  bool cameraStabilization = true;
  bool cameraRaw = true;
  int cameraFocalMm = 300;

  late File file;

  Future<void> load() async {
    file = File('${await getDatabasesPath()}/wildtrack_preferences.json');
    await file.parent.create(recursive: true);
    try {
      final p = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      theme = ThemeMode.values.firstWhere(
        (x) => x.name == p['theme'],
        orElse: () => ThemeMode.light,
      );
      soundPanel = p['soundPanel'] == true;
      repeats = ((p['repeats'] as int?) ?? 1).clamp(1, 5);
      visible = p['visible'] == true;
      backgroundSharing = p['backgroundSharing'] == true;
      chatNotifications = p['chatNotifications'] != false;
      sightingNotifications = p['sightingNotifications'] != false;
      fieldSilence = p['fieldSilence'] == true;
      nickname = p['nickname'] as String? ?? nickname;
      token = p['token'] as String? ?? '';
      favoriteSpecies = (p['favoriteSpecies'] as List? ?? const [])
          .whereType<String>()
          .toSet();
      cameraLabel = p['cameraLabel'] as String? ?? cameraLabel;
      cameraMode = p['cameraMode'] as String? ?? cameraMode;
      cameraShutter = p['cameraShutter'] as String? ?? cameraShutter;
      cameraAperture = p['cameraAperture'] as String? ?? cameraAperture;
      cameraAutoIso = p['cameraAutoIso'] != false;
      cameraIso = (p['cameraIso'] as num?)?.toInt() ?? cameraIso;
      cameraAutoIsoMax =
          (p['cameraAutoIsoMax'] as num?)?.toInt() ?? cameraAutoIsoMax;
      cameraFocus = p['cameraFocus'] as String? ?? cameraFocus;
      cameraAfArea = p['cameraAfArea'] as String? ?? cameraAfArea;
      cameraSubject = p['cameraSubject'] as String? ?? cameraSubject;
      cameraDrive = p['cameraDrive'] as String? ?? cameraDrive;
      cameraStabilization = p['cameraStabilization'] != false;
      cameraRaw = p['cameraRaw'] != false;
      cameraFocalMm = (p['cameraFocalMm'] as num?)?.toInt() ?? cameraFocalMm;
    } catch (_) {}
    if (token.isEmpty) {
      final r = Random.secure();
      token = List.generate(
        32,
        (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await save();
    }
  }

  Future<void> toggleFavorite(String species) async {
    final previous = Set<String>.from(favoriteSpecies);
    if (!favoriteSpecies.add(species)) favoriteSpecies.remove(species);
    notifyListeners();
    try {
      await save();
    } catch (_) {
      favoriteSpecies = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _pendingSave = Future<void>.value();

  Future<void> save() {
    final operation = _pendingSave.then((_) => _writePreferences());
    _pendingSave = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _writePreferences() async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'theme': theme.name,
        'soundPanel': soundPanel,
        'repeats': repeats,
        'visible': visible,
        'backgroundSharing': backgroundSharing,
        'chatNotifications': chatNotifications,
        'sightingNotifications': sightingNotifications,
        'fieldSilence': fieldSilence,
        'nickname': nickname,
        'token': token,
        'favoriteSpecies': favoriteSpecies.toList()..sort(),
        'cameraLabel': cameraLabel,
        'cameraMode': cameraMode,
        'cameraShutter': cameraShutter,
        'cameraAperture': cameraAperture,
        'cameraAutoIso': cameraAutoIso,
        'cameraIso': cameraIso,
        'cameraAutoIsoMax': cameraAutoIsoMax,
        'cameraFocus': cameraFocus,
        'cameraAfArea': cameraAfArea,
        'cameraSubject': cameraSubject,
        'cameraDrive': cameraDrive,
        'cameraStabilization': cameraStabilization,
        'cameraRaw': cameraRaw,
        'cameraFocalMm': cameraFocalMm,
      }),
      flush: true,
    );
    await temporary.rename(file.path);
    notifyListeners();
  }
}
