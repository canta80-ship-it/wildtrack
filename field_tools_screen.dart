import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sighting.dart';
import '../models/track_session.dart';
import '../services/database_service.dart';
import '../services/geo_insights_service.dart';
import '../services/wildtrack_intelligence_service.dart';
import '../premium_ui.dart';

class FieldToolsScreen extends StatefulWidget {
  const FieldToolsScreen({super.key});
  @override
  State<FieldToolsScreen> createState() => _FieldToolsScreenState();
}

class _FieldToolsScreenState extends State<FieldToolsScreen> {
  List<Sighting> sightings = [];
  List<TrackSession> sessions = [];
  IntelligenceSnapshot? intelligence;
  Map<String, int> regions = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final s = await DatabaseService.instance.getSightings();
    final t = await DatabaseService.instance.getSessions();
    final i = await WildTrackIntelligenceService.instance.load();
    final points = s.where((x) => x.hasPosition).map((x) => (lat: x.latitude!, lng: x.longitude!));
    final r = await GeoInsightsService.instance.aggregate(points);
    if (!mounted) return;
    setState(() {
      sightings = s;
      sessions = t;
      intelligence = i;
      regions = r;
      loading = false;
    });
  }

  Set<String> get species => sightings.map((e) => e.species).where((e) => e.isNotEmpty && e != 'Specie non identificata').toSet();

  @override
  Widget build(BuildContext context) {
    final report = WildTrackIntelligenceService.instance.biodiversity(sightings, sessions);
    final snapshot = intelligence;
    final missions = snapshot == null ? const <DynamicMission>[] : WildTrackIntelligenceService.instance.missions(snapshot, sightings, sessions);
    final timeline = WildTrackIntelligenceService.instance.timeline(sightings);
    final first = WildTrackIntelligenceService.instance.firstSightings(sightings);

    return Scaffold(
      backgroundColor: WildColors.ivory,
      appBar: AppBar(title: const WildLogo(compact: true)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(15, 6, 15, 40),
          children: [
            const Text('Esplora+', style: WildText.display),
            const SizedBox(height: 5),
            const Text('Missioni, biodiversità, passaporto, fotografia e memoria naturalistica costruiti dai tuoi dati.', style: TextStyle(color: WildColors.muted)),
            if (loading) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator()),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _StatusCard(icon: Icons.radar, title: 'Radar', value: snapshot?.activity ?? '…', body: snapshot == null ? 'calcolo' : '${snapshot.species.first.name} ${snapshot.species.first.score}%')),
              const SizedBox(width: 9),
              Expanded(child: _StatusCard(icon: Icons.landscape_outlined, title: 'Habitat', value: snapshot?.habitat.primary ?? '—', body: snapshot?.hasPosition == true ? 'contesto locale' : 'GPS non autorizzato')),
            ]),
            const SizedBox(height: 22),
            const WildSectionTitle('Missioni dinamiche'),
            const SizedBox(height: 9),
            if (missions.isEmpty)
              const _InfoCard(text: 'Il motore genererà le missioni usando ora, stagione, meteo, habitat, storico e progressi personali.')
            else
              for (final m in missions) ...[
                _Mission(mission: m),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 12),
            const WildSectionTitle('Indice di biodiversità personale'),
            const SizedBox(height: 9),
            _Biodiversity(report: report),
            const SizedBox(height: 22),
            const WildSectionTitle('Passaporto naturalistico'),
            const SizedBox(height: 9),
            _Passport(
              species: report.uniqueSpecies,
              outings: sessions.length,
              seasons: report.seasons,
              areas: report.geoCells,
              lifers: first.length,
              regions: regions.keys.toList(),
              onShare: () => _copyPassport(report, first.length),
            ),
            const SizedBox(height: 22),
            const WildSectionTitle('Modalità fotografica'),
            const SizedBox(height: 9),
            _PhotoMode(snapshot: snapshot),
            const SizedBox(height: 22),
            const WildSectionTitle('Timeline della natura'),
            const SizedBox(height: 9),
            _Timeline(items: timeline),
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
                  Text('Resta separato finché non colleghiamo un motore di riconoscimento reale. Nessuna falsa identificazione “AI” viene mostrata come certezza.', style: TextStyle(fontSize: 11, color: WildColors.muted, height: 1.3)),
                ])),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyPassport(BiodiversityReport report, int lifers) async {
    final text = 'WildTrack · Passaporto naturalistico\n${report.uniqueSpecies} specie · $lifers lifer · ${sessions.length} uscite · ${report.seasons}/4 stagioni · ${report.geoCells} aree · indice biodiversità ${report.score}/100${regions.isEmpty ? '' : '\nAree: ${regions.keys.take(5).join(', ')}'}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passaporto copiato: pronto da condividere.')));
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.title, required this.value, required this.body});
  final IconData icon; final String title, value, body;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
    child: Row(children: [WildIconDisc(icon, size: 46), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 10, color: WildColors.muted)), Text(value, style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w800)), Text(body, style: const TextStyle(fontSize: 9, color: WildColors.muted))]))]),
  );
}

