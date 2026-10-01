import 'package:flutter/material.dart';

import '../services/wildtrack_intelligence_service.dart';
import '../premium_ui.dart';
import 'premium_explore_screen.dart';
import 'premium_sighting_screen.dart';
import 'record_screen.dart';

class MissionActionCard extends StatelessWidget {
  const MissionActionCard({super.key, required this.mission});
  final DynamicMission mission;

  IconData get icon => switch (mission.iconKey) {
    'tracks' => Icons.pets_outlined,
    'forest' => Icons.forest_outlined,
    'season' => Icons.calendar_month_outlined,
    'map' => Icons.map_outlined,
    _ => Icons.visibility_outlined,
  };

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => MissionActionScreen(mission: mission))),
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        WildIconDisc(icon, size: 54),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mission.title, style: const TextStyle(fontFamily: 'serif', fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(mission.description, style: const TextStyle(fontSize: 11, color: WildColors.muted, height: 1.3)),
          const SizedBox(height: 9),
          ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: mission.progress.clamp(0, 1), minHeight: 7, color: WildColors.forest, backgroundColor: WildColors.sageSoft)),
        ])),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, color: WildColors.forest),
      ]),
    ),
  );
}

class MissionActionScreen extends StatelessWidget {
  const MissionActionScreen({super.key, required this.mission});
  final DynamicMission mission;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(title: const Text('Missione sul campo')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WildLandscape(height: 210, animal: mission.iconKey == 'tracks' ? 'Impronta' : 'Fauna'),
        const SizedBox(height: 15),
        Text(mission.title, style: WildText.display),
        const SizedBox(height: 8),
        Text(mission.description, style: const TextStyle(fontSize: 14, color: WildColors.muted, height: 1.4)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Text('Progresso', style: TextStyle(fontWeight: FontWeight.w900)), const Spacer(), Text('${(mission.progress.clamp(0, 1) * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, color: WildColors.forest))]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: mission.progress.clamp(0, 1), minHeight: 9, color: WildColors.forest, backgroundColor: WildColors.sageSoft)),
          ]),
        ),
        const SizedBox(height: 15),
        const Text('Azioni utili', style: WildText.h2),
        const SizedBox(height: 9),
        _Action(icon: Icons.hiking, title: 'Avvia un’uscita', body: 'Registra percorso, tempo, quota e dislivello mentre svolgi la missione.', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RecordScreen()))),
        _Action(icon: Icons.visibility_outlined, title: 'Registra un avvistamento', body: 'Aggiungi specie, traccia, foto e note al tuo diario.', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PremiumSightingScreen()))),
        _Action(icon: Icons.map_outlined, title: 'Esplora la zona', body: 'Apri la mappa per sentieri, CAI, Radar e avvistamenti.', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PremiumExploreScreen()))),
        const SizedBox(height: 8),
        const Text('Il progresso viene ricalcolato dai dati reali salvati in WildTrack. Non serve premere un pulsante “completata”: quando soddisfi i criteri, la missione avanza.', style: TextStyle(fontSize: 10, color: WildColors.muted, height: 1.35)),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.title, required this.body, required this.onTap});
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: ListTile(leading: WildIconDisc(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(body), trailing: const Icon(Icons.chevron_right), onTap: onTap),
  );
}
