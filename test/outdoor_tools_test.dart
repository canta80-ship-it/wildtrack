import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildtrack_mvp/services/outdoor_tools_service.dart';
import 'package:wildtrack_mvp/services/outing_preparation_service.dart';
import 'package:wildtrack_mvp/screens/species_screen.dart';
import 'package:wildtrack_mvp/screens/outing_preparation_screen.dart';
import 'package:wildtrack_mvp/screens/return_point_screen.dart';

final at=DateTime.utc(2026,10,3,10);
Position fix({double lat=0,double lon=0,double accuracy=5,DateTime? time,double heading=0,double speed=0})=>Position(latitude:lat,longitude:lon,timestamp:time??at,accuracy:accuracy,altitude:0,altitudeAccuracy:1,heading:heading,headingAccuracy:5,speed:speed,speedAccuracy:1);
ReturnPoint point(double lat,double lon)=>ReturnPoint(id:'p',name:'Auto',kind:ReturnPointKind.auto,latitude:lat,longitude:lon,accuracy:5,savedAt:at);
class FakeGps implements PointLocationSource {
  Position value=fix();
  final events=StreamController<Position>.broadcast();
  @override Future<Position> current({bool requestPermission=false})async=>value;
  @override Stream<Position> watch()=>events.stream;
}
Future<void> flush(WidgetTester t)async {
  for(var i=0;i<30;i++){await t.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:50)));await t.pump();}
  await t.pumpAndSettle();
}
void main(){
  late Directory dir;late OutdoorToolsStore store;
  setUp(()async{dir=await Directory.systemTemp.createTemp('wildtrack-tools-test-');store=OutdoorToolsStore(directory:dir);});
  tearDown(()async{await dir.delete(recursive:true);});
  test('Every catalogue species supports every season and activity with unique checklist IDs',(){
    expect(animals.length,35);
    for(final animal in animals){for(final season in OutingSeason.values){for(final activity in OutingActivity.values){
      final plan=OutingPreparationService.build(species:animal.name,season:season,activity:activity);
      expect(plan.items.length,greaterThan(9));expect(plan.items.map((i)=>i.id).toSet().length,plan.items.length);
      expect(plan.items.firstWhere((i)=>i.id=='species_habitat').title,contains(animal.name));expect(plan.seasonNote,isNotEmpty);
    }}}
  });
  test('Checklist changes according to season and activity',(){
    PreparationPlan plan(OutingSeason s,OutingActivity a)=>OutingPreparationService.build(species:'Cervo',season:s,activity:a);
    expect(plan(OutingSeason.estate,OutingActivity.fotografia).items.map((i)=>i.id),containsAll(['heat','camera','photo_settings']));
    expect(plan(OutingSeason.inverno,OutingActivity.escursione).items.map((i)=>i.id),containsAll(['winter','map','kit']));
    expect(plan(OutingSeason.primavera,OutingActivity.ascolto).items.map((i)=>i.id),containsAll(['spring','quiet','light','voice']));
    expect(plan(OutingSeason.autunno,OutingActivity.osservazione).items.map((i)=>i.id),containsAll(['autumn','binoculars']));
  });
  test('Local season boundaries include January and December',(){for(final c in [(1,OutingSeason.inverno),(3,OutingSeason.primavera),(6,OutingSeason.estate),(9,OutingSeason.autunno),(12,OutingSeason.inverno)]){expect(OutingSeasonName.at(DateTime(2026,c.$1)),c.$2);}});
  test('Known cardinal distances and bearings: north east south west',(){for(final c in [(0.001,0.0,0.0,'N'),(0.0,0.001,90.0,'E'),(-0.001,0.0,180.0,'S'),(0.0,-0.001,270.0,'O')]){
    final g=ReturnGuidance.calculate(fix(),point(c.$1,c.$2),at)!;expect(g.distance,closeTo(111.195,0.05));expect(g.bearing,closeTo(c.$3,0.01));expect(g.cardinal,c.$4);expect(g.near,isFalse);
  }});
  test('Dateline distance follows shortest geodesic',(){final g=ReturnGuidance.calculate(fix(lon:179.999),point(0,-179.999),at)!;expect(g.distance,closeTo(222.39,.1));expect(g.bearing,90);});
  test('Walking arrow uses GPS heading; stationary arrow uses north',(){expect(ReturnGuidance.calculate(fix(speed:2,heading:90),point(.001,0),at)!.relativeBearing,270);expect(ReturnGuidance.calculate(fix(),point(.001,0),at)!.relativeBearing,isNull);});
  test('Arrival uses GPS accuracy and suppresses unstable direction',(){expect(ReturnGuidance.calculate(fix(),point(.00001,0),at)!.near,isTrue);});
  test('Stale imprecise invalid and future GPS do not produce guidance',(){for(final p in [fix(time:at.subtract(const Duration(minutes:2))),fix(accuracy:101),fix(accuracy:0),fix(lat:91),fix(time:at.add(const Duration(minutes:1)))]){expect(ReturnGuidance.calculate(p,point(.001,0),at),isNull);}});
  test('Points and separate checklist progress survive reopening and concurrent writes',()async{
    await Future.wait([store.saveChecks('a',{'water'}),store.saveChecks('b',{'camera'}),store.savePlan({'species':'Cervo','season':'autunno','activity':'fotografia'})]);
    final p=await store.savePoint(name:' Parcheggio ',kind:ReturnPointKind.auto,position:fix(),now:at);
    final reopened=OutdoorToolsStore(directory:dir);expect((await reopened.points()).single.name,'Parcheggio');expect(await reopened.checks('a'),{'water'});expect(await reopened.checks('b'),{'camera'});expect((await reopened.selectedPlan())!['activity'],'fotografia');
    await reopened.saveChecks('a',{});expect(await reopened.checks('b'),{'camera'});await reopened.removePoint(p.id);expect(await reopened.points(),isEmpty);
  });
  test('Bad GPS cannot save a return point',()async{await expectLater(store.savePoint(name:'Auto',kind:ReturnPointKind.auto,position:fix(accuracy:150),now:at),throwsA(isA<PointLocationException>()));expect(await store.points(),isEmpty);});
  test('Snapshot restores checklist and points; invalid snapshot preserves archive',()async{
    await store.saveChecks('a',{'water'});await store.savePoint(name:'Bivio',kind:ReturnPointKind.bivio,position:fix(),now:at);final snapshot=await store.exportSnapshot();await store.restoreSnapshot(OutdoorToolsStore.empty());await store.restoreSnapshot(snapshot);expect((await store.points()).single.kind,ReturnPointKind.bivio);expect(await store.checks('a'),{'water'});expect(()=>store.restoreSnapshot({'version':1,'points':[{'id':'bad'}],'checklists':{}}),throwsA(anything));expect(await store.exportSnapshot(),snapshot);
  });
  testWidgets('Premium checklist saves checkbox and selected activity across reopening',(t)async{
    t.view.physicalSize=const Size(360,844);t.view.devicePixelRatio=1;addTearDown(t.view.resetPhysicalSize);addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(home:OutingPreparationScreen(store:store,initialSpecies:'Cervo')));await flush(t);
    final dropdown=t.widget<DropdownButtonFormField<OutingActivity>>(find.byKey(const ValueKey('preparation-activity')));await t.runAsync(() async {dropdown.onChanged!(OutingActivity.fotografia);await store.exportSnapshot();await Future<void>.delayed(const Duration(milliseconds:100));});await flush(t);
    final checkbox=find.byKey(const ValueKey('check-weather'));await t.ensureVisible(checkbox);await t.runAsync(()async {t.widget<CheckboxListTile>(checkbox).onChanged!(true);await store.exportSnapshot();});await flush(t);
    expect(t.widget<CheckboxListTile>(checkbox).value,isTrue);expect(t.takeException(),isNull);
    await t.pumpWidget(const SizedBox());await flush(t);await t.pumpWidget(MaterialApp(home:OutingPreparationScreen(store:OutdoorToolsStore(directory:dir))));await flush(t);
    expect(t.widget<DropdownButtonFormField<OutingActivity>>(find.byKey(const ValueKey('preparation-activity'))).initialValue,OutingActivity.fotografia);
    await t.ensureVisible(checkbox);expect(t.widget<CheckboxListTile>(checkbox).value,isTrue);expect(t.takeException(),isNull);
    await t.pumpWidget(const SizedBox());await flush(t);
  });
  testWidgets('Return screen responds to movement stale GPS and proximity without layout errors',(t)async{
    final semantics=t.ensureSemantics();
    try {
    final gps=FakeGps();await t.runAsync(()=>store.savePoint(name:'Auto',kind:ReturnPointKind.auto,position:fix(lat:.001),now:at));
    t.view.physicalSize=const Size(360,844);t.view.devicePixelRatio=1;addTearDown(t.view.resetPhysicalSize);addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(home:ReturnPointScreen(store:store,locationSource:gps,now:()=>at)));await flush(t);
    expect(find.text('Circa 111 m'),findsOneWidget);expect(find.bySemanticsLabel('Circa 111 m'),findsOneWidget);expect(find.text('N · 0° dal Nord'),findsOneWidget);
    gps.events.add(fix(lat:.0005));await t.pump();await t.pump();expect(find.text('Circa 56 m'),findsOneWidget);
    gps.events.add(fix(time:at.subtract(const Duration(minutes:2))));await t.pump();await t.pump();expect(find.byKey(const ValueKey('return-arrow')),findsNothing);
    gps.events.add(fix(lat:.001));await t.pump();await t.pump();expect(find.byKey(const ValueKey('return-near')),findsOneWidget);expect(t.takeException(),isNull);
    await t.pumpWidget(const SizedBox());await flush(t);await gps.events.close();
    } finally {semantics.dispose();}
  });
}
