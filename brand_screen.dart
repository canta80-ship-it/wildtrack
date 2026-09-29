import 'package:flutter/material.dart';

/// WildTrack's compact mark, using the same greens as the application theme.
class WildTrackLogo extends StatelessWidget {
  const WildTrackLogo({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logo WildTrack',
    image: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF647A3F), Color(0xFF244A32)],
        ),
        border: Border.all(color: const Color(0xFFA9BE82)),
      ),
      child: Icon(
        Icons.pets_rounded,
        color: const Color(0xFFD4E1B9),
        size: size * .64,
      ),
    ),
  );
}

class WildTrackBrand extends StatelessWidget {
  const WildTrackBrand({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      WildTrackLogo(),
      SizedBox(width: 10),
      Flexible(child: Text('WildTrack', overflow: TextOverflow.ellipsis)),
    ],
  );
}
