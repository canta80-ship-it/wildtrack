import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/sighting.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
import 'community_screen.dart';
import 'species_screen.dart';

class SightingsScreen extends StatefulWidget {
  const SightingsScreen({super.key});
  @override
  State<SightingsScreen> createState() => _SightingsScreenState();
}

class _SightingsScreenState extends State<SightingsScreen> {
  List<Sighting> sightings = [];
  @override
  void initState() {
    super.initState();
    DatabaseService.instance.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    DatabaseService.instance.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await DatabaseService.instance.getSightings();
      if (mounted) setState(() => sightings = rows);
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Taccuino offline')),
    body: sightings.isEmpty
        ? const Center(
            child: Text(
              'Salva un incontro, un verso o una traccia.\nFunziona anche senza rete.',
              textAlign: TextAlign.center,
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sightings.length,
            itemBuilder: (context, i) {
              final s = sightings[i];
              return Card(
                child: ListTile(
                  leading: Icon(
                    s.hasPosition
                        ? Icons.location_on
                        : Icons.add_location_alt_outlined,
                  ),
                  title: Text('${s.species} · ${s.kind}'),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(s.timestamp)}\n${s.hasPosition ? '${s.latitude!.toStringAsFixed(5)}, ${s.longitude!.toStringAsFixed(5)}' : 'Posizione da aggiungere'}',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SightingEditorScreen(initial: s),
                    ),
                  ),
                ),
              );
            },
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const SightingEditorScreen()),
      ),
      icon: const Icon(Icons.add),
      label: const Text('Registra osservazione'),
    ),
  );
}

class SightingEditorScreen extends StatefulWidget {
  const SightingEditorScreen({super.key, this.initial});
  final Sighting? initial;
  @override
  State<SightingEditorScreen> createState() => _SightingEditorScreenState();
}

