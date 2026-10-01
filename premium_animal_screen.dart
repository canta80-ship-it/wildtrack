import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'species_screen.dart';
import 'exploration_screen.dart';
import '../premium_ui.dart';

class PremiumAnimalScreen extends StatelessWidget {
  const PremiumAnimalScreen(this.animal, {super.key});
  final Animal animal;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    body: CustomScrollView(slivers:[
      SliverToBoxAdapter(child:SizedBox(height:430,child:Stack(fit:StackFit.expand,children:[
        WildLandscape(height:430,darkBottom:true,animal:animal.name),
        const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0x04FFFFFF),Color(0x11000000),Color(0xB817241B)]))),
        SafeArea(bottom:false,child:Padding(padding:const EdgeInsets.fromLTRB(15,8,15,22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[CircleAvatar(backgroundColor:Colors.white.withValues(alpha:.92),child:IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back_ios_new,color:WildColors.forest,size:18))),const Spacer(),const WildLogo(compact:true,light:true),const Spacer(),CircleAvatar(backgroundColor:Colors.white.withValues(alpha:.92),child:const Icon(Icons.favorite_border,color:WildColors.forest))]),
          const Spacer(),
          Text(animal.name,style:const TextStyle(fontFamily:'serif',fontSize:52,height:.9,fontWeight:FontWeight.w800,color:Colors.white)),
          const SizedBox(height:4),Text(animal.latin,style:const TextStyle(fontFamily:'serif',fontStyle:FontStyle.italic,fontSize:21,color:Colors.white)),
          const SizedBox(height:15),
          Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),decoration:BoxDecoration(color:const Color(0xDD173F2B),borderRadius:BorderRadius.circular(20)),child:const Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.bar_chart,color:Color(0xFF8CDF78)),SizedBox(width:7),Text('Attività: ALTA',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),SizedBox(width:5),Text('· alba e tramonto',style:TextStyle(color:Colors.white70,fontSize:10))]))
        ])))
      ]))),
      SliverPadding(padding:const EdgeInsets.fromLTRB(14,12,14,45),sliver:SliverList(delegate:SliverChildListDelegate([
        Row(children:[
          Expanded(child:_InfoCard(icon:Icons.eco_outlined,title:'Specie',body:animal.group)),
          const SizedBox(width:8),const Expanded(child:_InfoCard(icon:Icons.shield_outlined,title:'Conservazione',body:'Consulta la fonte')), 
          const SizedBox(width:8),const Expanded(child:_InfoCard(icon:Icons.straighten,title:'Dimensioni',body:'Varia per sesso/età')),
        ]),
        const SizedBox(height:18),
        _Title('Habitat',action:'Vedi sulla mappa',onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>ExplorationScreen(species:animal.name)))),
        const SizedBox(height:8),
        _IllustratedHabitat(animal:animal.name,text:animal.habitat),
        const SizedBox(height:18),
        const _Title('Segni e impronte'),
        const SizedBox(height:8),
        TrackCard(animal),
        const SizedBox(height:18),
        const _Title('Periodo migliore'),
        const SizedBox(height:8),
        const Row(children:[
          Expanded(child:_Season(icon:Icons.local_florist_outlined,label:'Primavera',level:.45)),SizedBox(width:6),
          Expanded(child:_Season(icon:Icons.wb_sunny_outlined,label:'Estate',level:.5)),SizedBox(width:6),
          Expanded(child:_Season(icon:Icons.eco_outlined,label:'Autunno',level:.9,hot:true)),SizedBox(width:6),
          Expanded(child:_Season(icon:Icons.ac_unit,label:'Inverno',level:.25)),
        ]),
        const SizedBox(height:18),
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:_Panel(title:'Consigli fotografici',icon:Icons.camera_alt_outlined,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_Tip(animal.behaviour),const _Tip('Mantieni distanza e usa un teleobiettivo quando possibile.'),const _Tip('Evita richiami, flash e inseguimenti.')]))),
          const SizedBox(width:8),
          Expanded(child:_Panel(title:'Versi',icon:Icons.volume_up_outlined,child:animal.audio==null?const Text('Registrazione verificata non disponibile per questa specie.',style:TextStyle(fontSize:11,color:WildColors.muted)):AudioTile(animal))),
        ]),
        const SizedBox(height:18),
        _Panel(title:'Ecologia e rispetto',icon:Icons.eco,child:Text(animal.ecology,style:const TextStyle(height:1.35))),
        const SizedBox(height:12),
        WildOutlineButton(label:'Fonte naturalistica',icon:Icons.open_in_new,onPressed:()=>launchUrl(Uri.parse(animal.source),mode:LaunchMode.externalApplication)),
      ])))
    ])
  );
}

class _IllustratedHabitat extends StatelessWidget {
  const _IllustratedHabitat({required this.animal,required this.text});
  final String animal,text;
  @override
  Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(10),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),
    child:Row(children:[
      ClipRRect(borderRadius:BorderRadius.circular(15),child:SizedBox(width:145,height:100,child:WildLandscape(height:100,animal:animal))),
      const SizedBox(width:12),
      Expanded(child:Text(text,style:const TextStyle(fontSize:12,height:1.3,color:WildColors.muted))),
    ]),
  );
}

class _InfoCard extends StatelessWidget{const _InfoCard({required this.icon,required this.title,required this.body});final IconData icon;final String title,body;@override Widget build(BuildContext context)=>Container(height:115,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:WildColors.forest),const Spacer(),Text(title,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800)),Text(body,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:WildColors.muted))]));}
class _Title extends StatelessWidget{const _Title(this.text,{this.action,this.onTap});final String text;final String? action;final VoidCallback? onTap;@override Widget build(BuildContext context)=>Row(children:[Expanded(child:Text(text,style:WildText.h2)),if(action!=null)TextButton(onPressed:onTap,child:Text(action!,style:const TextStyle(color:WildColors.muted,fontSize:11))) ]);}
class _Season extends StatelessWidget{const _Season({required this.icon,required this.label,required this.level,this.hot=false});final IconData icon;final String label;final double level;final bool hot;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:hot?const Color(0xFFF6E5C8):Colors.white,borderRadius:BorderRadius.circular(17)),child:Column(children:[Icon(icon,color:hot?WildColors.amber:WildColors.forest),const SizedBox(height:5),Text(label,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w800)),const SizedBox(height:8),ClipRRect(borderRadius:BorderRadius.circular(6),child:LinearProgressIndicator(value:level,minHeight:5,color:hot?WildColors.amber:WildColors.forest,backgroundColor:WildColors.cream))]));}
class _Panel extends StatelessWidget{const _Panel({required this.title,required this.icon,required this.child});final String title;final IconData icon;final Widget child;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon,color:WildColors.forest),const SizedBox(width:6),Expanded(child:Text(title,style:const TextStyle(fontFamily:'serif',fontWeight:FontWeight.w800,fontSize:17)))]),const SizedBox(height:10),child]));}
class _Tip extends StatelessWidget{const _Tip(this.text);final String text;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:7),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.check_circle,size:15,color:Color(0xFF65A35A)),const SizedBox(width:5),Expanded(child:Text(text,maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,height:1.25)))]));}
