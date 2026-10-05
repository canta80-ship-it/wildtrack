import 'package:flutter/material.dart';
import '../premium_ui.dart';
import '../services/radar_map_service.dart';
import '../services/community_service.dart';
import '../services/preferences_service.dart';

const radarAmber = Color(0xFFB98435);
const radarSage = Color(0xFFB9CCAA);

class RadarMapHeader extends StatelessWidget {
  const RadarMapHeader({super.key, required this.mode, required this.onMode, required this.busy, required this.radius, required this.onRefresh, required this.onExpand, this.species, this.onClearSpecies, this.routeName, this.onClearRoute});
  final int mode;
  final ValueChanged<int> onMode;
  final bool busy;
  final double radius;
  final VoidCallback onRefresh, onExpand;
  final String? species, routeName;
  final VoidCallback? onClearSpecies, onClearRoute;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: WildColors.ivory.withValues(alpha: .98), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x220B392B), blurRadius: 18, offset: Offset(0,4))]),
    padding: const EdgeInsets.fromLTRB(14,12,14,10),
    child: Column(children: [
      Row(children: [const WildIconDisc(Icons.radar, size: 43, background: WildColors.forest, foreground: Colors.white), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('WildTrack Radar', style: TextStyle(fontFamily: 'serif', fontSize: 21, fontWeight: FontWeight.w700, color: WildColors.forest)), Text('Habitat e segnalazioni · ${radius.toInt()} km', style: const TextStyle(fontSize: 11, color: WildColors.muted))])), IconButton(tooltip: 'Aggiorna zone e avvistamenti', onPressed: busy ? null : onRefresh, icon: busy ? const SizedBox(width: 20,height: 20,child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh))]),
      const SizedBox(height: 10),
      Row(children: [for (var i = 0; i < 3; i++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: InkWell(onTap: () => onMode(i), borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: mode == i ? WildColors.forest : const Color(0xFFE7EBDD), borderRadius: BorderRadius.circular(18)), child: Text(const ['Possibili','Avvistamenti','Tutti'][i], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mode == i ? Colors.white : WildColors.forest))))))]),
      if (species != null || routeName != null) Row(children: [Expanded(child: Text(species ?? 'Lungo ${routeName!}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), IconButton(tooltip: 'Rimuovi filtro', visualDensity: VisualDensity.compact, onPressed: species != null ? onClearSpecies : onClearRoute, icon: const Icon(Icons.close,size:18))]),
      if (radius < 10) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: busy ? null : onExpand, style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero), child: const Text('Amplia raggio', style: TextStyle(fontSize: 11)))),
    ]),
  );
}

class RadarObservationThumb extends StatelessWidget {
  const RadarObservationThumb(this.row, {super.key, this.size = 52});
  final Map<String,dynamic> row;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size,height: size,child: ClipRRect(borderRadius: BorderRadius.circular(12),child: row['photo'] == null ? const ColoredBox(color: Color(0xFFF0E3CB), child: Icon(Icons.pets,color: radarAmber)) : Image.network('$communityUrl/api/photo?id=${Uri.encodeQueryComponent('${row['id']}')}&v=${Uri.encodeQueryComponent('${row['photo']}')}', headers: {'Authorization':'Bearer ${PreferencesService.instance.token}'}, fit: BoxFit.cover, errorBuilder: (_, e, st) => const ColoredBox(color: Color(0xFFF0E3CB), child: Icon(Icons.broken_image_outlined,color: radarAmber)))));
}

class RadarPossiblePin extends StatelessWidget {
  const RadarPossiblePin(this.species, {super.key, required this.onTap});
  final String species;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min,children: [Container(width: 48,height: 48,padding: const EdgeInsets.all(3),decoration: BoxDecoration(color: WildColors.ivory,shape: BoxShape.circle,border: Border.all(color: WildColors.forest,width: 2),boxShadow: const [BoxShadow(color: Color(0x33000000),blurRadius: 9)]),child: ClipOval(child: WildAnimalIllustration(species,size: 42))),const SizedBox(height: 3),Container(padding: const EdgeInsets.symmetric(horizontal: 7,vertical: 3),decoration: BoxDecoration(color: WildColors.ivory.withValues(alpha:.96),borderRadius: BorderRadius.circular(10)),child: Text(species,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,fontWeight:FontWeight.bold,color:WildColors.forest)))]));
}
class RadarObservedPin extends StatelessWidget {
  const RadarObservedPin(this.row, {super.key, required this.onTap});
  final Map<String,dynamic> row;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap:onTap,child:Stack(clipBehavior:Clip.none,children:[Container(padding:const EdgeInsets.all(3),decoration:BoxDecoration(color:WildColors.ivory,borderRadius:BorderRadius.circular(15),border:Border.all(color:radarAmber,width:2.5),boxShadow:const [BoxShadow(color:Color(0x33000000),blurRadius:10)]),child:RadarObservationThumb(row,size:43)),Positioned(right:-4,bottom:-5,child:Container(padding:const EdgeInsets.all(3),decoration:const BoxDecoration(color:radarAmber,shape:BoxShape.circle),child:const Icon(Icons.schedule,size:14,color:Colors.white)))]));
}

