import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WildColors {
  static const forest = Color(0xFF124D36);
  static const forest2 = Color(0xFF225B40);
  static const sage = Color(0xFFDCE8D8);
  static const sageSoft = Color(0xFFEEF3E9);
  static const ivory = Color(0xFFF8F6EF);
  static const cream = Color(0xFFF1EEE4);
  static const sand = Color(0xFFEADCC8);
  static const earth = Color(0xFF8A633A);
  static const ink = Color(0xFF16251B);
  static const muted = Color(0xFF4D5E50);
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
    final color = WildColors.forest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: (light ? Colors.white : WildColors.ivory).withValues(alpha: .96), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 8)]),
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      ],
    ),
    );
  }
}

class WildGlass extends StatelessWidget {
  const WildGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
  });
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
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 22,
          offset: Offset(0, 7),
        ),
      ],
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
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/approved/access_land2.jpg',
          fit: BoxFit.cover,
          alignment: alignment,
          filterQuality: FilterQuality.high,
        ),
        if (darkBottom)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x70152F22)],
              ),
            ),
          ),
        child,
      ],
    ),
  );
}

class WildLandscape extends StatelessWidget {
  const WildLandscape({
    super.key,
    this.height = 220,
    this.darkBottom = false,
    this.animal,
  });
  final double height;
  final bool darkBottom;
  final String? animal;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/approved/access_land2.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        if (animal != null)
          Positioned(
            right: 18,
            bottom: 12,
            child: WildAnimalIllustration(
              animal!,
              size: height * .46,
              light: true,
            ),
          ),
      ],
    ),
  );
}

enum _AnimalKind {
  deer,
  roe,
  fox,
  wolf,
  bear,
  boar,
  hare,
  mustelid,
  bird,
  raptor,
  owl,
  ungulate,
  generic,
  track,
}

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
  if (n.contains('tasso') ||
      n.contains('martora') ||
      n.contains('faina') ||
      n.contains('lontra'))
    return _AnimalKind.mustelid;
  if (n.contains('gufo') || n.contains('civetta') || n.contains('allocco'))
    return _AnimalKind.owl;
  if (n.contains('poiana') ||
      n.contains('aquila') ||
      n.contains('falco') ||
      n.contains('gheppio'))
    return _AnimalKind.raptor;
  if (n.contains('airone') ||
      n.contains('germano') ||
      n.contains('picchio') ||
      n.contains('ucc') ||
      n.contains('anatra'))
    return _AnimalKind.bird;
  if (n.contains('camoscio') ||
      n.contains('stambecco') ||
      n.contains('muflone'))
    return _AnimalKind.ungulate;
  return _AnimalKind.generic;
}

class WildAnimalIllustration extends StatelessWidget {
  const WildAnimalIllustration(
    this.name, {
    super.key,
    this.size = 96,
    this.light = false,
  });
  final String name;
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final n = name.toLowerCase();
    final asset = n.contains('cervo')
        ? 'cervo_thumb.jpg'
        : n.contains('capriolo')
        ? 'capriolo_thumb.jpg'
        : n.contains('volpe')
        ? 'volpe_thumb.jpg'
        : n.contains('poiana')
        ? 'poiana_thumb.jpg'
        : null;
    const otherAssets = <String, String>{
      'camoscio alpino': 'camoscio',
      'stambecco': 'stambecco',
      'cinghiale': 'cinghiale',
      'aquila reale': 'aquila',
      'grifone': 'grifone',
      'allocco': 'allocco',
      'picchio nero': 'picchio',
      'airone cenerino': 'airone',
      'germano reale': 'germano',
      'falco di palude': 'falco',
      'orso bruno': 'orso',
      'lupo': 'lupo',
      'sciacallo dorato': 'sciacallo',
      'marmotta': 'marmotta',
      'ermellino': 'ermellino',
      'tasso': 'tasso',
      'gracchio alpino': 'gracchio',
      'gufo reale': 'gufo',
      'barbagianni': 'barbagianni',
      'ghiandaia': 'ghiandaia',
    };
    const newAssets = <String,String>{'lince':'lince','tritone':'tritone','rospo':'rospo','salamandra':'salamandra','lepre':'lepre','scoiattolo':'scoiattolo','upupa':'upupa','gheppio':'gheppio','assiolo':'assiolo','nibbio reale':'nibbio_reale','nibbio bruno':'nibbio_bruno'};
    final imageAsset =
        newAssets[n] != null ? '${newAssets[n]}_hero.jpg' : asset ?? (otherAssets[n] == null ? null : '${otherAssets[n]}_hero.jpg');
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: imageAsset != null
            ? Image.asset(
                '${newAssets[n] != null ? 'assets/radar_species' : 'assets/approved'}/$imageAsset',
                fit: asset != null || newAssets[n] != null ? BoxFit.contain : BoxFit.cover,
                alignment: Alignment.centerRight,
                filterQuality: FilterQuality.high,
              )
            : Semantics(
                label: name,
                child: ColoredBox(
                  color: WildColors.sageSoft,
                  child: Icon(
                    _kindFor(name) == _AnimalKind.bird ||
                            _kindFor(name) == _AnimalKind.raptor ||
                            _kindFor(name) == _AnimalKind.owl
                        ? Icons.flight
                        : CupertinoIcons.paw,
                    color: WildColors.forest,
                    size: size * .45,
                  ),
                ),
              ),
      ),
    );
  }
}

class WildSectionTitle extends StatelessWidget {
  const WildSectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: WildText.h2)),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(action!, style: const TextStyle(color: WildColors.muted)),
        ),
    ],
  );
}

class WildIconDisc extends StatelessWidget {
  const WildIconDisc(
    this.icon, {
    super.key,
    this.background = WildColors.sage,
    this.foreground = WildColors.forest,
    this.size = 46,
  });
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
  const WildPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
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
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: WildColors.forest,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
  );
}

class WildOutlineButton extends StatelessWidget {
  const WildOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
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
      label: Text(
        label,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: WildColors.forest,
        side: const BorderSide(color: WildColors.forest, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
  );
}

class WildIcons {
  WildIcons._();
  static const binoculars = IconData(0xe900, fontFamily: 'WildTrackIcons');
}

