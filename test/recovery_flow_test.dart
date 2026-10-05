import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildtrack_mvp/screens/recovery_screen.dart';
import 'package:wildtrack_mvp/services/preferences_service.dart';
void main() {
  testWidgets('Legacy request displays validation instead of silently ignoring a tap', (tester) async {
    var posts = 0;
    await tester.pumpWidget(MaterialApp(home: RecoveryScreen(sighting: const {'id': 'old', 'species': 'Stambecco'}, api: (path, method, body) async {if (method == 'POST') posts++;return path == 'recovery' ? {'items': []} : {'active': false};})));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Invia richiesta al gestore'), 250, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invia richiesta al gestore'));
    await tester.pumpAndSettle();
    expect(find.text('Descrivi la prova con almeno 10 caratteri.'), findsOneWidget);
    expect(posts, 0);
  });
  testWidgets('Original screenshot text submits even when previous nickname is forgotten', (tester) async {
    Map<String, dynamic>? submitted;
    PreferencesService.instance.nickname = '';
    await tester.pumpWidget(MaterialApp(home: RecoveryScreen(sighting: const {'id': 'old', 'species': 'Stambecco'}, api: (path, method, body) async {if (method == 'POST') submitted = body;return path == 'recovery' ? {'items': []} : {'active': false};})));
    await tester.pumpAndSettle();
    final evidence = find.byType(TextFormField).last;
    await tester.ensureVisible(evidence);
    await tester.enterText(evidence, 'foto disponibile');
    await tester.scrollUntilVisible(find.text('Invia richiesta al gestore'), 250, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invia richiesta al gestore'));
    await tester.pumpAndSettle();
    expect(submitted?['previousName'], 'Non ricordo');
    expect(submitted?['evidence'], 'foto disponibile');
    expect(find.text('Richiesta inviata'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Replacing Community identity retains previous credential and supports returning to it', (tester) async {
    await tester.runAsync(() async {
    final dir = await Directory.systemTemp.createTemp('wildtrack-recovery');
    final prefs = PreferencesService.instance;
    final original = prefs.token, previous = prefs.previousCommunityToken;
    File? oldFile;try {oldFile = prefs.file;} catch (_) {}
    try {
      prefs.file = File('${dir.path}/wildtrack_preferences.json');
      prefs.token = List.filled(64, 'a').join();
      final newer = List.filled(64, 'b').join();
      await prefs.replaceCommunityIdentity(newer);
      final identity = File('${dir.path}/wildtrack_identity.json');
      expect(jsonDecode(await identity.readAsString())['previousToken'], List.filled(64, 'a').join());
      await prefs.replaceCommunityIdentity(prefs.previousCommunityToken!);
      expect(prefs.token, List.filled(64, 'a').join());
      expect(prefs.previousCommunityToken, newer);
      expect(jsonDecode(await prefs.file.readAsString())['token'], prefs.token);
    } finally {prefs.token = original;prefs.previousCommunityToken = previous;if (oldFile != null) prefs.file = oldFile;await dir.delete(recursive: true);}
    });
  });
}
