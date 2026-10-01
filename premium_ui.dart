import 'package:flutter/material.dart';

class WildColors {
  static const forest = Color(0xFF173F2B);
  static const forest2 = Color(0xFF28563C);
  static const sage = Color(0xFFDCE8D8);
  static const sageSoft = Color(0xFFEEF3E9);
  static const ivory = Color(0xFFF8F6EF);
  static const cream = Color(0xFFF1EEE4);
  static const sand = Color(0xFFEADCC8);
  static const earth = Color(0xFF8A633A);
  static const ink = Color(0xFF16251B);
  static const muted = Color(0xFF657064);
  static const amber = Color(0xFFC78B35);
}

class WildText {
  static const display = TextStyle(
    fontFamily: 'serif',
    fontSize: 36,
    height: .98,
    fontWeight: FontWeight.w700,
    color: WildColors.ink,
    letterSpacing: -1.2,
  );
  static const h1 = TextStyle(
    fontFamily: 'serif',
    fontSize: 28,
    height: 1,
    fontWeight: FontWeight.w700,
    color: WildColors.ink,
    letterSpacing: -.7,
  );
  static const h2 = TextStyle(
    fontFamily: 'serif',
    fontSize: 22,
    height: 1.05,
    fontWeight: FontWeight.w700,
    color: WildColors.ink,
    letterSpacing: -.35,
  );
}

class WildLogo extends StatelessWidget {
  const WildLogo({super.key, this.compact = false, this.light = false});
  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : WildColors.forest;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.pets, color: color, size: compact ? 25 : 34),
      SizedBox(width: compact ? 6 : 9),
      Text(
        'WildTrack',
        style: TextStyle(
          fontFamily: 'serif',
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 23 : 34,
          letterSpacing: -.8,
        ),
      ),
    ]);
  }
}

class WildGlass extends StatelessWidget {
  const WildGlass({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Colors.white.withValues(alpha: .91),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .65)),
      boxShadow: const [BoxShadow(color: Color(0x17000000), blurRadius: 22, offset: Offset(0, 7))],
    ),
    child: child,
  );
}

class WildHero extends StatelessWidget {
  const WildHero({
    super.key,
    required this.image,
    required this.child,
    this.height = 260,
    this.alignment = Alignment.center,
    this.darkBottom = true,
  });
  final String image;
  final Widget child;
  final double height;
  final Alignment alignment;
  final bool darkBottom;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(fit: StackFit.expand, children: [
      Image.asset(image, fit: BoxFit.cover, alignment: alignment),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: darkBottom
                ? [Colors.white.withValues(alpha: .05), Colors.transparent, const Color(0xB30C1C13)]
                : [Colors.white.withValues(alpha: .4), Colors.transparent],
            stops: const [0, .46, 1],
          ),
        ),
      ),
      child,
    ]),
  );
}

class WildSectionTitle extends StatelessWidget {
  const WildSectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: WildText.h2)),
    if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(color: WildColors.muted))),
  ]);
}

class WildIconDisc extends StatelessWidget {
  const WildIconDisc(this.icon, {super.key, this.background = WildColors.sage, this.foreground = WildColors.forest, this.size = 46});
  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(icon, color: foreground, size: size * .52),
  );
}

class WildPrimaryButton extends StatelessWidget {
  const WildPrimaryButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      style: FilledButton.styleFrom(
        backgroundColor: WildColors.forest,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
  );
}

class WildOutlineButton extends StatelessWidget {
  const WildOutlineButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: WildColors.forest,
        side: const BorderSide(color: WildColors.forest, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
  );
}
