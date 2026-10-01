import 'package:flutter/material.dart';

import '../premium_ui.dart';

String wildBookAssetFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('lupo') || n.contains('volpe') || n.contains('sciacallo')) {
    return 'intro_lupo.jpg';
  }
  if (n.contains('marmotta') || n.contains('tasso') || n.contains('lepre') || n.contains('ermellino') || n.contains('martora') || n.contains('faina')) {
    return 'intro_marmotta.jpg';
  }
  if (n.contains('gufo') || n.contains('allocco') || n.contains('civetta') || n.contains('poiana') || n.contains('aquila') || n.contains('falco') || n.contains('grifone') || n.contains('airone') || n.contains('germano') || n.contains('picchio') || n.contains('uccell')) {
    return 'intro_gufo.jpg';
  }
  return 'intro_cervo.jpg';
}

class BookPhoto extends StatelessWidget {
  const BookPhoto({super.key, required this.asset, this.alignment = Alignment.center, this.fit = BoxFit.cover});
  final String asset;
  final Alignment alignment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        fit: fit,
        alignment: alignment,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF2D9A6), Color(0xFFD6E0D2), Color(0xFF284B39)],
            ),
          ),
        ),
      );
}

class BookHero extends StatelessWidget {
  const BookHero({
    super.key,
    required this.asset,
    required this.child,
    this.height = 340,
    this.alignment = Alignment.center,
    this.bottomStrength = .78,
  });
  final String asset;
  final Widget child;
  final double height;
  final Alignment alignment;
  final double bottomStrength;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BookPhoto(asset: asset, alignment: alignment),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x16000000),
                    Colors.transparent,
                    Color.fromRGBO(12, 31, 22, bottomStrength),
                  ],
                  stops: const [0, .42, 1],
                ),
              ),
            ),
            child,
          ],
        ),
      );
}

class BookAnimalThumb extends StatelessWidget {
  const BookAnimalThumb(this.name, {super.key, this.width = 132, this.height = 116});
  final String name;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F0E6),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BookPhoto(asset: wildBookAssetFor(name), alignment: Alignment.center),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00FFFDF8), Color(0x16FFFDF8), Color(0xB8FFFDF8)],
                  stops: [0, .58, 1],
                ),
              ),
            ),
          ],
        ),
      );
}

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.tint});
  final Widget child;
  final EdgeInsets padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: tint ?? Colors.white.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x10000000)),
          boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: child,
      );
}

class BookSectionTitle extends StatelessWidget {
  const BookSectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 25,
                height: 1,
                fontWeight: FontWeight.w800,
                color: WildColors.ink,
                letterSpacing: -.5,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!, style: const TextStyle(color: WildColors.muted, fontWeight: FontWeight.w700)),
            ),
        ],
      );
}
