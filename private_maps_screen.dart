import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/community_service.dart';
import '../services/preferences_service.dart';
import 'community_screen.dart';
import '../premium_ui.dart';

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
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final d = await CommunityService.instance.api('maps');
      if (mounted) setState(() {
        maps = (d['items'] as List).map((x) => Map<String,dynamic>.from(x as Map)).toList();
        members = (d['members'] as List).map((x) => Map<String,dynamic>.from(x as Map)).toList();
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
    final r = await showDialog<String>(context: context, builder: (c) => AlertDialog(title: Text(title), content: TextField(controller: t, decoration: InputDecoration(labelText: hint)), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annulla')), FilledButton(onPressed: () => Navigator.pop(c, t.text.trim()), child: const Text('Conferma'))]));
    t.dispose();
    return r;
  }

  Future<void> action(Map<String,dynamic> body) async {
    try {
      final d = await CommunityService.instance.api('maps', method: 'POST', body: body);
      if (!mounted) return;
      if (d['code'] != null) {
        await showDialog<void>(context: context, builder: (c) => AlertDialog(title: const Text('Invito personale'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Valido 24 ore e utilizzabile una sola volta. La richiesta dovrà poi essere approvata.'), const SizedBox(height: 12), SelectableText(d['code'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))]), actions: [TextButton(onPressed: () async { await Clipboard.setData(ClipboardData(text: d['code'] as String)); if (c.mounted) message(c, 'Codice copiato'); }, child: const Text('Copia')), TextButton(onPressed: () => Navigator.pop(c), child: const Text('Chiudi'))]));
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
  Widget build(BuildContext context) {
    final current = maps.isEmpty ? null : maps.first;
    final mapMembers = current == null ? <Map<String,dynamic>>[] : members.where((m) => m['mapId'] == current['id']).toList();
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: WildHero(
          image: 'intro_marmotta.jpg', height: 355, alignment: const Alignment(.05, -.18),
          child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(17, 8, 17, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white)), const WildLogo(compact: true, light: true), const Spacer(), IconButton(onPressed: load, icon: const Icon(Icons.settings_outlined, color: Colors.white))]),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: const Color(0xBB173F2B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white38)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock, color: Colors.white, size: 15), SizedBox(width: 6), Text('SPEDIZIONE PRIVATA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8))])),
            const SizedBox(height: 12),
            Text(current?['name'] as String? ?? 'La tua spedizione', style: const TextStyle(fontFamily: 'serif', fontSize: 38, height: 1, color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Row(children: [Icon(Icons.location_on_outlined, color: Colors.white, size: 19), SizedBox(width: 5), Text('Area naturalistica privata', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))]),
            const SizedBox(height: 7),
            const Row(children: [Icon(Icons.event_outlined, color: Colors.white, size: 19), SizedBox(width: 5), Text('Condivisione temporanea', style: TextStyle(color: Colors.white, fontSize: 15))]),
            const SizedBox(height: 14),
            Row(children: [for (var i=0;i<mapMembers.length.clamp(0,4);i++) Align(widthFactor: .72, child: CircleAvatar(radius: 22, backgroundColor: Colors.white, child: CircleAvatar(radius: 19, backgroundColor: WildColors.sage, child: Text('${i+1}', style: const TextStyle(color: WildColors.forest, fontWeight: FontWeight.w800))))), if (mapMembers.length > 4) CircleAvatar(radius: 22, backgroundColor: WildColors.forest, child: Text('+${mapMembers.length-4}', style: const TextStyle(color: Colors.white))), const Spacer(), if (current != null && current['mine'] == 1) FilledButton.tonalIcon(onPressed: () => _manage(current, mapMembers), icon: const Icon(Icons.group_outlined), label: const Text('Gestisci membri'))]),
          ]))),
        )),
        SliverPadding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 40), sliver: SliverList(delegate: SliverChildListDelegate([
          if (loading) const LinearProgressIndicator(),
          if (error != null) Padding(padding: const EdgeInsets.all(10), child: Text(error!)),
          if (current == null) _empty(),
          if (current != null) ...[
            _MapPreview(memberCount: mapMembers.length),
            const SizedBox(height: 12),
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.17, children: [
              const _ExpeditionCard(icon: Icons.location_on, title: 'Posizione\ndel gruppo', body: 'Segui i membri durante l’uscita.', tint: WildColors.sageSoft),
              const _ExpeditionCard(icon: Icons.chat_bubble_outline, title: 'Messaggi', body: 'Comunica con il gruppo durante la spedizione.', tint: Color(0xFFEAF2F3), badge: '3'),
              const _ExpeditionCard(icon: Icons.visibility_outlined, title: 'Avvistamenti\ndel gruppo', body: 'Tutti gli avvistamenti condivisi.', tint: Color(0xFFF4E9D9)),
              _ExpeditionCard(icon: Icons.person_add_alt, title: 'Invita membri', body: 'Aggiungi altri compagni di spedizione.', tint: WildColors.sageSoft, onTap: current['mine'] == 1 ? () => action({'action':'invite','mapId':current['id']}) : null),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(children: [const WildIconDisc(Icons.schedule_outlined, size: 48, background: Color(0xFFF3E7D5), foreground: WildColors.earth), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Condivisione temporanea attiva', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 2), Text('La posizione viene condivisa solo durante l’uscita e può essere disattivata in qualsiasi momento.', style: TextStyle(fontSize: 10, color: WildColors.muted))])), TextButton(onPressed: () {}, child: const Text('Modifica'))])),
            const SizedBox(height: 18),
            if (maps.length > 1) ...[const Text('Altre mappe private', style: WildText.h2), const SizedBox(height: 8), for (final m in maps.skip(1)) ListTile(tileColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), leading: const WildIconDisc(Icons.lock_outline), title: Text(m['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(m['mine'] == 1 ? 'Sei il proprietario' : 'Membro approvato'))],
          ],
        ]))),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () async { final n = await input('Crea spedizione privata','Nome'); if (n != null && n.isNotEmpty) await action({'action':'create','name':n}); }, icon: const Icon(Icons.add), label: const Text('Nuova spedizione')),
    );
  }

  Widget _empty() => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(children: [const WildIconDisc(Icons.lock_outline, size: 70), const SizedBox(height: 14), const Text('Nessuna spedizione privata', style: WildText.h2), const SizedBox(height: 7), const Text('Crea un gruppo oppure usa un codice invito ricevuto.', textAlign: TextAlign.center, style: TextStyle(color: WildColors.muted)), const SizedBox(height: 16), WildPrimaryButton(label: 'Crea spedizione', onPressed: () async { final n = await input('Crea spedizione privata','Nome'); if (n != null && n.isNotEmpty) await action({'action':'create','name':n}); }), const SizedBox(height: 9), WildOutlineButton(label:'Usa invito', onPressed: () async { final code=await input('Chiedi accesso','Codice ricevuto'); if(code!=null&&code.isNotEmpty) await action({'action':'join','code':code,'nickname':PreferencesService.instance.nickname}); })]));

  Future<void> _manage(Map<String,dynamic> m,List<Map<String,dynamic>> rows) async => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (c) => SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Gestisci membri', style: WildText.h1), const SizedBox(height: 10), FilledButton.icon(onPressed: () {Navigator.pop(c); action({'action':'invite','mapId':m['id']});}, icon: const Icon(Icons.person_add_alt), label: const Text('Crea invito personale')), for(final p in rows) ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(p['nickname'] as String), subtitle: Text(p['approved']==1?'Accesso consentito':'In attesa di approvazione'), trailing: Wrap(children:[if(p['approved']!=1) IconButton(onPressed:(){Navigator.pop(c);action({'action':'approve','mapId':m['id'],'memberId':p['id']});},icon:const Icon(Icons.check)),IconButton(onPressed:(){Navigator.pop(c);action({'action':'remove','mapId':m['id'],'memberId':p['id']});},icon:const Icon(Icons.person_remove_outlined))]))]))));
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.memberCount}); final int memberCount;
  @override
  Widget build(BuildContext context) => Container(height: 260, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(26)), child: Stack(fit: StackFit.expand, children: [
    Image.asset('intro_cervo.jpg', fit: BoxFit.cover),
    Container(color: const Color(0x774F7957)),
    const Positioned(left: 35, top: 55, child: _Marker(icon: Icons.pets, earth: true)),
    const Positioned(right: 45, top: 82, child: _Marker(icon: Icons.pets, earth: true)),
    const Positioned(left: 130, top: 105, child: _Marker(icon: Icons.groups)),
    Positioned(left: 18, right: 18, bottom: 15, child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white.withValues(alpha:.93), borderRadius: BorderRadius.circular(20)), child: Row(children: [const WildIconDisc(Icons.groups, size: 44), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[const Text('Posizione del gruppo',style:TextStyle(fontFamily:'serif',fontSize:18,fontWeight:FontWeight.w800)),Text('$memberCount membri nella spedizione',style:const TextStyle(fontSize:10,color:WildColors.muted))])), const Text('Vedi mappa ›',style:TextStyle(color:WildColors.forest,fontWeight:FontWeight.w700))]))),
  ]));
}

