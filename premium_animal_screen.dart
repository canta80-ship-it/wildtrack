import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'species_screen.dart';
import 'premium_explore_screen.dart';
import 'book_widget.dart';
import '../premium_ui.dart';

class PremiumAnimalScreen extends StatelessWidget {
  const PremiumAnimalScreen(this.animal, {super.key});
  final Animal animal;

  bool get isDeer => animal.name == 'Cervo';

  String get sizeLine => switch (animal.name) {
        'Cervo' => '180–250 cm',
        'Capriolo' => '95–135 cm',
        'Lupo' => '100–140 cm',
        'Volpe' => '60–90 cm',
        _ => 'Varia per sesso ed età',
      };

  String get weightLine => switch (animal.name) {
        'Cervo' => '120–250 kg',
        'Capriolo' => '15–35 kg',
        'Lupo' => '25–45 kg',
        'Volpe' => '4–10 kg',
        _ => animal.group,
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WildColors.ivory,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BookHero(
                asset: wildBookAssetFor(animal.name),
                height: 430,
                alignment: Alignment.center,
                bottomStrength: .72,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _RoundButton(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.pop(context)),
                            const Spacer(),
                            const WildLogo(compact: true, light: true),
                            const Spacer(),
                            const _RoundButton(icon: Icons.favorite_border),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          animal.name,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 52,
                            height: .9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          animal.latin,
                          style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 21, color: Colors.white),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: const Color(0xE6173F2B), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bar_chart_rounded, color: Color(0xFF8CDF78)),
                              const SizedBox(width: 7),
                              const Text('Attività: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              const Text('ALTA', style: TextStyle(color: Color(0xFF8CDF78), fontWeight: FontWeight.w900)),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  isDeer ? 'più attivo all’alba e al tramonto' : 'osserva nelle ore più tranquille',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.eco_outlined,
                          title: 'Specie autoctona',
                          body: isDeer ? 'Presente in gran parte delle Alpi e dell’Appennino.' : animal.group,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: _InfoCard(
                          icon: Icons.shield_outlined,
                          title: 'Stato di conservazione',
                          body: 'Consulta la fonte naturalistica',
                          badge: 'LC',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.straighten,
                          title: 'Dimensioni',
                          body: '$sizeLine\n$weightLine',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  BookSectionTitle(
                    'Habitat',
                    action: 'Vedi sulla mappa',
                    onAction: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PremiumExploreScreen(species: animal.name))),
                  ),
                  const SizedBox(height: 8),
                  _HabitatCard(animal: animal),
                  const SizedBox(height: 20),
                  const BookSectionTitle('Segni e impronte', action: 'Vedi tutti'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(child: _SignCard(icon: Icons.pets_outlined, title: 'Impronta', body: 'Forma, dita e dimensioni aiutano a leggere la traccia.')),
                      SizedBox(width: 7),
                      Expanded(child: _SignCard(icon: Icons.blur_circular, title: 'Fatte', body: 'Osserva forma e contesto senza toccare o raccogliere.')),
                      SizedBox(width: 7),
                      Expanded(child: _SignCard(icon: Icons.park_outlined, title: 'Sfregamenti', body: 'Segni su tronchi, corteccia e vegetazione.')),
                      SizedBox(width: 7),
                      Expanded(child: _SignCard(icon: Icons.account_tree_outlined, title: 'Altri segni', body: 'Peli, piume, palchi, piste e resti alimentari.')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(cardTheme: CardThemeData(color: const Color(0xFFFFFEFA), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)))),
                    child: TrackCard(animal),
                  ),
                  const SizedBox(height: 20),
                  const BookSectionTitle('Periodo migliore'),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(child: _Season(icon: Icons.local_florist_outlined, label: 'Primavera', months: 'Mar – Mag', level: .45, levelText: 'Medio')),
                      SizedBox(width: 6),
                      Expanded(child: _Season(icon: Icons.wb_sunny_outlined, label: 'Estate', months: 'Giu – Ago', level: .5, levelText: 'Medio')),
                      SizedBox(width: 6),
                      Expanded(child: _Season(icon: Icons.eco_outlined, label: 'Autunno', months: 'Set – Nov', level: .9, levelText: 'Molto alto', hot: true)),
                      SizedBox(width: 6),
                      Expanded(child: _Season(icon: Icons.ac_unit, label: 'Inverno', months: 'Dic – Feb', level: .25, levelText: 'Basso')),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(height: 105, width: double.infinity, child: BookPhoto(asset: wildBookAssetFor(animal.name))),
                              ),
                              const SizedBox(height: 9),
                              _Tip(animal.behaviour),
                              const _Tip('Mantieni distanza e usa un teleobiettivo quando possibile.'),
                              const _Tip('Muoviti con calma e in silenzio; niente richiami o inseguimenti.'),
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
                              ? const Text('Registrazione verificata non disponibile per questa specie.', style: TextStyle(fontSize: 11, color: WildColors.muted))
                              : AudioTile(animal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Panel(title: 'Ecologia e rispetto', icon: Icons.eco, child: Text(animal.ecology, style: const TextStyle(height: 1.35))),
                  const SizedBox(height: 12),
                  WildOutlineButton(
                    label: 'Fonte naturalistica',
                    icon: Icons.open_in_new,
                    onPressed: () => launchUrl(Uri.parse(animal.source), mode: LaunchMode.externalApplication),
                  ),
                ]),
              ),
            ),
          ],
        ),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .94),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 46, height: 46, child: Icon(icon, color: WildColors.forest, size: 21)),
        ),
      );
}

