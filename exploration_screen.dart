import 'premium_screen.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/exploration_service.dart';
import '../services/community_service.dart';
import '../services/location_service.dart';
import 'species_screen.dart';
import 'community_screen.dart';

class ExplorationScreen extends StatefulWidget {
  const ExplorationScreen({super.key, this.species, this.trail});
  final String? species;
  final NatureTrail? trail;
  @override
  State<ExplorationScreen> createState() => _ExplorationScreenState();
}

class _ExplorationScreenState extends State<ExplorationScreen> {
  final map = MapController();
  String selected = 'Cervo';
  int? taxon;
  bool fauna = true, trekking = true, loading = false, following = false;
  String? error;
  String notice = 'Seleziona una specie e carica i sentieri dell’area.';
  List<NatureTrail> trails = [];
  NatureTrail? active;
  Position? gps;
  StreamSubscription<Position>? stream;
  int speciesGeneration = 0, navigationGeneration = 0;
  bool navigationBusy = false;
  Position? _distanceGps;
  NatureTrail? _distanceTrail;
  double? _distanceResult;
  List<Map<String, dynamic>> records = [];
  @override
  void initState() {
    super.initState();
    selected = widget.species ?? selected;
    active = widget.trail;
    if (active != null) trails = [active!];
    loadTaxon();
    if (active == null) loadPresets();
  }

  @override
  void dispose() {
    speciesGeneration++;
    navigationGeneration++;
    stream?.cancel();
    map.dispose();
    super.dispose();
  }

