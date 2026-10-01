import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../models/sighting.dart';
import '../models/track_session.dart';
import '../premium_ui.dart';

class FieldToolsScreen extends StatefulWidget {
  const FieldToolsScreen({super.key});
  @override
  State<FieldToolsScreen> createState() => _FieldToolsScreenState();
}

class _FieldToolsScreenState extends State<FieldToolsScreen> {
  List<Sighting> sightings = [];
  List<TrackSession> sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await DatabaseService.instance.getSightings();
    final t = await DatabaseService.instance.getSessions();
    if (mounted) setState(() { sightings = s; sessions = t; });
  }

  Set<String> get species => sightings.map((e) => e.species).where((e) => e.isNotEmpty).toSet();
  int get habitats => sightings.map((e) => e.notes.toLowerCase()).where((e) => e.isNotEmpty).take(8).length.clamp(1, 8);
  int get biodiversity => ((species.length * 6) + (habitats * 3) + sessions.length).clamp(0, 100);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(title: const WildLogo(compact: true)),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 6, 15, 40),
        children: [
          const Text('Esplora', style: WildText.display),
          const SizedBox(height: 5),
          const Text('Piccole missioni sul campo, senza trasformare il bosco in un videogioco rumoroso.', style: TextStyle(color: WildColors.muted)),
          const SizedBox(height: 18),
          _Mission(
            icon: Icons.pets_outlined,
            title: 'Missione di oggi',
            body: species.length < 3 ? 'Documenta tre specie diverse senza avvicinarti o disturbarle.' : 'Trova un segno di presenza che non hai ancora registrato.',
            progress: species.isEmpty ? .1 : (species.length / 3).clamp(0, 1),
          ),
          const SizedBox(height: 12),
          _Mission(
            icon: Icons.route_outlined,
            title: 'Esplora un habitat nuovo',
            body: 'Percorri un sentiero diverso e annota habitat, condizioni e tracce osservate.',
            progress: sessions.isEmpty ? 0 : (sessions.length / 5).clamp(0, 1),
          ),
          const SizedBox(height: 22),
          const WildSectionTitle('Indice di biodiversità'),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: WildColors.forest, borderRadius: BorderRadius.circular(26)),
            child: Row(children: [
              SizedBox(width: 82, height: 82, child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: biodiversity / 100, strokeWidth: 8, backgroundColor: Colors.white12, color: const Color(0xFF9DDD8E)),
                Text('$biodiversity', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Il tuo indice personale', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('${species.length} specie · $habitats contesti · ${sessions.length} uscite', style: const TextStyle(color: Color(0xFFD8E5D9), fontSize: 12)),
                const SizedBox(height: 6),
                const Text('Premia varietà e continuità, non il numero bruto di animali.', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ])),
            ]),
          ),
          const SizedBox(height: 22),
          const WildSectionTitle('Passaporto naturalistico'),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _Badge(icon: Icons.eco_outlined, label: '${species.length} specie'),
              _Badge(icon: Icons.hiking, label: '${sessions.length} uscite'),
              const _Badge(icon: Icons.public, label: 'Italia'),
              if (species.length >= 10) const _Badge(icon: Icons.workspace_premium, label: '10 specie'),
              if (sessions.length >= 5) const _Badge(icon: Icons.route, label: 'Esploratore'),
            ]),
          ),
          const SizedBox(height: 22),
          const WildSectionTitle('Modalità fotografica'),
          _PhotoMode(species: species.isEmpty ? 'Cervo' : species.first),
          const SizedBox(height: 22),
          const WildSectionTitle('Timeline della natura'),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: sightings.isEmpty
                ? const Text('La timeline crescerà con i tuoi avvistamenti privati.', style: TextStyle(color: WildColors.muted))
                : Column(children: [
                    for (final s in sightings.take(8))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const WildIconDisc(Icons.pets, size: 38),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.species, style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text('${s.timestamp.day}/${s.timestamp.month}/${s.timestamp.year} · ${s.kind}', style: const TextStyle(fontSize: 10, color: WildColors.muted)),
                          ])),
                        ]),
                      ),
                  ]),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF3E9DB), borderRadius: BorderRadius.circular(22)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.auto_awesome_outlined, color: WildColors.earth),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WildTrack Lens', style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 3),
                Text('Non attivo in questa build: verrà acceso solo con un motore di riconoscimento reale e con costi/privacy definiti. Niente finte percentuali generate dal nulla.', style: TextStyle(fontSize: 11, color: WildColors.muted, height: 1.3)),
              ])),
            ]),
          ),
        ],
      ),
    ),
  );
}

class _Mission extends StatelessWidget {
  const _Mission({required this.icon, required this.title, required this.body, required this.progress});
  final IconData icon; final String title, body; final double progress;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
    child: Row(children: [
      WildIconDisc(icon, size: 54), const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4), Text(body, style: const TextStyle(fontSize: 11, color: WildColors.muted, height: 1.3)),
        const SizedBox(height: 9), ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: progress, minHeight: 7, color: WildColors.forest, backgroundColor: WildColors.sageSoft)),
      ])),
    ]),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});
  final IconData icon; final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(18)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 17, color: WildColors.forest), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]));
}

class _PhotoMode extends StatelessWidget {
  const _PhotoMode({required this.species}); final String species;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFF2E8D7), borderRadius: BorderRadius.circular(24)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(species, style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      const Wrap(spacing: 7, runSpacing: 7, children: [
        _Chip('AF-C'), _Chip('Animal Eye AF'), _Chip('1/800 s o più'), _Chip('Raffica Hi'), _Chip('Auto ISO prudente'),
      ]),
      const SizedBox(height: 10),
      const Text('Priorità: luce, stabilità e distanza etica. L’app suggerisce impostazioni, non controlla la fotocamera.', style: TextStyle(fontSize: 11, color: WildColors.muted)),
    ]),
  );
}

class _Chip extends StatelessWidget { const _Chip(this.text); final String text; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))); }
