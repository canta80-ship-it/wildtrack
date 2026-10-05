import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/nearby_groups_service.dart';
import '../services/preferences_service.dart';
import '../premium_ui.dart';

class NearbyGroupsScreen extends StatefulWidget {
  const NearbyGroupsScreen({super.key});
  @override State<NearbyGroupsScreen> createState() => _NearbyGroupsScreenState();
}
class _NearbyGroupsScreenState extends State<NearbyGroupsScreen> {
  final service = NearbyGroupsService.instance;
  final nearby = Nearby();
  final peers = <String,String>{};
  Map<String,dynamic>? hosting;
  String status = 'Attiva Wi-Fi e Bluetooth su entrambi i telefoni. Internet non serve.';
  bool active = false;
  @override void initState(){ super.initState(); service.load().then((_) { if(mounted)setState((){}); }); }
  @override void dispose(){ nearby.stopAdvertising(); nearby.stopDiscovery(); nearby.stopAllEndpoints(); super.dispose(); }
  void report(String value){ if(mounted)setState(()=>status=value); }
  Future<void> permissions() async {
    final sdk = await const MethodChannel('wildtrack/notifications').invokeMethod<int>('sdk') ?? 33;
    final permissions = <Permission>[Permission.locationWhenInUse,
      if(sdk>=31)...[Permission.bluetoothAdvertise,Permission.bluetoothConnect,Permission.bluetoothScan],
      if(sdk>=33)Permission.nearbyWifiDevices];
    final results=await permissions.request();
    if(results.values.any((s)=>!s.isGranted))throw Exception('Autorizza posizione e dispositivi vicini per collegare i telefoni.');
    if(!await Permission.location.serviceStatus.isEnabled)throw Exception('Attiva il GPS per cercare telefoni vicini.');
  }
  Future<void> stop() async { await nearby.stopAdvertising(); await nearby.stopDiscovery(); await nearby.stopAllEndpoints(); if(mounted)setState((){active=false;peers.clear();}); }
  Future<void> start({bool create=false, Map<String,dynamic>? group}) async {
    try {
      await stop(); await permissions();
      if(create && group==null){
        final controller=TextEditingController();
        final name=await showDialog<String>(context:context,builder:(c)=>AlertDialog(title:const Text('Crea gruppo senza campo'),content:TextField(controller:controller,decoration:const InputDecoration(labelText:'Nome del gruppo')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annulla')),FilledButton(onPressed:()=>Navigator.pop(c,controller.text.trim()),child:const Text('Crea'))]));
        controller.dispose(); if(name==null)return; group=await service.create(name);
      }
      hosting=create?group:null;
      final name=PreferencesService.instance.nickname;
      final bool ok;
      if(create){ok=await nearby.startAdvertising(name,Strategy.P2P_STAR,serviceId:'it.wildtrack.groups.v1',onConnectionInitiated:pair,onConnectionResult:connected,onDisconnected:(id)=>report('Telefono scollegato.'));}
      else {ok=await nearby.startDiscovery(name,Strategy.P2P_STAR,serviceId:'it.wildtrack.groups.v1',onEndpointFound:(id,name,_) {if(mounted)setState(()=>peers[id]=name);},onEndpointLost:(id){if(mounted)setState(()=>peers.remove(id));});}
      if(!ok)throw Exception('Ricerca non avviata. Controlla Wi-Fi e Bluetooth.');
      if(mounted)setState(()=>active=true);
      report(create?'Gruppo pronto. Gli altri telefoni possono cercarti.':'Cerco organizzatori nelle vicinanze…');
    }catch(e){report(e.toString().replaceFirst('Exception: ',''));}
  }
  void pair(String id,ConnectionInfo info) async {
    if(!mounted){await nearby.rejectConnection(id);return;}
    final accept=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text('Collegarti a ${info.endpointName}?'),content:Text('Controllate che entrambi i telefoni mostrino questo codice:\n\n${info.authenticationToken}'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Rifiuta')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Accetta'))]));
    if(accept!=true){await nearby.rejectConnection(id);return;}
    await nearby.acceptConnection(id,onPayLoadRecieved:(endpoint,payload) async {
      if(payload.type!=PayloadType.BYTES || payload.bytes==null || payload.bytes!.length>16000)return;
      try {
        final data=Map<String,dynamic>.from(jsonDecode(utf8.decode(payload.bytes!)) as Map);
        if(data['type']=='group' && hosting==null){
          await service.receive(Map<String,dynamic>.from(data['group'] as Map));
          await send(endpoint,{'type':'member','member':{'id':service.identity,'nickname':PreferencesService.instance.nickname}});
          report('Gruppo ricevuto. Attendo la conferma dell’organizzatore…');
        }else if(data['type']=='member' && hosting!=null){
          await service.addMember(hosting!,Map<String,dynamic>.from(data['member'] as Map));
          await send(endpoint,{'type':'confirmed','groupId':hosting!['id']});
          report('Partecipante aggiunto a ${hosting!['name']}. Sincronizzazione quando torna la rete.');
        }else if(data['type']=='confirmed' && hosting==null){report('Adesione confermata. Il gruppo è salvato sul telefono.');}
        if(mounted)setState((){});
      }catch(e){report('Invito non salvato: $e');}
    },onPayloadTransferUpdate:(_,update){});
  }
  Future<void> send(String id,Map<String,dynamic> value) async {await nearby.sendBytesPayload(id,Uint8List.fromList(utf8.encode(jsonEncode(value))));}
  void connected(String id,Status status) async {
    if(status==Status.CONNECTED && hosting!=null){try{await send(id,{'type':'group','group':{'id':hosting!['id'],'name':hosting!['name'],'owner':hosting!['owner']}});}catch(e){report('Invito non inviato: $e');}}
  }
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:WildColors.ivory,appBar:AppBar(title:const Text('Gruppi senza campo')),body:ListView(padding:const EdgeInsets.all(20),children:[
    const Icon(Icons.wifi_tethering,size:60,color:WildColors.forest),const SizedBox(height:18),
    const Text('Insieme, anche senza rete',style:WildText.h1),const SizedBox(height:10),Text(status),const SizedBox(height:18),
    FilledButton.icon(onPressed:active?null:()=>start(create:true),icon:const Icon(Icons.group_add_outlined),label:const Text('Crea gruppo')),
    OutlinedButton.icon(onPressed:active?null:()=>start(),icon:const Icon(Icons.radar),label:const Text('Cerca gruppo vicino')),
    if(active)TextButton(onPressed:stop,child:const Text('Interrompi collegamento')),
    for(final peer in peers.entries)ListTile(title:Text(peer.value),trailing:const Icon(Icons.chevron_right),onTap:()async{try{await nearby.requestConnection(PreferencesService.instance.nickname,peer.key,onConnectionInitiated:pair,onConnectionResult:connected,onDisconnected:(_)=>report('Telefono scollegato.'));}catch(e){report('$e');}}),
    const Divider(height:30),const Text('Gruppi salvati sul telefono',style:WildText.h2),
    for(final group in service.groups.where((g)=>g['owner']==service.identity || g['mine']==0))ListTile(title:Text('${group['name']}'),subtitle:Text(group['synced']==true?'Sincronizzato':'Creato o ricevuto offline'),trailing:group['owner']==service.identity?IconButton(icon:const Icon(Icons.person_add_alt),tooltip:'Invita nelle vicinanze',onPressed:()=>start(create:true,group:group)):null),
    const SizedBox(height:12),const Text('Il collegamento funziona tra telefoni vicini. Per vedere i dati online, l’organizzatore deve riaprire WildTrack quando torna la connessione.',style:TextStyle(color:WildColors.muted)),
  ]));
}
