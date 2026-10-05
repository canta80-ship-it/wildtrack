import 'package:flutter/material.dart';
import 'package:wildtrack_mvp/services/radar_habitat_service.dart';
import 'package:wildtrack_mvp/services/species_ecology_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildtrack_mvp/services/solar_context_service.dart';
import 'package:wildtrack_mvp/services/radar_profile_service.dart';
import 'package:wildtrack_mvp/services/radar_service.dart';
import 'package:wildtrack_mvp/services/wildtrack_intelligence_service.dart';
import 'package:wildtrack_mvp/models/sighting.dart';
import 'package:wildtrack_mvp/services/radar_survey_service.dart';
import 'package:wildtrack_mvp/screens/radar_panel_widget.dart';
import 'package:wildtrack_mvp/screens/species_screen.dart';
import 'package:wildtrack_mvp/screens/species_detail_screen.dart';

Position position(DateTime now,{double latitude=46,double altitude=500,double accuracy=5})=>Position(latitude:latitude,longitude:13,timestamp:now,accuracy:accuracy,altitude:altitude,altitudeAccuracy:10,heading:0,headingAccuracy:1,speed:0,speedAccuracy:1);
Sighting sighting(String species,DateTime now,{double latitude=46,String kind='Animale'})=>Sighting(id:'$species:$now',species:species,count:1,notes:'',latitude:latitude,longitude:13,timestamp:now,kind:kind);
const habitat=HabitatContext(primary:'mosaic',tags:{'forest','meadow','farmland','park','water','wetland'},elevation:500,mapped:true);
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 final engine=WildTrackIntelligenceService.instance;
 test('All 35 catalogue species have forecast profiles, complete new cards and distinct assets',()async{
  expect(radarProfiles.keys.toSet(),animals.map((a)=>a.name).toSet());
  expect(speciesDetails.keys.toSet(),radarProfiles.keys.toSet());
  for(final d in speciesDetails.values.where((d)=>d.newArtwork)){
   expect(d.bestPeriod,isNotEmpty);expect(d.diet,isNotEmpty);expect(d.breeding,isNotEmpty);expect(d.voiceDescription,isNotEmpty);
   expect(d.signs.length,4);expect(d.seasonLevels.length,4);expect(d.seasons.length,4);
   expect((await rootBundle.load('assets/radar_species/${d.asset}_hero.jpg')).lengthInBytes,greaterThan(10000));
   expect((await rootBundle.load('assets/radar_species/${d.asset}_signs.webp')).lengthInBytes,greaterThan(10000));
  }
 });
 test('Solar phase follows date and location, not fixed clock windows',(){
  expect(SolarContext.at(DateTime.utc(2026,10,3,20,27),46,13).phase,'night');
  expect(SolarContext.at(DateTime.utc(2026,10,3,11),46,13).phase,'day');
  expect(SolarContext.at(DateTime.utc(2026,6,21,4),46,13).dark,false);
  expect(SolarContext.at(DateTime.utc(2026,12,21,4),46,13).dark,true);
  final u=DateTime.utc(2026,10,3,11);expect(SolarContext.at(u,46,13).elevation,SolarContext.at(u.toLocal(),46,13).elevation);
 });
 test('Missing, stale or imprecise GPS gives no fabricated forecasts',(){
  final now=DateTime.utc(2026,10,3,11);
  for(final p in [null,position(now.subtract(const Duration(hours:1))),position(now,accuracy:500)]){
   final s=engine.evaluate(now:now,position:p,habitat:habitat,weather:const WeatherContext(temperature:15));
   expect(s.hasPosition,false);expect(s.species,isEmpty);expect(s.weather.temperature,isNull);
  }
 });
 test('Night excludes diurnal birds and separates passive listening from visual encounter',(){
  final now=DateTime.utc(2026,10,3,20,27);
  final s=engine.evaluate(now:now,position:position(now),habitat:habitat,history:[sighting('Poiana',now.subtract(const Duration(days:1))),sighting('Allocco',now.subtract(const Duration(days:1)))]);
  expect(s.species.where((s)=>radarProfiles[s.name]!.cycle=='diurnal'),isEmpty);
  expect(s.listening.any((s)=>s.name=='Allocco'),true);
  expect(s.species.every((s)=>s.score<=32),true);
 });
 test('Capriolo remains eligible at real evening twilight',(){
  final now=DateTime.utc(2026,10,3,16,45);
  expect(SolarContext.at(now,46,13).phase,'dusk');
  final s=engine.evaluate(now:now,position:position(now),habitat:habitat,history:[sighting('Capriolo',now.subtract(const Duration(days:1)))]);
  expect(s.species.any((s)=>s.name=='Capriolo'),true);
 });
 test('Migrants and hibernating mammals are not promoted in winter',(){
  final now=DateTime.utc(2026,1,15,11);
  final s=engine.evaluate(now:now,position:position(now,altitude:1500),habitat:const HabitatContext(primary:'mosaic',tags:{'meadow','rock','forest','park','water','farmland'},elevation:1500,mapped:true));
  expect(s.species.where((s)=>{'Upupa','Assiolo','Nibbio bruno','Marmotta'}.contains(s.name)),isEmpty);
  final night=DateTime.utc(2026,1,15,21);
  final listening=engine.evaluate(now:night,position:position(night),habitat:habitat,evidence:[RadarEvidence('gbif:summer-owl','Assiolo',46,13,DateTime.utc(2025,7,15),'GBIF')]);
  expect(listening.listening.where((s)=>s.name=='Assiolo'),isEmpty);
 });
 test('Old, distant, unpositioned and trace records cannot confirm a local encounter',(){
  final now=DateTime.utc(2026,10,3,11);
  final s=engine.evaluate(now:now,position:position(now),habitat:habitat,history:[sighting('Cervo',now.subtract(const Duration(days:400))),sighting('Cervo',now.subtract(const Duration(days:1)),latitude:43),sighting('Cervo',now.subtract(const Duration(days:1)),kind:'Impronta')]);
  expect(s.species.firstWhere((s)=>s.name=='Cervo').presenceSupported,false);
 });
 test('Regional evidence is positive support; missing records are not species absence',(){
  final now=DateTime.utc(2026,10,3,11);
  final plain=engine.evaluate(now:now,position:position(now),habitat:habitat);
  expect(plain.species.any((s)=>s.name=='Poiana'),true);
  final withEvidence=engine.evaluate(now:now,position:position(now),habitat:habitat,evidence:[RadarEvidence('gbif:1','Gheppio',46,13,now.subtract(const Duration(days:2)),'GBIF')]);
  expect(withEvidence.species.firstWhere((s)=>s.name=='Gheppio').presenceSupported,true);
  expect(withEvidence.species.firstWhere((s)=>s.name=='Gheppio').score,greaterThan(plain.species.firstWhere((s)=>s.name=='Gheppio').score));
 });
 test('Unknown habitat is not fabricated from altitude',(){
  final now=DateTime.utc(2026,10,3,11);
  final s=engine.evaluate(now:now,position:position(now,altitude:2000));
  expect(s.habitat.primary,'unknown');expect(s.species,isEmpty);expect(s.listening,isEmpty);
 });
 test('Incompatible mapped habitat or reliable altitude cannot promote a species',(){
  final now=DateTime.utc(2026,10,3,11);
  final s=engine.evaluate(now:now,position:position(now),habitat:const HabitatContext(primary:'forest',tags:{'forest'},elevation:500,mapped:true));
  expect(s.species.where((s)=>{'Germano reale','Airone cenerino','Stambecco','Marmotta'}.contains(s.name)),isEmpty);
 });
 test('Negative surveys are explicit descriptive counts, not predicted probabilities',(){
  final now=DateTime.utc(2026,10,3,11);
  final s=engine.evaluate(now:now,position:position(now),habitat:habitat,surveys:[RadarSurvey(species:'Cervo',latitude:46,longitude:13,at:now.subtract(const Duration(days:1)),minutes:30,seen:false,phase:'day')]);
  expect(s.species.firstWhere((s)=>s.name=='Cervo').reason,contains('0/1 con incontro'));
 });
 test('All species have sourced ecology and no arbitrary default altitude limit',(){
  expect(speciesEcology.keys.toSet(),radarProfiles.keys.toSet());
  for(final e in speciesEcology.values){expect(e.source,startsWith('https://'));expect(e.habitat,isNotEmpty);expect(e.altitudeNote,isNotEmpty);}
  expect(speciesEcology['Marmotta']!.minimum,800);
  expect(speciesEcology['Volpe']!.maximum,isNull);
 });
 test('Unmapped, expired and distant habitat suppress both lists even with local records',(){
  final now=DateTime.utc(2026,10,3,20);
  for(final h in [const HabitatContext(primary:'forest',tags:{'forest'}),HabitatContext(primary:'forest',tags:{'forest'},mapped:true,fetchedAt:now.subtract(const Duration(hours:1))),HabitatContext(primary:'forest',tags:{'forest'},mapped:true,latitude:47,longitude:13)]){
   final s=engine.evaluate(now:now,position:position(now),habitat:h,history:[sighting('Allocco',now.subtract(const Duration(days:1)))]);
   expect(s.species,isEmpty);expect(s.listening,isEmpty);expect(s.hasPosition,true);
  }
 });
 test('Waterways are local habitats; remote ponds and missing geometry are rejected',(){
  final p=position(DateTime.now());
  final tags=RadarHabitatService.tags({'elements':[
   {'type':'way','tags':{'waterway':'stream'},'geometry':[{'lat':45.999,'lon':13.001},{'lat':46.001,'lon':13.001}]},
   {'type':'node','lat':46.02,'lon':13,'tags':{'natural':'wetland'}},
   {'type':'way','tags':{'natural':'wood'}}
  ]},p);
  expect(tags,{'water','stream'});
  expect(RadarHabitatService.query(p),contains('waterway'));
  expect(RadarHabitatService.tags({'remark':'timeout','elements':[{'type':'area','tags':{'natural':'wood'}}]},p),isEmpty);
 });
 test('A river alone cannot suggest a pond-breeding newt or a forest salamander',(){
  final now=DateTime.utc(2026,5,3,20);
  final s=engine.evaluate(now:now,position:position(now),habitat:const HabitatContext(primary:'water',tags:{'water','river'},elevation:500,mapped:true),history:[sighting('Tritone',now.subtract(const Duration(days:1))),sighting('Salamandra',now.subtract(const Duration(days:1)))]);
  expect(s.species.where((s)=>{'Tritone','Salamandra'}.contains(s.name)),isEmpty);
 });
 test('A large enclosing forest is loaded even when its edges exceed search radius',(){
  final p=position(DateTime.now());
  final ring=[{'lat':45.99,'lon':12.99},{'lat':45.99,'lon':13.01},{'lat':46.01,'lon':13.01},{'lat':46.01,'lon':12.99},{'lat':45.99,'lon':12.99}];
  expect(RadarHabitatService.tags({'elements':[{'type':'way','tags':{'landuse':'forest'},'geometry':ring}]},p),{'forest'});
 });
 test('Plain meadows cannot suggest alpine specialists without compatible quota',(){
  final now=DateTime.utc(2026,7,3,11);
  for(final altitude in <double?>[100,null]){
   final s=engine.evaluate(now:now,position:position(now),habitat:HabitatContext(primary:'meadow',tags:{'meadow','rock'},mapped:true,elevation:altitude));
   expect(s.species.where((s)=>{'Marmotta','Stambecco','Camoscio alpino','Gracchio alpino'}.contains(s.name)),isEmpty);
  }
  final mountain=engine.evaluate(now:now,position:position(now,altitude:2200),habitat:const HabitatContext(primary:'meadow',tags:{'meadow','rock'},mapped:true,elevation:2200));
  expect(mountain.species.any((s)=>s.name=='Marmotta'),true);
 });
 test('Source quota is typical: supported exceptions are penalized, not declared impossible',(){
  final now=DateTime.utc(2026,7,3,20);
  final s=engine.evaluate(now:now,position:position(now,altitude:1200),habitat:const HabitatContext(primary:'farmland',tags:{'farmland'},mapped:true,elevation:1200),history:[sighting('Assiolo',now.subtract(const Duration(days:1)))]);
  expect(s.species.any((s)=>s.name=='Assiolo'),true);
  expect(s.species.firstWhere((s)=>s.name=='Assiolo').reason,contains('fascia tipica documentata'));
 });
 test('GPS movement, elevation changes and lost GPS invalidate cached suggestions',()async{
  final now=DateTime.utc(2026,7,3,11);var p=position(now);var calls=0;
  final radar=RadarService(clock:()=>now,positionProvider:()async=>p,loader:(p)async{calls++;return RadarSnapshot(activity:'LIMITATE',species:const [],hasPosition:p!=null,latitude:p?.latitude,longitude:p?.longitude,elevation:p?.altitude);});
  await radar.load();await radar.load();expect(calls,1);
  p=position(now,latitude:46.0004);await radar.load();expect(calls,1);
  p=position(now,latitude:46.004);await radar.load();expect(calls,2);
  p=position(now,latitude:46.004,altitude:1000);await radar.load();expect(calls,3);
  p=position(now.subtract(const Duration(hours:1)));expect((await radar.load()).hasPosition,false);expect(calls,4);
 });
 testWidgets('Radar hides old area while new habitat is loading',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:RadarPanel(snapshot:const RadarSnapshot(activity:'BUONE',hasPosition:true,habitat:'forest',species:[RadarSpecies('Cervo',70)]),loading:true,onRefresh:()async{}))));
  expect(find.text('Cervo'),findsNothing);expect(find.byType(LinearProgressIndicator),findsOneWidget);
  await tester.pumpWidget(const SizedBox());
 });
 testWidgets('Radar home uses supplied ranking and no percentage or fixed deer fallback',(tester)async{
  tester.view.physicalSize=const Size(360,844);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:SingleChildScrollView(child:RadarPanel(snapshot:RadarSnapshot(activity:'DISCRETE',hasPosition:true,habitat:'forest',generatedAt:DateTime(2026,10,3,11),solar:const SolarContext('day',30,null,null),species:const [RadarSpecies('Upupa',48),RadarSpecies('Gheppio',45)]),onRefresh:()async{})))));
  await tester.pumpAndSettle();expect(find.text('Upupa'),findsOneWidget);expect(find.text('Gheppio'),findsOneWidget);expect(find.text('Cervo'),findsNothing);expect(find.text('82%'),findsNothing);expect(tester.takeException(),isNull);
  await tester.tap(find.text('Upupa'));await tester.pumpAndSettle();expect(find.text('Apri scheda completa'),findsOneWidget);
 });
}
