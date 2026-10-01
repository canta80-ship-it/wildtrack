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
    child: Stack(fit: StackFit.expand, children: [CustomPaint(painter: WildLandscapePainter(darkBottom: darkBottom)), child]),
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

    canvas.drawRect(rect, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: darkBottom ? [Colors.transparent, Colors.transparent, const Color(0xB3152F22)] : [Colors.white.withValues(alpha: .18), Colors.transparent, Colors.white.withValues(alpha: .06)],
      stops: darkBottom ? const [0, .52, 1] : const [0, .5, 1],
    ).createShader(rect));
  }

  void _mountain(Canvas c, Size s, double y, Color color, double phase, double peak) {
    final p = Path()..moveTo(0, s.height)..lineTo(0, s.height * y);
    for (var i = 0; i <= 8; i++) {
      final x = s.width * i / 8;
      final wave = math.sin(i * 1.55 + phase) * s.height * .045;
      final sharp = i == 5 ? -s.height * (peak - y) * .22 : 0.0;
      p.lineTo(x, s.height * y + wave + sharp);
    }
    p.lineTo(s.width, s.height)..close();
    c.drawPath(p, Paint()..color = color);
  }

  void _pine(Canvas c, Offset base, double h, Paint paint) {
    c.drawRect(Rect.fromLTWH(base.dx - 1.3, base.dy - h * .48, 2.6, h * .48), Paint()..color = const Color(0xFF4F4B38));
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

enum _AnimalKind { deer, roe, fox, wolf, bear, boar, hare, mustelid, bird, raptor, owl, ungulate, generic, track }

_AnimalKind _kindFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('impronta') || n.contains('traccia')) return _AnimalKind.track;
  if (n.contains('cervo')) return _AnimalKind.deer;
  if (n.contains('capriolo')) return _AnimalKind.roe;
  if (n.contains('volpe')) return _AnimalKind.fox;
  if (n.contains('lupo')) return _AnimalKind.wolf;
  if (n.contains('orso')) return _AnimalKind.bear;
  if (n.contains('cinghiale')) return _AnimalKind.boar;
  if (n.contains('lepre') || n.contains('coniglio')) return _AnimalKind.hare;
  if (n.contains('tasso') || n.contains('martora') || n.contains('faina') || n.contains('lontra')) return _AnimalKind.mustelid;
  if (n.contains('gufo') || n.contains('civetta') || n.contains('allocco')) return _AnimalKind.owl;
  if (n.contains('poiana') || n.contains('aquila') || n.contains('falco') || n.contains('gheppio')) return _AnimalKind.raptor;
  if (n.contains('airone') || n.contains('germano') || n.contains('picchio') || n.contains('ucc') || n.contains('anatra')) return _AnimalKind.bird;
  if (n.contains('camoscio') || n.contains('stambecco') || n.contains('muflone')) return _AnimalKind.ungulate;
  return _AnimalKind.generic;
}

class WildAnimalIllustration extends StatelessWidget {
  const WildAnimalIllustration(this.name, {super.key, this.size = 96, this.light = false});
  final String name;
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final bg = light ? const Color(0x33FFFFFF) : WildColors.sageSoft;
    final kind = _kindFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bg, const Color(0xFFE9E0CB)]),
        borderRadius: BorderRadius.circular(size * .22),
      ),
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: Padding(padding: EdgeInsets.all(size * .08), child: CustomPaint(painter: _AnimalPainter(kind: kind, color: WildColors.forest, accent: WildColors.earth)))),
        Positioned(bottom: size * .10, child: Container(width: size * .56, height: size * .08, decoration: BoxDecoration(color: WildColors.forest.withValues(alpha: .10), borderRadius: BorderRadius.circular(99)))),
      ]),
    );
  }
}

class _AnimalPainter extends CustomPainter {
  const _AnimalPainter({required this.kind, required this.color, required this.accent});
  final _AnimalKind kind;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color..style = PaintingStyle.fill;
    final a = Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = s.width * .035..strokeCap = StrokeCap.round;
    final cx = s.width * .48;
    final cy = s.height * .58;

