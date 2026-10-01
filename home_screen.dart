import 'package:flutter/material.dart';

import 'exploration_screen.dart';
import 'map_screen.dart';
import 'record_screen.dart';
import 'sightings_screen.dart';
import 'species_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _activity() {
    final h = DateTime.now().hour;
    if (h <= 8 || h >= 17) return 'ALTA';
    if (h <= 11 || h >= 15) return 'MEDIA';
    return 'BASSA';
  }

  Color _activityColor(BuildContext context) {
    switch (_activity()) {
      case 'ALTA':
        return const Color(0xFF28563C);
      case 'MEDIA':
        return const Color(0xFF9A6B34);
      default:
        return const Color(0xFF6E756B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF254D38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.pets, color: Color(0xFFF8F6EF)),
              ),
              const SizedBox(width: 10),
              const Text('WildTrack', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, letterSpacing: -.7)),
              const Spacer(),
              IconButton(
                tooltip: 'Impostazioni',
                onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
                icon: const Icon(Icons.settings_outlined),
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF254D38), Color(0xFF678060)],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Buongiorno', style: TextStyle(color: Color(0xFFDDE8DA), fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Pronto a esplorare?', style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Pill(icon: Icons.eco_outlined, label: 'Attività fauna: $activity', color: _activityColor(context)),
                  const _Pill(icon: Icons.wb_twilight_outlined, label: 'Alba e tramonto consigliati', color: Color(0xFF6A5942)),
                ]),
              ]),
            ),
            const SizedBox(height: 22),
            const Text('Azioni rapide', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ActionCard(icon: Icons.travel_explore, title: 'Esplora zona', subtitle: 'Mappa, sentieri e fauna', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ExplorationScreen())))),
              const SizedBox(width: 10),
              Expanded(child: _ActionCard(icon: Icons.add_a_photo_outlined, title: 'Registra avvistamento', subtitle: 'Foto, specie e posizione', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SightingEditorScreen())))),
            ]),
            const SizedBox(height: 10),
            _ActionCard(icon: Icons.route_outlined, title: 'Avvia uscita', subtitle: 'Registra percorso, distanza e tempo sul campo', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RecordScreen())), horizontal: true),
            const SizedBox(height: 24),
            Row(children: [
              const Expanded(child: Text('Scopri WildTrack', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MapScreen())), child: const Text('Apri mappa')),
            ]),
            const SizedBox(height: 8),
            _FeatureTile(icon: Icons.radar, title: 'WildTrack Radar', subtitle: 'Indicazioni di attività basate su orario e stagione. Le prossime release integreranno meteo e habitat.', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ExplorationScreen()))),
            _FeatureTile(icon: Icons.pets_outlined, title: 'Catalogo specie', subtitle: 'Schede, impronte, habitat, versi e consigli fotografici.', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SpeciesScreen()))),
            _FeatureTile(icon: Icons.menu_book_outlined, title: 'Taccuino offline', subtitle: 'Rivedi e completa gli avvistamenti salvati sul telefono.', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SightingsScreen()))),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: .92), borderRadius: BorderRadius.circular(18)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap, this.horizontal = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool horizontal;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF3F0E7),
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: horizontal
            ? Row(children: [
                _IconBox(icon), const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFF657064)))])),
                const Icon(Icons.chevron_right),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _IconBox(icon), const SizedBox(height: 20),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Color(0xFF657064), height: 1.3)),
              ]),
      ),
    ),
  );
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFDDE8DA), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: const Color(0xFF254D38)));
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _IconBox(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
