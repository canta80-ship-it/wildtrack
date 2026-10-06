import 'community_edit_photo_widget.dart';
import 'community_photo_widget.dart';
import 'profile_avatar_widget.dart';
import 'premium_explore_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/community_service.dart';
import '../services/did_you_know_service.dart';
import '../services/preferences_service.dart';
import '../services/push_service.dart';
import 'community_screen.dart';
import 'community_sighting_map_screen.dart';
import 'community_delete_widget.dart';
import '../services/preferences_service.dart';
import 'private_maps_screen.dart';
import 'settings_screen.dart';
import '../premium_ui.dart';

class PremiumCommunityScreen extends StatefulWidget {
  const PremiumCommunityScreen({super.key});
  @override
  State<PremiumCommunityScreen> createState() => _PremiumCommunityScreenState();
}

class _PremiumCommunityScreenState extends State<PremiumCommunityScreen> {
  int tab = 0;

  Future<void> _toggleMute() async {
    final p = PreferencesService.instance;
    p.chatNotifications = !p.chatNotifications;
    await p.save();
    await PushService.instance.syncPreferences();
    if (mounted) setState(() {});
  }

  Future<void> _menu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: WildColors.ivory,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Aggiorna Community'),
                onTap: () async {
                  Navigator.pop(sheet);
                  await CommunityService.instance.refresh();
                  if (mounted) setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Spedizioni private'),
                onTap: () {
                  Navigator.pop(sheet);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivateMapsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Impostazioni e privacy'),
                onTap: () {
                  Navigator.pop(sheet);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: WildHero(
            image: '',
            height: 280,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const WildLogo(compact: true),
                        const Spacer(),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'Community',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const SizedBox(
                      width: 320,
                      child: Text(
                        'Condividi avvistamenti, esperienze e consigli con altri appassionati di natura.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _Tabs(
                selected: tab,
                onTap: (i) => setState(() => tab = i),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 115),
          sliver: SliverToBoxAdapter(child: _content()),
        ),
      ],
    ),
  );

  Widget _content() {
    if (tab == 0) return _ChatAndFeed(onMute: _toggleMute, onMenu: _menu);
    if (tab == 1)
      return _Groups(
        onPrivate: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const PrivateMapsScreen()),
        ),
      );
    if (tab == 2) return const _People();
    return const _Events();
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onTap});
  final int selected;
  final ValueChanged<int> onTap;
  static const items = [
    (Icons.location_on_outlined, 'Avvistamenti'),
    (Icons.groups_outlined, 'Gruppi'),
    (Icons.people_outline, 'Persone'),
    (Icons.event_outlined, 'Eventi'),
  ];
  @override
  Widget build(BuildContext context) => Container(
    height: 62,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x19000000),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected == i ? WildColors.forest : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[i].$1,
                      size: 19,
                      color: selected == i ? Colors.white : WildColors.forest,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected == i ? Colors.white : WildColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ChatAndFeed extends StatelessWidget {
  const _ChatAndFeed({required this.onMute, required this.onMenu});
  final VoidCallback onMute;
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const WildAnimalIllustration('Community', size: 56),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community WildTrack',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Avvistamenti reali della community',
                    style: TextStyle(fontSize: 11, color: WildColors.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: PreferencesService.instance.chatNotifications
                  ? 'Silenzia chat'
                  : 'Riattiva chat',
              onPressed: onMute,
              icon: Icon(
                PreferencesService.instance.chatNotifications
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
              ),
            ),
            IconButton(onPressed: onMenu, icon: const Icon(Icons.more_vert)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      ListenableBuilder(
        listenable: CommunityService.instance,
        builder: (context, _) {
          final c = CommunityService.instance;
          return Column(
            children: [
              if (c.syncing) const LinearProgressIndicator(),
              if (c.error != null)
                _Info(text: 'Aggiornamento non riuscito: ${c.error}'),
              if (c.sightings.isEmpty)
                const _Info(
                  text: 'Nessun avvistamento pubblico caricato in questo momento.',
                ),
              for (final s in c.sightings) _FeedSighting(s: s),
            ],
          );
        },
      ),
      const SizedBox(height: 10),
      const WildSectionTitle('Chat'),
      const SizedBox(height: 10),
      Container(
        height: 280,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const InboxScreen(),
      ),
    ],
  );
}

class _FeedSighting extends StatelessWidget {
  const _FeedSighting({required this.s});
  final Map<String, dynamic> s;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(color: WildColors.ivory, borderRadius: BorderRadius.circular(26),
      border: Border.all(color: WildColors.forest.withValues(alpha: .12)),
      boxShadow: [BoxShadow(color: WildColors.forest.withValues(alpha: .07), blurRadius: 18, offset: const Offset(0, 6))]),
    child: ClipRRect(borderRadius: BorderRadius.circular(26), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.all(15), child: Row(children: [
        ProfileAvatar(url: s['avatarUrl'] as String?, radius: 22), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${s['authorName'] ?? 'Esploratore'}', style: const TextStyle(fontWeight: FontWeight.w700, color: WildColors.forest)),
          Text(timeLabel(s['observedAt']), style: const TextStyle(fontSize: 11, color: WildColors.muted)),
        ])), const Icon(Icons.nature_outlined, color: WildColors.forest),
      ])),
      if (s['photo'] != null)
        ColoredBox(color: WildColors.sageSoft, child: CommunityPhoto(version: '${s['photo']}', sightingId: '${s['id']}', height: 225))
      else SizedBox(height: 160, child: WildLandscape(height: 160, animal: '${s['species'] ?? 'Animale'}')),
      Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DAL CAMPO', style: TextStyle(fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w800, color: WildColors.forest)),
        const SizedBox(height: 5),
        Text('${s['species'] ?? 'Avvistamento'}', style: const TextStyle(fontFamily: 'serif', fontSize: 25, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        Text('${s['notes'] ?? ''}', style: const TextStyle(height: 1.4, color: WildColors.muted)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 6, children: [
          Text('${s['count'] ?? 1} individui', style: const TextStyle(fontSize: 11, color: WildColors.forest)),
          Text(s['groupId'] == null ? 'Community' : 'Gruppo privato', style: const TextStyle(fontSize: 11, color: WildColors.forest)),
        ]),
        const Divider(height: 25),
        CommunitySightingMapButton(sighting: s),
        CommunityEditPhotoButton(sighting: s),
        CommunityDeleteButton(sighting: s),
        TextButton(onPressed: () => showSighting(context, s), child: const Text('Apri avvistamento')),
      ])),
    ])),
  );
}

