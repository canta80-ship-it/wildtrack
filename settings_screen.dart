import 'recovery_screen.dart';
import '../services/photo_processing_service.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../services/community_service.dart';
import '../services/push_service.dart';
import 'backup_screen.dart';
import 'intro_screen.dart';
import '../main.dart' show HomeShell;
import 'species_screen.dart';
import 'guide_screen.dart';
import '../premium_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool pendingBackgroundEnable = false;
  final nickname = TextEditingController(
    text: PreferencesService.instance.nickname,
  );
  bool saving = false;
  bool locationAllowed = false;
  bool cameraAllowed = false;
  bool notificationsAllowed = false;
  bool backgroundAllowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    nickname.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final location = await Permission.locationWhenInUse.status;
    final camera = await Permission.camera.status;
    final notifications = await Permission.notification.status;
    final background = await Permission.locationAlways.status;
    if (!mounted) return;
    if (pendingBackgroundEnable && background.isGranted) {
      pendingBackgroundEnable = false;
      PreferencesService.instance.backgroundSharing = true;
      await PreferencesService.instance.save();
      await CommunityService.instance.configureBackgroundSharing();
      if (!mounted) return;
    }
    setState(() {
      locationAllowed = location.isGranted || location.isLimited;
      cameraAllowed = camera.isGranted || camera.isLimited;
      notificationsAllowed = notifications.isGranted || notifications.isLimited;
      backgroundAllowed = background.isGranted;
    });
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await PreferencesService.instance.save();
      await PushService.instance.syncPreferences();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impostazioni non salvate. Riprova.')),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _profilePhoto({bool remove = false}) async {
    if (saving) return;
    final p = PreferencesService.instance;
    String? encoded;
    try {
      if (!remove) {
        final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
        if (picked == null) return;
        encoded = await PhotoProcessingService.encode(await picked.readAsBytes(), avatar: true);
      }
      if (!mounted) return;
      setState(() => saving = true);
      p.avatarBase64 = encoded;
      await p.save();
      try {await CommunityService.instance.syncProfile();await CommunityService.instance.refresh();if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(remove ? 'Foto profilo rimossa' : 'Foto profilo aggiornata')));} catch (_) {if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto salvata sul telefono. Verrà sincronizzata al ritorno della connessione.')));}
    } catch (e) {if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto non salvata: $e')));} finally {if (mounted) setState(() => saving = false);}
  }

  Future<void> _permissionToggle(Permission permission, bool enable) async {
    if (enable) {
      final result = await permission.request();
      if (result.isPermanentlyDenied) await openAppSettings();
    } else {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Modifica permesso Android'),
          content: const Text(
            'Android non consente a WildTrack di revocare autonomamente un permesso già concesso. Apri le impostazioni di sistema per modificarlo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                openAppSettings();
              },
              child: const Text('Apri impostazioni'),
            ),
          ],
        ),
      );
    }
    await _refreshPermissions();
  }

  Future<void> _toggleNotifications(bool value) async {
    final p = PreferencesService.instance;
    if (value) {
      final status = await Permission.notification.request();
      if (!status.isGranted && status.isPermanentlyDenied)
        await openAppSettings();
      p.chatNotifications = status.isGranted;
      p.sightingNotifications = status.isGranted;
    } else {
      p.chatNotifications = false;
      p.sightingNotifications = false;
    }
    await save();
    await _refreshPermissions();
  }

  Future<void> _toggleBackground(bool value) async {
    final p = PreferencesService.instance;
    if (!value) {
      pendingBackgroundEnable = false;
      p.backgroundSharing = false;
      await p.save();
      await CommunityService.instance.configureBackgroundSharing();
      await _refreshPermissions();
      return;
    }
    final foreground = await Permission.locationWhenInUse.request();
    if (!foreground.isGranted) {
      if (foreground.isPermanentlyDenied) await openAppSettings();
      await _refreshPermissions();
      return;
    }
    if (!mounted) return;
    if (!await Permission.locationAlways.isGranted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('GPS a schermo spento'),
          content: const Text(
            'Per autorizzare la posizione in background, scegli “Consenti sempre” nelle impostazioni Android della posizione. Attiva anche la posizione precisa. Puoi continuare a usare l’app senza questo permesso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non ora'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continua'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    pendingBackgroundEnable = true;
    final always = await Permission.locationAlways.request();
    if (always.isGranted) {
      await _refreshPermissions();
    } else if (mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Autorizza la posizione in background'),
          content: const Text(
            'Apri Permessi → Posizione e seleziona “Consenti sempre”. Al ritorno nell’app lo stato verrà aggiornato. Per uscite lunghe controlla anche Batteria e scegli “Senza restrizioni”, se disponibile sul tuo telefono.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non ora'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apri impostazioni'),
            ),
          ],
        ),
      );
      if (open == true)
        await openAppSettings();
      else
        pendingBackgroundEnable = false;
    }
    await _refreshPermissions();
  }

  Future<void> _logout() async {
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const IntroScreen(home: HomeShell()),
        ),
        (_) => false,
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnessione non riuscita. Riprova.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PreferencesService.instance;
    return Scaffold(
      backgroundColor: WildColors.ivory,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 226,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const WildLandscape(height: 226),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x22FFFFFF),
                          Color(0xB8F8F6EF),
                          WildColors.ivory,
                        ],
                        stops: [0, .58, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: WildColors.forest,
                                ),
                              ),
                              const WildLogo(compact: true),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'Privacy e\npermessi',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 32,
                              height: .92,
                              fontWeight: FontWeight.w700,
                              color: WildColors.forest,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const SizedBox(
                            width: 300,
                            child: Text(
                              'Per offrirti la migliore esperienza e contribuire alla tutela della fauna selvatica, abbiamo bisogno di alcuni permessi.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.25,
                                color: WildColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PermissionCard(
                  icon: Icons.location_on,
                  title: 'Posizione precisa',
                  body: 'Ci permette di mostrarti specie, sentieri e avvistamenti vicino a te.',
                  tint: WildColors.sageSoft,
                  trailing: Switch(
                    value: locationAllowed,
                    onChanged: saving
                        ? null
                        : (v) => _permissionToggle(
                            Permission.locationWhenInUse,
                            v,
                          ),
                  ),
                  foot: locationAllowed
                      ? 'Permesso Android attivo'
                      : 'Permesso non concesso',
                ),
                const SizedBox(height: 10),
                _PermissionCard(
                  icon: Icons.notifications,
                  title: 'Notifiche',
                  body: 'Messaggi e nuovi avvistamenti.',
                  tint: const Color(0xFFF5EADB),
                  trailing: Switch(
                    value:
                        notificationsAllowed &&
                        (p.chatNotifications || p.sightingNotifications),
                    onChanged: saving ? null : _toggleNotifications,
                  ),
                  foot: notificationsAllowed
                      ? 'Permesso Android attivo'
                      : 'Permesso Android non concesso',
                ),
                const SizedBox(height: 10),
                _PermissionCard(
                  icon: Icons.camera_alt,
                  title: 'Fotocamera e foto',
                  body:
                      'Scatta foto degli avvistamenti e aggiungile al diario.',
                  tint: WildColors.sageSoft,
                  trailing: Switch(
                    value: cameraAllowed,
                    onChanged: saving
                        ? null
                        : (v) => _permissionToggle(Permission.camera, v),
                  ),
                  foot: cameraAllowed
                      ? 'Fotocamera autorizzata'
                      : 'Fotocamera non autorizzata',
                ),
                const SizedBox(height: 10),
                _PermissionCard(
                  icon: Icons.navigation,
                  title: 'Posizione in background',
                  body: 'Autorizza il GPS anche a schermo spento. La condivisione con gli altri avviene solo se il profilo è visibile.',
                  tint: const Color(0xFFF5EADB),
                  foot: backgroundAllowed
                      ? 'Permesso sempre attivo'
                      : 'Non autorizzata in background',
                  trailing: Switch(
                    value: backgroundAllowed && p.backgroundSharing,
                    onChanged: saving ? null : _toggleBackground,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: WildColors.sageSoft,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WildIconDisc(
                        Icons.eco_outlined,
                        size: 64,
                        background: WildColors.forest,
                        foreground: Colors.white,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I tuoi dati restano tuoi',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Le posizioni sensibili della fauna vengono protette. I backup restano nella destinazione scelta dall’utente.',
                              style: TextStyle(
                                height: 1.25,
                                color: WildColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                WildPrimaryButton(
                  label: 'Continua',
                  icon: Icons.arrow_forward,
                  onPressed: () => Navigator.maybePop(context),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Configura dopo'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Notifiche', style: WildText.h2),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Messaggi chat',
                  subtitle:
                      'Disattivabile indipendentemente dagli avvistamenti.',
                  value: p.chatNotifications,
                  onChanged: saving
                      ? null
                      : (v) async {
                          p.chatNotifications = v;
                          if (v && !notificationsAllowed)
                            await Permission.notification.request();
                          await save();
                          await _refreshPermissions();
                        },
                ),
                _ToggleTile(
                  title: 'Nuovi avvistamenti',
                  subtitle: 'Avvisi per nuovi inserimenti della community.',
                  value: p.sightingNotifications,
                  onChanged: saving
                      ? null
                      : (v) async {
                          p.sightingNotifications = v;
                          if (v && !notificationsAllowed)
                            await Permission.notification.request();
                          await save();
                          await _refreshPermissions();
                        },
                ),
                const SizedBox(height: 14),
                const Text('Modalità sul campo', style: WildText.h2),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Silenzio sul campo',
                  subtitle: 'Riduce distrazioni e disattiva il pannello versi.',
                  value: p.fieldSilence,
                  onChanged: saving
                      ? null
                      : (v) async {
                          p.fieldSilence = v;
                          if (v) {
                            p.soundPanel = false;
                            await AudioService.instance.stop();
                          }
                          await save();
                        },
                ),
                const SizedBox(height: 14),
                ListTile(leading: const Icon(Icons.manage_accounts_outlined), title: const Text('Recupero avvistamenti'), subtitle: const Text('Recupera i vecchi post anche senza backup'), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RecoveryScreen()))),
                const Text('Profilo e persone vicine', style: WildText.h2),
                const SizedBox(height: 12),
                Center(child: ProfileAvatar(base64: p.avatarBase64, radius: 42)),
                const SizedBox(height: 8),
                WildOutlineButton(label: 'Carica foto profilo', onPressed: saving ? null : () => _profilePhoto()),
                if (p.avatarBase64 != null) TextButton(onPressed: saving ? null : () => _profilePhoto(remove: true), child: const Text('Rimuovi foto profilo')),
                const Text('Nome e foto sono visibili nei tuoi post Community.', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                TextField(
                  controller: nickname,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Nome visualizzato',
                    helperText: 'Non modifica il nickname usato per accedere.',
                  ),
                ),
                WildOutlineButton(
                  label: 'Salva nome visualizzato',
                  onPressed: saving
                      ? null
                      : () async {
                          if (nickname.text.trim().length < 2) return;
                          p.nickname = nickname.text.trim();
                          await save();
                          await CommunityService.instance.refresh();
                        },
                ),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Condividi la mia posizione',
                  subtitle: 'Visibile alle persone entro 15 km che condividono a loro volta la posizione.',
                  value: p.visible,
                  onChanged: saving
                      ? null
                      : (v) async {
                          if (v && nickname.text.trim().length < 2) return;
                          if (v) p.nickname = nickname.text.trim();
                          p.visible = v;
                          await save();
                          if (v) {
                            await CommunityService.instance
                                .configureBackgroundSharing();
                            await CommunityService.instance.refresh();
                          } else {
                            await CommunityService.instance.hide();
                          }
                        },
                ),
                const SizedBox(height: 14),
                const Text('Dati e backup', style: WildText.h2),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  leading: const WildIconDisc(Icons.cloud_done_outlined),
                  title: const Text(
                    'Backup cloud',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Destinazione scelta da te · dati, profilo e impostazioni',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BackupScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  leading: const WildIconDisc(Icons.menu_book_outlined),
                  title: const Text(
                    'Guida sul campo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const GuideScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  leading: const WildIconDisc(Icons.logout),
                  title: const Text(
                    'Disconnetti account',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Non cancella i dati presenti sul dispositivo',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _logout,
                ),
                const SizedBox(height: 20),
                WildPrimaryButton(
                  label: 'Continua',
                  icon: Icons.arrow_forward,
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.tint,
    required this.trailing,
    this.foot,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color tint;
  final Widget trailing;
  final String? foot;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        WildIconDisc(
          icon,
          size: 48,
          background: Colors.white.withValues(alpha: .65),
          foreground: WildColors.forest,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12,
                  color: WildColors.muted,
                  height: 1.25,
                ),
              ),
              if (foot != null) ...[
                const SizedBox(height: 7),
                Text(
                  foot!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: WildColors.forest,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: WildColors.muted),
      ),
    ),
  );
}
