import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ffi' show DynamicLibrary;
import 'package:sqlite3/open.dart' as sqlite;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wildtrack_mvp/main.dart';
import 'package:wildtrack_mvp/models/sighting.dart';
import 'package:wildtrack_mvp/screens/guide_screen.dart';
import 'package:wildtrack_mvp/screens/intro_screen.dart';
import 'package:wildtrack_mvp/screens/premium_screen.dart';
import 'package:wildtrack_mvp/screens/species_screen.dart';
import 'package:wildtrack_mvp/services/community_service.dart';
import 'package:wildtrack_mvp/services/database_service.dart';
import 'package:wildtrack_mvp/services/exploration_service.dart';
import 'package:wildtrack_mvp/services/location_service.dart';
import 'package:wildtrack_mvp/services/lifecycle_service.dart';
import 'package:wildtrack_mvp/services/network_service.dart';
import 'package:wildtrack_mvp/services/preferences_service.dart';
import 'package:wildtrack_mvp/services/storage_service.dart';
import 'package:wildtrack_mvp/services/tracking_service.dart';

class TestGps extends GeolocatorPlatform {
  final controllers = <StreamController<Position>>[];
  final settings = <AndroidSettings>[];
  int active = 0, maximum = 0, permissionCalls = 0;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async {
    permissionCalls++;
    return LocationPermission.whileInUse;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    settings.add(locationSettings! as AndroidSettings);
    late StreamController<Position> controller;
    controller = StreamController<Position>.broadcast(
      onListen: () {
        active++;
        if (active > maximum) maximum = active;
      },
      onCancel: () {
        active--;
      },
    );
    controllers.add(controller);
    return controller.stream;
  }

  void emit(Position p) => controllers.last.add(p);
}

Position fix(int seconds, double altitude) => Position(
  latitude: 46,
  longitude: 12,
  timestamp: DateTime(2026, 10, 8).add(Duration(seconds: seconds)),
  accuracy: 2,
  altitude: altitude,
  altitudeAccuracy: 2,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);
Sighting sighting(String id, {String notes = 'originale'}) => Sighting(
  id: id,
  species: 'Cervo',
  count: 2,
  notes: notes,
  latitude: 46,
  longitude: 12,
  timestamp: DateTime(2026, 10, 8),
);
Future<void> flush() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class PollProbe extends StatefulWidget {
  const PollProbe(this.called, {super.key});
  final VoidCallback called;
  @override
  State<PollProbe> createState() => _PollProbeState();
}

class _PollProbeState extends State<PollProbe> with VisiblePolling<PollProbe> {
  @override
  Duration get pollInterval => const Duration(seconds: 8);
  @override
  Future<void> poll() async => widget.called();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Probe'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Directory temporary;
  String? protectedToken;
  setUpAll(() async {
    if (Platform.isLinux)
      sqlite.open.overrideFor(
        sqlite.OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    root = await Directory.systemTemp.createTemp('wildtrack-regression-');
    await databaseFactory.setDatabasesPath(root.path);
    // A real v2 archive, as installed by the preceding APK.
    final old = await openDatabase(
      '${root.path}/wildtrack.db',
      version: 2,
      onCreate: (db, _) async {
        await db.execute(
          "CREATE TABLE sightings(id TEXT PRIMARY KEY,species TEXT NOT NULL,count INTEGER NOT NULL,notes TEXT,latitude REAL,longitude REAL,timestamp TEXT NOT NULL,photo_path TEXT,kind TEXT NOT NULL DEFAULT 'Animale',accuracy REAL,position_source TEXT NOT NULL DEFAULT 'gps')",
        );
        await db.execute(
          'CREATE TABLE sessions(id TEXT PRIMARY KEY,started_at TEXT NOT NULL,ended_at TEXT NOT NULL,distance_m REAL NOT NULL,ascent_m REAL NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE track_points(id INTEGER PRIMARY KEY AUTOINCREMENT,session_id TEXT NOT NULL,latitude REAL NOT NULL,longitude REAL NOT NULL,altitude REAL NOT NULL,timestamp TEXT NOT NULL)',
        );
        await db.insert('sightings', sighting('existing-user-data').toMap());
      },
    );
    await old.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PreferencesService.secure, (call) async {
          if (call.method == 'readToken') return protectedToken;
          protectedToken = (call.arguments as Map)['token'] as String;
          return null;
        });
  });
  setUp(() async {
    temporary = await root.createTemp('case-');
    PreferencesService.instance.file = File('${temporary.path}/prefs.json');
    PreferencesService.instance.visible = false;
  });
  tearDown(() async {
    await temporary.delete(recursive: true);
  });
  tearDownAll(() async {
    await (await DatabaseService.instance.database).close();
    await root.delete(recursive: true);
  });

  test('v2 -> v3 retains observations and creates the GPS index', () async {
    final db = await DatabaseService.instance.database;
    expect(
      (await DatabaseService.instance.getSightings()).single.id,
      'existing-user-data',
    );
    expect(await db.getVersion(), 3);
    final plan = await db.rawQuery(
      "EXPLAIN QUERY PLAN SELECT * FROM track_points WHERE session_id='a' ORDER BY timestamp,id",
    );
    expect(
      plan.map((r) => r['detail']).join(),
      contains('track_points_session_time'),
    );
  });

