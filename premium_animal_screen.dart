import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../premium_ui.dart';
import 'premium_explore_screen.dart';
import 'species_screen.dart';
import 'species_detail_screen.dart';

class PremiumAnimalScreen extends StatelessWidget {
  const PremiumAnimalScreen(this.animal, {super.key});
  final Animal animal;

  bool get isDeer => animal.name.toLowerCase() == 'cervo';

  SpeciesDetail get detail => speciesDetails[animal.name]!;
  String get heroAsset => 'assets/approved/${detail.asset}_hero.jpg';
  String get footprintType => switch (animal.name) {
    'Volpe' || 'Lupo' || 'Sciacallo dorato' => 'canide',
    'Orso bruno' || 'Tasso' || 'Ermellino' => 'cinque_dita',
    'Marmotta' => 'roditore',
    'Germano reale' => 'palmata',
    'Picchio nero' || 'Allocco' || 'Gufo reale' || 'Barbagianni' => 'due_due',
    _ => animal.group == 'Mammiferi' ? 'zoccolo' : 'uccello',
  };
  List<(String, String)> get signs => [
    (
      'Impronta',
      animal.name == 'Marmotta'
          ? 'Zampe anteriori e posteriori diverse; valuta habitat e sequenza della pista.'
          : detail.signs.first.$1 == 'Impronta'
          ? detail.signs.first.$2
          : 'Osserva la forma del piede e documenta più orme con un riferimento metrico.',
    ),
    (
      const ['Allocco', 'Gufo reale', 'Barbagianni'].contains(animal.name)
          ? 'Borre'
          : 'Fatte',
      scatDescription(animal.name, animal.group),
    ),
    detail.signs[2],
    detail.signs[3],
  ];
  String get sizeLine => detail.size;
  String get weightLine => detail.mass;

