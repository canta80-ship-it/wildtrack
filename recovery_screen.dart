import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../services/preferences_service.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, this.sighting});
  final Map<String, dynamic>? sighting;
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}
class _RecoveryScreenState extends State<RecoveryScreen> {
  final previousName = TextEditingController();
  final evidence = TextEditingController();
  List<Map<String, dynamic>> requests = [];
  String? error;
  bool loading = true, sending = false;
  @override
  void initState() {super.initState(); previousName.text = PreferencesService.instance.nickname; load();}
  @override
  void dispose() {previousName.dispose(); evidence.dispose(); super.dispose();}
  Future<void> load() async {
    try {final result = await CommunityService.instance.api('recovery'); if (!mounted) return; setState(() {requests = (result['items'] as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();error = null;loading = false;});}
    catch (e) {if (mounted) setState(() {error = e.toString();loading = false;});}
  }
  Future<void> send() async {
    if (sending || previousName.text.trim().length < 2 || evidence.text.trim().length < 30) return;
    setState(() {sending = true;error = null;});
    try {await CommunityService.instance.syncProfile();await CommunityService.instance.api('recovery', method: 'POST', body: {'sightingId': widget.sighting!['id'], 'previousName': previousName.text.trim(), 'evidence': evidence.text.trim()});if (!mounted) return;ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Richiesta inviata al gestore per la verifica.')));await load();}
    catch (e) {if (mounted) setState(() => error = e.toString());}
    finally {if (mounted) setState(() => sending = false);}
  }
  String status(dynamic value) => switch (value) {'approved' => 'Approvata: ora puoi gestire l’avvistamento', 'rejected' => 'Non approvata', _ => 'In attesa di verifica'};
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recupero avvistamenti')),
    body: RefreshIndicator(onRefresh: () async {await load();await CommunityService.instance.refresh();}, child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Puoi richiedere la proprietà anche senza un backup. Il gestore deve verificare che l’avvistamento sia tuo prima di assegnarlo a questo account.'),
      const SizedBox(height: 12),
      if (widget.sighting != null) ...[
        Text('Avvistamento: ${widget.sighting!['species']}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Indica il vecchio nome e come verificare la tua proprietà: ad esempio disponibilità del file fotografico originale o dettagli non pubblicati. Il solo nome o la foto scaricata dal post non sono sufficienti. Non inserire password.'),
        TextField(controller: previousName, maxLength: 40, decoration: const InputDecoration(labelText: 'Nome usato in precedenza')),
        TextField(controller: evidence, minLines: 4, maxLines: 8, maxLength: 2000, decoration: const InputDecoration(labelText: 'Informazioni per la verifica', helperText: 'Almeno 30 caratteri. Visibili soltanto al gestore.')),
        FilledButton(onPressed: sending ? null : send, child: Text(sending ? 'Invio…' : 'Richiedi recupero proprietà')),
      ] else ...[
        const SizedBox(height: 12),
        const Text('Per iniziare, apri il tuo vecchio post nella Community o sulla mappa e scegli “Recupera proprietà”.'),
      ],
      const SizedBox(height: 24),
      Text('Le tue richieste', style: Theme.of(context).textTheme.titleLarge),
      if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      if (loading) const Center(child: CircularProgressIndicator()),
      if (!loading && requests.isEmpty) const Text('Nessuna richiesta inviata.'),
      for (final r in requests) Card(child: ListTile(title: Text('${r['species'] ?? 'Avvistamento'}'), subtitle: Text('${status(r['status'])}${r['decision'] == null ? '' : '\n${r['decision']}'}'))),
      TextButton.icon(onPressed: () async {await load();await CommunityService.instance.refresh();}, icon: const Icon(Icons.refresh), label: const Text('Aggiorna richieste e avvistamenti')),
    ])),
  );
}