    if (kind == _AnimalKind.track) {
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy + s.height * .08), width: s.width * .26, height: s.height * .30), p);
      for (final o in [const Offset(-.18, -.19), const Offset(-.06, -.29), const Offset(.08, -.29), const Offset(.19, -.18)]) {
        c.drawCircle(Offset(cx + s.width * o.dx, cy + s.height * o.dy), s.width * .075, p);
      }
      return;
    }

    if (kind == _AnimalKind.bird || kind == _AnimalKind.raptor || kind == _AnimalKind.owl) {
      final body = Rect.fromCenter(center: Offset(cx, cy), width: s.width * .26, height: s.height * .40);
      c.drawOval(body, p);
      c.drawCircle(Offset(cx, cy - s.height * .23), s.width * .12, p);
      final wing = Path()..moveTo(cx, cy)..quadraticBezierTo(cx - s.width * .32, cy - s.height * .15, cx - s.width * .33, cy + s.height * .13)..quadraticBezierTo(cx - s.width * .12, cy + s.height * .03, cx, cy);
      c.drawPath(wing, p);
      if (kind == _AnimalKind.raptor) {
        final wing2 = Path()..moveTo(cx, cy)..quadraticBezierTo(cx + s.width * .34, cy - s.height * .16, cx + s.width * .35, cy + s.height * .12)..quadraticBezierTo(cx + s.width * .12, cy + s.height * .03, cx, cy);
        c.drawPath(wing2, p);
      }
      if (kind == _AnimalKind.owl) {
        c.drawCircle(Offset(cx - s.width * .05, cy - s.height * .24), s.width * .025, Paint()..color = WildColors.ivory);
        c.drawCircle(Offset(cx + s.width * .05, cy - s.height * .24), s.width * .025, Paint()..color = WildColors.ivory);
      }
      return;
    }

    final bodyW = kind == _AnimalKind.bear || kind == _AnimalKind.boar ? .46 : .42;
    final bodyH = kind == _AnimalKind.bear ? .30 : .23;
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: s.width * bodyW, height: s.height * bodyH), p);
    final headX = cx + s.width * .25;
    final headY = cy - s.height * .12;
    c.drawOval(Rect.fromCenter(center: Offset(headX, headY), width: s.width * .18, height: s.height * .17), p);

    final legOffsets = [-.15, .10];
    for (final dx in legOffsets) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + s.width * dx, cy + s.height * .07, s.width * .045, s.height * .25), Radius.circular(s.width * .02)), p);
    }

    if (kind == _AnimalKind.fox || kind == _AnimalKind.wolf) {
      final tail = Path()..moveTo(cx - s.width * .20, cy - s.height * .02)..quadraticBezierTo(cx - s.width * .43, cy - s.height * .14, cx - s.width * .44, cy + s.height * .07)..quadraticBezierTo(cx - s.width * .33, cy + s.height * .11, cx - s.width * .20, cy + s.height * .03)..close();
      c.drawPath(tail, p);
      final ear1 = Path()..moveTo(headX - s.width * .06, headY - s.height * .07)..lineTo(headX - s.width * .03, headY - s.height * .20)..lineTo(headX + s.width * .01, headY - s.height * .07)..close();
      final ear2 = Path()..moveTo(headX + s.width * .02, headY - s.height * .07)..lineTo(headX + s.width * .07, headY - s.height * .20)..lineTo(headX + s.width * .09, headY - s.height * .05)..close();
      c.drawPath(ear1, p); c.drawPath(ear2, p);
    }

    if (kind == _AnimalKind.hare) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(headX - s.width * .08, headY - s.height * .24, s.width * .05, s.height * .19), Radius.circular(s.width * .02)), p);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(headX + s.width * .01, headY - s.height * .25, s.width * .05, s.height * .20), Radius.circular(s.width * .02)), p);
    }

    if (kind == _AnimalKind.deer || kind == _AnimalKind.roe || kind == _AnimalKind.ungulate) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(headX - s.width * .08, headY - s.height * .06, s.width * .055, s.height * .21), Radius.circular(s.width * .02)), p);
      if (kind == _AnimalKind.deer) {
        final leftBase = Offset(headX - s.width * .04, headY - s.height * .08);
        final rightBase = Offset(headX + s.width * .04, headY - s.height * .08);
        c.drawLine(leftBase, Offset(leftBase.dx - s.width * .09, leftBase.dy - s.height * .19), a);
        c.drawLine(rightBase, Offset(rightBase.dx + s.width * .09, rightBase.dy - s.height * .19), a);
        c.drawLine(Offset(leftBase.dx - s.width * .04, leftBase.dy - s.height * .10), Offset(leftBase.dx - s.width * .10, leftBase.dy - s.height * .11), a);
        c.drawLine(Offset(rightBase.dx + s.width * .04, rightBase.dy - s.height * .10), Offset(rightBase.dx + s.width * .10, rightBase.dy - s.height * .11), a);
      } else if (kind == _AnimalKind.ungulate) {
        c.drawArc(Rect.fromCircle(center: Offset(headX - s.width * .03, headY - s.height * .09), radius: s.width * .11), math.pi * 1.05, math.pi * .75, false, a);
      }
    }

    if (kind == _AnimalKind.boar) {
      c.drawLine(Offset(headX + s.width * .05, headY + s.height * .02), Offset(headX + s.width * .15, headY + s.height * .01), a);
      c.drawLine(Offset(headX + s.width * .10, headY + s.height * .04), Offset(headX + s.width * .14, headY + s.height * .08), a);
    }

    if (kind == _AnimalKind.bear) {
      c.drawCircle(Offset(headX - s.width * .06, headY - s.height * .08), s.width * .05, p);
      c.drawCircle(Offset(headX + s.width * .05, headY - s.height * .08), s.width * .05, p);
    }

    if (kind == _AnimalKind.mustelid) {
      c.drawOval(Rect.fromCenter(center: Offset(cx - s.width * .06, cy), width: s.width * .58, height: s.height * .15), p);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimalPainter oldDelegate) => oldDelegate.kind != kind || oldDelegate.color != color;
}

class WildSectionTitle extends StatelessWidget {
  const WildSectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: WildText.h2)), if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(color: WildColors.muted)))]);
}

class WildIconDisc extends StatelessWidget {
  const WildIconDisc(this.icon, {super.key, this.background = WildColors.sage, this.foreground = WildColors.forest, this.size = 46});
  final IconData icon; final Color background; final Color foreground; final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: background, shape: BoxShape.circle), child: Icon(icon, color: foreground, size: size * .52));
}

class WildPrimaryButton extends StatelessWidget {
  const WildPrimaryButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label; final VoidCallback? onPressed; final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 58, child: FilledButton.icon(onPressed: onPressed, icon: icon == null ? const SizedBox.shrink() : Icon(icon), label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), style: FilledButton.styleFrom(backgroundColor: WildColors.forest, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)))));
}

class WildOutlineButton extends StatelessWidget {
  const WildOutlineButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label; final VoidCallback? onPressed; final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 56, child: OutlinedButton.icon(onPressed: onPressed, icon: icon == null ? const SizedBox.shrink() : Icon(icon), label: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), style: OutlinedButton.styleFrom(foregroundColor: WildColors.forest, side: const BorderSide(color: WildColors.forest, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)))));
}