class _Marker extends StatelessWidget {
  const _Marker({required this.icon,this.earth=false}); final IconData icon; final bool earth;
  @override
  Widget build(BuildContext context) => CircleAvatar(radius: 24, backgroundColor: Colors.white, child: CircleAvatar(radius: 20, backgroundColor: earth?WildColors.earth:WildColors.forest, child: Icon(icon,color:Colors.white)));
}

class _ExpeditionCard extends StatelessWidget {
  const _ExpeditionCard({required this.icon,required this.title,required this.body,required this.tint,this.badge,this.onTap});
  final IconData icon; final String title,body; final Color tint; final String? badge; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap:onTap,borderRadius:BorderRadius.circular(24),child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:tint,borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[WildIconDisc(icon,size:44,background:WildColors.forest,foreground:Colors.white),if(badge!=null) Transform.translate(offset:const Offset(-8,-16),child:CircleAvatar(radius:11,backgroundColor:Colors.deepOrange,child:Text(badge!,style:const TextStyle(fontSize:10,color:Colors.white)))) ,const Spacer(),const Icon(Icons.chevron_right)]),const Spacer(),Text(title,style:const TextStyle(fontFamily:'serif',fontSize:20,height:1,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(body,style:const TextStyle(fontSize:10,color:WildColors.muted,height:1.2))])));
}