  Future<void> loadPresets() async {
    try {
      final rows = await ExplorationService.instance.presets();
      if (mounted) {
        setState(() {
          trails = rows;
          notice =
              '${rows.length} itinerari reali già disponibili. Scegli Itinerari oppure carica un’altra area.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = 'Catalogo itinerari non caricato: $e');
      }
    }
  }

  Future<void> loadTaxon() async {
    final generation = ++speciesGeneration;
    setState(() {
      taxon = null;
      records = [];
      error = null;
    });
    try {
      final a = animals.firstWhere((a) => a.name == selected);
      final bundle = await ExplorationService.instance.bundled();
      final cached = (bundle['taxa'] as Map)[a.latin];
      final d = cached != null
          ? <String, dynamic>{'taxon': cached}
          : await CommunityService.instance.api(
              'nature?name=${Uri.encodeQueryComponent(a.latin)}',
            );
      if (mounted && generation == speciesGeneration) {
        setState(() => taxon = d['taxon'] as int);
      }
    } catch (e) {
      if (mounted && generation == speciesGeneration) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> loadTrails() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final p = map.camera.center;
      final rows = await ExplorationService.instance.nearby(p);
      if (mounted) {
        setState(() {
          trails = rows;
          notice = rows.isEmpty
              ? 'Nessun itinerario OSM trovato entro 5 km. Sposta la mappa e riprova.'
              : '${rows.length} itinerari trovati entro 5 km dal centro mappa.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadRecords() async {
    if (loading) return;
    final gen = speciesGeneration;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final a = animals.firstWhere((a) => a.name == selected),
          p = map.camera.center;
      final d = await CommunityService.instance.api(
        'nature?name=${Uri.encodeQueryComponent(a.latin)}&lat=${p.latitude}&lng=${p.longitude}',
      );
      if (mounted && gen == speciesGeneration) {
        setState(() {
          records = (d['items'] as List)
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
          notice =
              '${records.length} registrazioni mostrate su ${d['count']} nell’area. Date e qualità variabili: tocca un punto.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> locate() async {
    try {
      final p = await LocationService.currentPosition();
      if (!mounted) return;
      if (p == null) throw Exception('GPS non disponibile');
      setState(() => gps = p);
      map.move(LatLng(p.latitude, p.longitude), 13);
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  Future<void> navigate() async {
    if (navigationBusy) return;
    navigationBusy = true;
    final generation = ++navigationGeneration;
    try {
      if (following) {
        await stream?.cancel();
        stream = null;
        if (mounted) setState(() => following = false);
        return;
      }
      if (!await LocationService.ensurePermission())
        throw Exception('Autorizza il GPS');
      if (!mounted || generation != navigationGeneration) return;
      setState(() => following = true);
      stream = LocationService.positionStream(purpose: 'navigation').listen(
        (p) {
          if (!mounted || generation != navigationGeneration) return;
          setState(() => gps = p);
          map.move(
            LatLng(p.latitude, p.longitude),
            math.max(map.camera.zoom, 14.0),
          );
        },
        onError: (Object e) {
          if (!mounted || generation != navigationGeneration) return;
          setState(() {
            following = false;
            error = 'GPS interrotto: $e';
          });
          final old = stream;
          stream = null;
          unawaited(old?.cancel());
        },
      );
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      navigationBusy = false;
    }
  }

  List<NatureTrail>? _lineTrails;
  String? _lineActive;
  List<Polyline> _lines = [];
  List<Polyline> get trailLines {
    if (!identical(_lineTrails, trails) || _lineActive != active?.id) {
      _lineTrails = trails;
      _lineActive = active?.id;
      _lines = [
        for (final t in trails)
          for (final segment in t.segments)
            Polyline(
              points: segment,
              color: t.id == active?.id
                  ? const Color(0xFFD7824A)
                  : const Color(0xFF2A563C),
              strokeWidth: t.id == active?.id ? 6 : 3,
            ),
      ];
    }
    return _lines;
  }

  double? offTrack() {
    if (gps == null || active == null) return null;
    if (identical(_distanceGps, gps) && identical(_distanceTrail, active))
      return _distanceResult;
    _distanceGps = gps;
    _distanceTrail = active;
    final lat = gps!.latitude,
        lon = gps!.longitude,
        scale = 111320 * math.cos(lat * math.pi / 180);
    double best = double.infinity;
    for (final s in active!.segments) {
      for (var i = 1; i < s.length; i++) {
        final ax = (s[i - 1].longitude - lon) * scale,
            ay = (s[i - 1].latitude - lat) * 111320,
            bx = (s[i].longitude - lon) * scale,
            by = (s[i].latitude - lat) * 111320,
            dx = bx - ax,
            dy = by - ay,
            l = dx * dx + dy * dy;
        final t = l == 0 ? 0.0 : ((-ax * dx - ay * dy) / l).clamp(0.0, 1.0);
        best = math.min(
          best,
          math.sqrt(math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2)),
        );
      }
    }
    return _distanceResult = best.isFinite ? best : null;
  }

  void focus(NatureTrail t) {
    setState(() => active = t);
    Navigator.pop(context);
    map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(t.segments.expand((s) => s).toList()),
        padding: const EdgeInsets.all(45),
      ),
    );
  }

  Future<void> listTrails({bool saved = false}) async {
    List<NatureTrail> rows;
    try {
      rows = saved ? await ExplorationService.instance.saved() : trails;
    } catch (e) {
      if (mounted) message(context, e);
      return;
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .7,
          builder: (c, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                saved ? 'Itinerari salvati offline' : 'Itinerari nell’area',
                style: Theme.of(c).textTheme.headlineSmall,
              ),
              const Text(
                'Geometrie OSM: controlla segnaletica, accessibilità e meteo. La distanza è calcolata sul tracciato, non sui tempi di cammino.',
              ),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nessun itinerario. Usa “Carica sentieri qui”.'),
                ),
              for (final t in rows)
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(t.name),
                        subtitle: Text(
                          '${(t.length / 1000).toStringAsFixed(1)} km di tracciato · difficoltà: ${t.data['difficulty']}',
                        ),
                        onTap: () => focus(t),
                      ),
                      Wrap(
                        children: [
                          TextButton.icon(
                            onPressed: () => focus(t),
                            icon: const Icon(Icons.map),
                            label: const Text('Mostra'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                await ExplorationService.instance.save(t);
                                if (c.mounted) {
                                  message(
                                    c,
                                    'Tracciato salvato sul telefono. La mappa di sfondo richiede rete.',
                                  );
                                }
                              } catch (e) {
                                if (c.mounted) message(c, e);
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Salva'),
                          ),
                          if (t.data['source'] != null)
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse(t.data['source'] as String),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: const Text('Fonte OSM'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void destinations() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('Esplora l’Italia'),
            subtitle: Text(
              'Scegli una zona, poi carica i sentieri reali. I punti sono centri di ricerca, non punti di avvistamento.',
            ),
          ),
          for (final d in const <(String, double, double)>[
            ('Cansiglio', 46.061, 12.403),
            ('Prealpi Giulie · Val Resia', 46.36, 13.31),
            ('Gran Paradiso · Cogne', 45.594, 7.356),
            ('Stelvio · Valfurva', 46.403, 10.491),
            ('Dolomiti · Val di Funes', 46.637, 11.766),
            ('Delta del Po · Comacchio', 44.695, 12.18),
            ('Foreste Casentinesi · Camaldoli', 43.795, 11.82),
            ('Monti Sibillini · Castelluccio', 42.829, 13.206),
            ('Abruzzo · Camosciara', 41.76, 13.908),
            ('Pollino · Piano Ruggio', 39.912, 16.131),
            ('Sila · Lago Cecita', 39.38, 16.54),
            ('Etna · Piano Provenzana', 37.795, 15.037),
            ('Sardegna · Fonni', 40.12, 9.25),
          ])
            ListTile(
              leading: const Icon(Icons.landscape_outlined),
              title: Text(d.$1),
              onTap: () {
                Navigator.pop(c);
                map.move(LatLng(d.$2, d.$3), 12);
                setState(
                  () => notice =
                      '${d.$1}: carica i sentieri o le registrazioni della specie.',
                );
              },
            ),
        ],
      ),
    ),
  );
  void recordInfo(Map<String, dynamic> r) => showModalBottomSheet<void>(
    context: context,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r['name'] as String? ?? selected,
              style: Theme.of(c).textTheme.headlineSmall,
            ),
            Text('Data: ${r['date'] ?? r['year'] ?? 'non indicata'}'),
            Text('Tipo di record: ${r['basis'] ?? 'non indicato'}'),
            Text(
              'Incertezza coordinate: ${r['uncertainty'] == null ? 'non dichiarata' : '${r['uncertainty']} m'}',
            ),
            Text('Licenza: ${r['license'] ?? 'consulta la fonte'}'),
            const Text(
              'Dato d’archivio: non indica presenza attuale né garantisce l’avvistamento.',
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(r['url'] as String),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Apri scheda originale GBIF'),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final off = offTrack();
    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('Italia · specie e itinerari'),
        actions: [
          IconButton(
            onPressed: locate,
            icon: const Icon(Icons.my_location),
            tooltip: "La mia posizione",
          ),
          IconButton(
            onPressed: destinations,
            icon: const Icon(Icons.travel_explore),
            tooltip: 'Destinazioni',
          ),
          IconButton(
            onPressed: () => listTrails(saved: true),
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Tracciati offline',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selected,
                    isExpanded: true,
                    items: animals
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.name,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => selected = v!);
                      loadTaxon();
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    map.move(const LatLng(42, 12.5), 5.5);
                  },
                  icon: const Icon(Icons.public),
                  tooltip: 'Tutta Italia',
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Fauna Italia'),
                selected: fauna,
                onSelected: (v) => setState(() => fauna = v),
              ),
              FilterChip(
                label: const Text('Trekking'),
                selected: trekking,
                onSelected: (v) => setState(() => trekking = v),
              ),
              ActionChip(
                label: const Text('Carica sentieri qui'),
                onPressed: loading ? null : loadTrails,
              ),
              ActionChip(
                label: const Text('Dati fauna qui'),
                onPressed: loading ? null : loadRecords,
              ),
              ActionChip(
                label: Text('Itinerari (${trails.length})'),
                onPressed: () => listTrails(),
              ),
            ],
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: FlutterMap(
              mapController: map,
              options: MapOptions(
                initialCenter: active?.center ?? const LatLng(42, 12.5),
                initialZoom: active == null ? 5.5 : 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'it.wildtrack.wildtrack_v2',
                ),
                if (fauna && taxon != null)
                  TileLayer(
                    key: ValueKey(taxon),
                    urlTemplate:
                        'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@1x.png?srs=EPSG:3857&taxonKey=$taxon&country=IT&bin=hex&hexPerTile=57&style=classic.poly',
                    userAgentPackageName: 'it.wildtrack.wildtrack_v2',
                    maxNativeZoom: 14,
                  ),
                if (trekking) PolylineLayer(polylines: trailLines),
                MarkerLayer(
                  markers: [
                    if (fauna)
                      for (final r in records)
                        Marker(
                          point: LatLng(
                            (r['lat'] as num).toDouble(),
                            (r['lng'] as num).toDouble(),
                          ),
                          width: 32,
                          height: 32,
                          child: GestureDetector(
                            onTap: () => recordInfo(r),
                            child: const Icon(
                              Icons.hexagon,
                              color: Colors.purple,
                              size: 23,
                            ),
                          ),
                        ),
                    if (trekking)
                      for (final t in trails)
                        Marker(
                          point: t.center,
                          width: 38,
                          height: 38,
                          child: IconButton(
                            onPressed: () {
                              setState(() => active = t);
                              listTrails();
                            },
                            icon: const Icon(
                              Icons.hiking,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                    if (gps != null)
                      Marker(
                        point: LatLng(gps!.latitude, gps!.longitude),
                        width: 35,
                        height: 35,
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: const [
                    TextSourceAttribution('© OpenStreetMap · GBIF.org'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(active?.name ?? notice, maxLines: 3),
                if (active != null && off != null)
                  Text(
                    'Distanza dal tracciato: ${off.toStringAsFixed(0)} m · precisione GPS ±${gps!.accuracy.toStringAsFixed(0)} m',
                  ),
                const Text(
                  'Giallo/rosso: concentrazione di record GBIF, anche storici. L’assenza di record non significa assenza della specie.',
                  style: TextStyle(fontSize: 12),
                ),
                if (active != null)
                  PremiumFilledButton.icon(
                    onPressed: navigate,
                    icon: Icon(following ? Icons.stop : Icons.navigation),
                    label: Text(
                      following
                          ? 'Ferma navigazione'
                          : 'Segui tracciato con GPS',
                    ),
                  ),
                if (following)
                  const Text(
                    'Segui la traccia sulla mappa. Non vengono calcolate svolte o percorsi alternativi.',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
