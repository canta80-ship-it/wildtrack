import 'package:flutter/material.dart';

import '../services/community_service.dart';
import 'community_screen.dart';
import 'private_maps_screen.dart';
import '../premium_ui.dart';

class PremiumCommunityScreen extends StatefulWidget {
  const PremiumCommunityScreen({super.key});
  @override
  State<PremiumCommunityScreen> createState() => _PremiumCommunityScreenState();
}

class _PremiumCommunityScreenState extends State<PremiumCommunityScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: WildHero(
        image: 'intro_cervo.jpg', height: 265, alignment: const Alignment(.05, -.22),
        child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [WildLogo(compact: true, light: true), Spacer(), Icon(Icons.notifications_none, color: Colors.white), SizedBox(width: 12), CircleAvatar(radius: 18, backgroundImage: AssetImage('intro_cervo.jpg'))]),
          const Spacer(),
          const Text('Community', style: TextStyle(fontFamily: 'serif', fontSize: 39, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 5),
          const SizedBox(width: 320, child: Text('Condividi avvistamenti, esperienze e consigli con altri appassionati di natura.', style: TextStyle(color: Colors.white, fontSize: 15, height: 1.25))),
        ]))),
      )),
      SliverToBoxAdapter(child: Transform.translate(offset: const Offset(0, -14), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: _Tabs(selected: tab, onTap: (i) => setState(() => tab = i))))),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 115),
        sliver: SliverToBoxAdapter(child: _content()),
      ),
    ]),
  );

  Widget _content() {
    if (tab == 0) return const _ChatAndFeed();
    if (tab == 1) return _Groups(onPrivate: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PrivateMapsScreen())));
    if (tab == 2) return const _Placeholder(icon: Icons.people_outline, title: 'Persone vicino a te', body: 'Qui compariranno solo gli utenti che hanno scelto esplicitamente di condividere la posizione e che si trovano entro il raggio consentito.');
    return const _Placeholder(icon: Icons.event_outlined, title: 'Eventi naturalistici', body: 'Una sezione per escursioni, osservazioni e iniziative della community. Nessun evento inventato: verranno mostrati solo contenuti realmente disponibili.');
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onTap});
  final int selected; final ValueChanged<int> onTap;
  static const items = [(Icons.chat_bubble_outline, 'Chat'), (Icons.groups_outlined, 'Gruppi'), (Icons.people_outline, 'Persone'), (Icons.event_outlined, 'Eventi')];
  @override
  Widget build(BuildContext context) => Container(
    height: 62, padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 18, offset: Offset(0, 6))]),
    child: Row(children: [for (var i=0;i<items.length;i++) Expanded(child: InkWell(onTap: () => onTap(i), borderRadius: BorderRadius.circular(22), child: AnimatedContainer(duration: const Duration(milliseconds: 150), decoration: BoxDecoration(color: selected == i ? WildColors.forest : Colors.transparent, borderRadius: BorderRadius.circular(22)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(items[i].$1, size: 19, color: selected == i ? Colors.white : WildColors.forest), const SizedBox(width: 5), Text(items[i].$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected == i ? Colors.white : WildColors.ink))]))))]),
  );
}

class _ChatAndFeed extends StatelessWidget {
  const _ChatAndFeed();
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        const CircleAvatar(radius: 28, backgroundImage: AssetImage('intro_cervo.jpg')),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Community WildTrack', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800, fontSize: 20)), Text('Avvistamenti reali della community', style: TextStyle(fontSize: 11, color: WildColors.muted))])),
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_off_outlined)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
      ]),
    ),
    const SizedBox(height: 10),
    ListenableBuilder(listenable: CommunityService.instance, builder: (context, _) {
      final c = CommunityService.instance;
      return Column(children: [
        if (c.syncing) const LinearProgressIndicator(),
        if (c.error != null) _Info(text: 'Aggiornamento non riuscito. Trascina o riapri la sezione per riprovare.'),
        if (c.sightings.isEmpty) const _Info(text: 'Nessun avvistamento pubblico caricato in questo momento.'),
        for (final s in c.sightings.take(5)) _FeedSighting(s: s),
      ]);
    }),
    const SizedBox(height: 10),
    Container(height: 280, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: const InboxScreen()),
  ]);
}

