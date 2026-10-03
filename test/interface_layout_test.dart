import 'package:flutter/services.dart';
import 'package:wildtrack_mvp/main.dart' show wildTrackTheme;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildtrack_mvp/screens/access_screen.dart';
import 'package:wildtrack_mvp/screens/intro_screen.dart';
import 'package:wildtrack_mvp/screens/premium_animal_screen.dart';
import 'package:wildtrack_mvp/screens/premium_sighting_screen.dart';
import 'package:wildtrack_mvp/screens/species_screen.dart';
import 'package:wildtrack_mvp/screens/species_detail_screen.dart';

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('interface-capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/interface-previews')
      ..createSync(recursive: true);
    File(
      '${folder.path}/${name.replaceAll(RegExp(r"[^a-zA-Z0-9_-]"), "_")}.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> settleImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isNotEmpty) {
    final context = tester.element(find.byType(Image).first);
    await tester.runAsync(() async {
      for (final image in images) {
        if (image.image is AssetImage)
          await precacheImage(image.image, context);
      }
    });
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = <String, List<String>>{
      'serif': [
        'assets/approved/editorial_serif.ttf',
        'assets/approved/editorial_serif_italic.ttf',
      ],
      'sans-serif': ['assets/approved/interface_sans.ttf'],
      'Roboto': ['assets/approved/interface_sans.ttf'],
      'WildTrackIcons': ['assets/approved/wildtrack_icons.ttf'],
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
    };
    for (final font in fonts.entries) {
      final loader = FontLoader(font.key);
      for (final path in font.value) loader.addFont(rootBundle.load(path));
      await loader.load();
    }
  });
  for (final width in [360.0, 411.0]) {
    final screens = <String, Widget>{
      'welcome': const IntroScreen(home: SizedBox()),
      'access': const AccessScreen(home: SizedBox()),
      for (final animal in animals)
        'species ${animal.name}': PremiumAnimalScreen(animal),
      'sighting': const PremiumSightingScreen(),
    };
    for (final screen in screens.entries) {
      testWidgets(
        '${screen.key} renders and scrolls without layout exceptions at $width dp',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('interface-capture'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: wildTrackTheme(Brightness.light),
                home: screen.value,
              ),
            ),
          );
          await settleImages(tester);
          expect(tester.takeException(), isNull);
          if (width == 411) await capture(tester, screen.key);
          if (screen.key.startsWith('species ')) {
            final animal = (screen.value as PremiumAnimalScreen).animal;
            expect(
              tester
                  .widgetList<Image>(find.byType(Image))
                  .every((image) => image.fit != BoxFit.cover),
              true,
            );
            await tester.scrollUntilVisible(
              find.text(speciesDetails[animal.name]!.habitat),
              300,
              scrollable: find.byType(Scrollable).first,
            );
            expect(
              find.text(speciesDetails[animal.name]!.habitat),
              findsOneWidget,
            );
            await tester.scrollUntilVisible(
              find.text('Periodo migliore'),
              300,
              scrollable: find.byType(Scrollable).first,
            );
            await settleImages(tester);
            expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
            // Low seasonal suitability is not a diagnosis of hibernation.
            expect(find.text('In letargo'), findsNothing);

            for (final text in tester.widgetList<Text>(find.byType(Text))) {
              expect(text.overflow, isNot(TextOverflow.ellipsis));
            }
            if (width == 411) await capture(tester, '${screen.key}_seasons');
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, 1500),
            );
            await settleImages(tester);
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -550),
            );
            await settleImages(tester);
            expect(tester.takeException(), isNull);
            if (width == 411) await capture(tester, '${screen.key}_middle');
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -550),
            );
            await settleImages(tester);
            expect(tester.takeException(), isNull);
            if (width == 411) await capture(tester, '${screen.key}_bottom');
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
