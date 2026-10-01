import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../services/community_service.dart';
import '../services/push_service.dart';
import 'species_screen.dart';
import 'guide_screen.dart';
import '../premium_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final nickname = TextEditingController(text: PreferencesService.instance.nickname);
  bool saving = false;

  @override
  void dispose() { nickname.dispose(); super.dispose(); }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await PreferencesService.instance.save();
      await PushService.instance.syncPreferences();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impostazioni non salvate. Riprova.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PreferencesService.instance;
    return Scaffold(
      backgroundColor: WildColors.ivory,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: SizedBox(height: 315, child: Stack(fit: StackFit.expand, children: [
          const WildLandscape(height: 315),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x22FFFFFF), Color(0xB8F8F6EF), WildColors.ivory], stops: [0, .58, 1]))),
          SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: WildColors.forest)), const WildLogo(compact: true)]),
            const Spacer(),
            const Text('Privacy e\npermessi', style: TextStyle(fontFamily: 'serif', fontSize: 42, height: .92, fontWeight: FontWeight.w700, color: WildColors.forest)),
            const SizedBox(height: 10),
            const SizedBox(width: 300, child: Text('Per offrirti la migliore esperienza e contribuire alla tutela della fauna selvatica, abbiamo bisogno di alcuni permessi.', style: TextStyle(fontSize: 16, height: 1.25, color: WildColors.muted))),
          ]))),
        ]))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _PermissionCard(icon: Icons.location_on, title: 'Posizione precisa', body: 'Ci permette di mostrarti specie, sentieri e avvistamenti vicino a te.', tint: WildColors.sageSoft, trailing: Switch(value: true, onChanged: (_) {}), foot: 'Usata solo durante l’app'),
            const SizedBox(height: 10),
            _PermissionCard(icon: Icons.notifications, title: 'Notifiche', body: 'Ricevi avvisi su specie di interesse, nuovi avvistamenti e messaggi.', tint: const Color(0xFFF5EADB), trailing: Switch(value: p.chatNotifications || p.sightingNotifications, onChanged: saving ? null : (v) async { p.chatNotifications = v; p.sightingNotifications = v; await save(); })),
            const SizedBox(height: 10),
            _PermissionCard(icon: Icons.camera_alt, title: 'Fotocamera e foto', body: 'Ti consente di scattare foto degli avvistamenti e caricarle nel tuo diario personale.', tint: WildColors.sageSoft, trailing: Switch(value: true, onChanged: (_) {})),
            const SizedBox(height: 10),
            _PermissionCard(icon: Icons.navigation, title: 'Posizione in background', body: 'Migliora il tracciamento delle tue uscite, anche quando l’app è chiusa.', tint: const Color(0xFFF5EADB), foot: 'Usata solo durante le uscite', trailing: OutlinedButton(onPressed: saving ? null : () async { p.backgroundSharing = !p.backgroundSharing; await CommunityService.instance.configureBackgroundSharing(); await save(); }, child: const Text('Attiva'))),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(24)),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                WildIconDisc(Icons.eco_outlined, size: 64, background: WildColors.forest, foreground: Colors.white),
                SizedBox(width: 15),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('I tuoi dati restano tuoi', style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('WildTrack raccoglie solo i dati necessari per funzionare. Le posizioni sensibili della fauna vengono protette e non vengono mai mostrate pubblicamente con precisione completa.', style: TextStyle(height: 1.25, color: WildColors.muted)),
                  SizedBox(height: 9),
                  Row(children: [Icon(Icons.lock_outline, size: 16, color: WildColors.forest), SizedBox(width: 6), Text('Scopri di più sulla nostra privacy', style: TextStyle(fontWeight: FontWeight.w700, color: WildColors.forest))]),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Notifiche', style: WildText.h2),
            const SizedBox(height: 8),
            _ToggleTile(title: 'Messaggi chat', subtitle: 'Attive di default, disattivabili in qualsiasi momento.', value: p.chatNotifications, onChanged: saving ? null : (v) async { p.chatNotifications = v; await save(); }),
            _ToggleTile(title: 'Nuovi avvistamenti', subtitle: 'Avvisi per nuovi inserimenti della community.', value: p.sightingNotifications, onChanged: saving ? null : (v) async { p.sightingNotifications = v; await save(); }),
            const SizedBox(height: 14),
            const Text('Modalità sul campo', style: WildText.h2),
            const SizedBox(height: 8),
            _ToggleTile(title: 'Silenzio sul campo', subtitle: 'Riduce distrazioni e disattiva il pannello versi.', value: p.fieldSilence, onChanged: saving ? null : (v) async { p.fieldSilence = v; if (v) { p.soundPanel = false; await AudioService.instance.stop(); } await save(); }),
            const SizedBox(height: 14),
            const Text('Identità e persone vicine', style: WildText.h2),
            const SizedBox(height: 8),
            TextField(controller: nickname, maxLength: 30, decoration: const InputDecoration(labelText: 'Nickname')),
            WildOutlineButton(label: 'Salva nickname', onPressed: saving ? null : () async { if (nickname.text.trim().length < 2) return; p.nickname = nickname.text.trim(); await save(); await CommunityService.instance.updatePresence(); }),
            const SizedBox(height: 8),
            _ToggleTile(title: 'Condividi la mia posizione', subtitle: 'Visibile alle persone entro 5 km che condividono a loro volta la posizione.', value: p.visible, onChanged: saving ? null : (v) async { if (v && nickname.text.trim().length < 2) return; if (v) p.nickname = nickname.text.trim(); p.visible = v; await save(); if (v) { await CommunityService.instance.configureBackgroundSharing(); await CommunityService.instance.updatePresence(); } else { await CommunityService.instance.hide(); } }),
            const SizedBox(height: 14),
            ListTile(contentPadding: EdgeInsets.zero, leading: const WildIconDisc(Icons.menu_book_outlined), title: const Text('Guida sul campo', style: TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const GuideScreen()))),
            const SizedBox(height: 16),
            WildPrimaryButton(label: 'Continua', icon: Icons.arrow_forward, onPressed: () => Navigator.pop(context)),
            TextButton(onPressed: () => Navigator.pop(context), child: const Center(child: Text('Configura dopo', style: TextStyle(color: WildColors.forest, fontWeight: FontWeight.w700)))),
          ])),
        ),
      ]),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.icon, required this.title, required this.body, required this.tint, required this.trailing, this.foot});
  final IconData icon; final String title; final String body; final Color tint; final Widget trailing; final String? foot;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      WildIconDisc(icon, size: 62, background: Colors.white.withValues(alpha: .65), foreground: WildColors.forest),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3), Text(body, style: const TextStyle(color: WildColors.muted, height: 1.25)),
        if (foot != null) ...[const SizedBox(height: 7), Text(foot!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: WildColors.forest))],
      ])),
      const SizedBox(width: 8), trailing,
    ]),
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title; final String subtitle; final bool value; final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: SwitchListTile(value: value, onChanged: onChanged, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: WildColors.muted))),
  );
}
