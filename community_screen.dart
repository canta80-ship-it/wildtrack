import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/sighting.dart';
import 'sightings_screen.dart';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../services/community_service.dart';
import 'species_screen.dart';

String timeLabel(dynamic value) {
  try {
    return DateFormat('dd/MM HH:mm').format(
      value is int
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.parse(value as String).toLocal(),
    );
  } catch (_) {
    return '';
  }
}

void message(BuildContext context, Object e) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Comunità'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Avvistamenti'),
            Tab(text: 'Messaggi'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          ListenableBuilder(
            listenable: CommunityService.instance,
            builder: (context, _) {
              final c = CommunityService.instance;
              return RefreshIndicator(
                onRefresh: () => c.refresh(),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Text(
                      'Segnalazioni degli utenti, non verificate. Trascina per aggiornare.',
                    ),
                    if (c.error != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Aggiornamento non riuscito. ${c.error}'),
                      ),
                    if (c.syncing) const LinearProgressIndicator(),
                    for (final s in c.pending)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.cloud_upload_outlined),
                          title: Text(s['species'] as String),
                          subtitle: const Text('In attesa di pubblicazione'),
                          trailing: IconButton(
                            tooltip: 'Annulla invio',
                            onPressed: c.syncing
                                ? null
                                : () async {
                                    try {
                                      await c.cancelPending(s['id'] as String);
                                    } catch (e) {
                                      if (context.mounted) message(context, e);
                                    }
                                  },
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ),
                    if (c.sightings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Non ci sono ancora avvistamenti condivisi caricati.',
                        ),
                      ),
                    for (final s in c.sightings) SightingTile(s),
                    if (c.nextOffset != null)
                      TextButton(
                        onPressed: () => c.refresh(more: true),
                        child: const Text('Carica altri avvistamenti'),
                      ),
                    const SizedBox(height: 90),
                  ],
                ),
              );
            },
          ),
          const InboxScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SightingEditorScreen()),
        ),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Segnala'),
      ),
    ),
  );
}

class SightingTile extends StatelessWidget {
  const SightingTile(this.s, {super.key});
  final Map<String, dynamic> s;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.pets),
      title: Text('${s['species']} · ${s['count']}'),
      subtitle: Text(
        '${timeLabel(s['observedAt'])}${s['approximate'] == 1 ? ' · posizione approssimata' : ''}',
      ),
      trailing: s['mine'] == 1 ? const Icon(Icons.person) : null,
      onTap: () => showSighting(context, s),
    ),
  );
}