class _Mission extends StatelessWidget {
  const _Mission({required this.mission});
  final DynamicMission mission;
  IconData get icon => switch (mission.iconKey) {
    'tracks' => Icons.pets_outlined,
    'forest' => Icons.forest_outlined,
    'season' => Icons.calendar_month_outlined,
    'map' => Icons.map_outlined,
    _ => WildIcons.binoculars,
  };
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
    child: Row(children: [
      WildIconDisc(icon, size: 54), const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(mission.title, style: const TextStyle(fontFamily: 'serif', fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4), Text(mission.description, style: const TextStyle(fontSize: 11, color: WildColors.muted, height: 1.3)),
        const SizedBox(height: 9), ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: mission.progress.clamp(0, 1), minHeight: 7, color: WildColors.forest, backgroundColor: WildColors.sageSoft)),
      ])),
    ]),
  );
}

class _Biodiversity extends StatelessWidget {
  const _Biodiversity({required this.report});
  final BiodiversityReport report;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: WildColors.forest, borderRadius: BorderRadius.circular(26)),
    child: Column(children: [
      Row(children: [
        SizedBox(width: 88, height: 88, child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(value: report.score / 100, strokeWidth: 8, backgroundColor: Colors.white12, color: const Color(0xFF9DDD8E)),
          Text('${report.score}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        ])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Indice personale', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text('${report.uniqueSpecies} specie · ${report.geoCells} aree · ${report.seasons}/4 stagioni', style: const TextStyle(color: Color(0xFFD8E5D9), fontSize: 11)),
          const SizedBox(height: 5),
          const Text('Combina ricchezza, Shannon/Pielou, copertura spaziale, stagionale e continuità di uscita. È un indice personale, non una misura ufficiale della biodiversità dell’ecosistema.', style: TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.3)),
        ])),
      ]),
      const SizedBox(height: 13),
      _Metric(label: 'Ricchezza', value: report.richness),
      _Metric(label: 'Equità specie', value: report.evenness),
      _Metric(label: 'Copertura geografica', value: report.spatialCoverage),
      _Metric(label: 'Copertura stagionale', value: report.seasonCoverage),
    ]),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label; final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(children: [SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 6, color: const Color(0xFF9DDD8E), backgroundColor: Colors.white12)))]),
  );
}

