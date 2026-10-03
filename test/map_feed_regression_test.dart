import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildtrack_mvp/services/map_location_service.dart';
import 'package:wildtrack_mvp/services/habitat_map_service.dart';
import 'package:wildtrack_mvp/services/did_you_know_service.dart';
import 'package:wildtrack_mvp/screens/species_screen.dart';
import 'package:wildtrack_mvp/screens/species_habitat_map_screen.dart';
import 'package:wildtrack_mvp/screens/species_detail_screen.dart';
import 'package:wildtrack_mvp/screens/sign_plate_widget.dart';
import 'package:flutter/services.dart';

Position fix(double lat, int seconds) => Position(latitude: lat, longitude: 12, timestamp: DateTime(2026).add(Duration(seconds: seconds)), accuracy: 5, altitude: 300, altitudeAccuracy: 1, heading: 0, headingAccuracy: 1, speed: 1, speedAccuracy: 1);
class OfflineTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => const AssetImage('assets/approved/cervo_thumb.jpg');
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('FERRATE appear in old cache and news-filled feed without duplication', () {
    final old = List.generate(25, (i) => DidYouKnowItem(id: '$i', category: 'FAUNA', title: 'Notizia $i', body: '', asset: '', source: 'Test', publishedAt: DateTime(2026)));
    final merged = DidYouKnowService.withFerrate(old);
    expect(merged.length, 32);
    expect(merged.where((e) => e.category == 'FERRATE').length, 12);
    expect(merged[1].id, 'ferrata-contin');
    expect(DidYouKnowService.withFerrate(merged).map((e) => e.id).toList(), merged.map((e) => e.id).toList());
    for (final item in DidYouKnowService.ferrataCards()) { expect(Uri.parse(item.link!).scheme, 'https'); expect(item.body.isNotEmpty, true); }
  });
  test('GPS updates current marker and rejects older asynchronous fix', () async {
    final stream = StreamController<Position>();
    final current = Completer<Position?>();
    final service = MapLocationService(permission: () async => true, current: () => current.future, stream: () => stream.stream);
    final started = service.start();
    await Future<void>.delayed(Duration.zero);
    stream.add(fix(46.2, 20));
    await Future<void>.delayed(Duration.zero);
    current.complete(fix(46.1, 10));
    await started;
    expect(service.point!.latitude, 46.2);
    stream.add(fix(46.3, 30));
    await Future<void>.delayed(Duration.zero);
    expect(service.point!.latitude, 46.3);
    service.dispose();
    expect(stream.hasListener, false);
    await stream.close();
  });
  test('Denied GPS never fabricates current location', () async {
    final service = MapLocationService(permission: () async => false);
    await service.start(); expect(service.point, isNull); expect(service.error, isNotNull); service.dispose();
  });
  test('Habitat profiles cover all 31 species and exclude unsuitable mapped cover', () {
    expect(HabitatMapService.profiles.keys.toSet(), animals.map((a) => a.name).toSet());
    final geometry = [{'lat':46.0,'lon':12.0},{'lat':46.1,'lon':12.0},{'lat':46.1,'lon':12.1},{'lat':46.0,'lon':12.0}];
    final data = {'elements':[{'type':'way','id':1,'tags':{'natural':'wood'},'geometry':geometry},{'type':'way','id':2,'tags':{'natural':'water'},'geometry':geometry}]};
    expect(HabitatMapService.instance.parse(data, 'Picchio nero').single.kind, 'forest');
    expect(HabitatMapService.instance.parse(data, 'Airone cenerino').single.kind, 'water');
    for (final animal in animals) { expect(HabitatMapService.instance.query(animal.name, const LatLng(46,12)), contains('out geom')); }
    expect(() => HabitatMapService.instance.parse({'elements':[],'remark':'timeout'}, 'Cervo'), throwsFormatException);
  });
  test('Multipolygon habitat preserves holes and ignores open ways', () {
    final outer=[{'lat':46.0,'lon':12.0},{'lat':46.2,'lon':12.0},{'lat':46.2,'lon':12.2},{'lat':46.0,'lon':12.2},{'lat':46.0,'lon':12.0}];
    final inner=[{'lat':46.05,'lon':12.05},{'lat':46.1,'lon':12.05},{'lat':46.1,'lon':12.1},{'lat':46.05,'lon':12.05}];
    final data={'elements':[{'type':'relation','id':1,'tags':{'natural':'wood'},'members':[{'type':'way','role':'outer','geometry':outer.take(3).toList()},{'type':'way','role':'outer','geometry':outer.skip(2).toList()},{'type':'way','role':'inner','geometry':inner}]},{'type':'way','id':2,'tags':{'natural':'wood'},'geometry':outer.take(3).toList()}]};
    final patches=HabitatMapService.instance.parse(data,'Cervo'); expect(patches.length,1); expect(patches.single.holes.length,1);
  });
  testWidgets('Habitat screen draws species polygons and premium green current marker', (tester) async {
    final patch=HabitatPatch('1','forest','Bosco',const [LatLng(46,12),LatLng(46.01,12),LatLng(46.01,12.01)],[]);
    await tester.pumpWidget(MaterialApp(home: SpeciesHabitatMapScreen(animals.first, initialPosition: const LatLng(46,12), enableLocation:false, tileProvider:OfflineTiles(), loader:(_,__) async => [patch])));
    await tester.pump(); await tester.pump(const Duration(milliseconds:100));
    expect(find.text('Habitat · Cervo'), findsOneWidget);
    expect(find.byKey(const ValueKey('live-position-marker')), findsOneWidget);
    expect(tester.widget<PolygonLayer>(find.byType(PolygonLayer)).polygons.length,1);
    expect(find.textContaining('non presenza accertata'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Habitat error stops loading and permits retry', (tester) async {
    var calls=0;
    await tester.pumpWidget(MaterialApp(home: SpeciesHabitatMapScreen(animals[1], enableLocation:false, tileProvider:OfflineTiles(), loader:(_,__) async {calls++; throw Exception('offline');})));
    await tester.pump(); await tester.pump(const Duration(milliseconds:100));
    expect(find.textContaining('Habitat non disponibili'), findsOneWidget); expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.text('Mostra habitat in questa zona')); await tester.pump(); expect(calls,2);
    await tester.pumpWidget(const SizedBox());
  });
  for (final animal in animals.where((a) => a.name != 'Cervo')) {
    testWidgets('Premium illustration plate bundled for ${animal.name}', (tester) async {
      final d=speciesDetails[animal.name]!; final asset=d.newArtwork ? 'assets/radar_species/${d.asset}_signs.webp' : 'assets/signs/${d.asset}.webp';
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(10000));
      await tester.pumpWidget(MaterialApp(home: SizedBox(height:90, child: SignPlateIllustration(asset:asset,grid:d.newArtwork,index:3,label:animal.name))));
      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

