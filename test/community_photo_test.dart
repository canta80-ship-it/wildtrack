import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildtrack_mvp/screens/community_photo_widget.dart';
void main() {
  testWidgets('Unavailable Community photo has a retry action that requests a fresh image URL', (tester) async {
    final urls = <String>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CommunityPhoto(sightingId: 'test-photo', imageBuilder: (url) {urls.add(url);return NetworkImage(url);}))));
    await tester.pumpAndSettle();
    expect(find.text('Riprova foto'), findsOneWidget);
    expect(urls.last, contains('retry=0'));
    await tester.tap(find.text('Riprova foto'));
    await tester.pumpAndSettle();
    expect(urls.last, contains('retry=1'));
    expect(find.text('Foto non caricata'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Loaded Community photo opens with pinch zoom and closes', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CommunityPhoto(sightingId: 'loaded-photo', imageBuilder: (_) => const AssetImage('assets/approved/cervo_thumb.jpg')))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Chiudi foto'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });

}