class _SightingEditorScreenState extends State<SightingEditorScreen> {
  final species = TextEditingController();
  final notes = TextEditingController();
  final count = TextEditingController();
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  late final String id;
  late DateTime observedAt;
  String kind = 'Animale', source = 'missing';
  String? photoPath, error;
  double? accuracy;
  bool saving = false, locating = false, saved = false;
  int locationGeneration = 0;
  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    saved = s != null;
    id = s?.id ?? const Uuid().v4();
    observedAt = s?.timestamp ?? DateTime.now();
    species.text = s?.species ?? '';
    count.text = '${s?.count ?? 1}';
    notes.text = s?.notes ?? '';
    kind = s?.kind ?? kind;
    photoPath = s?.photoPath;
    accuracy = s?.accuracy;
    source = s?.positionSource ?? source;
    latitude.text = s?.latitude?.toStringAsFixed(6) ?? '';
    longitude.text = s?.longitude?.toStringAsFixed(6) ?? '';
    if (s == null) unawaited(locate());
  }

  @override
  void dispose() {
    locationGeneration++;
    for (final c in [species, notes, count, latitude, longitude]) {
      c.dispose();
    }
    super.dispose();
  }

  double? number(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
  bool valid(double? lat, double? lng) =>
      lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180;
  void manual() {
    locationGeneration++;
    setState(() {
      locating = false;
      source = 'manual';
      accuracy = null;
    });
  }

  Future<void> locate() async {
    final generation = ++locationGeneration;
    setState(() {
      locating = true;
      error = null;
    });
    try {
      final p = await LocationService.currentPosition();
      if (!mounted || generation != locationGeneration) return;
      if (p == null)
        throw Exception(
          'GPS non disponibile. Puoi salvare ora e aggiungere la posizione dopo.',
        );
      setState(() {
        latitude.text = p.latitude.toStringAsFixed(6);
        longitude.text = p.longitude.toStringAsFixed(6);
        accuracy = p.accuracy;
        source = 'gps';
      });
    } catch (_) {
      if (mounted && generation == locationGeneration)
        setState(
          () => error =
              'Posizione non ottenuta. Salva comunque; potrai inserirla dopo.',
        );
    } finally {
      if (mounted && generation == locationGeneration)
        setState(() => locating = false);
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (!mounted || image == null) return;
      setState(() => photoPath = image.path);
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  Future<void> pickPoint() async {
    final lat = number(latitude.text), lng = number(longitude.text);
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => SightingPointScreen(
          initial: valid(lat, lng) ? LatLng(lat!, lng!) : null,
        ),
      ),
    );
    if (result != null && mounted) {
      manual();
      setState(() {
        latitude.text = result.latitude.toStringAsFixed(6);
        longitude.text = result.longitude.toStringAsFixed(6);
      });
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: observedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(observedAt),
    );
    if (time != null && mounted)
      setState(
        () => observedAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
  }

  Future<Sighting?> save({bool close = true}) async {
    if (saving) return null;
    final lat = number(latitude.text), lng = number(longitude.text);
    final empty = latitude.text.trim().isEmpty && longitude.text.trim().isEmpty;
    final n = int.tryParse(count.text);
    if (!empty && !valid(lat, lng)) {
      setState(
        () => error = 'Inserisci entrambe le coordinate valide oppure lascia entrambe vuote.',
      );
      return null;
    }
    if (n == null || n < 1 || n > 10000) {
      setState(() => error = 'Quantità: usa un numero da 1 a 10000.');
      return null;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      String? storedPhoto = photoPath;
      if (photoPath != null) {
        final directory = Directory(
          '${PreferencesService.instance.file.parent.path}/sighting_photos',
        );
        await directory.create(recursive: true);
        if (!photoPath!.startsWith('${directory.path}/')) {
          // Keep the original file extension: cameras can supply HEIC as well as JPEG.
          final extension = photoPath!.split('.').last.toLowerCase();
          final suffix = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension)
              ? extension
              : 'img';
          final target =
              '${directory.path}/$id-${DateTime.now().microsecondsSinceEpoch}.$suffix';
          storedPhoto = (await File(photoPath!).copy(target)).path;
        }
      }
      final sighting = Sighting(
        id: id,
        species: species.text.trim().isEmpty
            ? 'Specie non identificata'
            : species.text.trim(),
        count: n,
        notes: notes.text.trim(),
        latitude: empty ? null : lat,
        longitude: empty ? null : lng,
        timestamp: observedAt,
        photoPath: storedPhoto,
        kind: kind,
        accuracy: accuracy,
        positionSource: empty ? 'missing' : source,
      );
      await DatabaseService.instance.insertSighting(sighting);
      if (mounted) {
        setState(() {
          photoPath = storedPhoto;
          saved = true;
        });
        if (close) Navigator.pop(context);
      }
      return sighting;
    } catch (e) {
      if (mounted) setState(() => error = 'Salvataggio non riuscito: $e');
      return null;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> deletePrivateSighting() async {
    if (saving || !saved) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancellare l’osservazione privata?'),
        content: const Text(
          'Il punto sarà rimosso dalla mappa e dal taccuino di questo telefono. '
          'L’eventuale avvistamento pubblicato in Comunità resterà visibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || saving) return;
    setState(() => saving = true);
    try {
      await DatabaseService.instance.deleteSighting(id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Cancellazione non riuscita. Riprova.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> share() async {
    final s = await save(close: false);
    if (!mounted || s == null) return;
    if (!s.hasPosition) {
      setState(
        () => error =
            'Salvato sul telefono. Aggiungi la posizione prima di condividere.',
      );
      return;
    }
    final publishedSpecies = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => PublishScreen(initial: s)),
    );
    if (mounted && publishedSpecies != null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(saved ? 'Osservazione privata' : 'Registra osservazione'),
      actions: [
        if (saved)
          IconButton(
            tooltip: 'Cancella dal telefono',
            onPressed: saving ? null : deletePrivateSighting,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Salva sul telefono anche senza campo. La condivisione è un passaggio separato.',
        ),
        DropdownButtonFormField<String>(
          initialValue: kind,
          items: [
            'Animale',
            'Verso',
            'Impronta',
            'Traccia',
            'Fatta',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: saving ? null : (v) => setState(() => kind = v!),
        ),
        DropdownButtonFormField<String>(
          initialValue: species.text.isEmpty
              ? 'Specie non identificata'
              : species.text,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Specie'),
          items:
              {
                    'Specie non identificata',
                    ...animals.map((a) => a.name),
                    if (species.text.isNotEmpty) species.text,
                  }
                  .map(
                    (name) => DropdownMenuItem(
                      value: name,
                      child: Row(
                        children: [
                          SpeciesIcon(name, size: 28),
                          const SizedBox(width: 8),
                          Text(name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          onChanged: saving
              ? null
              : (value) => setState(() => species.text = value!),
        ),
        TextField(
          controller: count,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantità osservata'),
        ),
        TextField(
          controller: notes,
          maxLines: 3,
          maxLength: 900,
          decoration: const InputDecoration(
            labelText: 'Note, dimensioni e ambiente',
          ),
        ),
        TextButton.icon(
          onPressed: saving ? null : pickDate,
          icon: const Icon(Icons.event),
          label: Text(
            'Osservato: ${DateFormat('dd/MM/yyyy HH:mm').format(observedAt)}',
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: saving ? null : () => pickPhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scatta'),
            ),
            OutlinedButton.icon(
              onPressed: saving ? null : () => pickPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo),
              label: const Text('Galleria'),
            ),
          ],
        ),
        if (photoPath != null) ...[
          Image.file(
            File(photoPath!),
            height: 180,
            errorBuilder: (_, e, st) => const Text('Foto non disponibile'),
          ),
          TextButton(
            onPressed: saving ? null : () => setState(() => photoPath = null),
            child: const Text('Rimuovi foto'),
          ),
        ],
        const Divider(),
        TextField(
          controller: latitude,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onChanged: (_) => manual(),
          decoration: const InputDecoration(
            labelText: 'Latitudine (facoltativa per la bozza)',
          ),
        ),
        TextField(
          controller: longitude,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onChanged: (_) => manual(),
          decoration: const InputDecoration(labelText: 'Longitudine'),
        ),
        if (accuracy != null)
          Text('GPS: precisione stimata ±${accuracy!.toStringAsFixed(0)} m'),
        if (source == 'manual') const Text('Posizione inserita manualmente'),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: saving || locating ? null : locate,
              icon: const Icon(Icons.my_location),
              label: Text(
                locating ? 'Ricerca GPS… puoi già salvare' : 'GPS attuale',
              ),
            ),
            OutlinedButton.icon(
              onPressed: saving ? null : pickPoint,
              icon: const Icon(Icons.map),
              label: const Text('Scegli sulla mappa'),
            ),
          ],
        ),
        const Text(
          'Se stai registrando dopo l’incontro, scegli il punto sulla mappa: il GPS attuale indica dove sei adesso.',
        ),
        if (error != null)
          Padding(padding: const EdgeInsets.all(8), child: Text(error!)),
        FilledButton.icon(
          onPressed: saving ? null : () => save(),
          icon: const Icon(Icons.save),
          label: Text(saving ? 'Salvataggio…' : 'Salva sul telefono'),
        ),
        TextButton(
          onPressed: saving ? null : share,
          child: const Text('Salva e prepara condivisione pubblica'),
        ),
      ],
    ),
  );
}

class SightingPointScreen extends StatefulWidget {
  const SightingPointScreen({super.key, this.initial});
  final LatLng? initial;
  @override
  State<SightingPointScreen> createState() => _SightingPointScreenState();
}

class _SightingPointScreenState extends State<SightingPointScreen> {
  LatLng? selected;
  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tocca il punto osservato')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'La cartografia richiede rete se non è già disponibile. In alternativa torna indietro e inserisci le coordinate.',
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: selected ?? const LatLng(42.5, 12.5),
              initialZoom: selected == null ? 5 : 14,
              onTap: (_, p) => setState(() => selected = p),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'it.wildtrack.wildtrack_v2',
              ),
              if (selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selected!,
                      child: const Icon(Icons.location_pin, size: 40),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        if (selected != null)
          Text(
            '${selected!.latitude.toStringAsFixed(6)}, ${selected!.longitude.toStringAsFixed(6)}',
          ),
        SafeArea(
          child: FilledButton(
            onPressed: selected == null
                ? null
                : () => Navigator.pop(context, selected),
            child: const Text('Usa questa posizione'),
          ),
        ),
      ],
    ),
  );
}
