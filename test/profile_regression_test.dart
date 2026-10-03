import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildtrack_mvp/services/preferences_service.dart';
import 'package:wildtrack_mvp/services/community_service.dart';
import 'package:wildtrack_mvp/screens/profile_avatar_widget.dart';
import 'package:wildtrack_mvp/screens/premium_community_screen.dart';

void main() {
  test('Profile photo and name persist without changing Community ownership', () async {
    final folder = await Directory.systemTemp.createTemp('wildtrack-profile');
    final prefs = PreferencesService.instance;
    final oldToken = prefs.token;
    final oldName = prefs.nickname;
    final oldAvatar = prefs.avatarBase64;
    prefs.file = File('${folder.path}/prefs.json');
    prefs.token = 'a' * 64;
    prefs.nickname = 'Stefano';
    prefs.avatarBase64 = 'photo';
    await prefs.save();
    final saved = jsonDecode(await prefs.file.readAsString());
    expect(saved['nickname'], 'Stefano');
    expect(saved['avatarBase64'], 'photo');
    expect(saved['token'], 'a' * 64);
    prefs.avatarBase64 = null;
    await prefs.save();
    expect(jsonDecode(await prefs.file.readAsString())['avatarBase64'], isNull);
    prefs.token = oldToken; prefs.nickname = oldName; prefs.avatarBase64 = oldAvatar;
    await folder.delete(recursive: true);
  });
  testWidgets('Community displays the actual author next to the profile circle', (tester) async {
    CommunityService.instance.sightings = [{'id':'example', 'species':'Cervo', 'authorName':'Autore reale', 'notes':'Osservazione', 'observedAt':'2026-10-03T10:00:00Z', 'lat':46, 'lng':13}];
    await tester.pumpWidget(const MaterialApp(home: PremiumCommunityScreen()));
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0,-260));
    await tester.pump();
    expect(find.text('Autore reale'), findsOneWidget);
    expect(find.byType(ProfileAvatar), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    CommunityService.instance.sightings=[];
  });
  testWidgets('Missing and corrupt avatars preserve the profile circle', (tester) async {
    for (final photo in <String?>[null, '!invalid']) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProfileAvatar(base64: photo))));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
