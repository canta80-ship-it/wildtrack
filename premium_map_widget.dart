import 'package:flutter/material.dart';

/// Shared ivory/sage cartography treatment. Apply only to base-map tiles:
/// markers, habitat colors, GPS geometry and source attribution retain contrast.
class PremiumMapSurface extends StatelessWidget {
  const PremiumMapSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      .72, .15, .05, 0, 19,
      .07, .80, .05, 0, 18,
      .07, .15, .70, 0, 15,
      0, 0, 0, 1, 0,
    ]),
    child: child,
  );
}
