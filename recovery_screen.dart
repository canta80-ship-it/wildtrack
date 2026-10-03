import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/community_service.dart';
import '../services/preferences_service.dart';
typedef RecoveryApi = Future<Map<String, dynamic>> Function(String path, String method, Map<String, dynamic>? body);
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, this.sighting, this.api});
  final Map<String, dynamic>? sighting;
  final RecoveryApi? api;
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}
class _RecoveryScreenState extends State<RecoveryScreen> {
  final form = GlobalKey<FormState>();
  final previousName = TextEditingController(), evidence = TextEditingController(), code = TextEditingController();
  List<Map<String, dynamic>> requests = [];
  String? error;
  bool loading = true, busy = false, activeCode = false, sent = false;
  Future<Map<String, dynamic>> api(String path, {String method = 'GET', Map<String, dynamic>? body}) => widget.api != null ? widget.api!(path, method, body) : CommunityService.instance.api(path, method: method, body: body);
  @override
  void initState() {super.initState();previousName.text = PreferencesService.instance.nickname;load();}
  @override
  void dispose() {previousName.dispose();evidence.dispose();code.dispose();super.dispose();}
  Future<void> load() async {
    try {final result = await api('recovery');final protection = await api('recovery-code');if (!mounted) return;setState(() {requests = (result['items'] as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();activeCode = protection['active'] == true;error = null;loading = false;});}
    catch (e) {if (mounted) setState(() {error = e.toString();loading = false;});}
  }
  Future<void> send() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();setState(() {busy = true;error = null;});
    try {
      if (widget.api == null) await CommunityService.instance.syncProfile();
      await api('recovery', method: 'POST', body: {'sightingId': widget.sighting!['id'], 'previousName': previousName.text.trim().isEmpty ? 'Non ricordo' : previousName.text.trim(), 'evidence': evidence.text.trim()});
      if (!mounted) return;setState(() => sent = true);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Richiesta inviata. Il gestore può ora verificarla.')));await load();
    } catch (e) {if (mounted) setState(() => error = e.toString());}
    finally {if (mounted) setState(() => busy = false);}
  }
  Future<bool> confirm(String title, String text) async => await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(title), content: Text(text), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Continua'))])) == true;
  Future<void> createCode() async {
    if (activeCode && !await confirm('Generare un nuovo codice?', 'Il codice salvato in precedenza non funzionerà più.')) return;
    setState(() {busy = true;error = null;});
    try {final data = await api('recovery-code', method: 'POST', body: {'action': 'create'});if (!mounted) return;setState(() => activeCode = true);final value = data['code'] as String;
      await showDialog<void>(context: context, barrierDismissible: false, builder: (c) => AlertDialog(title: const Text('Salva il codice personale'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Conservalo fuori dall’app, ad esempio nel gestore delle password. Chi possiede questo codice può accedere ai tuoi avvistamenti Community. Il codice viene mostrato soltanto adesso.'), const SizedBox(height: 16), SelectableText(value)])), actions: [TextButton(onPressed: () async {await Clipboard.setData(ClipboardData(text: value));if (c.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codice copiato. Salvalo in un luogo sicuro.')));}, child: const Text('Copia codice')), FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Ho salvato il codice'))]));
    } catch (e) {if (mounted) setState(() => error = e.toString());}
    finally {if (mounted) setState(() => busy = false);}
  }
  Future<void> restore({bool undo = false}) async {
    final clean = code.text.replaceAll(RegExp(r'[\s-]'), '').toLowerCase();
    if (!undo && !RegExp(r'^[a-f0-9]{64}$').hasMatch(clean)) {setState(() => error = 'Incolla il codice personale completo di 64 caratteri.');return;}
    if (!await confirm('Ripristinare l’identità Community?', 'Recupererai i post, i gruppi e le chat dell’identità associata al codice. L’identità attuale rimane conservata sul telefono: potrai tornarci con il pulsante dedicato. Il diario locale non viene cancellato.')) return;
    setState(() {busy = true;error = null;});
    try {await CommunityService.instance.restoreCommunityIdentity(code: clean, undo: undo);code.clear();await load();if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identità recuperata. Avvistamenti aggiornati.')));}
    catch (e) {if (mounted) setState(() => error = e.toString());}
    finally {if (mounted) setState(() => busy = false);}
  }
  Future<void> revoke() async {
    if (!await confirm('Revocare il codice?', 'Il codice attuale non consentirà più il recupero. Potrai generarne uno nuovo.')) return;
    setState(() {busy = true;error = null;});
    try {await api('recovery-code', method: 'DELETE');if (mounted) setState(() => activeCode = false);}
    catch (e) {if (mounted) setState(() => error = e.toString());}
    finally {if (mounted) setState(() => busy = false);}
  }
  String status(dynamic value) => switch (value) {'approved' => 'Approvata: ora puoi gestire l’avvistamento', 'rejected' => 'Non approvata', _ => 'In attesa di verifica del gestore'};
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Recupero Community')), body: RefreshIndicator(onRefresh: () async {await load();if (widget.api == null) await CommunityService.instance.refresh();}, child: ListView(padding: const EdgeInsets.all(20), children: [
    if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, semanticsLabel: error, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    Text('Recupero con codice personale', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    const Text('Con un codice già salvato recuperi l’identità e i tuoi post condivisi senza backup e senza approvazione. Non ripristina foto o avvistamenti rimasti soltanto sul vecchio telefono.'),
    TextField(controller: code, autocorrect: false, enableSuggestions: false, maxLength: 100, decoration: const InputDecoration(labelText: 'Incolla il codice personale')),
    FilledButton(onPressed: busy ? null : () => restore(), child: const Text('Recupera con codice')),
    if (PreferencesService.instance.previousCommunityToken != null) TextButton(onPressed: busy ? null : () => restore(undo: true), child: const Text('Torna all’identità precedente')),
    const SizedBox(height: 20),
    Text('Proteggi gli avvistamenti attuali', style: Theme.of(context).textTheme.titleMedium),
    Text(activeCode ? 'Codice di recupero attivo.' : 'Nessun codice ancora predisposto per questa identità.'),
    OutlinedButton(onPressed: busy ? null : createCode, child: Text(activeCode ? 'Genera un nuovo codice' : 'Genera e salva il mio codice')),
    if (activeCode) TextButton(onPressed: busy ? null : revoke, child: const Text('Revoca codice attuale')),
    const Divider(height: 32),
    Text('Vecchi post senza codice', style: Theme.of(context).textTheme.titleLarge),
    const Text('Se hai perso l’identità originale e non avevi salvato un codice, serve una verifica del gestore. Il codice generato ora protegge l’identità attuale e non prova la proprietà di vecchi post scollegati.'),
    if (widget.sighting != null) Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12), Text('Avvistamento: ${widget.sighting!['species']}', style: Theme.of(context).textTheme.titleMedium),
      TextFormField(controller: previousName, maxLength: 40, decoration: const InputDecoration(labelText: 'Vecchio nome, se lo ricordi', helperText: 'Puoi lasciarlo vuoto. Il nome da solo non prova la proprietà.')),
      TextFormField(controller: evidence, minLines: 3, maxLines: 6, maxLength: 2000, validator: (v) => (v?.trim().length ?? 0) < 10 ? 'Descrivi la prova con almeno 10 caratteri.' : null, decoration: const InputDecoration(labelText: 'Come possiamo verificare che sia tuo?', helperText: 'Esempio: conservo la foto originale e posso mostrarla. Non inserire password.', helperMaxLines: 3)),
      FilledButton(onPressed: busy || sent ? null : send, child: Text(sent ? 'Richiesta inviata' : busy ? 'Invio…' : 'Invia richiesta al gestore')),
    ])) else const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Apri il vecchio post nella Community e scegli “Recupera proprietà” per inviare una richiesta.')),
    const SizedBox(height: 24), Text('Le tue richieste', style: Theme.of(context).textTheme.titleLarge),
    if (loading) const Center(child: CircularProgressIndicator()),
    if (!loading && requests.isEmpty) const Text('Nessuna richiesta inviata.'),
    for (final r in requests) Card(child: ListTile(title: Text('${r['species'] ?? 'Avvistamento'}'), subtitle: Text('${status(r['status'])}${r['decision'] == null ? '' : '\n${r['decision']}'}'))),
    TextButton.icon(onPressed: busy ? null : () async {await load();if (widget.api == null) await CommunityService.instance.refresh();}, icon: const Icon(Icons.refresh), label: const Text('Aggiorna richieste e avvistamenti')),
    TextButton.icon(onPressed: () async {final opened = await launchUrl(Uri.parse('$communityUrl/recovery'), mode: LaunchMode.externalApplication);if (!opened && mounted) setState(() => error = 'Apri il pannello da wildtrack-community.canta80.chatgpt.site/recovery');}, icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Pannello del gestore (web)')),
    const Text('Il pannello richiede l’accesso con l’account ChatGPT del proprietario del progetto.'),
  ])));
}
