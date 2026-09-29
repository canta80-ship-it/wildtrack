import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/sighting.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

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
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseService.instance.getSightings();
    if (mounted) setState(() => sightings = rows);
  }

  Future<void> _add() async {
    final species = TextEditingController(text: 'Cervo');
    final count = TextEditingController(text: '1');
    final notes = TextEditingController();
    String? photoPath;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Nuovo avvistamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: species,
                  decoration: const InputDecoration(labelText: 'Specie'),
                ),
                TextField(
                  controller: count,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Numero'),
                ),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final image = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (image != null) setLocal(() => photoPath = image.path);
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    photoPath == null ? 'Scatta foto' : 'Foto acquisita',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final p = await LocationService.currentPosition();
    if (p == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile ottenere la posizione GPS.'),
          ),
        );
      }
      return;
    }
    final sighting = Sighting(
      id: const Uuid().v4(),
      species: species.text.trim().isEmpty ? 'Fauna' : species.text.trim(),
      count: int.tryParse(count.text) ?? 1,
      notes: notes.text.trim(),
      latitude: p.latitude,
      longitude: p.longitude,
      timestamp: DateTime.now(),
      photoPath: photoPath,
    );
    await DatabaseService.instance.insertSighting(sighting);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avvistamenti')),
      body: sightings.isEmpty
          ? const Center(child: Text('Ancora nessun avvistamento salvato.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sightings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = sightings[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.pets)),
                    title: Text('${s.species} · ${s.count}'),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy HH:mm').format(s.timestamp)}\n${s.latitude.toStringAsFixed(5)}, ${s.longitude.toStringAsFixed(5)}${s.notes.isEmpty ? '' : '\n${s.notes}'}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Avvistamento'),
      ),
    );
  }
}