class _FeedSighting extends StatelessWidget {
  const _FeedSighting({required this.s});
  final Map<String,dynamic> s;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => showSighting(context, s),
    child: Container(
      margin: const EdgeInsets.only(top: 9), padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: const Color(0xFFF4F6F0), borderRadius: BorderRadius.circular(22)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CircleAvatar(radius: 21, backgroundColor: WildColors.sage, child: Icon(Icons.person_outline, color: WildColors.forest)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('${s['species'] ?? 'Avvistamento'}', style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800))), Text(timeLabel(s['observedAt']), style: const TextStyle(fontSize: 10, color: WildColors.muted))]),
          const SizedBox(height: 4),
          Text(s['notes'] as String? ?? 'Avvistamento condiviso con la community.', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.25)),
          const SizedBox(height: 8),
          if (s['photo'] != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network('$communityUrl/api/photo?id=${s['id']}', headers: {'Authorization':'Bearer ${CommunityService.instance.preferences.token}'}, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => Image.asset('intro_cervo.jpg', height: 160, width: double.infinity, fit: BoxFit.cover))) else ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('intro_cervo.jpg', height: 135, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 7),
          Row(children: const [Icon(Icons.favorite_border, size: 18, color: WildColors.forest), SizedBox(width: 5), Text('Condiviso', style: TextStyle(fontSize: 10)), Spacer(), Icon(Icons.visibility_outlined, size: 18)]),
        ])),
      ]),
    ),
  );
}

class _Groups extends StatelessWidget {
  const _Groups({required this.onPrivate});
  final VoidCallback onPrivate;
  @override
  Widget build(BuildContext context) => Column(children: [
    _GroupCard(asset: 'intro_cervo.jpg', title: 'Spedizioni private', body: 'Posizione temporanea, messaggi e avvistamenti condivisi solo con i membri approvati.', icon: Icons.lock_outline, onTap: onPrivate),
    const SizedBox(height: 10),
    _GroupCard(asset: 'intro_marmotta.jpg', title: 'Crea un gruppo sul campo', body: 'Organizza un’uscita con compagni fidati senza pubblicare coordinate sensibili.', icon: Icons.group_add_outlined, onTap: onPrivate),
  ]);
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.asset, required this.title, required this.body, required this.icon, required this.onTap});
  final String asset,title,body; final IconData icon; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Container(height: 155, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)), child: Stack(fit: StackFit.expand, children: [Image.asset(asset, fit: BoxFit.cover), const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors:[Color(0xE8173F2B),Color(0x55173F2B)]))), Padding(padding: const EdgeInsets.all(18), child: Row(children:[Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children:[Icon(icon,color:Colors.white),const SizedBox(height:8),Text(title,style:const TextStyle(fontFamily:'serif',fontSize:22,fontWeight:FontWeight.w800,color:Colors.white)),const SizedBox(height:5),Text(body,style:const TextStyle(color:Colors.white,fontSize:11,height:1.25))])),const Icon(Icons.chevron_right,color:Colors.white,size:30)]))])));
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.title, required this.body});
  final IconData icon; final String title,body;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(children:[WildIconDisc(icon,size:64),const SizedBox(height:14),Text(title,style:WildText.h2,textAlign:TextAlign.center),const SizedBox(height:8),Text(body,textAlign:TextAlign.center,style:const TextStyle(color:WildColors.muted,height:1.35))]));
}

class _Info extends StatelessWidget {
  const _Info({required this.text}); final String text;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top:8),padding: const EdgeInsets.all(14),decoration:BoxDecoration(color:WildColors.sageSoft,borderRadius:BorderRadius.circular(18)),child:Row(children:[const Icon(Icons.info_outline,color:WildColors.forest),const SizedBox(width:8),Expanded(child:Text(text,style:const TextStyle(fontSize:12))) ]));
}
