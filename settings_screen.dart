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
  final nickname = TextEditingController(
    text: PreferencesService.instance.nickname,
  );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impostazioni non salvate. Riprova.')),
        );
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
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Aspetto',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<ThemeMode>(
            initialValue: p.theme,
            decoration: const InputDecoration(labelText: 'Tema'),
            items: const [
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Verde militare chiaro'),
              ),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Scuro')),
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('Come il telefono'),
              ),
            ],
            onChanged: saving
                ? null
                : (v) async {
                    p.theme = v!;
                    await save();
                  },
          ),
          const SizedBox(height: 24),
          const Text(
            'Versi degli animali',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: p.soundPanel,
            onChanged: saving
                ? null
                : (v) async {
                    p.soundPanel = v;
                    if (!v) await AudioService.instance.stop();
                    await save();
                    if (mounted) setState(() {});
                  },
            title: const Text('Mostra pannello versi sulla mappa'),
          ),
          DropdownButtonFormField<int>(
            initialValue: p.repeats,
            decoration: const InputDecoration(
              labelText: 'Ripetizioni per avvio',
            ),
            items: [
              for (int n = 1; n <= 5; n++)
                DropdownMenuItem(
                  value: n,
                  child: Text('$n ${n == 1 ? 'volta' : 'volte'}'),
                ),
            ],
            onChanged: saving
                ? null
                : (v) async {
                    await AudioService.instance.stop();
                    p.repeats = v!;
                    await save();
                  },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'L’audio segue l’uscita Android: cuffie quando collegate, altrimenti altoparlante. Massimo 5 ripetizioni, mai in ciclo continuo. Scollegando le cuffie l’audio si ferma; puoi riavviarlo dall’altoparlante. Evita di usare i versi per attirare la fauna.',
            ),
          ),
          const Divider(),
          const Text(
            'Persone vicine',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: nickname,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Il tuo nickname'),
          ),
          OutlinedButton(
            onPressed: saving
                ? null
                : () async {
                    if (nickname.text.trim().length < 2) return;
                    p.nickname = nickname.text.trim();
                    await save();
                    await CommunityService.instance.updatePresence();
                  },
            child: const Text('Salva nickname'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: p.visible,
            title: const Text('Condividi la mia posizione'),
            subtitle: const Text(
              'Visibile alle persone entro 5 km che condividono a loro volta la posizione.',
            ),
            onChanged: saving
                ? null
                : (v) async {
                    if (v) {
                      if (nickname.text.trim().length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Inserisci un nickname di almeno 2 caratteri.',
                            ),
                          ),
                        );
                        return;
                      }
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Renderti visibile sulla mappa?'),
                          content: const Text(
                            'Condividerai nickname e posizione precisa con altri utenti entro 5 km. Potranno scriverti. Aggiornamento mentre l’app è aperta; la posizione scade dopo 3 minuti senza aggiornamenti. Puoi disattivare tutto qui.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Annulla'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Attiva'),
                            ),
                          ],
                        ),
                      );
                      if (yes != true) return;
                      p.nickname = nickname.text.trim();
                    }
                    p.visible = v;
                    await save();
                    if (v) {
                      await CommunityService.instance.updatePresence();
                    } else {
                      await CommunityService.instance.hide();
                    }
                    if (mounted) setState(() {});
                  },
          ),
          const Text(
            'Le posizioni non sono tracciati: viene conservata solo l’ultima posizione condivisa. Chiudendo l’app viene richiesta la rimozione; senza rete scade entro 3 minuti. La chat non è un canale di soccorso e non invia notifiche a app chiusa.',
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Guida sul campo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const GuideScreen()),
            ),
          ),
          const Text(
            'WildTrack 0.2 · Catalogo e guida disponibili offline; mappe, foto, versi e comunità richiedono connessione.',
          ),
        ],
      ),
    );
  }
}
