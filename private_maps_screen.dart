import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/community_service.dart';
import '../services/preferences_service.dart';
import 'community_screen.dart';

class PrivateMapsScreen extends StatefulWidget {
  const PrivateMapsScreen({super.key});
  @override
  State<PrivateMapsScreen> createState() => _PrivateMapsScreenState();
}

class _PrivateMapsScreenState extends State<PrivateMapsScreen> {
  List<Map<String, dynamic>> maps = [], members = [];
  String? error;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final d = await CommunityService.instance.api('maps');
      if (mounted)
        setState(() {
          maps = (d['items'] as List)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList();
          members = (d['members'] as List)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList();
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String?> input(String title, String hint) async {
    final t = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: t,
          decoration: InputDecoration(labelText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, t.text.trim()),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
    return r;
  }

  Future<void> action(Map<String, dynamic> b) async {
    try {
      final d = await CommunityService.instance.api(
        'maps',
        method: 'POST',
        body: b,
      );
      if (!mounted) return;
      if (d['code'] != null) {
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Invito personale'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Valido 24 ore, utilizzabile una sola volta. Invia questo codice alla persona scelta; dovrai poi approvare la sua richiesta.',
                ),
                SelectableText(d['code'] as String),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: d['code'] as String),
                  );
                  if (c.mounted) message(c, 'Codice copiato');
                },
                child: const Text('Copia'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Chiudi'),
              ),
            ],
          ),
        );
      } else if (d['pending'] == true) {
        message(context, 'Richiesta inviata. Il proprietario deve approvarti.');
      }
      await load();
      await CommunityService.instance.refresh();
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mappe private'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Condividi osservazioni solo con le persone che approvi. Le mappe private non compaiono nella comunità pubblica.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () async {
                final n = await input('Crea mappa privata', 'Nome della mappa');
                if (n != null && n.isNotEmpty)
                  await action({'action': 'create', 'name': n});
              },
              icon: const Icon(Icons.add),
              label: const Text('Crea mappa'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final code = await input('Chiedi accesso', 'Codice ricevuto');
                if (code != null && code.isNotEmpty)
                  await action({
                    'action': 'join',
                    'code': code,
                    'nickname': PreferencesService.instance.nickname,
                  });
              },
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('Usa invito'),
            ),
          ],
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null) Text(error!),
        for (final m in maps)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['name'] as String,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    m['mine'] == 1
                        ? 'Sei il proprietario'
                        : 'Sei un membro approvato',
                  ),
                  if (m['mine'] == 1) ...[
                    TextButton.icon(
                      onPressed: () =>
                          action({'action': 'invite', 'mapId': m['id']}),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Crea invito personale'),
                    ),
                    TextButton(
                      onPressed: () =>
                          action({'action': 'revokeInvites', 'mapId': m['id']}),
                      child: const Text('Annulla inviti non usati'),
                    ),
                    for (final p in members.where((p) => p['mapId'] == m['id']))
                      ListTile(
                        title: Text(p['nickname'] as String),
                        subtitle: Text(
                          p['approved'] == 1
                              ? 'Accesso consentito'
                              : 'In attesa: verifica chi ti ha chiesto accesso',
                        ),
                        trailing: Wrap(
                          children: [
                            if (p['approved'] != 1)
                              IconButton(
                                tooltip: 'Approva',
                                onPressed: () => action({
                                  'action': 'approve',
                                  'mapId': m['id'],
                                  'memberId': p['id'],
                                }),
                                icon: const Icon(Icons.check),
                              ),
                            IconButton(
                              tooltip: 'Revoca accesso',
                              onPressed: () => action({
                                'action': 'remove',
                                'mapId': m['id'],
                                'memberId': p['id'],
                              }),
                              icon: const Icon(Icons.person_remove_outlined),
                            ),
                          ],
                        ),
                      ),
                  ] else
                    TextButton(
                      onPressed: () =>
                          action({'action': 'leave', 'mapId': m['id']}),
                      child: const Text('Esci dalla mappa'),
                    ),
                  const Text(
                    'Per aggiungere un’osservazione: salvala nel Taccuino, scegli Condividi e seleziona questa mappa.',
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