Future<void> showSighting(
  BuildContext context,
  Map<String, dynamic> s,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${s['species']} · ${s['count']}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(timeLabel(s['observedAt'])),
          if (s['photo'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.network(
                '$communityUrl/api/photo?id=${s['id']}',
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, e, st) => const Text('Foto non disponibile'),
              ),
            ),
          Text(s['notes'] as String? ?? ''),
          Text('Coordinate: ${s['lat']}, ${s['lng']}'),
          if (s['approximate'] == 1)
            const Text('Posizione approssimata a circa 1 km.'),
          const Text('Segnalazione pubblicata da un utente, non verificata.'),
          if (s['mine'] == 1)
            TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Rimuovere la segnalazione condivisa?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Annulla'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Rimuovi'),
                      ),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                try {
                  await CommunityService.instance.deleteSighting(
                    s['id'] as String,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) message(context, e);
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Rimuovi la mia segnalazione'),
            ),
        ],
      ),
    ),
  ),
);

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key, this.initial});
  final Sighting? initial;
  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  String species = animals.first.name;
  final count = TextEditingController(text: '1'),
      notes = TextEditingController();
  bool approximate = true, busy = false, consent = false;
  XFile? photo;
  LatLng? location;
  double? accuracy;
  late DateTime observedAt;
  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    observedAt = s?.timestamp ?? DateTime.now();
    if (s != null) {
      species = s.species;
      count.text = '${s.count}';
      notes.text = '[${s.kind}] ${s.notes}';
      if (s.photoPath != null) photo = XFile(s.photoPath!);
      if (s.hasPosition) location = LatLng(s.latitude!, s.longitude!);
      accuracy = s.accuracy;
    }
  }

  String? error;
  @override
  void dispose() {
    count.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> locate() async {
    setState(() => busy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Attiva il GPS');
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p != LocationPermission.always &&
          p != LocationPermission.whileInUse) {
        throw Exception('Permesso GPS non concesso');
      }
      final value = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (mounted) {
        setState(() {
          location = LatLng(value.latitude, value.longitude);
          accuracy = value.accuracy;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> publish() async {
    final n = int.tryParse(count.text);
    if (location == null || n == null || n < 1 || n > 10000 || !consent) return;
    setState(() => busy = true);
    try {
      String? encoded;
      if (photo != null) {
        final codec = await ui.instantiateImageCodec(
          await File(photo!.path).readAsBytes(),
          targetWidth: 800,
        );
        final frame = await codec.getNextFrame();
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        frame.image.dispose();
        codec.dispose();
        if (data == null || data.lengthInBytes > 1000000) {
          throw Exception(
            'Foto troppo grande: scegli una foto più semplice o pubblica senza foto.',
          );
        }
        encoded = base64Encode(data.buffer.asUint8List());
      }
      final p = location!;
      await CommunityService.instance.add({
        'id': widget.initial?.id ?? const Uuid().v4(),
        'species': species,
        'count': n,
        'notes': notes.text.trim(),
        'lat': p.latitude,
        'lng': p.longitude,
        'observedAt': observedAt.toUtc().toIso8601String(),
        'approximate': approximate,
        'photo': encoded,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Condividi avvistamento')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        DropdownButtonFormField<String>(
          initialValue: species,
          decoration: const InputDecoration(labelText: 'Specie'),
          items: [
            if (!animals.any((a) => a.name == species))
              DropdownMenuItem(value: species, child: Text(species)),
            ...animals
                .map(
                  (a) => DropdownMenuItem(
                    value: a.name,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [SpeciesIcon(a.name, size: 28), const SizedBox(width: 8), Text(a.name)]),
                  ),
                )
                .toList(),
          ],
          onChanged: busy ? null : (v) => setState(() => species = v!),
        ),
        TextField(
          controller: count,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Numero di animali'),
        ),
        TextField(
          controller: notes,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Note (senza dati personali)',
          ),
        ),
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () async {
                  final f = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1000,
                    imageQuality: 80,
                  );
                  if (mounted) setState(() => photo = f);
                },
          icon: const Icon(Icons.photo),
          label: Text(photo == null ? 'Aggiungi foto' : 'Foto selezionata'),
        ),
        if (photo != null)
          TextButton(
            onPressed: () => setState(() => photo = null),
            child: const Text('Rimuovi foto'),
          ),
        OutlinedButton.icon(
          onPressed: busy ? null : locate,
          icon: const Icon(Icons.gps_fixed),
          label: const Text('Rileva posizione avvistamento'),
        ),
        if (location != null)
          Text(
            '${location!.latitude.toStringAsFixed(5)}, ${location!.longitude.toStringAsFixed(5)} · ±${accuracy?.toStringAsFixed(0) ?? 'non disponibile'} m',
          ),
        SwitchListTile(
          value: approximate,
          onChanged: busy ? null : (v) => setState(() => approximate = v),
          title: const Text('Posizione approssimata'),
          subtitle: const Text(
            'Arrotonda a circa 1 km. Non pubblicare nidi o tane.',
          ),
        ),
        CheckboxListTile(
          value: consent,
          onChanged: busy ? null : (v) => setState(() => consent = v == true),
          title: const Text('Pubblica per tutti gli utenti'),
          subtitle: const Text(
            'Condivido specie, foto, note, data e posizione indicata. Senza rete l’invio resta in attesa.',
          ),
        ),
        if (error != null) Text(error!),
        if (busy) const LinearProgressIndicator(),
        FilledButton(
          onPressed: busy || location == null || !consent ? null : publish,
          child: const Text('Pubblica avvistamento'),
        ),
      ],
    ),
  );
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> rows = [];
  String? error;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 15), (_) => load());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final r = await CommunityService.instance.api('messages');
      if (mounted) {
        setState(() {
          rows = (r['items'] as List)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList();
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = 'Messaggi non disponibili. Trascina per riprovare.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chats = <String, Map<String, dynamic>>{};
    for (final r in rows) {
      final peer = (r['mine'] == 1 ? r['recipient'] : r['sender']) as String;
      chats.putIfAbsent(peer, () => r);
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        children: [
          if (error != null) ListTile(title: Text(error!)),
          if (chats.isEmpty)
            const ListTile(
              title: Text('Nessuna conversazione'),
              subtitle: Text(
                'Tocca una persona sulla mappa per iniziare una chat.',
              ),
            ),
          for (final entry in chats.entries)
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(
                (entry.value['mine'] == 1
                        ? entry.value['recipientName']
                        : entry.value['senderName'])
                    as String,
              ),
              subtitle: Text(
                entry.value['body'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ChatScreen(
                    peer: entry.key,
                    nickname:
                        (entry.value['mine'] == 1
                                ? entry.value['recipientName']
                                : entry.value['senderName'])
                            as String,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.peer, required this.nickname});
  final String peer, nickname;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  String? error;
  bool busy = false, blocked = false;
  Timer? timer;
  String? retryId, retryText;
  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 8), (_) => load());
  }

  @override
  void dispose() {
    timer?.cancel();
    input.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await CommunityService.instance.api(
        'messages?peer=${widget.peer}',
      );
      if (mounted) {
        setState(() {
          rows = (data['items'] as List)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList();
          blocked = data['blocked'] == true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Aggiornamento non riuscito.');
    }
  }

  Future<void> send() async {
    final body = input.text.trim();
    if (body.isEmpty || busy) return;
    setState(() => busy = true);
    if (retryText != body) {
      retryId = const Uuid().v4();
      retryText = body;
    }
    try {
      await CommunityService.instance.api(
        'messages',
        method: 'POST',
        body: {'peer': widget.peer, 'id': retryId, 'body': body},
      );
      if (!mounted) return;
      input.clear();
      retryId = null;
      retryText = null;
      setState(() => error = null);
      await load();
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.nickname),
      actions: [
        IconButton(
          tooltip: 'Blocca utente',
          icon: const Icon(Icons.block),
          onPressed: () async {
            final yes = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Bloccare questa persona?'),
                content: const Text(
                  'Non vedrete più le rispettive posizioni né potrete scrivervi.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Annulla'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Blocca'),
                  ),
                ],
              ),
            );
            if (yes != true) return;
            try {
              await CommunityService.instance.api(
                'messages',
                method: 'POST',
                body: {'peer': widget.peer, 'action': 'block'},
              );
              if (mounted) setState(() => blocked = true);
            } catch (e) {
              if (context.mounted) message(context, e);
            }
          },
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Nickname non verificato. Non condividere dati personali.',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final r in rows)
                  Align(
                    alignment: r['mine'] == 1
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['body'] as String),
                            Text(
                              timeLabel(r['created']),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (error != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(error!)),
          if (blocked)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Conversazione bloccata'),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Scrivi un messaggio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Invia',
                    onPressed: busy ? null : send,
                    icon: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
