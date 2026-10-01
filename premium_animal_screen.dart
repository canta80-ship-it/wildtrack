import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../premium_ui.dart';
import 'premium_explore_screen.dart';
import 'species_screen.dart';

class PremiumAnimalScreen extends StatelessWidget {
  const PremiumAnimalScreen(this.animal, {super.key});
  final Animal animal;

  bool get isDeer => animal.name.toLowerCase() == 'cervo';

  String get heroAsset {
    final n = animal.name.toLowerCase();
    if (n == 'cervo') return 'assets/approved/cervo_hero.jpg';
    if (n.contains('lupo') || n.contains('volpe') || n.contains('sciacallo'))
      return 'intro_lupo.jpg';
    if (n.contains('gufo') ||
        n.contains('poiana') ||
        n.contains('aquila') ||
        n.contains('falco') ||
        n.contains('civetta') ||
        n.contains('allocco'))
      return 'intro_gufo.jpg';
    if (n.contains('marmotta') || n.contains('tasso') || n.contains('lepre'))
      return 'intro_marmotta.jpg';
    return 'intro_cervo.jpg';
  }

  String get sizeLine => switch (animal.name) {
    'Cervo' => '180–250 cm',
    'Capriolo' => '95–135 cm',
    'Lupo' => '100–140 cm',
    'Volpe' => '60–90 cm',
    _ => 'Varia per sesso/età',
  };

  String get weightLine => switch (animal.name) {
    'Cervo' => '120–250 kg',
    'Capriolo' => '15–35 kg',
    'Lupo' => '25–45 kg',
    'Volpe' => '4–10 kg',
    _ => animal.group,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5ED),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(animal: animal, asset: heroAsset, isDeer: isDeer),
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
                        child: _InfoCard(
                          icon: Icons.eco_outlined,
                          title: 'Specie autoctona',
                          body: isDeer
                              ? 'Presente in gran parte delle Alpi e dell’Appennino.'
                              : animal.group,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: _InfoCard(
                          icon: Icons.groups_outlined,
                          title: 'Stato di conservazione',
                          body: 'Rischio minimo',
                          badge: 'LC',
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
                ),
                const SizedBox(height: 12),
                const _SectionTitle(
                  title: 'Segni e impronte',
                  action: 'Vedi tutti',
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SignCard(
                        title: 'Impronta',
                        body: isDeer
                            ? 'Zoccolo grande e ovale, con due unghioni ben evidenti.'
                            : 'Osserva forma, dita e dimensioni.',
                        asset: isDeer ? 'assets/approved/impronta.jpg' : null,
                        icon: Icons.pets_outlined,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _SignCard(
                        title: 'Fatte',
                        body: isDeer
                            ? 'Escrementi ovali e scuri, spesso in piccoli ammassi.'
                            : 'Forma e contesto aiutano il riconoscimento.',
                        asset: isDeer ? 'assets/approved/fatte.jpg' : null,
                        icon: Icons.blur_circular,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _SignCard(
                        title: 'Sfregamenti',
                        body: isDeer
                            ? 'Tracce sui tronchi degli alberi, soprattutto nel periodo degli amori.'
                            : 'Segni su tronchi e vegetazione.',
                        asset: isDeer
                            ? 'assets/approved/sfregamenti.jpg'
                            : null,
                        icon: Icons.park_outlined,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _SignCard(
                        title: isDeer ? 'Palchi' : 'Altri segni',
                        body: isDeer
                            ? 'Cadono tra febbraio e aprile, cercali a terra nei boschi.'
                            : 'Peli, piume, piste e resti alimentari.',
                        asset: isDeer ? 'assets/approved/palchi.jpg' : null,
                        icon: Icons.account_tree_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _SectionTitle(title: 'Periodo migliore'),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(
                      child: _Season(
                        icon: Icons.local_florist_outlined,
                        label: 'Primavera',
                        months: 'Mar – Mag',
                        level: .42,
                        levelText: 'Medio',
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: _Season(
                        icon: Icons.wb_sunny_outlined,
                        label: 'Estate',
                        months: 'Giu – Ago',
                        level: .48,
                        levelText: 'Medio',
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: _Season(
                        icon: Icons.eco_outlined,
                        label: 'Autunno',
                        months: 'Set – Nov',
                        level: .92,
                        levelText: 'Molto alto',
                        best: true,
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: _Season(
                        icon: Icons.ac_unit,
                        label: 'Inverno',
                        months: 'Dic – Feb',
                        level: .24,
                        levelText: 'Basso',
                      ),
                    ),
                  ],
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
                            _Tip(
                              isDeer
                                  ? 'Momenti migliori all’alba e al tramonto.'
                                  : animal.behaviour,
                            ),
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
                            : AudioTile(animal),
                      ),
                    ),
                  ],
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
                    Uri.parse(animal.source),
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.animal,
    required this.asset,
    required this.isDeer,
  });
  final Animal animal;
  final String asset;
  final bool isDeer;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 265,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: isDeer ? Alignment.centerRight : Alignment.center,
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
                Text(
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
                                text: 'ALTA\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8DE67D),
                                ),
                              ),
                              TextSpan(
                                text: isDeer
                                    ? 'più attivo all’alba e al tramonto'
                                    : 'osserva nelle ore più tranquille',
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: WildColors.forest, size: 20),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
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
            fontSize: 27,
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
  const _HabitatCard({required this.animal, required this.asset});
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
                height: 92,
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
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
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
        const Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Tag(icon: Icons.park, label: 'Foreste'),
            _Tag(icon: Icons.landscape, label: 'Aree montane'),
            _Tag(icon: Icons.grass, label: 'Radure e pascoli'),
            _Tag(
              icon: Icons.water_drop_outlined,
              label: 'Vicino a corsi d’acqua',
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
  });
  final String title;
  final String body;
  final IconData icon;
  final String? asset;

  @override
  Widget build(BuildContext context) => Container(
    height: 170,
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
            height: 82,
            width: double.infinity,
            child: asset == null
                ? Container(
                    color: const Color(0xFFF1E8D8),
                    child: Icon(icon, size: 40, color: WildColors.earth),
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
            body,
            maxLines: 4,
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
  final double level;
  final String levelText;
  final bool best;

  @override
  Widget build(BuildContext context) => Container(
    height: 94,
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
        Text(
          months,
          style: const TextStyle(fontSize: 8.5, color: WildColors.muted),
        ),
        const Spacer(),
        Text(
          levelText,
          style: TextStyle(
            fontSize: 8.5,
            color: best ? const Color(0xFF9A5421) : WildColors.muted,
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: level,
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