class _Passport extends StatelessWidget {
  const _Passport({required this.species, required this.outings, required this.seasons, required this.areas, required this.lifers, required this.regions, required this.onShare});
  final int species, outings, seasons, areas, lifers;
  final List<String> regions;
  final VoidCallback onShare;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Badge(icon: Icons.eco_outlined, label: '$species specie', unlocked: species >= 5),
        _Badge(icon: Icons.workspace_premium, label: '$lifers lifer', unlocked: lifers >= 3),
        _Badge(icon: Icons.hiking, label: '$outings uscite', unlocked: outings >= 5),
        _Badge(icon: Icons.calendar_month_outlined, label: '$seasons/4 stagioni', unlocked: seasons == 4),
        _Badge(icon: Icons.map_outlined, label: '$areas aree', unlocked: areas >= 5),
        if (species >= 25) const _Badge(icon: Icons.emoji_events_outlined, label: 'Naturalista 25', unlocked: true),
      ]),
      if (regions.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(regions.take(5).join(' · '), style: const TextStyle(fontSize: 10, color: WildColors.muted)),
      ],
      const SizedBox(height: 12),
      WildOutlineButton(label: 'Condividi passaporto', onPressed: onShare, icon: Icons.ios_share_outlined),
    ]),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.unlocked});
  final IconData icon; final String label; final bool unlocked;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(color: unlocked ? WildColors.sageSoft : const Color(0xFFF1F0EC), borderRadius: BorderRadius.circular(18)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(unlocked ? icon : Icons.lock_outline, size: 16, color: unlocked ? WildColors.forest : Colors.grey), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: unlocked ? WildColors.ink : Colors.grey))]),
  );
}

class _PhotoMode extends StatelessWidget {
  const _PhotoMode({required this.snapshot});
  final IntelligenceSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final target = snapshot?.species.firstOrNull;
    final fast = target != null && const {'Poiana', 'Picchio nero', 'Volpe', 'Lupo'}.contains(target.name);
    final shutter = fast ? '1/1600 s' : '1/800 s';
    final light = (snapshot?.weather.temperature != null || snapshot?.hasPosition == true) ? 'Auto ISO, limite 6400' : 'Auto ISO prudente';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF2E8D7), borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [WildIconDisc(Icons.camera_alt_outlined, size: 46, background: WildColors.earth, foreground: Colors.white), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sony a6700 + Sigma 16–300', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800)), Text('Profilo fauna · APS-C', style: TextStyle(fontSize: 10, color: WildColors.muted))]))]),
        const SizedBox(height: 12),
        Text(target == null ? 'Preset generale fauna' : 'Target probabile: ${target.name} · ${target.score}%', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 7, runSpacing: 7, children: [
          const _Chip('AF-C'),
          const _Chip('Tracking: Animal/Bird Eye'),
          _Chip(shutter),
          const _Chip('Raffica Hi+'),
          _Chip(light),
          const _Chip('RAW + JPEG'),
          const _Chip('Stabilizzazione ON'),
        ]),
        const SizedBox(height: 10),
        Text('Habitat: ${snapshot?.habitat.primary ?? 'non rilevato'} · vento ${snapshot?.weather.wind?.toStringAsFixed(0) ?? '—'} km/h. A 300 mm privilegia tempo rapido e appoggio stabile; non sacrificare distanza etica per riempire il fotogramma.', style: const TextStyle(fontSize: 10.5, color: WildColors.muted, height: 1.35)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => launchUrl(Uri.parse('https://creatorscloud.sony.net/catalog/en-us/creatorsapp/'), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Apri supporto Sony Creators’ App'),
        ),
        const Text('Il controllo diretto dei parametri della α6700 richiede un SDK/protocollo Sony autorizzato. WildTrack non finge di controllare la fotocamera quando non può farlo.', style: TextStyle(fontSize: 9, color: WildColors.muted)),
      ]),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});
  final List<NatureTimelineInsight> items;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
    child: items.isEmpty
        ? const Text('La timeline crescerà con i tuoi avvistamenti privati.', style: TextStyle(color: WildColors.muted))
        : Column(children: [
            for (final e in items.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const WildIconDisc(Icons.history, size: 38),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(e.body, style: const TextStyle(fontSize: 10, color: WildColors.muted, height: 1.3)),
                    Text('${e.date.day}/${e.date.month}/${e.date.year}', style: const TextStyle(fontSize: 9, color: WildColors.earth)),
                  ])),
                ]),
              ),
          ]),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)));
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Text(text, style: const TextStyle(color: WildColors.muted)));
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
