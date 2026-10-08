import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'storage_service.dart';

class PreferencesService extends ChangeNotifier {
  static final instance = PreferencesService();
  static const secure = MethodChannel('wildtrack/secure');
  final _writes = SerialExecutor();
  ThemeMode theme = ThemeMode.light;
  bool soundPanel = false;
  int repeats = 1;
  bool visible = false;
  bool backgroundSharing = false;
  String nickname = 'Esploratore';
  String token = '';
  late File file;
  Future<void> load() async {
    file = File('${await getDatabasesPath()}/wildtrack_preferences.json');
    await file.parent.create(recursive: true);
    final value = await JsonStorage.read(file, empty: <String, dynamic>{});
    if (value is! Map) throw const FormatException('Preferenze non valide');
    final p = Map<String, dynamic>.from(value);
    theme = ThemeMode.values.firstWhere(
      (x) => x.name == p['theme'],
      orElse: () => ThemeMode.light,
    );
    soundPanel = p['soundPanel'] == true;
    repeats = p['repeats'] is int ? (p['repeats'] as int).clamp(1, 5) : 1;
    visible = p['visible'] == true;
    backgroundSharing = p['backgroundSharing'] == true;
    nickname = p['nickname'] is String ? p['nickname'] as String : nickname;
    final protected = await secure.invokeMethod<String>('readToken');
    final legacy = p['token'];
    token = protected ?? (legacy is String ? legacy : '');
    if (token.isEmpty) {
      if (await File('${file.path}.bak').exists()) {
        // A legacy identity in the recovery file must not be regenerated.
        final backup = await JsonStorage.read(
          File('${file.path}.bak'),
          empty: <String, dynamic>{},
        );
        if (backup is Map && backup['token'] is String)
          token = backup['token'] as String;
      }
      if (token.isEmpty) {
        final r = Random.secure();
        token = List.generate(
          32,
          (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
      }
    }
    // Write and read back before removing the legacy plaintext identity.
    await secure.invokeMethod<void>('writeToken', {'token': token});
    if (await secure.invokeMethod<String>('readToken') != token) {
      throw const FormatException(
        'Impossibile proteggere la credenziale esistente',
      );
    }
    await save();
    // The recovery preferences must not retain the old plaintext token either.
    final backup = File('${file.path}.bak');
    if (await backup.exists()) await file.copy(backup.path);
  }

  Future<void> save() {
    final snapshot = <String, Object>{
      'theme': theme.name,
      'soundPanel': soundPanel,
      'repeats': repeats,
      'visible': visible,
      'backgroundSharing': backgroundSharing,
      'nickname': nickname,
    };
    return _writes.run(() async {
      await JsonStorage.write(file, snapshot);
      notifyListeners();
    });
  }
}