  void showExplanation(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WildColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(body, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 16),
              WildOutlineButton(
                label: 'Fonte naturalistica',
                icon: Icons.open_in_new,
                onPressed: () => launchUrl(
                  Uri.parse(detail.source),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5ED),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(
              animal: animal,
              asset: heroAsset,
              activity: detail.activity,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(
                  height: 68,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => showExplanation(
                            context,
                            'Specie autoctona',
                            animal.description,
                          ),
                          child: _InfoCard(
                            icon: Icons.eco_outlined,
                            title: 'Specie autoctona',
                            body: animal.description,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: InkWell(
                          onTap: () => showExplanation(
                            context,
                            'Stato di conservazione',
                            detail.badge == null
                                ? animal.ecology
                                : detail.status + '\n\n' + animal.ecology,
                          ),
                          child: _InfoCard(
                            icon: Icons.groups_outlined,
                            title: 'Stato di conservazione',
                            body: detail.badge == null
                                ? animal.ecology
                                : detail.status,
                            badge: detail.badge,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.straighten,
                          title: 'Dimensioni',
                          body: '$sizeLine\n$weightLine',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionTitle(
                  title: 'Habitat',
                  action: 'Vedi sulla mappa',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PremiumExploreScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _HabitatCard(
                  animal: animal,
                  asset: isDeer ? 'assets/approved/habitat.jpg' : heroAsset,
                  tags: detail.tags,
                ),
                const SizedBox(height: 12),
                _SectionTitle(
                  title: 'Segni e impronte',
                  action: 'Vedi tutti',
                  onTap: () => showExplanation(
                    context,
                    'Segni e impronte · ${animal.name}',
                    signs.map((s) => '${s.$1}\n${s.$2}').join('\n\n'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < signs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => showExplanation(
                            context,
                            signs[i].$1,
                            signs[i].$2,
                          ),
                          child: _SignCard(
                            illustration: i == 0 && !isDeer
                                ? Center(
                                    child: CustomPaint(
                                      size: const Size(54, 66),
                                      painter: TrackPainter(
                                        footprintType,
                                        WildColors.earth,
                                        animal.name == 'Cinghiale',
                                      ),
                                    ),
                                  )
                                : null,
                            title: signs[i].$1,
                            body: signs[i].$2,
                            icon: signIcon(signs[i].$1),
                            asset: isDeer
                                ? [
                                    'assets/approved/impronta.jpg',
                                    'assets/approved/fatte.jpg',
                                    'assets/approved/sfregamenti.jpg',
                                    'assets/approved/palchi.jpg',
                                  ][i]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                const _SectionTitle(title: 'Periodo migliore'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _Season(
                          icon: [
                            Icons.local_florist_outlined,
                            Icons.wb_sunny_outlined,
                            Icons.eco_outlined,
                            Icons.ac_unit,
                          ][i],
                          label: [
                            'Primavera',
                            'Estate',
                            'Autunno',
                            'Inverno',
                          ][i],
                          months: [
                            'Mar – Mag',
                            'Giu – Ago',
                            'Set – Nov',
                            'Dic – Feb',
                          ][i],
                          level: null,
                          levelText: detail.seasons[i],
                          best:
                              (isDeer && i == 2) ||
                              (animal.name == 'Marmotta' && i == 1),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Indicazioni stagionali: la possibilità di osservazione dipende dal luogo e dalle condizioni.',
                  style: TextStyle(fontSize: 10, color: WildColors.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Panel(
                        title: 'Consigli fotografici',
                        icon: Icons.camera_alt_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 102,
                                width: double.infinity,
                                child: Image.asset(
                                  isDeer
                                      ? 'assets/approved/photo_tip.jpg'
                                      : heroAsset,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            _Tip(detail.activity),
                            _Tip(detail.photo),
                            const _Tip(
                              'Mantieni distanza e usa un teleobiettivo.',
                            ),
                            const _Tip(
                              'Cerca punti riparati e muoviti con calma e silenzio.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Panel(
                        title: 'Versi',
                        icon: Icons.volume_up_outlined,
                        child: animal.audio == null
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Registrazione verificata non disponibile per questa specie.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: WildColors.muted,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AudioTile(animal),
                                  const SizedBox(height: 8),
                                  Text(
                                    animal.behaviour,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.35,
                                      color: WildColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                if (detail.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      detail.note,
                      style: const TextStyle(
                        fontSize: 11,
                        color: WildColors.muted,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                _Panel(
                  title: 'Ecologia e rispetto',
                  icon: Icons.eco_outlined,
                  child: Text(
                    animal.ecology,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: WildColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                WildOutlineButton(
                  label: 'Fonte naturalistica',
                  icon: Icons.open_in_new,
                  onPressed: () => launchUrl(
                    Uri.parse(detail.source),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

IconData signIcon(String title) {
  final text = title.toLowerCase();
  if (text.contains('ulul') ||
      text.contains('richiam') ||
      text.contains('vers'))
    return Icons.volume_up_outlined;
  if (text.contains('pista') || text.contains('impront'))
    return Icons.pets_outlined;
  if (text.contains('pen') || text.contains('pium') || text.contains('peli'))
    return Icons.air;
  if (text.contains('tan') || text.contains('nido') || text.contains('rifug'))
    return Icons.home_outlined;
  if (text.contains('sfreg') ||
      text.contains('tron') ||
      text.contains('scorte'))
    return Icons.park_outlined;
  if (text.contains('rest') || text.contains('aliment'))
    return Icons.restaurant_outlined;
  if (text.contains('vol')) return Icons.flight;
  if (text.contains('fatte') || text.contains('borre'))
    return Icons.blur_circular;
  return Icons.search;
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.animal,
    required this.asset,
    required this.activity,
  });
  final Animal animal;
  final String asset;
  final String activity;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 265,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          filterQuality: FilterQuality.high,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x12000000), Color(0x08000000), Color(0xB8102619)],
              stops: [0, .5, 1],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const WildLogo(compact: true),
                    const Spacer(),
                    const _CircleButton(icon: Icons.favorite_border),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    animal.name,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 38,
                      height: .92,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  animal.latin,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    fontSize: 21,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxWidth: 330),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE51A4A34),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFF8DE67D),
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: RichText(
                          maxLines: 2,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'sans-serif',
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.12,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Attività: ',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const TextSpan(
                                text: 'ORARI\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8DE67D),
                                ),
                              ),
                              TextSpan(
                                text: activity,
                                style: const TextStyle(fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .95),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: WildColors.forest, size: 21),
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.badge,
  });
  final IconData icon;
  final String title;
  final String body;
  final String? badge;

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F6EE),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x0D000000)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: WildColors.forest, size: 15),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 8.5,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Text(
            badge == null ? body : '$badge · $body',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              height: 1.05,
              color: WildColors.muted,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 17,
            height: 1,
            fontWeight: FontWeight.w800,
            color: WildColors.ink,
            letterSpacing: -.5,
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onTap,
          child: Row(
            children: [
              Text(
                action!,
                style: const TextStyle(fontSize: 12, color: WildColors.muted),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: WildColors.muted,
              ),
            ],
          ),
        ),
    ],
  );
}

class _HabitatCard extends StatelessWidget {
  const _HabitatCard({
    required this.animal,
    required this.asset,
    required this.tags,
  });
  final List<String> tags;
  final Animal animal;
  final String asset;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x0D000000)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: 145,
                height: 64,
                child: Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                animal.habitat,

                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  color: WildColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in tags)
              _Tag(
                icon:
                    tag.contains('acq') ||
                        tag.contains('umid') ||
                        tag.contains('Palud') ||
                        tag.contains('Cann') ||
                        tag.contains('Fiumi')
                    ? Icons.water_drop_outlined
                    : tag.contains('Rocc') ||
                          tag.contains('mont') ||
                          tag.contains('quota')
                    ? Icons.landscape
                    : Icons.park,
                label: tag,
              ),
          ],
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF1E5),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: WildColors.forest),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: WildColors.ink),
        ),
      ],
    ),
  );
}

class _SignCard extends StatelessWidget {
  const _SignCard({
    required this.title,
    required this.body,
    required this.icon,
    this.asset,
    this.illustration,
  });
  final Widget? illustration;
  final String title;
  final String body;
  final IconData icon;
  final String? asset;

