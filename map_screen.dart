import 'premium_screen.dart';
import '../services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/database_service.dart';
import '../services/community_service.dart';
import '../services/preferences_service.dart';
import 'brand_screen.dart';
import 'settings_screen.dart';
import 'species_screen.dart';
import 'exploration_screen.dart';
import 'sos_screen.dart';
import 'community_screen.dart';
import 'sightings_screen.dart';

import 'package:url_launcher/url_launcher.dart';

class HabitatArea {
  const HabitatArea(
    this.name,
    this.center,
    this.points,
    this.species,
    this.note,
    this.source,
  );
  final String name, note, source;
  final LatLng center;
  final List<LatLng> points;
  final List<String> species;
}

const areas = <HabitatArea>[
  HabitatArea(
    'Cansiglio',
    LatLng(46.061, 12.403),
    [
      LatLng(46.028, 12.366),
      LatLng(46.089, 12.361),
      LatLng(46.117, 12.411),
      LatLng(46.092, 12.463),
      LatLng(46.032, 12.444),
    ],
    ['Cervo', 'Capriolo', 'Volpe', 'Picchio nero'],
    'Boschi e radure. Mammiferi spesso più visibili nelle ore tranquille. Il contorno è uno schema geografico, non il confine ufficiale né una previsione.',
    cansiglioSource,
  ),
  HabitatArea(
    'Prealpi Giulie',
    LatLng(46.321, 13.256),
    [
      LatLng(46.260, 13.109),
      LatLng(46.361, 13.110),
      LatLng(46.409, 13.453),
      LatLng(46.314, 13.455),
      LatLng(46.260, 13.302),
    ],
    [
      'Cervo',
      'Capriolo',
      'Camoscio alpino',
      'Stambecco',
      'Cinghiale',
      'Aquila reale',
      'Poiana',
      'Allocco',
      'Grifone',
    ],
    'Mosaico di boschi, praterie e rocce. Le specie occupano ambienti e quote differenti; non sono distribuite uniformemente nel poligono.',
    prealpsSource,
  ),
  HabitatArea(
    'Cornino e Tagliamento',
    LatLng(46.229, 13.022),
    [
      LatLng(46.210, 12.995),
      LatLng(46.249, 12.999),
      LatLng(46.252, 13.041),
      LatLng(46.221, 13.054),
    ],
    ['Grifone'],
    'Area indicativa collegata alla colonia e ai voli dei grifoni. Per osservare usa i percorsi autorizzati della riserva.',
    'https://www.riservacornino.it/chi-siamo/la-riserva/',
  ),
  HabitatArea(
    'Foce dell’Isonzo',
    LatLng(45.758, 13.504),
    [
      LatLng(45.724, 13.478),
      LatLng(45.807, 13.486),
      LatLng(45.808, 13.525),
      LatLng(45.744, 13.563),
    ],
    ['Airone cenerino', 'Germano reale', 'Falco di palude'],
    'Zone umide, canneti e acque aperte. Presenze variabili secondo stagione, migrazione e livello dell’acqua.',
    birdsSource,
  ),
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final controller = MapController();
  LatLng? position;
  Map<String, Marker> personal = {};
  bool ready = false,
      locating = false,
      habitats = true,
      possible = true,
      shared = true,
      locals = true;
  String selected = 'Tutte';
  String selectedMap = 'all';
  @override
  void initState() {
    super.initState();
    CommunityService.instance.addListener(changed);
    PreferencesService.instance.addListener(changed);
    DatabaseService.instance.changes.addListener(loadPersonal);
    loadPersonal();
  }

  void changed() {
    if (selectedMap != "all" &&
        selectedMap != "public" &&
        !CommunityService.instance.sightings.any(
          (s) => s["groupId"] == selectedMap,
        )) {
      selectedMap = "all";
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CommunityService.instance.removeListener(changed);
    PreferencesService.instance.removeListener(changed);
    DatabaseService.instance.changes.removeListener(loadPersonal);
    controller.dispose();
    super.dispose();
  }

  Future<void> loadPersonal() async {
    try {
      final rows = await DatabaseService.instance.getSightings();
      if (mounted) {
        setState(
          () => personal = Map.fromEntries(
            rows
                .where((s) => s.hasPosition)
                .map(
                  (s) => MapEntry(
                    s.id,
                    Marker(
                      point: LatLng(s.latitude!, s.longitude!),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SightingEditorScreen(initial: s),
                          ),
                        ),
                        child: Tooltip(
                          message: 'Privato: ${s.species} · ${s.kind}',
                          child: SpeciesIcon(s.species, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) message(context, 'Taccuino non caricato: $e');
    }
  }

  Future<void> locate() async {
    if (locating) return;
    setState(() => locating = true);
    try {
      final p = await LocationService.currentPosition();
      if (p == null)
        throw Exception('Autorizza il GPS e attiva la posizione del telefono');
      if (!mounted) return;
      setState(() => position = LatLng(p.latitude, p.longitude));
      if (ready) controller.move(position!, 13);
      await loadPersonal();
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> areaDetails(HabitatArea a) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(a.note),
            Text('Specie documentate nell’area: ${a.species.join(', ')}'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Zona possibile, non avvistamento confermato. Nessuna indicazione di nidi o tane. Verifica accessi e regole locali.',
              ),
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(a.source),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Consulta la fonte'),
            ),
          ],
        ),
      ),
    ),
  );
  void filters() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Livelli e specie',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              for (final item in [
                ('Habitat indicativi', habitats, 0),
                ('Zone di possibile osservazione', possible, 1),
                ('Avvistamenti pubblici e mappe private', shared, 2),
                ('Avvistamenti privati', locals, 3),
              ])
                SwitchListTile(
                  title: Text(item.$1),
                  value: item.$2,
                  onChanged: (v) {
                    setState(() {
                      switch (item.$3) {
                        case 0:
                          habitats = v;
                        case 1:
                          possible = v;
                        case 2:
                          shared = v;
                        case 3:
                          locals = v;
                      }
                    });
                    update(() {});
                  },
                ),
              DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: 'Tutte',
                    child: Text('Tutte le specie'),
                  ),
                  for (final a in animals)
                    DropdownMenuItem(value: a.name, child: Text(a.name)),
                ],
                onChanged: (v) {
                  setState(() => selected = v!);
                  update(() {});
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedMap,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Mappa condivisa'),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Tutte le mappe accessibili'),
                  ),
                  const DropdownMenuItem(
                    value: 'public',
                    child: Text('Solo comunità pubblica'),
                  ),
                  for (final id
                      in CommunityService.instance.sightings
                          .where((s) => s['groupId'] != null)
                          .map((s) => s['groupId'] as String)
                          .toSet())
                    DropdownMenuItem(
                      value: id,
                      child: Text(
                        CommunityService.instance.sightings.firstWhere(
                                  (s) => s['groupId'] == id,
                                )['groupName']
                                as String? ??
                            'Mappa privata',
                      ),
                    ),
                ],
                onChanged: (v) {
                  setState(() => selectedMap = v!);
                  update(() {});
                },
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Copertura iniziale: 4 aree documentate del Nordest. I poligoni sono schemi approssimativi, non confini ufficiali o mappe complete di distribuzione.',
                ),
              ),
              for (final a in areas)
                ListTile(
                  title: Text(a.name),
                  trailing: const Icon(Icons.center_focus_strong),
                  onTap: () {
                    Navigator.pop(context);
                    if (ready) {
                      controller.move(
                        a.center,
                        a.name == 'Prealpi Giulie' ? 10 : 12,
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesService.instance, c = CommunityService.instance;
    final filtered = areas
        .where((a) => selected == 'Tutte' || a.species.contains(selected))
        .toList();
    final gps =
        position ??
        (c.position == null
            ? null
            : LatLng(c.position!.latitude, c.position!.longitude));
    return PremiumScaffold(
      appBar: AppBar(
        title: const WildTrackBrand(),
        actions: [
          IconButton(
            tooltip: 'Impostazioni',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
          TextButton(
            onPressed: () async {
              await AudioService.instance.stop();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SosScreen()),
                );
              }
            },
            child: const Text(
              'SOS',
              style: TextStyle(
                color: Color(0xFFAE292F),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: const LatLng(46.08, 13.02),
              initialZoom: 8,
              onMapReady: () {
                ready = true;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'it.wildtrack.wildtrack_mvp',
              ),
              if (habitats)
                PolygonLayer(
                  polygons: [
                    for (final a in filtered)
                      Polygon(
                        points: a.points,
                        color: const Color(0xFF628348).withValues(alpha: .20),
                        borderColor: const Color(0xFF446B36),
                        borderStrokeWidth: 2,
                      ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (possible)
                    for (final a in filtered)
                      Marker(
                        point: a.center,
                        width: 145,
                        height: 60,
                        child: GestureDetector(
                          onTap: () => areaDetails(a),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.visibility,
                                color: Color(0xFF365626),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                color: const Color(0xFFE0E8CE),
                                child: Text(
                                  a.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF173921),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (locals)
                    ...personal.entries
                        .where(
                          (entry) =>
                              !shared ||
                              !c.sightings.any(
                                (s) =>
                                    '${s['id']}' == entry.key &&
                                    (selected == 'Tutte' ||
                                        s['species'] == selected),
                              ),
                        )
                        .map((entry) => entry.value),
                  if (shared)
                    for (final s in c.sightings.where(
                      (s) =>
                          (selected == 'Tutte' || s['species'] == selected) &&
                          (selectedMap == 'all' ||
                              (selectedMap == 'public'
                                  ? s['groupId'] == null
                                  : s['groupId'] == selectedMap)),
                    ))
                      Marker(
                        point: LatLng(
                          (s['lat'] as num).toDouble(),
                          (s['lng'] as num).toDouble(),
                        ),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => showSighting(context, s),
                          child: SpeciesIcon(
                            s['species'] as String? ?? '',
                            size: 36,
                          ),
                        ),
                      ),
                  if (gps != null)
                    Marker(
                      point: gps,
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF135AA6),
                        size: 30,
                      ),
                    ),
                  if (prefs.visible)
                    for (final p in c.people.where(
                      (p) =>
                          DateTime.now().millisecondsSinceEpoch -
                              (p['updated'] as num) <
                          180000,
                    ))
                      Marker(
                        point: LatLng(
                          (p['lat'] as num).toDouble(),
                          (p['lng'] as num).toDouble(),
                        ),
                        width: 44,
                        height: 44,
                        child: IconButton(
                          tooltip: '${p['nickname']} · ${p['distanceM']} m',
                          icon: const Icon(
                            Icons.person_pin_circle,
                            color: Color(0xFF773E95),
                            size: 38,
                          ),
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      p['nickname'] as String,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                    Text(
                                      '${p['distanceM']} m · aggiornamento ${timeLabel(p['updated'])}',
                                    ),
                                    const Text(
                                      'Posizione condivisa volontariamente · nickname non verificato',
                                    ),
                                    PremiumFilledButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          this.context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => ChatScreen(
                                              peer: p['id'] as String,
                                              nickname: p['nickname'] as String,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                      ),
                                      label: const Text('Scrivi messaggio'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
              RichAttributionWidget(
                attributions: const [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.hiking),
                  label: const Text('Italia e sentieri'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ExplorationScreen(),
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add_location_alt),
                  label: const Text('Registra offline'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SightingEditorScreen(),
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.layers_outlined),
                  label: Text(
                    selected == 'Tutte' ? 'Livelli e specie' : selected,
                  ),
                  onPressed: filters,
                ),
                if (prefs.visible)
                  Chip(
                    avatar: const Icon(Icons.people_outline),
                    label: Text('${c.people.length} persone entro 5 km'),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 230),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Verde: habitat indicativo\nOcchio: zona possibile · Animale: osservazione\nViola: persone · Filtri per mappe private',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
          if (c.error != null)
            Positioned(
              top: 65,
              left: 12,
              right: 12,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    c.error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefs.soundPanel) ...[
            FloatingActionButton.small(
              heroTag: 'sounds',
              tooltip: 'Versi animali',
              onPressed: () => showSounds(context),
              child: const Icon(Icons.volume_up),
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton.small(
            heroTag: 'layers',
            tooltip: 'Livelli',
            onPressed: filters,
            child: const Icon(Icons.layers),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'gps',
            tooltip: 'La mia posizione',
            onPressed: locating ? null : locate,
            child: locating
                ? const CircularProgressIndicator()
                : const Icon(Icons.gps_fixed),
          ),
        ],
      ),
    );
  }
}
