import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/exploration_service.dart';
import '../services/location_service.dart';
import '../services/radar_service.dart';
import '../premium_ui.dart';
import 'species_screen.dart';

class PremiumExploreScreen extends StatefulWidget {
  const PremiumExploreScreen({super.key});
  @override
  State<PremiumExploreScreen> createState() => _PremiumExploreScreenState();
}

class _PremiumExploreScreenState extends State<PremiumExploreScreen> {
  final map=MapController();
  final search=TextEditingController();
  late Future<RadarSnapshot> radar=RadarService.instance.load();
  List<NatureTrail> trails=[];
  bool loading=false;
  int filter=0;
  LatLng center=const LatLng(46.061,12.403);

  @override
  void initState(){super.initState();_load();}
  @override
  void dispose(){search.dispose();map.dispose();super.dispose();}

  Future<void> _load() async {
    try{final rows=await ExplorationService.instance.presets();if(mounted)setState(()=>trails=rows);}catch(_){}
  }

  Future<void> nearby() async {
    if(loading)return;setState(()=>loading=true);
    try{final rows=await ExplorationService.instance.nearby(map.camera.center);if(mounted)setState(()=>trails=rows);}finally{if(mounted)setState(()=>loading=false);}
  }

  Future<void> locate() async {
    final p=await LocationService.currentPosition();if(p!=null&&mounted){final c=LatLng(p.latitude,p.longitude);setState(()=>center=c);map.move(c,14);}
  }

  List<Marker> get markers => [
    Marker(point:const LatLng(46.07,12.42),width:52,height:52,child:_AnimalMarker(icon:Icons.pets,onTap:()=>_species('Cervo'))),
    Marker(point:const LatLng(46.04,12.45),width:52,height:52,child:_AnimalMarker(icon:Icons.pets,onTap:()=>_species('Capriolo'))),
    Marker(point:const LatLng(46.03,12.39),width:52,height:52,child:_AnimalMarker(icon:Icons.visibility_outlined,earth:true,onTap:()=>_species('Volpe'))),
    Marker(point:const LatLng(46.085,12.46),width:52,height:52,child:_AnimalMarker(icon:Icons.flutter_dash,earth:true,onTap:()=>_species('Poiana'))),
  ];

  void _species(String name){final a=animals.firstWhere((e)=>e.name==name);Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>PremiumAnimalScreen(a)));}

  @override
  Widget build(BuildContext context){final active=trails.isEmpty?null:trails.first;return Scaffold(
    body:SafeArea(bottom:false,child:Stack(children:[
      FlutterMap(mapController:map,options:MapOptions(initialCenter:center,initialZoom:12.3,onPositionChanged:(p,_)=>center=p.center),children:[
        TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'it.wildtrack.wildtrack_mvp'),
        if(active!=null) PolylineLayer(polylines:[for(final seg in active.segments)Polyline(points:seg,strokeWidth:4,color:WildColors.forest)]),
        MarkerLayer(markers:markers),
        const RichAttributionWidget(attributions:[TextSourceAttribution('OpenStreetMap contributors')]),
      ]),
      Positioned(top:8,left:14,right:14,child:Column(children:[
        Row(children:[const WildLogo(compact:true),const Spacer(),const Icon(Icons.notifications_none,color:WildColors.forest),const SizedBox(width:10),const CircleAvatar(radius:18,backgroundImage:AssetImage('intro_cervo.jpg'))]),
        const SizedBox(height:12),
        Container(decoration:BoxDecoration(color:Colors.white.withValues(alpha:.96),borderRadius:BorderRadius.circular(22),boxShadow:const[BoxShadow(color:Color(0x18000000),blurRadius:15)]),child:TextField(controller:search,decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Cerca sentieri, specie, luoghi…',suffixIcon:IconButton(onPressed:nearby,icon:const Icon(Icons.tune)),border:InputBorder.none)),
        const SizedBox(height:9),
        _Filters(selected:filter,onTap:(i)=>setState(()=>filter=i)),
        const SizedBox(height:9),
        FutureBuilder<RadarSnapshot>(future:radar,builder:(context,s){final d=s.data;final top=d?.species.take(2).map((e)=>e.name.toLowerCase()).join(', ')??'calcolo in corso';return InkWell(onTap:()=>setState(()=>radar=RadarService.instance.load()),child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.95),borderRadius:BorderRadius.circular(22),boxShadow:const[BoxShadow(color:Color(0x18000000),blurRadius:15)]),child:Row(children:[const WildIconDisc(Icons.radar,size:50,background:WildColors.forest,foreground:Colors.white),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('WildTrack Radar',style:TextStyle(fontFamily:'serif',fontWeight:FontWeight.w800,fontSize:18)),Text('Probabilità ${d?.activity.toLowerCase()??'…'}: $top',style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),const Text('Stima basata su ora, stagione, meteo e storico privato',style:TextStyle(fontSize:9,color:WildColors.muted))])),const Icon(Icons.chevron_right)])));}),
      ])),
      Positioned(right:14,bottom:215,child:Column(children:[
        _MapButton(icon:Icons.layers_outlined,onTap:nearby),const SizedBox(height:8),_MapButton(icon:Icons.my_location,onTap:locate),const SizedBox(height:8),_MapButton(icon:Icons.navigation,onTap:locate),
      ])),
      Positioned(left:14,right:14,bottom:20,child:_TrailCard(trail:active,onRefresh:nearby)),
      if(loading)const Positioned(top:0,left:0,right:0,child:LinearProgressIndicator()),
    ])),
  );}
}

