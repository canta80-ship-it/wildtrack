import 'outdoor_tools_theme_widget.dart';
import 'package:flutter/material.dart';
import '../premium_ui.dart';
import '../services/outdoor_tools_service.dart';
import '../services/outing_preparation_service.dart';
import 'species_screen.dart';

class OutingPreparationScreen extends StatefulWidget {
  const OutingPreparationScreen({super.key,this.store,this.initialSpecies});
  final OutdoorToolsStore? store;
  final String? initialSpecies;
  @override State<OutingPreparationScreen> createState()=>_OutingPreparationScreenState();
}
class _OutingPreparationScreenState extends State<OutingPreparationScreen> {
  late final OutdoorToolsStore store=widget.store??OutdoorToolsStore.instance;
  late String species=animals.any((a)=>a.name==widget.initialSpecies)?widget.initialSpecies!:animals.first.name;
  OutingSeason season=OutingSeasonName.at(DateTime.now());
  OutingActivity activity=OutingActivity.osservazione;
  Set<String> checked={};bool loading=true;String? error;int generation=0;
  PreparationPlan get plan=>OutingPreparationService.build(species:species,season:season,activity:activity);
  @override void initState(){super.initState();_initial();}
  Future<void> _initial()async {
    try {
      final last=await store.selectedPlan();
      if(last!=null&&widget.initialSpecies==null&&animals.any((a)=>a.name==last['species'])) {
        species=last['species'] as String;season=OutingSeason.values.byName(last['season'] as String);activity=OutingActivity.values.byName(last['activity'] as String);
      }
      await _load();
    }catch(_){if(mounted)setState((){loading=false;error='Preparazione non caricata. Riprova.';});}
  }
  Future<void> _load()async {
    final token=++generation,key=plan.key;
    if(mounted)setState((){loading=true;error=null;});
    try {
      final values=await store.checks(key);
      if(mounted&&token==generation)setState((){checked=values;loading=false;});
    }catch(_){if(mounted&&token==generation)setState((){loading=false;error='Checklist non caricata. Riprova.';});}
  }
  Future<void> _change({String? nextSpecies,OutingSeason? nextSeason,OutingActivity? nextActivity})async {
    setState((){species=nextSpecies??species;season=nextSeason??season;activity=nextActivity??activity;checked={};loading=true;error=null;});
    final selected={'species':species,'season':season.name,'activity':activity.name};
    try{await store.savePlan(selected);await _load();}catch(_){if(mounted)setState((){loading=false;error='Selezione non salvata. Riprova.';});}
  }
  Future<void> _toggle(String id,bool value)async {
    final key=plan.key;
    setState((){if(value){checked.add(id);}else{checked.remove(id);}});
    final values=Set<String>.from(checked);
    try{await store.saveChecks(key,values);}catch(_){if(mounted)setState(()=>error='Modifica non salvata. Riprova prima di chiudere.');}
  }
  Future<void> _reset()async {
    final key=plan.key;
    final confirm=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Azzera questa checklist?'),content:const Text('Le altre preparazioni restano salvate.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Annulla')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Azzera'))]));
    if(confirm!=true)return;
    if(!mounted)return;
    setState(()=>loading=true);
    try{await store.saveChecks(key,{});if(mounted)setState((){checked={};loading=false;});}catch(_){if(mounted)setState((){loading=false;error='Checklist non azzerata. Riprova.';});}
  }
  @override Widget build(BuildContext context) {
    final p=plan,completed=p.items.where((i)=>checked.contains(i.id)).length;
    return OutdoorToolsTheme(child:Scaffold(backgroundColor:WildColors.ivory,appBar:AppBar(title:const Text('Prepara l’uscita')),body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Preparazione dell’uscita',style:WildText.display),
      const SizedBox(height:8),const Text('Scegli specie, stagione e attività. I progressi di ogni checklist vengono salvati sul dispositivo.'),
      const SizedBox(height:16),
      DropdownButtonFormField<String>(key:const ValueKey('preparation-species'),value:species,isExpanded:true,decoration:const InputDecoration(labelText:'Specie'),items:animals.map((a)=>DropdownMenuItem(value:a.name,child:Text(a.name))).toList(),onChanged:loading?null:(v)=>_change(nextSpecies:v)),
      const SizedBox(height:12),
      DropdownButtonFormField<OutingSeason>(key:const ValueKey('preparation-season'),value:season,isExpanded:true,decoration:const InputDecoration(labelText:'Stagione'),items:OutingSeason.values.map((s)=>DropdownMenuItem(value:s,child:Text(s.label))).toList(),onChanged:loading?null:(v)=>_change(nextSeason:v)),
      const SizedBox(height:12),
      DropdownButtonFormField<OutingActivity>(key:const ValueKey('preparation-activity'),value:activity,isExpanded:true,decoration:const InputDecoration(labelText:'Attività'),items:OutingActivity.values.map((a)=>DropdownMenuItem(value:a,child:Text(a.label))).toList(),onChanged:loading?null:(v)=>_change(nextActivity:v)),
      const SizedBox(height:16),
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$species · ${season.label} · ${activity.label}',style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(p.seasonNote),const SizedBox(height:6),Text(p.bestPeriod)]))),
      if(error!=null)...[Text(error!,style:const TextStyle(color:Colors.red)),TextButton(onPressed:_load,child:const Text('Riprova'))],
      if(loading)const LinearProgressIndicator()
      else ...[
        Text('$completed/${p.items.length} completati',key:const ValueKey('preparation-progress'),style:const TextStyle(fontWeight:FontWeight.bold)),
        const SizedBox(height:8),LinearProgressIndicator(value:p.items.isEmpty?0:completed/p.items.length),
        for(final section in p.items.map((i)=>i.section).toSet())...[
          Padding(padding:const EdgeInsets.only(top:20,bottom:4),child:Text(section,style:const TextStyle(fontFamily:'serif',fontSize:20,fontWeight:FontWeight.bold))),
          for(final item in p.items.where((i)=>i.section==section))Card(child:CheckboxListTile(key:ValueKey('check-${item.id}'),value:checked.contains(item.id),onChanged:(v)=>_toggle(item.id,v??false),controlAffinity:ListTileControlAffinity.leading,title:Text(item.title),subtitle:Text(item.detail))),
        ],
        const SizedBox(height:16),OutlinedButton(onPressed:_reset,child:const Text('Azzera questa checklist')),
      ],
    ])));
  }
}
