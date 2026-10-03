import 'outdoor_tools_theme_widget.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../premium_ui.dart';
import '../services/outdoor_tools_service.dart';

class ReturnPointScreen extends StatefulWidget {
  const ReturnPointScreen({super.key,this.store,this.locationSource,this.now});
  final OutdoorToolsStore? store;final PointLocationSource? locationSource;final DateTime Function()? now;
  @override State<ReturnPointScreen> createState()=>_ReturnPointScreenState();
}
class _ReturnPointScreenState extends State<ReturnPointScreen> with WidgetsBindingObserver {
  late final store=widget.store??OutdoorToolsStore.instance;
  late final source=widget.locationSource??GpsPointLocationSource();
  StreamSubscription<Position>? subscription;Timer? ageTimer;
  List<ReturnPoint> points=[];String? selected,error;Position? fix;bool loading=true,busy=false,visible=true;
  DateTime get now=>widget.now?.call()??DateTime.now();
  ReturnPoint? get target=>points.where((p)=>p.id==selected).firstOrNull;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);_load();_refresh(requestPermission:false);}
  @override void dispose(){WidgetsBinding.instance.removeObserver(this);subscription?.cancel();ageTimer?.cancel();super.dispose();}
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state==AppLifecycleState.resumed){visible=true;_refresh(requestPermission:false);}else{visible=false;subscription?.cancel();subscription=null;ageTimer?.cancel();}
  }
  Future<void> _load()async {
    try {
      final data=await store.points();
      if(mounted)setState((){points=data;if(!data.any((p)=>p.id==selected))selected=data.firstOrNull?.id;loading=false;});
    }catch(_){if(mounted)setState((){loading=false;error='Punti non caricati. Riprova.';});}
  }
  void _watch() {
    if(!visible||!mounted)return;
    subscription?.cancel();ageTimer?.cancel();
    subscription=source.watch().listen((p){if(mounted)setState((){fix=p;error=usablePointFix(p,now)?null:'GPS poco preciso o non aggiornato. Attendi all’aperto e aggiorna.';});},onError:(Object _){if(mounted)setState((){fix=null;error='Aggiornamento GPS interrotto. Riprova.';});});
    ageTimer=Timer.periodic(const Duration(seconds:10),(_){if(mounted)setState((){});});
  }
  Future<void> _refresh({bool requestPermission=true})async {
    if(busy)return;
    setState(()=>busy=true);
    try {
      final p=await source.current(requestPermission:requestPermission);
      if(!mounted)return;
      setState((){fix=p;error=usablePointFix(p,now)?null:'GPS poco preciso o non aggiornato. Aggiorna prima di salvare.';});
      _watch();
    }catch(e){if(mounted)setState((){fix=null;error=e is PointLocationException?e.message:'Posizione non disponibile. Autorizza e aggiorna il GPS.';});}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> _save(ReturnPointKind kind)async {
    final label=await showDialog<String>(context:context,builder:(_)=>_PointNameDialog(kind:kind));
    if(label==null||!mounted)return;
    setState(()=>busy=true);
    try {
      // Always acquire a fresh fix for the exact save action, not an old UI fix.
      final current=await source.current(requestPermission:true);
      final p=await store.savePoint(name:label,kind:kind,position:current,now:now);
      if(!mounted)return;
      setState((){selected=p.id;fix=current;error=null;});await _load();if(mounted)_watch();
    }catch(e){if(mounted)setState(()=>error=e is PointLocationException?e.message:'Punto non salvato. Riprova.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> _remove(ReturnPoint point)async {
    final confirm=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text('Eliminare ${point.name}?'),content:const Text('Il punto verrà rimosso dal dispositivo.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Annulla')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Elimina'))]));
    if(confirm!=true)return;
    try{await store.removePoint(point.id);await _load();}catch(_){if(mounted)setState(()=>error='Punto non eliminato. Riprova.');}
  }
  Future<void> _openMap(ReturnPoint p)async {
    final uri=Uri.https('www.openstreetmap.org','/',{'mlat':'${p.latitude}','mlon':'${p.longitude}'}).replace(fragment:'map=17/${p.latitude}/${p.longitude}');
    try{if(!await launchUrl(uri,mode:LaunchMode.externalApplication))throw Exception();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Mappa non aperta. Le coordinate restano visibili nella scheda.')));}
  }
  @override Widget build(BuildContext context) {
    final p=target,g=fix==null||p==null?null:ReturnGuidance.calculate(fix!,p,now);
    return OutdoorToolsTheme(child:Scaffold(backgroundColor:WildColors.ivory,appBar:AppBar(title:const Text('Torna al mio punto')),body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Salva un punto, ritrovalo dopo',style:WildText.display),const SizedBox(height:8),
      const Text('Auto, bivio e postazione restano privati sul dispositivo. Direzione e distanza funzionano anche senza rete quando il GPS è disponibile.'),
      const SizedBox(height:16),
      Wrap(spacing:8,runSpacing:8,children:[for(final kind in ReturnPointKind.values)FilledButton.icon(key:ValueKey('save-${kind.name}'),onPressed:busy?null:()=>_save(kind),icon:Icon(switch(kind){ReturnPointKind.auto=>Icons.directions_car_outlined,ReturnPointKind.bivio=>Icons.alt_route,ReturnPointKind.postazione=>Icons.place_outlined}),label:Text('Salva ${kind.label.toLowerCase()}'))]),
      const SizedBox(height:12),OutlinedButton.icon(onPressed:busy?null:()=>_refresh(),icon:const Icon(Icons.my_location),label:const Text('Autorizza e aggiorna GPS')),
      if(busy||loading)const LinearProgressIndicator(),
      if(error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Text(error!,style:const TextStyle(color:Colors.red))),
      if(p!=null)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
        Text(p.name,style:const TextStyle(fontFamily:'serif',fontWeight:FontWeight.bold,fontSize:24)),
        if(g==null)const Padding(padding:EdgeInsets.all(16),child:Text('Serve una posizione recente e precisa per calcolare il ritorno.'))
        else ...[
          const SizedBox(height:12),Text(g.distanceLabel,key:const ValueKey('return-distance'),style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
          if(g.near)...[const Icon(Icons.near_me,color:WildColors.forest,size:50),const Text('Sei nell’area del punto',key:ValueKey('return-near'))]
          else ...[
            if(g.relativeBearing==null)const Text('N',style:TextStyle(fontWeight:FontWeight.bold)),
            Transform.rotate(key:const ValueKey('return-arrow'),angle:(g.relativeBearing??g.bearing)*math.pi/180,child:const Icon(Icons.navigation_rounded,size:96,color:WildColors.forest)),
            Text('${g.cardinal} · ${g.bearing.round()}° dal Nord',key:const ValueKey('return-bearing'),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
            Text(g.relativeBearing==null?'Freccia riferita al Nord geografico: orienta la mappa o usa una bussola.':'Freccia rispetto alla tua direzione di cammino, calcolata dal GPS.',textAlign:TextAlign.center),
          ],
          const SizedBox(height:8),Text('Precisione GPS dichiarata: attuale ${fix!.accuracy.round()} m · punto ${p.accuracy.round()} m',textAlign:TextAlign.center),
        ],
        const SizedBox(height:12),const Text('Distanza in linea d’aria. Sentieri, ostacoli e dislivello non sono calcolati.',textAlign:TextAlign.center),
        const SizedBox(height:8),SelectableText('${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}'),
        TextButton.icon(onPressed:()=>_openMap(p),icon:const Icon(Icons.map_outlined),label:const Text('Apri sulla mappa')),
      ]))),
      const SizedBox(height:20),const Text('I tuoi punti',style:TextStyle(fontFamily:'serif',fontSize:22,fontWeight:FontWeight.bold)),
      if(!loading&&points.isEmpty)const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('Nessun punto salvato. Salva l’auto prima di partire o un bivio lungo il percorso.')),
      for(final point in points)Card(child:ListTile(key:ValueKey('point-${point.id}'),selected:point.id==selected,onTap:()=>setState(()=>selected=point.id),title:Text(point.name),subtitle:Text('${point.kind.label} · ${point.savedAt.toLocal().day}/${point.savedAt.toLocal().month}/${point.savedAt.toLocal().year} · GPS ${point.accuracy.round()} m'),leading:const Icon(Icons.place_outlined),trailing:IconButton(tooltip:'Elimina ${point.name}',onPressed:()=>_remove(point),icon:const Icon(Icons.delete_outline)))),
    ])));
  }
}

class _PointNameDialog extends StatefulWidget {
  const _PointNameDialog({required this.kind});final ReturnPointKind kind;
  @override State<_PointNameDialog> createState()=>_PointNameDialogState();
}
class _PointNameDialogState extends State<_PointNameDialog> {
  late final controller=TextEditingController(text:widget.kind.label);
  @override void dispose(){controller.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AlertDialog(title:Text('Salva ${widget.kind.label.toLowerCase()} qui'),content:TextField(controller:controller,maxLength:80,decoration:const InputDecoration(labelText:'Nome del punto')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Annulla')),FilledButton(onPressed:()=>Navigator.pop(context,controller.text),child:const Text('Salva qui'))]);
}
