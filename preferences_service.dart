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

  Future<void> save() async {
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
      }),
      flush: true,
    );
    await temporary.rename(file.path);
    notifyListeners();
  }
}
