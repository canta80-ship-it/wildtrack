import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../services/community_service.dart';
import 'species_screen.dart';
import 'guide_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final nickname = TextEditingController(text: PreferencesService.instance.nickname);
  bool saving = false;

  @override
  void dispose() {
    nickname.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await PreferencesService.instance.save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impostazioni non salvate. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PreferencesService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _section(
            'Privacy prima di tutto',
            'WildTrack conserva sul dispositivo ciò che può restare locale. Non usa advertising ID, non vende dati e non richiede nome reale o telefono.',
            Icons.shield_outlined,
          ),
          const SizedBox(height: 18),
          const _Title('Notifiche'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: p.chatNotifications,
            title: const Text('Messaggi chat'),
            subtitle: const Text('Attive di default. Puoi disattivarle in qualsiasi momento.'),
            onChanged: saving ? null : (v) async { p.chatNotifications = v; await save(); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: p.sightingNotifications,
            title: const Text('Nuovi avvistamenti'),
            subtitle: const Text('Avvisi per nuovi inserimenti della community. Attivi di default.'),
            onChanged: saving ? null : (v) async { p.sightingNotifications = v; await save(); },
          ),
          const Text('Le preferenze sono già operative nell’app. Le notifiche push a app completamente chiusa richiedono il servizio push server della Community.', style: TextStyle(fontSize: 12, color: Color(0xFF657064))),
          const SizedBox(height: 22),
          const _Title('Modalità sul campo'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: p.fieldSilence,
            title: const Text('Silenzio sul campo'),
            subtitle: const Text('Riduce distrazioni e disattiva il pannello versi mentre osservi la fauna.'),
            onChanged: saving ? null : (v) async {
              p.fieldSilence = v;
              if (v) {
                p.soundPanel = false;
                await AudioService.instance.stop();
              }
              await save();
            },
          ),
          const SizedBox(height: 22),
          const _Title('Aspetto'),
          DropdownButtonFormField<ThemeMode>(
            initialValue: p.theme,
            decoration: const InputDecoration(labelText: 'Tema'),
            items: const [
              DropdownMenuItem(value: ThemeMode.light, child: Text('Naturale chiaro')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Scuro')),
              DropdownMenuItem(value: ThemeMode.system, child: Text('Come il telefono')),
            ],
            onChanged: saving ? null : (v) async { p.theme = v!; await save(); },
          ),
          const SizedBox(height: 22),
          const _Title('Versi degli animali'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: p.soundPanel,
            onChanged: saving || p.fieldSilence ? null : (v) async {
              p.soundPanel = v;
              if (!v) await AudioService.instance.stop();
              await save();
            },
            title: const Text('Mostra pannello versi sulla mappa'),
            subtitle: p.fieldSilence ? const Text('Disattivato dalla modalità Silenzio sul campo') : null,
          ),
          DropdownButtonFormField<int>(
            initialValue: p.repeats,
            decoration: const InputDecoration(labelText: 'Ripetizioni per avvio'),
            items: [for (int n = 1; n <= 5; n++) DropdownMenuItem(value: n, child: Text('$n ${n == 1 ? 'volta' : 'volte'}'))],
            onChanged: saving ? null : (v) async { await AudioService.instance.stop(); p.repeats = v!; await save(); },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Massimo 5 ripetizioni, mai in ciclo continuo. Evita di usare richiami per attirare la fauna.', style: TextStyle(fontSize: 12, color: Color(0xFF657064))),
          ),
          const SizedBox(height: 14),
          const _Title('Identità e persone vicine'),
          TextField(controller: nickname, maxLength: 30, decoration: const InputDecoration(labelText: 'Nickname')),
          OutlinedButton(
            onPressed: saving ? null : () async {
              if (nickname.text.trim().length < 2) return;
              p.nickname = nickname.text.trim();
              await save();
              await CommunityService.instance.updatePresence();
            },
            child: const Text('Salva nickname'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: p.visible,
            title: const Text('Condividi la mia posizione'),
            subtitle: const Text('Visibile alle persone entro 5 km che condividono a loro volta la posizione.'),
            onChanged: saving ? null : (v) async {
              if (v && nickname.text.trim().length < 2) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inserisci prima un nickname di almeno 2 caratteri.')));
                return;
              }
              if (v) p.nickname = nickname.text.trim();
              p.visible = v;
              await save();
              if (v) {
                await CommunityService.instance.configureBackgroundSharing();
                await CommunityService.instance.updatePresence();
              } else {
                await CommunityService.instance.hide();
              }
              if (mounted) setState(() {});
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: p.backgroundSharing,
            title: const Text('Condividi anche a schermo spento'),
            subtitle: const Text('Solo durante la condivisione esplicita. Consuma più batteria e richiede rete.'),
            onChanged: saving ? null : (v) async {
              final old = p.backgroundSharing;
              p.backgroundSharing = v;
              try {
                await CommunityService.instance.configureBackgroundSharing();
                await save();
              } catch (e) {
                p.backgroundSharing = old;
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
          ),
          const SizedBox(height: 22),
          _section(
            'Dati raccolti',
            'Account pseudonimo, token tecnico, impostazioni e dati necessari alla sincronizzazione. Avvistamenti e percorsi restano locali finché non scegli di condividerli. Nessuna profilazione pubblicitaria.',
            Icons.lock_outline,
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Guida sul campo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const GuideScreen())),
          ),
          const Text('WildTrack · Taccuino, foto, catalogo e guida disponibili offline. Cartografia, versi online e sincronizzazione richiedono rete.', style: TextStyle(fontSize: 12, color: Color(0xFF657064))),
        ],
      ),
    );
  }

  Widget _section(String title, String body, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFDDE8DA), borderRadius: BorderRadius.circular(20)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: const Color(0xFF254D38)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 5),
        Text(body, style: const TextStyle(height: 1.35)),
      ])),
    ]),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
  );
}
