import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildtrack_mvp/screens/access_screen.dart';
import 'package:wildtrack_mvp/screens/intro_screen.dart';
import 'package:wildtrack_mvp/screens/premium_animal_screen.dart';
import 'package:wildtrack_mvp/screens/premium_sighting_screen.dart';
import 'package:wildtrack_mvp/screens/species_screen.dart';

void main() {
  for (final width in [360.0, 411.0]) {
    final screens = <String, Widget>{
      'welcome': const IntroScreen(home: SizedBox()),
      'access': const AccessScreen(home: SizedBox()),
      'deer': PremiumAnimalScreen(animals.firstWhere((a) => a.name == 'Cervo')),
      'sighting': const PremiumSightingScreen(),
    };
    for (final screen in screens.entries) {
      testWidgets('${screen.key} has no clipped controls at $width dp', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(home: screen.value));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
