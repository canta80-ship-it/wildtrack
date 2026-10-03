import 'dart:async';
import 'package:wildtrack_mvp/screens/community_delete_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildtrack_mvp/services/radar_service.dart';
import 'package:wildtrack_mvp/screens/radar_panel_widget.dart';
import 'package:wildtrack_mvp/screens/community_sighting_map_screen.dart';

class OfflineTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => const AssetImage('assets/approved/cervo_thumb.jpg');
}

void main() {
  testWidgets('Premium delete button appears only for the creator', (tester) async {
    for (final mine in [0, 1]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: CommunityDeleteButton(sighting: {'id':'post','mine':mine}))));
      expect(find.text('Elimina avvistamento'), mine == 1 ? findsOneWidget : findsNothing);
      if (mine == 1) {
        await tester.tap(find.text('Elimina avvistamento')); await tester.pumpAndSettle();
        expect(find.text('Eliminare questo avvistamento?'), findsOneWidget);
        await tester.tap(find.text('Annulla')); await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
  test('Automatic Radar loads reuse snapshot up to one hour and expire at boundary', () async {
    var now = DateTime(2026, 10, 3, 12), calls = 0;
    final radar = RadarService(clock: () => now, loader: (_) async { calls++; return const RadarSnapshot(activity: 'BUONE', species: []); });
    final first = await radar.load();
    now = now.add(const Duration(minutes: 59, seconds: 59));
    expect(await radar.load(), same(first)); expect(calls, 1);
    now = now.add(const Duration(seconds: 1));
    await radar.load(); expect(calls, 2);
    await radar.load(forceRefresh: true); expect(calls, 3);
  });
  test('Simultaneous Radar requests share one load and failure permits retry', () async {
    final pending = Completer<RadarSnapshot>(); var calls = 0;
    final radar = RadarService(loader: (_) { calls++; return pending.future; });
    final a = radar.load(), b = radar.load();
    expect(calls, 1);
    pending.complete(const RadarSnapshot(activity: 'BUONE', species: []));
    expect(await a, same(await b));
    var fail = true;
    final retry = RadarService(loader: (_) async { if (fail) throw StateError('offline'); return const RadarSnapshot(activity: 'BUONE', species: []); });
    await expectLater(retry.load(), throwsStateError); fail = false;
    expect((await retry.load()).activity, 'BUONE');
  });
  test('Community coordinates accept actual shared numbers, reject invalid positions', () {
    expect(communitySightingPosition({'lat': '46.1', 'lng': 13.2}), const LatLng(46.1, 13.2));
    expect(communitySightingPosition({'lat': 0, 'lng': 0}), const LatLng(0, 0));
    for (final row in <Map<String,dynamic>>[{}, {'lat': 91, 'lng': 13}, {'lat': 46, 'lng': 181}, {'lat': double.nan, 'lng': 13}]) { expect(communitySightingPosition(row), isNull); }
  });
  testWidgets('Every community map button handles unavailable coordinates without inventing a location', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CommunitySightingMapButton(sighting: {'species': 'Cervo'}))));
    await tester.tap(find.text('Vedi su mappa')); await tester.pump();
    expect(find.text('Posizione non disponibile per questo avvistamento.'), findsOneWidget);
    expect(find.byType(CommunitySightingMapScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Community map centers marker on shared sighting and preserves approximation', (tester) async {
    for (final approximate in [0,1]) {
      await tester.pumpWidget(MaterialApp(home: CommunitySightingMapScreen(sighting: {'species':'Cervo','approximate':approximate},position: const LatLng(46.1,13.2),tileProvider: OfflineTiles())));
      await tester.pump(); await tester.pump(const Duration(milliseconds:100));
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.initialCenter, const LatLng(46.1,13.2));
      expect(tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single.point, const LatLng(46.1,13.2));
      expect(find.byType(CircleLayer), approximate == 1 ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
  for (final width in [360.0, 411.0]) {
    testWidgets('Radar restores real percentage bar at $width dp', (tester) async {
      tester.view.physicalSize = Size(width, 844); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: RadarPanel(snapshot: const RadarSnapshot(activity:'BUONE',hasPosition:true,species:[RadarSpecies('Cervo',73)]),onRefresh: () async {})))));
      await tester.pumpAndSettle();
      expect(find.text('73%'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, .73);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