  test('concurrent preferences complete and the last snapshot wins', () async {
    final p = PreferencesService.instance;
    final writes = <Future<void>>[];
    for (var i = 0; i < 40; i++) {
      p.nickname = 'Utente $i';
      writes.add(p.save());
    }
    await Future.wait(writes);
    expect(
      (jsonDecode(await p.file.readAsString()) as Map)['nickname'],
      'Utente 39',
    );
    expect(
      (await p.file.parent.list().toList()).where(
        (f) => f.path.endsWith('.tmp'),
      ),
      isEmpty,
    );
  });

  test('concurrent trails preserve both complete transactions', () async {
    await Future.wait([
      for (final id in ['a', 'b', 'c'])
        ExplorationService.instance.save(
          NatureTrail({
            'id': id,
            'segments': [
              [
                [46, 12],
                [46.01, 12.01],
              ],
            ],
          }),
        ),
    ]);
    expect(
      (await ExplorationService.instance.saved()).map((t) => t.id),
      containsAll(['a', 'b', 'c']),
    );
    await Future.wait([
      ExplorationService.instance.remove('b'),
      ExplorationService.instance.save(
        NatureTrail({'id': 'd', 'segments': []}),
      ),
    ]);
    expect(
      (await ExplorationService.instance.saved()).map((t) => t.id).toSet(),
      {'a', 'c', 'd'},
    );
  });

  test(
    'corrupt JSON restores the backup and is never overwritten silently',
    () async {
      final f = File('${temporary.path}/data.json');
      await JsonStorage.write(f, {'n': 1});
      await JsonStorage.write(f, {'n': 2});
      await f.writeAsString('{broken');
      expect(await JsonStorage.read(f, empty: {}), {'n': 1});
      await File('${f.path}.bak').writeAsString('{broken');
      await expectLater(
        JsonStorage.read(f, empty: {}),
        throwsA(isA<FileSystemException>()),
      );
      expect(await f.readAsString(), '{broken');
    },
  );

  test(
    'legacy token migration keeps the exact identity and removes plaintext',
    () async {
      protectedToken = null;
      final f = File('${root.path}/wildtrack_preferences.json');
      await f.writeAsString(
        jsonEncode({
          'token': 'retained-identity',
          'nickname': 'Marco',
          'theme': 'dark',
        }),
      );
      await PreferencesService.instance.load();
      expect(PreferencesService.instance.token, 'retained-identity');
      expect(protectedToken, 'retained-identity');
      expect(PreferencesService.instance.nickname, 'Marco');
      expect(PreferencesService.instance.theme, ThemeMode.dark);
      expect(await f.readAsString(), isNot(contains('retained-identity')));
      expect(
        await File('${f.path}.bak').readAsString(),
        isNot(contains('retained-identity')),
      );
      await PreferencesService.instance.load();
      expect(PreferencesService.instance.token, 'retained-identity');
    },
  );

  test(
    'failed cancellation leaves the durable queue and memory unchanged',
    () async {
      final c = CommunityService()..foreground = false;
      c.queueFile = File('${temporary.path}/queue.json');
      final item = {'id': 'one', 'species': 'Cervo', 'lat': 46, 'lng': 12};
      await c.add(item);
      final original = await c.queueFile.readAsString();
      await c.queueFile.rename('${c.queueFile.path}.retained');
      await Directory(c.queueFile.path).create();
      await expectLater(
        c.cancelPending('one'),
        throwsA(isA<FileSystemException>()),
      );
      expect(c.pending.single['id'], 'one');
      expect(
        await File('${c.queueFile.path}.retained').readAsString(),
        original,
      );
      c.dispose();
    },
  );

  test(
    'publishing an old snapshot never deletes a newer private edit',
    () async {
      final posted = Completer<void>(), release = Completer<void>();
      final c = CommunityService(
        transport: (path, method, body) async {
          if (method == 'POST') {
            expect(body!.keys.any((k) => k.startsWith('_')), false);
            posted.complete();
            await release.future;
          }
          return {'items': <Object>[]};
        },
      )..foreground = false;
      c.queueFile = File('${temporary.path}/queue.json');
      await DatabaseService.instance.insertSighting(sighting('editable'));
      await c.add({
        'id': 'editable',
        'species': 'Cervo',
        'lat': 46,
        'lng': 12,
        '_localSnapshot': await DatabaseService.instance.sightingSnapshot(
          'editable',
        ),
      });
      final sync = c.refresh();
      await posted.future;
      await DatabaseService.instance.insertSighting(
        sighting('editable', notes: 'modifica successiva'),
      );
      release.complete();
      await sync;
      expect(
        (await DatabaseService.instance.sightingSnapshot('editable'))!['notes'],
        'modifica successiva',
      );
      expect(c.pending, isEmpty);
      c.dispose();
    },
  );