class _People extends StatefulWidget {
  const _People();
  @override
  State<_People> createState() => _PeopleState();
}

class _PeopleState extends State<_People> {
  @override
  void initState() {
    super.initState();
    CommunityService.instance.updatePresence();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: CommunityService.instance,
    builder: (context, _) {
      final c = CommunityService.instance;
      if (!PreferencesService.instance.visible) {
        return const _Placeholder(
          icon: Icons.location_off_outlined,
          title: 'Posizione non condivisa',
          body: 'Per vedere persone vicine devi attivare volontariamente la condivisione posizione nelle impostazioni.',
        );
      }
      if (c.people.isEmpty) {
        return Column(
          children: [
            const _Placeholder(
              icon: Icons.people_outline,
              title: 'Nessuno nelle vicinanze',
              body: 'Nessun utente visibile entro 15 km. Entrambi dovete attivare la condivisione; la posizione scade dopo 3 minuti senza aggiornamenti.',
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => c.updatePresence(),
              icon: const Icon(Icons.refresh),
              label: const Text('Aggiorna'),
            ),
          ],
        );
      }
      return Column(
        children: [
          for (final p in c.people)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                leading: ProfileAvatar(url: p['avatarUrl'] as String?),
                title: Text(
                  '${p['nickname'] ?? 'Esploratore'} · Vedi su mappa',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${((p['distanceM'] as num? ?? 0) / 1000).toStringAsFixed(1)} km · posizione condivisa'),
                trailing: IconButton(tooltip: 'Apri chat', icon: const Icon(Icons.chat_bubble_outline), onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(peer: '${p['id'] ?? ''}', nickname: '${p['nickname'] ?? 'Esploratore'}')))),
                onTap: () {
                  if (p['lat'] is! num || p['lng'] is! num) return;
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PremiumExploreScreen(initialPosition: LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()), initialCommunity: true)));
                },
              ),
            ),
        ],
      );
    },
  );
}

class _Events extends StatefulWidget {
  const _Events();
  @override
  State<_Events> createState() => _EventsState();
}

class _EventsState extends State<_Events> {
  late Future<DidYouKnowFeed> feed = _load();
  Future<DidYouKnowFeed> _load({bool force = false}) =>
      DidYouKnowService.instance.loadEvents(force: force)
          .timeout(const Duration(seconds: 30));

  void _refresh() => setState(() => feed = _load(force: true));

  @override
  Widget build(BuildContext context) => Column(children: [
    Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _refresh,
        icon: const Icon(Icons.refresh),
        label: const Text('Aggiorna eventi'),
      ),
    ),
    FutureBuilder<DidYouKnowFeed>(
    future: feed,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting)
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        );
      if (snapshot.hasError || !snapshot.hasData)
        return const _Placeholder(
          icon: Icons.cloud_off_outlined,
          title: 'Eventi non disponibili',
          body: 'Il caricamento non è riuscito. Tocca Aggiorna eventi per riprovare.',
        );
      final rows = snapshot.data!.items;
      if (rows.isEmpty)
        return const _Placeholder(
          icon: Icons.event_outlined,
          title: 'Nessun evento di montagna trovato',
          body: 'Le fonti consultate non hanno restituito notizie recenti su eventi di montagna. Tocca Aggiorna eventi per riprovare.',
        );
      return Column(
        children: [
          for (final e in rows)
            InkWell(
              onTap: e.link == null
                  ? null
                  : () => launchUrl(
                      Uri.parse(e.link!),
                      mode: LaunchMode.externalApplication,
                    ),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const WildIconDisc(Icons.event_outlined, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${e.source} · ${e.body}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: WildColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new, size: 18),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  ),
  ]);
}

class _Groups extends StatelessWidget {
  const _Groups({required this.onPrivate});
  final VoidCallback onPrivate;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _GroupCard(
        title: 'Spedizioni private',
        body: 'Posizione temporanea, messaggi e avvistamenti condivisi solo con i membri approvati.',
        icon: Icons.lock_outline,
        animal: 'Camoscio',
        onTap: onPrivate,
      ),
      const SizedBox(height: 10),
      _GroupCard(
        title: 'Crea un gruppo sul campo',
        body: 'Organizza un’uscita con compagni fidati senza pubblicare coordinate sensibili.',
        icon: Icons.group_add_outlined,
        animal: 'Fauna',
        onTap: onPrivate,
      ),
    ],
  );
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.animal,
    required this.onTap,
  });
  final String title, body, animal;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      height: 155,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          WildLandscape(height: 155, animal: animal),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xE8173F2B), Color(0x55173F2B)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        body,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 30),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        WildIconDisc(icon, size: 64),
        const SizedBox(height: 14),
        Text(title, style: WildText.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: WildColors.muted, height: 1.35),
        ),
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: WildColors.sageSoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: WildColors.forest),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}
