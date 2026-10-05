import 'chat_attachment_widget.dart';
import '../services/file_import_service.dart';
import '../services/push_service.dart';
import 'community_edit_photo_widget.dart';
import 'recovery_screen.dart';
import '../premium_ui.dart';
import 'community_photo_widget.dart';
import 'profile_avatar_widget.dart';
import 'community_sighting_map_screen.dart';
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
import '../services/database_service.dart';
import '../services/media_storage_service.dart';
import '../services/preferences_service.dart';
import 'private_maps_screen.dart';
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
        actions: [
          IconButton(
            tooltip: 'Mappe private',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const PrivateMapsScreen(),
              ),
            ),
          ),
        ],
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
        '${s['groupId'] == null ? 'Pubblico' : 'Privato · ${s['groupName']}'} · ${timeLabel(s['observedAt'])}${s['approximate'] == 1 ? ' · posizione approssimata' : ''}',
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
          Row(children: [ProfileAvatar(url: s['avatarUrl'] as String?), const SizedBox(width: 8), Expanded(child: Text('${s['authorName'] ?? 'Autore non disponibile'}', style: const TextStyle(fontWeight: FontWeight.bold, color: WildColors.forest)))]),
          Text(timeLabel(s['observedAt'])),
          Text(
            s['groupId'] == null
                ? 'Condivisione pubblica'
                : 'Mappa privata: ${s['groupName']}',
          ),
          if (s['photo'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CommunityPhoto(version: '${s['photo']}', sightingId: '${s['id']}'),
            ),
          Text(s['notes'] as String? ?? ''),
          CommunitySightingMapButton(sighting: s),
          CommunityEditPhotoButton(sighting: s),
          Text('Coordinate: ${s['lat']}, ${s['lng']}'),
          if (s['approximate'] == 1)
            const Text('Posizione approssimata a circa 1 km.'),
          const Text('Segnalazione pubblicata da un utente, non verificata.'),
          if (s['mine'] != 1)
            TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => RecoveryScreen(sighting: s))), icon: const Icon(Icons.manage_accounts_outlined), label: const Text('Recupera proprietà')),
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
    loadMaps();
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

  String? groupId;
  List<Map<String, dynamic>> privateMaps = [];
  Future<void> loadMaps() async {
    try {
      final d = await CommunityService.instance.api('maps');
      if (mounted)
        setState(
          () => privateMaps = (d['items'] as List)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList(),
        );
    } catch (e) {
      if (mounted)
        setState(
          () => error =
              'Mappe private non caricate: riprova prima di condividere.',
        );
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
        final bytes = await File(photo!.path).readAsBytes();
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        ui.ImageDescriptor? descriptor;
        try {
          descriptor = await ui.ImageDescriptor.encoded(buffer);
          final longest = descriptor.width > descriptor.height
              ? descriptor.width
              : descriptor.height;
          var edge = longest.clamp(1, 1600).toInt();
          while (encoded == null) {
            final width = (descriptor.width * edge / longest)
                .round()
                .clamp(1, 1600)
                .toInt();
            final height = (descriptor.height * edge / longest)
                .round()
                .clamp(1, 1600)
                .toInt();
            final codec = await descriptor.instantiateCodec(
              targetWidth: width,
              targetHeight: height,
            );
            try {
              final frame = await codec.getNextFrame();
              try {
                final data = await frame.image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                if (data == null)
                  throw Exception(
                    'Impossibile elaborare questa foto. Prova un’altra immagine.',
                  );
                if (data.lengthInBytes <= 1000000) {
                  encoded = base64Encode(
                    data.buffer.asUint8List(
                      data.offsetInBytes,
                      data.lengthInBytes,
                    ),
                  );
                }
              } finally {
                frame.image.dispose();
              }
            } finally {
              codec.dispose();
            }
            if (encoded != null) break;
            if (edge <= 256)
              throw Exception(
                'Impossibile preparare questa foto per la condivisione.',
              );
            edge = (edge * 0.8).floor().clamp(256, 1600).toInt();
          }
        } finally {
          descriptor?.dispose();
          buffer.dispose();
        }
      }
      final original = widget.initial;
      final localId = original?.id ?? const Uuid().v4();
      final storedPhoto = await MediaStorageService.instance.persistPhoto(photo?.path, localId);
      final row = Sighting(
        id: localId, species: species, count: n, notes: notes.text.trim(),
        latitude: location!.latitude, longitude: location!.longitude,
        timestamp: observedAt, photoPath: storedPhoto ?? original?.photoPath,
        kind: original?.kind ?? 'Animale', accuracy: accuracy,
        positionSource: original?.positionSource ?? 'manual',
        publicationState: original?.publicationState ?? 'private',
      );
      await DatabaseService.instance.insertSighting(row);
      if (storedPhoto != null) {
        final previous = await DatabaseService.instance.getSightingPhotos(localId);
        await DatabaseService.instance.replaceSightingPhotos(localId, {...previous, storedPhoto}.toList());
      }
      final p = location!;
      await CommunityService.instance.add({
        'id':
            '${localId}${groupId == null ? '' : '-$groupId'}',
        'groupId': groupId,
        'authorName': PreferencesService.instance.nickname,
        'species': species,
        'count': n,
        'notes': notes.text.trim(),
        'lat': p.latitude,
        'lng': p.longitude,
        'observedAt': observedAt.toUtc().toIso8601String(),
        'approximate': approximate,
        'photo': encoded,
      });
      if (mounted) Navigator.pop(context, species);
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
          initialValue: groupId ?? 'public',
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Chi può vedere questa osservazione?',
          ),
          items: [
            const DropdownMenuItem(
              value: 'public',
              child: Text('Comunità pubblica'),
            ),
            for (final m in privateMaps)
              DropdownMenuItem(
                value: m['id'] as String,
                child: Text('Privata: ${m['name']}'),
              ),
          ],
          onChanged: busy
              ? null
              : (v) => setState(() {
                  groupId = v == 'public' ? null : v;
                  consent = false;
                }),
        ),
        TextButton(
          onPressed: loadMaps,
          child: const Text('Aggiorna mappe private'),
        ),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpeciesIcon(a.name, size: 28),
                        const SizedBox(width: 8),
                        Text(a.name),
                      ],
                    ),
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
            onPressed: busy
                ? null
                : () => setState(() {
                    photo = null;
                    error = null;
                  }),
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
          title: Text(
            groupId == null
                ? 'Pubblica per tutti gli utenti'
                : 'Condividi solo nella mappa privata scelta',
          ),
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
  PickedWildFile? attachment;
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
      unawaited(PushService.instance.checkNewSightings());
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
    if ((body.isEmpty && attachment == null) || busy) return;
    setState(() => busy = true);
    if (retryText != body) {
      retryId = const Uuid().v4();
      retryText = body;
    }
    try {
      await CommunityService.instance.api(
        'messages',
        method: 'POST',
        body: {'peer': widget.peer, 'id': retryId, 'body': body, if(attachment != null) 'attachment': {'name':attachment!.name, 'mime':attachment!.mime, 'data':base64Encode(attachment!.bytes)}},
      );
      if (!mounted) return;
      input.clear();
      retryId = null;
      retryText = null;
      setState(() {error = null; attachment = null;});
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
                      color: r['mine'] == 1 ? const Color(0xffc9ddc4) : const Color(0xfff3eadb),
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if(r['attachment'] is Map) ChatAttachment(key: ValueKey(r['id']), id:r['id'] as String, metadata:Map<String,dynamic>.from(r['attachment'] as Map)),
                            if((r['body'] as String? ?? '').isNotEmpty) Text(r['body'] as String, style: const TextStyle(color: Color(0xff183b29))),
                            Text(
                              timeLabel(r['created']),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )),
                    ),
                  ),
              ],
            ),
          ),
          if(attachment != null) ListTile(leading: const Icon(Icons.attach_file), title: Text(attachment!.name), subtitle: Text("${(attachment!.bytes.length / 1024).toStringAsFixed(0)} KB"), trailing: IconButton(tooltip:"Rimuovi allegato", onPressed:busy?null:()=>setState(() {attachment=null; retryId=null; retryText=null;}), icon:const Icon(Icons.close))),
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
                  PopupMenuButton<String>(enabled: !busy, tooltip: 'Invia foto o file', icon: const Icon(Icons.add_circle_outline), onSelected: (value) async {
                    try {
                      PickedWildFile? picked;
                      if(value == 'photo') {
                        final image=await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth:1600, imageQuality:85);
                        if(image != null) {final bytes=await image.readAsBytes(); final mime=bytes.length>8 && bytes[0]==137 && bytes[1]==80 ? 'image/png' : (bytes.length>12 && ascii.decode(bytes.sublist(0,4),allowInvalid:true)=='RIFF' ? 'image/webp' : 'image/jpeg'); picked=PickedWildFile(image.name, mime, bytes);}
                      } else { picked=await PickedWildFile.pick(); }
                      if(picked != null && picked.bytes.length>5*1024*1024) throw Exception('File troppo grande: massimo 5 MB');
                      if(picked != null && mounted) setState(() {attachment=picked; retryId=null; retryText=null;});
                    }catch(e){if(mounted) setState(() => error=e.toString().replaceFirst('Exception: ',''));}
                  }, itemBuilder:(_)=>const [PopupMenuItem(value:'photo',child:Text('Foto dalla galleria')),PopupMenuItem(value:'file',child:Text('File · massimo 5 MB'))]),
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