  test(
    'successful unchanged public observation converts after acknowledgement',
    () async {
      final c = CommunityService(
        transport: (_, _, _) async => {'items': <Object>[]},
      )..foreground = false;
      c.queueFile = File('${temporary.path}/queue.json');
      await DatabaseService.instance.insertSighting(sighting('convertible'));
      await c.add({
        'id': 'convertible',
        'species': 'Cervo',
        'lat': 46,
        'lng': 12,
        '_localSnapshot': await DatabaseService.instance.sightingSnapshot(
          'convertible',
        ),
      });
      await c.refresh();
      expect(
        await DatabaseService.instance.sightingSnapshot('convertible'),
        isNull,
      );
      c.dispose();
    },
  );

  test(
    'GPS consumers share one stream and reconfigure instead of first-policy-wins',
    () async {
      final fake = TestGps();
      GeolocatorPlatform.instance = fake;
      final tracking = LocationService.positionStream().listen((_) {});
      await flush();
      final navigation = LocationService.positionStream(
        purpose: 'navigation',
      ).listen((_) {});
      await flush();
      expect(fake.settings.last.intervalDuration, const Duration(seconds: 3));
      expect(fake.maximum, 1);
      await navigation.cancel();
      await flush();
      expect(fake.settings.last.intervalDuration, const Duration(seconds: 10));
      await tracking.cancel();
      expect(fake.active, 0);
    },
  );

  test(
    'stationary GPS altitude noise adds no distance/ascent; GPS errors still allow stop',
    () async {
      final fake = TestGps();
      GeolocatorPlatform.instance = fake;
      final tracker = TrackingService.instance;
      expect(await tracker.start(), true);
      await flush();
      for (final (i, altitude) in [100.0, 105.0, 100.0].indexed) {
        fake.emit(fix(i * 10, altitude));
        for (
          var tries = 0;
          tracker.points.length < i + 1 && tries < 100;
          tries++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      }
      expect(tracker.points.length, 3);
      expect(tracker.ascentMeters, 0);
      expect(tracker.distanceMeters, 0);
      fake.controllers.last.addError(Exception('GPS disattivato'));
      await flush();
      final saved = await tracker.stop();
      expect(saved, isNotNull);
      expect(fake.active, 0);
      expect(
        (await DatabaseService.instance.getTrackPoints(saved!.id)).length,
        3,
      );
    },
  );

  test(
    'malformed records and nonfinite/out-of-range coordinates are rejected',
    () {
      expect(
        records([
          {
            'id': 'bad',
            'species': 'Cervo',
            'count': 1,
            'lat': double.nan,
            'lng': 12,
          },
        ], 'sightings'),
        isEmpty,
      );
      expect(
        records([
          {'lat': 46, 'lng': 12, 'url': 'javascript:alert(1)'},
        ], 'nature'),
        isEmpty,
      );
      expect(validCoordinates(91, 12), false);
    },
  );

  test(
    'legacy queued approximate positions are rounded before persistence or transmission',
    () async {
      final prefs = PreferencesService.instance;
      final file = File('${prefs.file.parent.path}/wildtrack_outbox.json');
      await file.writeAsString(
        jsonEncode([
          {
            'id': 'legacy',
            'species': 'Cervo',
            'lat': 46.061234,
            'lng': 12.403456,
            'approximate': true,
          },
        ]),
      );
      final c = CommunityService()..foreground = false;
      await c.load();
      expect(c.pending.single['lat'], 46.06);
      expect(c.pending.single['lng'], 12.40);
      expect(await file.readAsString(), isNot(contains('46.061234')));
      c.dispose();
    },
  );

  testWidgets('polling stops for hidden tabs, covered routes and paused app', (
    tester,
  ) async {
    var calls = 0;
    final active = ValueNotifier(true);
    final navigation = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigation,
        navigatorObservers: [wildTrackRoutes],
        home: ValueListenableBuilder<bool>(
          valueListenable: active,
          builder: (context, value, _) =>
              TickerMode(enabled: value, child: PollProbe(() => calls++)),
        ),
      ),
    );
    await tester.pump();
    expect(calls, greaterThan(0));
    active.value = false;
    await tester.pump();
    final hidden = calls;
    await tester.pump(const Duration(seconds: 24));
    expect(calls, hidden);
    active.value = true;
    await tester.pump();
    navigation.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Covered')),
      ),
    );
    await tester.pumpAndSettle();
    final covered = calls;
    await tester.pump(const Duration(seconds: 24));
    expect(calls, covered);
    navigation.currentState!.pop();
    await tester.pumpAndSettle();
    expect(calls, greaterThan(covered));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final paused = calls;
    await tester.pump(const Duration(seconds: 24));
    expect(calls, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, greaterThan(paused));
    await tester.pumpWidget(const SizedBox.shrink());
    active.dispose();
  });

  testWidgets(
    'premium screens retain navigation and fit a small phone with large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final screen in [
        const MoreScreen(),
        const GuideScreen(),
        const SpeciesScreen(),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: wildTrackTheme(Brightness.light),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(1.3),
              ),
              child: screen,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: wildTrackTheme(Brightness.dark),
          home: const IntroScreen(home: Scaffold(body: Text('Home'))),
        ),
      );
      await tester.tap(find.text('Salta'));
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
