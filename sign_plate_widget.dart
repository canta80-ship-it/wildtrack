import 'package:flutter/material.dart';

/// The four specimens occupy equal quarters of a 3:1 illustrated plate.
class SignPlateIllustration extends StatelessWidget {
  const SignPlateIllustration({super.key, required this.asset, required this.index, required this.label});
  final String asset, label;
  final int index;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label, image: true,
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(width: 120, height: 160,
        child: ClipRect(child: OverflowBox(
          minWidth: 480, maxWidth: 480, minHeight: 160, maxHeight: 160,
          alignment: Alignment(-1 + 2 * index / 3, 0),
          child: Image.asset(asset, width: 480, height: 160, fit: BoxFit.contain, filterQuality: FilterQuality.high, excludeFromSemantics: true),
        )),
      ),
    ),
  );
}
