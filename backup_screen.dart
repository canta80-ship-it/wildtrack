import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/backup_service.dart';
import '../premium_ui.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupFolderInfo? folder;
  DateTime? lastBackup;
  bool busy = false;
  String? status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final f = await WildTrackBackupService.instance.folderInfo();
    final last = await WildTrackBackupService.instance.lastBackupAt();
    if (!mounted) return;
    setState(() {
      folder = f;
      lastBackup = last;
    });
  }

  Future<void> _choose() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final selected = await WildTrackBackupService.instance.chooseFolder();
      if (!mounted) return;
      setState(() {
        folder = selected;
        status = selected == null ? 'Nessuna cartella selezionata.' : 'Destinazione impostata: ${selected.label}';
      });
    } catch (e) {
      if (mounted) setState(() => status = 'Impossibile selezionare la destinazione: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _backup() async {
    if (busy) return;
    setState(() { busy = true; status = 'Creazione backup…'; });
    try {
      final name = await WildTrackBackupService.instance.backupNow();
      final last = await WildTrackBackupService.instance.lastBackupAt();
      if (mounted) setState(() { lastBackup = last; status = 'Backup completato: $name'; });
    } catch (e) {
      if (mounted) setState(() => status = 'Backup non riuscito: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _restore({bool selectFile = false}) async {
    if (busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ripristinare il backup?'),
        content: const Text('Avvistamenti, uscite, foto, profilo, impostazioni e stato locale delle spedizioni verranno sostituiti con il backup scelto.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ripristina')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() { busy = true; status = 'Ripristino in corso…'; });
    try {
      if (selectFile) {final restored = await WildTrackBackupService.instance.restoreFile();if (!restored) {if (mounted) setState(() => status = 'Selezione annullata.');return;}} else {await WildTrackBackupService.instance.restoreLatest();}
      if (mounted) setState(() => status = 'Ripristino completato. I dati WildTrack sono stati aggiornati.');
    } catch (e) {
      if (mounted) setState(() => status = 'Ripristino non riuscito: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    body: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: WildHero(
        image: 'intro_cervo.jpg',
        height: 255,
        child: SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white)),
              const WildLogo(compact: true, light: true),
            ]),
            const Spacer(),
            const Text('Backup cloud', style: TextStyle(fontFamily: 'serif', fontSize: 38, color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            const Text('I tuoi dati restano tuoi, anche quando cambi APK o telefono.', style: TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        )),
      )),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
        sliver: SliverList(delegate: SliverChildListDelegate([
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              const WildIconDisc(Icons.cloud_outlined, size: 58),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Destinazione', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(folder?.label ?? 'Non configurata', style: const TextStyle(color: WildColors.muted)),
                if (lastBackup != null) ...[
                  const SizedBox(height: 4),
                  Text('Ultimo backup ${DateFormat('dd/MM/yyyy HH:mm').format(lastBackup!)}', style: const TextStyle(fontSize: 10, color: WildColors.muted)),
                ],
              ])),
              TextButton(onPressed: busy ? null : _choose, child: Text(folder == null ? 'Scegli' : 'Cambia')),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(24)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cosa viene salvato', style: WildText.h2),
              SizedBox(height: 9),
              Text('• avvistamenti e coordinate private\n• foto salvate da WildTrack\n• uscite GPS e tracce\n• profilo e nickname\n• impostazioni privacy, notifiche, tema e audio\n• statistiche ricostruibili dai dati\n• spedizioni private e relativa timeline locale', style: TextStyle(height: 1.45, fontSize: 12)),
              SizedBox(height: 10),
              Text('Token temporanei, credenziali e segreti non vengono copiati nel backup.', style: TextStyle(fontSize: 10, color: WildColors.muted)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              WildIconDisc(Icons.autorenew, size: 48),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Backup automatico', style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Dopo aver scelto la cartella, WildTrack crea automaticamente una nuova copia quando sono passate almeno 12 ore. Conserva le ultime 5 versioni.', style: TextStyle(fontSize: 11, color: WildColors.muted, height: 1.3)),
              ])),
            ]),
          ),
          const SizedBox(height: 14),
          WildPrimaryButton(label: busy ? 'Operazione in corso…' : 'Backup adesso', icon: Icons.cloud_upload_outlined, onPressed: busy || folder == null ? null : _backup),
          const SizedBox(height: 9),
          WildOutlineButton(label: 'Ripristina ultimo backup', icon: Icons.restore, onPressed: busy || folder == null ? null : () => _restore()),
          const SizedBox(height: 9),
          WildOutlineButton(label: 'Scegli file da ripristinare', icon: Icons.folder_open_outlined, onPressed: busy ? null : () => _restore(selectFile: true)),
          const Text('Se la cartella cloud non è accessibile, scegli direttamente il file .wildtrack. Se il permesso è scaduto, seleziona nuovamente la cartella.'),
          if (status != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFF3E9DB), borderRadius: BorderRadius.circular(18)), child: Text(status!, style: const TextStyle(fontSize: 11))),
          ],
        ])),
      ),
    ]),
  );
}