  @override
  Widget build(BuildContext context) => Container(
    height: 158,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFFAF5EA),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 62,
            width: double.infinity,
            child: asset == null
                ? Container(
                    color: const Color(0xFFF1E8D8),
                    child:
                        illustration ??
                        Icon(icon, size: 40, color: WildColors.earth),
                  )
                : Image.asset(
                    asset!,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Text(
            body.split(RegExp(r'(?<=[.!?])\s')).first,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              height: 1.15,
              color: WildColors.muted,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Season extends StatelessWidget {
  const _Season({
    required this.icon,
    required this.label,
    required this.months,
    required this.level,
    required this.levelText,
    this.best = false,
  });
  final IconData icon;
  final String label;
  final String months;
  final double? level;
  final String levelText;
  final bool best;

  @override
  Widget build(BuildContext context) => Container(
    height: 86,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: best ? const Color(0xFFF7E6C9) : const Color(0xFFFFFEFA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x0D000000)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: best ? const Color(0xFFC87925) : WildColors.forest,
              size: 19,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            months,
            style: const TextStyle(fontSize: 8.5, color: WildColors.muted),
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Text(
            levelText,
            style: TextStyle(
              fontSize: 8.5,
              color: best ? const Color(0xFF9A5421) : WildColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 3),
        if (level != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: level ?? 0,
              minHeight: 5,
              color: best ? WildColors.forest : const Color(0xFFE7B348),
              backgroundColor: const Color(0xFFE6E3D9),
            ),
          ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x0D000000)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: WildColors.forest, size: 22),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        child,
      ],
    ),
  );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 14, color: Color(0xFF65A35A)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, height: 1.2),
          ),
        ),
      ],
    ),
  );
}