class _HabitatCard extends StatelessWidget {
  const _HabitatCard({required this.animal});
  final Animal animal;

  @override
  Widget build(BuildContext context) => BookCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(width: 145, height: 98, child: BookPhoto(asset: wildBookAssetFor(animal.name))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(animal.habitat, style: const TextStyle(fontSize: 12, height: 1.35, color: WildColors.muted))),
              ],
            ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Tag(icon: Icons.park, label: 'Foreste'),
                _Tag(icon: Icons.landscape, label: 'Aree montane'),
                _Tag(icon: Icons.grass, label: 'Radure e pascoli'),
                _Tag(icon: Icons.water_drop_outlined, label: 'Acqua e zone umide'),
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(11)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: WildColors.forest), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 10, color: WildColors.ink))]),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.body, this.badge});
  final IconData icon;
  final String title;
  final String body;
  final String? badge;

  @override
  Widget build(BuildContext context) => BookCard(
        padding: const EdgeInsets.all(11),
        tint: const Color(0xFFFBF9F2),
        child: SizedBox(
          height: 106,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(icon, color: WildColors.forest, size: 23), const Spacer(), if (badge != null) Container(padding: const EdgeInsets.all(7), decoration: const BoxDecoration(color: WildColors.forest, shape: BoxShape.circle), child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))]),
              const Spacer(),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, height: 1.2, color: WildColors.muted)),
            ],
          ),
        ),
      );
}

class _SignCard extends StatelessWidget {
  const _SignCard({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => BookCard(
        padding: const EdgeInsets.all(9),
        tint: const Color(0xFFF8F1E5),
        child: SizedBox(
          height: 135,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Center(child: Icon(icon, size: 44, color: WildColors.earth))),
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, height: 1.2, color: WildColors.muted)),
            ],
          ),
        ),
      );
}

class _Season extends StatelessWidget {
  const _Season({required this.icon, required this.label, required this.months, required this.level, required this.levelText, this.hot = false});
  final IconData icon;
  final String label;
  final String months;
  final double level;
  final String levelText;
  final bool hot;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: hot ? const Color(0xFFF7E7CC) : const Color(0xFFFFFEFA), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0x10000000))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: hot ? WildColors.amber : WildColors.forest, size: 20), const SizedBox(width: 5), Expanded(child: Text(label, maxLines: 1, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)))]),
            const SizedBox(height: 3),
            Text(months, style: const TextStyle(fontSize: 8.5, color: WildColors.muted)),
            const SizedBox(height: 7),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: level, minHeight: 5, color: hot ? WildColors.forest : WildColors.amber, backgroundColor: WildColors.cream)),
            const SizedBox(height: 4),
            Text(levelText, style: TextStyle(fontSize: 8.5, color: hot ? WildColors.earth : WildColors.muted)),
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
  Widget build(BuildContext context) => BookCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: WildColors.forest), const SizedBox(width: 6), Expanded(child: Text(title, style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800, fontSize: 17)))]),
            const SizedBox(height: 10),
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
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, size: 15, color: Color(0xFF65A35A)),
            const SizedBox(width: 5),
            Expanded(child: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, height: 1.25))),
          ],
        ),
      );
}
