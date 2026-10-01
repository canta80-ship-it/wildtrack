import 'dart:math' as math;
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
  static const display = TextStyle(fontFamily: 'serif', fontSize: 36, height: .98, fontWeight: FontWeight.w700, color: WildColors.ink, letterSpacing: -1.2);
  static const h1 = TextStyle(fontFamily: 'serif', fontSize: 28, height: 1, fontWeight: FontWeight.w700, color: WildColors.ink, letterSpacing: -.7);
  static const h2 = TextStyle(fontFamily: 'serif', fontSize: 22, height: 1.05, fontWeight: FontWeight.w700, color: WildColors.ink, letterSpacing: -.35);
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
      Text('WildTrack', style: TextStyle(fontFamily: 'serif', color: color, fontWeight: FontWeight.w700, fontSize: compact ? 23 : 34, letterSpacing: -.8)),
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
      color: color ?? Colors.white.withValues(alpha: .93),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .72)),
      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 22, offset: Offset(0, 7))],
    ),
    child: child,
  );
}

/// Canonical WildTrack hero. The [image] parameter is intentionally retained for
/// source compatibility but is no longer rendered. All decorative heroes are
/// illustrated so the visual language matches the approved mockups.
class WildHero extends StatelessWidget {
  const WildHero({super.key, required this.image, required this.child, this.height = 260, this.alignment = Alignment.center, this.darkBottom = true});
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
      CustomPaint(painter: WildLandscapePainter(darkBottom: darkBottom)),
      child,
    ]),
  );
}

class WildLandscape extends StatelessWidget {
  const WildLandscape({super.key, this.height = 220, this.darkBottom = false, this.animal});
  final double height;
  final bool darkBottom;
  final String? animal;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: WildLandscapePainter(darkBottom: darkBottom))),
      if (animal != null) Positioned(right: 18, bottom: 12, child: WildAnimalIllustration(animal!, size: height * .46, light: true)),
    ]),
  );
}

class WildLandscapePainter extends CustomPainter {
  const WildLandscapePainter({this.darkBottom = false});
  final bool darkBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF5DDAD), Color(0xFFD5E0D3), Color(0xFF70836C), Color(0xFF294A38)],
      stops: [0, .34, .66, 1],
    ).createShader(rect));

    final sun = Offset(size.width * .82, size.height * .18);
    canvas.drawCircle(sun, size.width * .055, Paint()..color = const Color(0xFFFFE4A0).withValues(alpha: .88));

    _mountain(canvas, size, .40, const Color(0xFFB8BEAD), .18, .64);
    _mountain(canvas, size, .55, const Color(0xFF88958A), .10, .72);
    _mountain(canvas, size, .70, const Color(0xFF5C725F), .06, .80);

    final tree = Paint()..color = const Color(0xFF213F2E).withValues(alpha: .94);
    for (var i = 0; i < 13; i++) {
      final x = size.width * (i / 12) + (i.isEven ? -8 : 6);
      final h = size.height * (.15 + (i % 4) * .035);
      _pine(canvas, Offset(x, size.height * .98), h, tree);
    }

    if (darkBottom) {
      canvas.drawRect(rect, Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.transparent, const Color(0xB3152F22)],
        stops: const [0, .52, 1],
      ).createShader(rect));
    } else {
      canvas.drawRect(rect, Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: .18), Colors.transparent, Colors.white.withValues(alpha: .06)],
      ).createShader(rect));
    }
  }

  void _mountain(Canvas c, Size s, double y, Color color, double phase, double peak) {
    final p = Path()..moveTo(0, s.height);
    p.lineTo(0, s.height * y);
    for (var i = 0; i <= 8; i++) {
      final x = s.width * i / 8;
      final wave = math.sin(i * 1.55 + phase) * s.height * .045;
      final sharp = i == 5 ? -s.height * (peak - y) * .22 : 0.0;
      p.lineTo(x, s.height * y + wave + sharp);
    }
    p.lineTo(s.width, s.height);
    p.close();
    c.drawPath(p, Paint()..color = color);
  }

  void _pine(Canvas c, Offset base, double h, Paint paint) {
    final trunk = Paint()..color = const Color(0xFF4F4B38);
    c.drawRect(Rect.fromLTWH(base.dx - 1.3, base.dy - h * .48, 2.6, h * .48), trunk);
    for (var i = 0; i < 4; i++) {
      final yy = base.dy - h * (.28 + i * .17);
      final w = h * (.25 - i * .035);
      final p = Path()..moveTo(base.dx, yy - h * .28)..lineTo(base.dx - w, yy + h * .06)..lineTo(base.dx + w, yy + h * .06)..close();
      c.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WildLandscapePainter oldDelegate) => oldDelegate.darkBottom != darkBottom;
}

class WildAnimalIllustration extends StatelessWidget {
  const WildAnimalIllustration(this.name, {super.key, this.size = 96, this.light = false});
  final String name;
  final double size;
  final bool light;

  IconData _icon() {
    final n = name.toLowerCase();
    if (n.contains('ucc') || n.contains('gufo') || n.contains('poiana') || n.contains('airone')) return Icons.flutter_dash;
    if (n.contains('impronta') || n.contains('traccia')) return Icons.pets;
    return Icons.pets;
  }

  @override
  Widget build(BuildContext context) {
    final bg = light ? const Color(0x33FFFFFF) : WildColors.sageSoft;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bg, const Color(0xFFE9E0CB)]),
        borderRadius: BorderRadius.circular(size * .22),
      ),
      child: Stack(alignment: Alignment.center, children: [
        Icon(_icon(), size: size * .50, color: WildColors.forest),
        Positioned(bottom: size * .10, child: Container(width: size * .52, height: size * .10, decoration: BoxDecoration(color: WildColors.forest.withValues(alpha: .10), borderRadius: BorderRadius.circular(99)))),
      ]),
    );
  }
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
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: background, shape: BoxShape.circle), child: Icon(icon, color: foreground, size: size * .52));
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
      style: FilledButton.styleFrom(backgroundColor: WildColors.forest, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
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
      style: OutlinedButton.styleFrom(foregroundColor: WildColors.forest, side: const BorderSide(color: WildColors.forest, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    ),
  );
}