class RadarResultsSheet extends StatelessWidget {
  const RadarResultsSheet({super.key, required this.possible, required this.observed, required this.mode, required this.busy, required this.onPossible, required this.onObserved, required this.onExpand, this.error});
  final List<RadarPossibleSpecies> possible;
  final List<Map<String,dynamic>> observed;
  final int mode;
  final bool busy;
  final String? error;
  final ValueChanged<RadarPossibleSpecies> onPossible;
  final ValueChanged<Map<String,dynamic>> onObserved;
  final VoidCallback onExpand;
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(initialChildSize:.31,minChildSize:.16,maxChildSize:.64,builder:(context,controller)=>Container(decoration:const BoxDecoration(color:WildColors.ivory,borderRadius:BorderRadius.vertical(top:Radius.circular(28)),boxShadow:[BoxShadow(color:Color(0x220B392B),blurRadius:22)]),child:ListView(controller:controller,padding:const EdgeInsets.fromLTRB(18,10,18,32),children:[
    Center(child:Container(width:38,height:4,decoration:BoxDecoration(color:WildColors.sage,borderRadius:BorderRadius.circular(8)))),const SizedBox(height:12),
    const Wrap(spacing:16,runSpacing:5,children:[_Legend(WildColors.forest,'Possibile presenza',Icons.crop_square),_Legend(radarAmber,'Segnalato dalla community',Icons.schedule)]),
    if(busy) const Padding(padding:EdgeInsets.symmetric(vertical:10),child:LinearProgressIndicator()),
    if(error!=null) Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Text(error!,style:const TextStyle(color:WildColors.muted))),
    if(mode!=1)...[
      const SizedBox(height:14),const Text('Specie da cercare qui',style:TextStyle(fontFamily:'serif',fontSize:22,fontWeight:FontWeight.w700,color:WildColors.forest)),
      const Text('Habitat compatibile · presenza da verificare',style:TextStyle(fontSize:11,color:WildColors.muted)),const SizedBox(height:10),
      if(possible.isEmpty&&!busy) const Text('Nessuna zona compatibile trovata nell’area caricata.'),
      if(possible.isNotEmpty) SizedBox(height:193,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:possible.length,separatorBuilder:(_,i)=>const SizedBox(width:10),itemBuilder:(context,i){final s=possible[i];return InkWell(onTap:()=>onPossible(s),borderRadius:BorderRadius.circular(18),child:Container(width:190,padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:const Color(0xFFE9EDDF),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFCBD5BF))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[ClipRRect(borderRadius:BorderRadius.circular(12),child:WildAnimalIllustration(s.name,size:62)),const SizedBox(width:8),const Expanded(child:Text('Possibile\npresenza',style:TextStyle(fontSize:11,color:WildColors.forest,fontWeight:FontWeight.bold)))]),const SizedBox(height:8),Text(s.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontFamily:'serif',fontSize:18,fontWeight:FontWeight.w700,color:WildColors.forest)),Text(s.habitat,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:WildColors.muted)),const SizedBox(height:5),Row(children:[const Icon(Icons.schedule,size:13,color:WildColors.forest),const SizedBox(width:4),Text(s.bestWindow,style:const TextStyle(fontSize:11,color:WildColors.forest))]),if(s.recentCount>0) Padding(padding:const EdgeInsets.only(top:7),child:Text('${s.recentCount} segnalazioni · 7 giorni',style:const TextStyle(fontSize:10,fontWeight:FontWeight.bold,color:radarAmber)))])));})),
    ],
    if(mode!=0)...[
      const SizedBox(height:18),const Text('Osservate nella zona',style:TextStyle(fontFamily:'serif',fontSize:22,fontWeight:FontWeight.w700,color:WildColors.forest)),const Text('Segnalazioni caricate · ultimi 7 giorni',style:TextStyle(fontSize:11,color:WildColors.muted)),
      if(observed.isEmpty&&!busy) const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('Nessun avvistamento recente caricato in questa zona.')),
      for(final row in observed) Padding(padding:const EdgeInsets.only(top:10),child:InkWell(onTap:()=>onObserved(row),borderRadius:BorderRadius.circular(16),child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:const Color(0xFFF4EBDD),borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFE5D4B8))),child:Row(children:[RadarObservationThumb(row,size:56),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${row['species']}',style:const TextStyle(fontFamily:'serif',fontSize:18,fontWeight:FontWeight.bold,color:WildColors.forest)),Text('${row['authorName']??'Autore non disponibile'}',style:const TextStyle(fontSize:11,color:WildColors.muted)),Text(_date(row['observedAt']),style:const TextStyle(fontSize:10,color:WildColors.muted)),if(row['approximate']==1||row['approximate']==true) const Text('Posizione approssimata',style:TextStyle(fontSize:10,color:radarAmber))])),const Icon(Icons.chevron_right,color:radarAmber)])))),
    ],
    if(!busy&&possible.isEmpty&&observed.isEmpty) TextButton.icon(onPressed:onExpand,icon:const Icon(Icons.zoom_out_map),label:const Text('Amplia raggio / riprova')),
    const SizedBox(height:14),const Text('Le zone seguono gli habitat OpenStreetMap. Le miniature verdi illustrano le specie; i pin ambra rappresentano segnalazioni, non animali in tempo reale.',style:TextStyle(fontSize:10,color:WildColors.muted)),
  ])));
  static String _date(dynamic value){final d=DateTime.tryParse('$value')?.toLocal();return d==null?'Data non disponibile':'${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} · ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}
}
class _Legend extends StatelessWidget {
  const _Legend(this.color,this.label,this.icon);
  final Color color;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context)=>Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:14,color:color),const SizedBox(width:5),Text(label,style:TextStyle(fontSize:10,color:color,fontWeight:FontWeight.w700))]);
}
