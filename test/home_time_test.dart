import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildtrack_mvp/screens/premium_home_screen.dart';
import 'package:wildtrack_mvp/services/solar_context_service.dart';

Widget hero({required DateTime time, SolarContext? solar, double? temperature}) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: PremiumHomeHero(nickname: 'Trailtester', activity: 'DISCRETE', phase: solar?.label ?? 'Fase solare non disponibile', phaseCode: solar?.phase, clockTime: time, hasPosition: solar != null, temperature: temperature, onBell: () {}))));

void main() {
  test('Greeting covers local hour boundaries including 22:27', () {
    for (final c in [(0,0,'Buonasera'),(4,59,'Buonasera'),(5,0,'Buongiorno'),(11,59,'Buongiorno'),(12,0,'Buon pomeriggio'),(17,59,'Buon pomeriggio'),(18,0,'Buonasera'),(22,27,'Buonasera')]) {
      expect(PremiumHomeHero.greeting(DateTime(2026,10,3,c.$1,c.$2)),c.$3);
    }
  });

  testWidgets('At 22:27 in Italy the actual header shows evening, night and moon', (tester) async {
    tester.view.physicalSize = const Size(360,844); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final sun = SolarContext.at(DateTime.utc(2026,10,3,20,27),46,13);
    await tester.pumpWidget(hero(time: DateTime(2026,10,3,22,27),solar:sun,temperature:14));
    await tester.pumpAndSettle();
    expect(find.text('Buonasera,\nTrailtester'),findsOneWidget);
    expect(find.text('14° · Notte · poca luce'),findsOneWidget);
    expect(find.byIcon(Icons.nightlight_round),findsOneWidget);
    expect(find.byIcon(Icons.wb_twilight_outlined),findsNothing);
    expect(find.byIcon(Icons.wb_sunny_outlined),findsNothing);
    expect(find.textContaining('alba ideale'),findsNothing);
    expect(tester.takeException(),isNull);
  });

  testWidgets('Each solar phase uses a matching header symbol and text', (tester) async {
    for (final c in [('day',30.0,Icons.wb_sunny_outlined),('dawn',0.0,Icons.wb_twilight_outlined),('dusk',0.0,Icons.wb_twilight_outlined),('night',-20.0,Icons.nightlight_round)]) {
      final solar=SolarContext(c.$1,c.$2,null,null);
      await tester.pumpWidget(hero(time:DateTime(2026,10,3,12),solar:solar));
      await tester.pumpAndSettle();
      expect(find.text(solar.label),findsOneWidget);
      expect(find.byIcon(c.$3),findsOneWidget);
      expect(tester.takeException(),isNull);
    }
  });

  testWidgets('Missing location shows unknown phase rather than a sun or moon guess', (tester) async {
    await tester.pumpWidget(hero(time:DateTime(2026,10,3,22,27)));
    await tester.pumpAndSettle();
    expect(find.text('Buonasera,\nTrailtester'),findsOneWidget);
    expect(find.text('Fase solare non disponibile'),findsOneWidget);
    expect(find.byIcon(Icons.help_outline),findsOneWidget);
    expect(find.byIcon(Icons.nightlight_round),findsNothing);
    expect(find.byIcon(Icons.wb_twilight_outlined),findsNothing);
    expect(find.byIcon(Icons.wb_sunny_outlined),findsNothing);
  });

  testWidgets('Rebuilt header updates greeting at noon while preserving solar presentation', (tester) async {
    const day=SolarContext('day',30,null,null);
    await tester.pumpWidget(hero(time:DateTime(2026,10,3,11,59),solar:day));
    await tester.pumpAndSettle();
    expect(find.text('Buongiorno,\nTrailtester'),findsOneWidget);
    await tester.pumpWidget(hero(time:DateTime(2026,10,3,12),solar:day));
    await tester.pumpAndSettle();
    expect(find.text('Buon pomeriggio,\nTrailtester'),findsOneWidget);
    expect(find.text('Buongiorno,\nTrailtester'),findsNothing);
    expect(find.byIcon(Icons.wb_sunny_outlined),findsOneWidget);
  });
}