class _Filters extends StatelessWidget{const _Filters({required this.selected,required this.onTap});final int selected;final ValueChanged<int> onTap;static const data=[(Icons.hiking,'Sentieri'),(Icons.pets,'Specie'),(Icons.groups_outlined,'Community'),(Icons.radar,'Radar')];@override Widget build(BuildContext context)=>Row(children:[for(var i=0;i<data.length;i++)Expanded(child:Padding(padding:EdgeInsets.only(right:i==data.length-1?0:6),child:InkWell(onTap:()=>onTap(i),borderRadius:BorderRadius.circular(20),child:Container(height:43,decoration:BoxDecoration(color:selected==i?WildColors.forest:Colors.white.withValues(alpha:.94),borderRadius:BorderRadius.circular(20)),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(data[i].$1,size:17,color:selected==i?Colors.white:WildColors.forest),const SizedBox(width:4),Text(data[i].$2,style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:selected==i?Colors.white:WildColors.ink))])))))]);}
class _AnimalMarker extends StatelessWidget{const _AnimalMarker({required this.icon,required this.onTap,this.earth=false});final IconData icon;final VoidCallback onTap;final bool earth;@override Widget build(BuildContext context)=>InkWell(onTap:onTap,child:CircleAvatar(backgroundColor:Colors.white,child:CircleAvatar(radius:20,backgroundColor:earth?WildColors.earth:WildColors.forest,child:Icon(icon,color:Colors.white,size:21))));}
class _MapButton extends StatelessWidget{const _MapButton({required this.icon,required this.onTap});final IconData icon;final VoidCallback onTap;@override Widget build(BuildContext context)=>Material(color:Colors.white,borderRadius:BorderRadius.circular(17),elevation:3,child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(17),child:SizedBox(width:52,height:52,child:Icon(icon,color:WildColors.forest))));}
class _TrailCard extends StatelessWidget{const _TrailCard({required this.trail,required this.onRefresh});final NatureTrail? trail;final VoidCallback onRefresh;@override Widget build(BuildContext context)=>Container(height:175,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.97),borderRadius:BorderRadius.circular(25),boxShadow:const[BoxShadow(color:Color(0x25000000),blurRadius:22,offset:Offset(0,7))]),child:trail==null?Center(child:FilledButton.icon(onPressed:onRefresh,icon:const Icon(Icons.hiking),label:const Text('Carica sentieri qui'))):Row(children:[ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.asset('intro_cervo.jpg',width:135,height:145,fit:BoxFit.cover)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(trail!.name,style:const TextStyle(fontFamily:'serif',fontWeight:FontWeight.w800,fontSize:19),maxLines:2,overflow:TextOverflow.ellipsis),const SizedBox(height:4),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:WildColors.sageSoft,borderRadius:BorderRadius.circular(10)),child:const Text('Sentiero OSM',style:TextStyle(fontSize:9,color:WildColors.forest,fontWeight:FontWeight.w700))),const Spacer(),const Text('Tra boschi e paesaggi naturali, con possibilità di osservazione.',style:TextStyle(fontSize:10,color:WildColors.muted,height:1.25)),const Spacer(),Row(children:[const Icon(Icons.route,size:15),const SizedBox(width:4),Text('${(trail!.length/1000).toStringAsFixed(1)} km',style:const TextStyle(fontSize:10)),const Spacer(),const Icon(Icons.chevron_right)])]))]));}
