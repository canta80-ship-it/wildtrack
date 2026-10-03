import 'package:flutter/material.dart';

/// The four specimens occupy equal quarters of a 3:1 illustrated plate.
class SignPlateIllustration extends StatelessWidget {
  const SignPlateIllustration({super.key, required this.asset, required this.index, required this.label, this.grid = false});
  final String asset, label;
  final int index;
  final bool grid;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label, image: true,
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(width: grid ? 160 : 120, height: 160,
        child: ClipRect(child: OverflowBox(
          minWidth: grid ? 320 : 480, maxWidth: grid ? 320 : 480, minHeight: grid ? 320 : 160, maxHeight: grid ? 320 : 160,
          alignment: grid ? Alignment(index.isEven ? -1 : 1, index < 2 ? -1 : 1) : Alignment(-1 + 2 * index / 3, 0),
          child: Image.asset(asset, width: grid ? 320 : 480, height: grid ? 320 : 160, fit: BoxFit.contain, filterQuality: FilterQuality.high, excludeFromSemantics: true),
        )),
      ),
    ),
  );
}

