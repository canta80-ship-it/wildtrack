import 'dart:io';
import 'package:wildtrack_mvp/services/nearby_groups_service.dart';
import 'package:wildtrack_mvp/services/preferences_service.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildtrack_mvp/services/photo_processing_service.dart';
import 'package:wildtrack_mvp/services/did_you_know_service.dart';
import 'package:wildtrack_mvp/services/habitat_map_service.dart';
import 'package:wildtrack_mvp/screens/species_screen.dart';
import 'package:wildtrack_mvp/screens/species_detail_screen.dart';
import 'package:latlong2/latlong.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 test('Offline groups persist approved members without transmitting the account token',()async{
  final dir=await Directory.systemTemp.createTemp('wildtrack-nearby');
  final prefs=PreferencesService.instance; final original=prefs.token;
  File? oldFile;try{oldFile=prefs.file;}catch(_){}
  final service=NearbyGroupsService.instance;
  try{
   prefs.file=File('${dir.path}/prefs.json');prefs.token='a'*64;service.groups.clear();service.loaded=false;
   final group=await service.create('Gruppo montagna');
   await service.addMember(group,{'id':'b'*64,'nickname':'Compagno'});
   await service.addMember(group,{'id':'b'*64,'nickname':'Compagno'});
   expect((group['members'] as List).length,1);expect((group['pendingMembers'] as List).length,1);
   final saved=await service.file.readAsString();expect(saved,contains('Gruppo montagna'));expect(saved,contains('Compagno'));expect(saved, isNot(contains(prefs.token)));
   service.groups.clear();service.loaded=false;await service.load();
   expect(service.groups.single['id'],group['id']);expect(service.groups.single['synced'],false);
  }finally{service.groups.clear();service.loaded=false;prefs.token=original;if(oldFile!=null)prefs.file=oldFile;await dir.delete(recursive:true);}
 });
 test('Avatar crop preserves proportions and discards side margins',()async{
  final recorder=ui.PictureRecorder();final canvas=ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0,0,400,200),ui.Paint()..color=const ui.Color(0xFFFF0000));
  canvas.drawRect(const ui.Rect.fromLTWH(100,0,200,200),ui.Paint()..color=const ui.Color(0xFF00FF00));
  final picture=recorder.endRecording();final image=await picture.toImage(400,200);picture.dispose();
  final data=await image.toByteData(format:ui.ImageByteFormat.png);image.dispose();
  final encoded=await PhotoProcessingService.encode(data!.buffer.asUint8List(),avatar:true);
  final codec=await ui.instantiateImageCodec(base64Decode(encoded));final frame=await codec.getNextFrame();codec.dispose();
  expect(frame.image.width,256);expect(frame.image.height,256);
  final pixels=await frame.image.toByteData(format:ui.ImageByteFormat.rawRgba);frame.image.dispose();
  final center=(128*256+128)*4;expect(pixels!.getUint8(center),0);expect(pixels.getUint8(center+1),255);
  expect(pixels.getUint8((128*256+8)*4+1),255);
 });
 test('Feed drops outdated and future news, keeps evergreen guides',(){
  final now=DateTime(2026,10,5);
  DidYouKnowItem item(String id,int days,{bool live=true})=>DidYouKnowItem(id:id,category:'FAUNA',title:id,body:'test',asset:'',source:'test',publishedAt:now.subtract(Duration(days:days)),isLive:live);
  expect(DidYouKnowService.freshItems([item('old',60),item('future',-2),item('recent',2),item('guide',100,live:false)],now:now).map((e)=>e.id),['recent','guide']);
  expect(DidYouKnowService.parksDate('Udine, 5 Ott 26'),DateTime(2026,10,5));
  expect(DidYouKnowService.parksDate('nessuna data'),isNull);
 });
 test('All four added species have complete matching cards and habitat layers',(){
  for(final name in ['Lince','Tritone','Rospo','Salamandra']){
   final animal=animals.firstWhere((a)=>a.name==name);final d=speciesDetails[name]!;
   expect(animal.description,isNotEmpty);expect(animal.ecology,isNotEmpty);
   expect(d.bestPeriod,isNotEmpty);expect(d.breeding,isNotEmpty);expect(d.diet,isNotEmpty);expect(d.voiceDescription,isNotEmpty);expect(d.signs.length,4);expect(d.seasons.length,4);
   expect(HabitatMapService.instance.query(name,const LatLng(46,13)),contains('out geom'));
  }
 });
 test('Every usable species call is bundled with credits and actual bytes',()async{
  final manifest=jsonDecode(await rootBundle.loadString('assets/audio/manifest.json')) as Map;
  for(final a in animals.where((a)=>a.audio!=null)){
   final info=manifest[a.audio] as Map;expect(info['credit'],isNotEmpty);expect(info['page'],startsWith('https://commons.wikimedia.org/'));
   expect((await rootBundle.load(info['asset'] as String)).lengthInBytes,greaterThan(100));
  }
 });
}
