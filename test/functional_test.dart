import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:wildtrack_mvp/services/location_service.dart';
import 'package:wildtrack_mvp/services/tracking_service.dart';
import 'package:wildtrack_mvp/services/radar_service.dart';
import 'package:wildtrack_mvp/screens/sos_screen.dart';
import 'package:wildtrack_mvp/screens/real_geo_stats_widget.dart';
import 'package:wildtrack_mvp/main.dart' show wildTrackTheme;
import 'package:wildtrack_mvp/models/sighting.dart';
import 'package:wildtrack_mvp/models/track_point.dart';
import 'package:wildtrack_mvp/models/track_session.dart';
import 'package:wildtrack_mvp/services/database_service.dart';
import 'package:wildtrack_mvp/services/preferences_service.dart';
import 'package:wildtrack_mvp/services/auth_service.dart';
import 'package:wildtrack_mvp/services/media_storage_service.dart';
import 'package:wildtrack_mvp/services/privacy_service.dart';
import 'package:wildtrack_mvp/services/expedition_service.dart';
import 'package:wildtrack_mvp/services/exploration_service.dart';
import 'package:wildtrack_mvp/services/activity_map_service.dart';
import 'package:wildtrack_mvp/services/community_service.dart';
import 'package:wildtrack_mvp/services/backup_service.dart';
import 'package:wildtrack_mvp/services/wildtrack_intelligence_service.dart';
import 'package:wildtrack_mvp/screens/access_screen.dart';
import 'package:wildtrack_mvp/screens/premium_sighting_screen.dart';
import 'package:wildtrack_mvp/screens/premium_animal_screen.dart';
import 'package:wildtrack_mvp/screens/species_screen.dart';
import 'package:wildtrack_mvp/screens/species_detail_screen.dart';

final empty = <String, dynamic>{
  'schemaVersion': 4,
  'sightings': [],
  'sightingPhotos': [],
  'sessions': [],
  'trackPoints': [],
};
Sighting row(
  String id, {
  String species = 'Cervo',
  int count = 1,
  DateTime? at,
  String? photo,
}) => Sighting(
  id: id,
  species: species,
  count: count,
  notes: 'nota test',
  latitude: 46.1,
  longitude: 12.2,
  timestamp: at ?? DateTime(2026, 9, 20),
  photoPath: photo,
);
TrackSession session(String id) => TrackSession(
  id: id,
  startedAt: DateTime(2026, 9, 20, 8),
  endedAt: DateTime(2026, 9, 20, 9),
  distanceMeters: 3600,
  ascentMeters: 150,
  descentMeters: 80,
  notes: 'uscita',
);
List<TrackPoint> points() => [
  TrackPoint(
    latitude: 46.1,
    longitude: 12.2,
    altitude: 500,
    timestamp: DateTime(2026, 9, 20, 8),
  ),
  TrackPoint(
    latitude: 46.11,
    longitude: 12.21,
    altitude: 510,
    timestamp: DateTime(2026, 9, 20, 8, 1),
  ),
];

class TestGps extends GeolocatorPlatform {
  TestGps({this.enabled = true});
  final bool enabled;
  final stream = StreamController<Position>.broadcast();
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => enabled
      ? LocationPermission.whileInUse
      : LocationPermission.deniedForever;
  @override
  Future<LocationPermission> requestPermission() async => enabled
      ? LocationPermission.whileInUse
      : LocationPermission.deniedForever;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      stream.stream;
}

Position gps(
  double lat,
  DateTime at, {
  double accuracy = 5,
  double altitude = 500,
}) => Position(
  latitude: lat,
  longitude: 12,
  timestamp: at,
  accuracy: accuracy,
  altitude: altitude,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 1,
  speedAccuracy: 1,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService.instance, prefs = PreferencesService.instance;
  late Directory temp;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    temp = await Directory.systemTemp.createTemp('wildtrack-functional-');
    await databaseFactory.setDatabasesPath(temp.path);
    await prefs.load();
    for (final entry in <String, List<String>>{
      'serif': [
        'assets/approved/editorial_serif.ttf',
        'assets/approved/editorial_serif_italic.ttf',
      ],
      'sans-serif': ['assets/approved/interface_sans.ttf'],
      'Roboto': ['assets/approved/interface_sans.ttf'],
      'WildTrackIcons': ['assets/approved/wildtrack_icons.ttf'],
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final path in entry.value) loader.addFont(rootBundle.load(path));
      await loader.load();
    }
  });
  setUp(() async {
    await db.restoreSnapshot(empty);
    final f = File('${temp.path}/wildtrack_local_account.json');
    if (await f.exists()) await f.delete();
    prefs.visible = false;
    prefs.backgroundSharing = false;
    CommunityService.instance.foreground = true;
    CommunityService.instance.pending.clear();
  });
  tearDownAll(() async {
    await (await db.database).close();
    await temp.delete(recursive: true);
  });

  test(
    'MODEL sighting roundtrip preserves coordinates photo kind accuracy',
    () {
      final s = Sighting(
        id: 's',
        species: 'Volpe',
        count: 3,
        notes: 'traccia',
        latitude: 46,
        longitude: 12,
        timestamp: DateTime(2026),
        kind: 'Impronta',
        accuracy: 7,
        positionSource: 'manual',
        photoPath: 'p.jpg',
      );
      final r = Sighting.fromMap(s.toMap());
      expect(r.toMap(), s.toMap());
      expect(r.hasPosition, true);
    },
  );
  test('MODEL legacy sightings retain defaults and missing position', () {
    final m = row('s').toMap()
      ..remove('kind')
      ..remove('position_source')
      ..['latitude'] = null;
    final s = Sighting.fromMap(m);
    expect(s.kind, 'Animale');
    expect(s.positionSource, 'gps');
    expect(s.hasPosition, false);
  });
  test('MODEL track session publication roundtrip and clearing', () {
    final s = session(
      't',
    ).copyWith(isPublic: true, publishedAt: DateTime(2026), notes: 'pubblico');
    expect(TrackSession.fromMap(s.toMap()).toMap(), s.toMap());
    expect(s.averageSpeedMps, 1);
    expect(s.copyWith(clearPublishedAt: true).publishedAt, null);
  });
  test('MODEL zero duration cannot divide by zero', () {
    final s = TrackSession(
      id: 'z',
      startedAt: DateTime(2026),
      endedAt: DateTime(2026),
      distanceMeters: 500,
      ascentMeters: 0,
    );
    expect(s.averageSpeedMps, 0);
  });
  test('GPS disabled prevents start and returns missing position', () async {
    final old = GeolocatorPlatform.instance, fake = TestGps(enabled: false);
    GeolocatorPlatform.instance = fake;
    try {
      expect(await LocationService.currentPosition(), null);
      expect(await TrackingService.instance.start(), false);
      expect(TrackingService.instance.isTracking, false);
    } finally {
      GeolocatorPlatform.instance = old;
      await fake.stream.close();
    }
  });
  test(
    'TRACKING simulated GPS records chronological accurate points and distance',
    () async {
      final old = GeolocatorPlatform.instance, fake = TestGps();
      GeolocatorPlatform.instance = fake;
      try {
        final track = TrackingService.instance;
        expect(await track.start(), true);
        final at = DateTime.now();
        fake.stream.add(gps(46, at));
        fake.stream.add(
          gps(46.0005, at.add(const Duration(seconds: 10)), altitude: 510),
        );
        fake.stream.add(
          gps(47, at.add(const Duration(seconds: 20)), accuracy: 200),
        );
        fake.stream.add(gps(46, at.subtract(const Duration(seconds: 10))));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final saved = await track.stop();
        expect(saved, isNotNull);
        expect(track.points, hasLength(2));
        expect(saved!.distanceMeters, inInclusiveRange(50, 60));
        expect(saved.ascentMeters, 10);
        expect(await db.getTrackPoints(saved.id), hasLength(2));
        expect(track.isTracking, false);
      } finally {
        GeolocatorPlatform.instance = old;
        await fake.stream.close();
      }
    },
  );
  test('RADAR missing GPS does not claim live weather or position', () async {
    final old = GeolocatorPlatform.instance, fake = TestGps(enabled: false);
    GeolocatorPlatform.instance = fake;
    try {
      final radar = await RadarService.instance.load();
      expect(radar.hasPosition, false);
      expect(radar.weatherAvailable, false);
      expect(radar.species, isNotEmpty);
      for (final s in radar.species) expect(s.score, inInclusiveRange(0, 100));
    } finally {
      GeolocatorPlatform.instance = old;
      await fake.stream.close();
    }
  });
  test('DB sightings insert update chronological order', () async {
    await db.insertSighting(row('old', at: DateTime(2020)));
    await db.insertSighting(row('new'));
    await db.insertSighting(row('new', count: 4));
    final s = await db.getSightings();
    expect(s.map((e) => e.id), ['new', 'old']);
    expect(s.first.count, 4);
  });
  test('DB multi photo order replacement and delete cascade', () async {
    await db.insertSighting(row('s'));
    await db.replaceSightingPhotos('s', ['a', 'b', 'c']);
    expect(await db.getSightingPhotos('s'), ['a', 'b', 'c']);
    await db.replaceSightingPhotos('s', ['c', 'a']);
    expect(await db.getSightingPhotos('s'), ['c', 'a']);
    await db.deleteSighting('s');
    expect(await db.getSightingPhotos('s'), isEmpty);
    expect(await db.getSightings(), isEmpty);
  });
  test('DB sessions track points activity map and edits', () async {
    await db.saveSession(session('t'), points());
    await db.updateSession(
      session('t').copyWith(notes: 'modificata', isPublic: true),
    );
    final s = (await db.getSessions()).single;
    expect(s.notes, 'modificata');
    expect(s.isPublic, true);
    expect(await db.getTrackPoints('t'), hasLength(2));
    final map = (await ActivityMapService.instance.load()).single;
    expect(map.route, hasLength(2));
    expect(map.route.first.latitude, 46.1);
  });
  test('DB incremental recording persists points and session', () async {
    await db.appendTrackPoint(session('t'), null);
    for (final p in points()) await db.appendTrackPoint(session('t'), p);
    expect(await db.getSessions(), hasLength(1));
    expect(await db.getTrackPoints('t'), hasLength(2));
  });
  test('DB snapshot restore includes photos and routes', () async {
    await db.insertSighting(row('s'));
    await db.replaceSightingPhotos('s', ['a', 'b']);
    await db.saveSession(session('t'), points());
    final snap = await db.exportSnapshot();
    await db.restoreSnapshot(empty);
    await db.restoreSnapshot(snap);
    expect(await db.getSightings(), hasLength(1));
    expect(await db.getSightingPhotos('s'), ['a', 'b']);
    expect(await db.getTrackPoints('t'), hasLength(2));
  });
  test('DB invalid backup version preserves existing records', () async {
    await db.insertSighting(row('keep'));
    await expectLater(
      db.restoreSnapshot({'schemaVersion': 99}),
      throwsFormatException,
    );
    expect((await db.getSightings()).single.id, 'keep');
  });
  test('DB failed restore rolls back transaction', () async {
    await db.insertSighting(row('keep'));
    await expectLater(
      db.restoreSnapshot({
        ...empty,
        'sightings': [
          {'id': 'broken'},
        ],
      }),
      throwsA(anything),
    );
    expect((await db.getSightings()).single.id, 'keep');
  });
  test('DB legacy restore migrates single photo', () async {
    await db.restoreSnapshot({
      ...empty,
      'schemaVersion': 1,
      'sightings': [row('old', photo: 'legacy.jpg').toMap()],
    });
    expect(await db.getSightingPhotos('old'), ['legacy.jpg']);
  });
  test('PREF settings and camera profile survive reload', () async {
    prefs.theme = ThemeMode.dark;
    prefs.repeats = 4;
    prefs.fieldSilence = true;
    prefs.cameraLabel = 'Test camera';
    prefs.cameraIso = 1600;
    prefs.cameraFocalMm = 500;
    await prefs.save();
    prefs.cameraLabel = '';
    prefs.cameraIso = 100;
    prefs.cameraFocalMm = 20;
    await prefs.load();
    expect(prefs.theme, ThemeMode.dark);
    expect(prefs.repeats, 4);
    expect(prefs.fieldSilence, true);
    expect(prefs.cameraLabel, 'Test camera');
    expect(prefs.cameraIso, 1600);
    expect(prefs.cameraFocalMm, 500);
  });
  test('PREF token stable across restarts and repeat limit', () async {
    final token = prefs.token;
    await prefs.save();
    final raw =
        jsonDecode(await prefs.file.readAsString()) as Map<String, dynamic>;
    raw['repeats'] = 99;
    await prefs.file.writeAsString(jsonEncode(raw));
    await prefs.load();
    expect(prefs.token, token);
    expect(prefs.repeats, 5);
  });
  test('AUTH register valid local account and reject wrong password', () async {
    expect(
      await AuthService.instance.register(' Test.User ', 'password-test'),
      'test.user',
    );
    expect(
      await AuthService.instance.signIn('test.user', 'password-test'),
      'test.user',
    );
    await expectLater(
      AuthService.instance.signIn('test.user', 'wrong'),
      throwsA(anything),
    );
  });
  test('AUTH reject short username and password', () async {
    expect(
      () => AuthService.instance.normalizeUsername('aa'),
      throwsA(anything),
    );
    await expectLater(
      AuthService.instance.register('test', 'short'),
      throwsA(anything),
    );
  });
  test('AUTH duplicate registration must not overwrite credentials', () async {
    await AuthService.instance.register('test.user', 'password-old');
    await expectLater(
      AuthService.instance.register('test.user', 'password-new'),
      throwsA(anything),
    );
    expect(
      await AuthService.instance.signIn('test.user', 'password-old'),
      'test.user',
    );
  });
  test('AUTH signout clears current local session', () async {
    await AuthService.instance.register('test.user', 'password-test');
    await AuthService.instance.signOut();
    expect(await AuthService.instance.currentUsername(), null);
  });
  test('MEDIA missing photos are handled without exception', () async {
    expect(await MediaStorageService.instance.persistPhoto(null, 'x'), null);
    expect(
      await MediaStorageService.instance.persistPhoto(
        '${temp.path}/missing.jpg',
        'x',
      ),
      null,
    );
  });
  test('MEDIA saved photo survives source deletion', () async {
    final source = File('${temp.path}/source.png');
    await source.writeAsBytes([1, 2, 3, 4]);
    final target = await MediaStorageService.instance.persistPhoto(
      source.path,
      'saved',
    );
    await source.delete();
    expect(await File(target!).readAsBytes(), [1, 2, 3, 4]);
  });
  test(
    'TRAIL bundled itineraries have usable coordinates and lengths',
    () async {
      final trails = await ExplorationService.instance.presets();
      expect(trails.length, greaterThanOrEqualTo(36));
      for (final t in trails) {
        expect(t.name, isNotEmpty);
        expect(t.length, greaterThan(0));
        expect(t.center.latitude, inInclusiveRange(-90, 90));
        expect(t.center.longitude, inInclusiveRange(-180, 180));
      }
    },
  );
  test('TRAIL save overwrite remove survives disk reload', () async {
    final service = ExplorationService.instance;
    final t = NatureTrail({
      'id': 'test',
      'name': 'Sentiero',
      'segments': [
        [
          [46.0, 12.0],
          [46.01, 12.01],
        ],
      ],
    });
    await service.save(t);
    await service.save(t);
    expect((await service.saved()).where((e) => e.id == 'test'), hasLength(1));
    await service.remove('test');
    expect((await service.saved()).where((e) => e.id == 'test'), isEmpty);
  });
  test('EXPEDITION starts private updates shares and expires', () async {
    final e = ExpeditionService.instance;
    final s = await e.ensure(mapId: 'test', name: 'Test');
    expect(s.positionSharing, false);
    await e.setPositionSharing('test', true);
    await e.reloadFromDisk();
    expect((await e.get('test'))!.positionSharing, true);
    await e.expireNow('test');
    expect((await e.get('test'))!.positionSharing, false);
    await expectLater(e.setPositionSharing('test', true), throwsStateError);
  });
  test('EXPEDITION duration limited to fourteen days', () async {
    final e = ExpeditionService.instance;
    await e.ensure(mapId: 'duration', name: 'Test');
    final s = await e.setDuration('duration', const Duration(days: 90));
    expect(s.remaining.inHours, inInclusiveRange(335, 336));
  });
  test('PRIVACY critical species overrides exact user choice and delays publication', () {
    final s = WildlifePrivacyService.instance.protect(
      species: 'Lupo',
      latitude: 46,
      longitude: 12,
      observedAt: DateTime.now(),
      userRequestedApproximation: false,
    );
    expect(s.approximate, true);
    expect(s.radiusMeters, 10000);
    expect(s.publishAfter, isNotNull);
    expect(s.latitude, isNot(46));
  });
  test('PRIVACY older sensitive sighting remains approximate', () {
    final s = WildlifePrivacyService.instance.protect(
      species: 'Orso bruno',
      latitude: 46,
      longitude: 12,
      observedAt: DateTime.now().subtract(const Duration(days: 10)),
    );
    expect(s.radiusMeters, 5000);
    expect(s.publishAfter, null);
  });
  test('PRIVACY ordinary exact and approximate choices respected', () {
    final service = WildlifePrivacyService.instance;
    final exact = service.protect(
      species: 'Cervo',
      latitude: 46,
      longitude: 12,
      observedAt: DateTime.now(),
      userRequestedApproximation: false,
    );
    expect(exact.latitude, 46);
    expect(exact.approximate, false);
    final approx = service.protect(
      species: 'Cervo',
      latitude: 46,
      longitude: 12,
      observedAt: DateTime.now(),
    );
    expect(approx.radiusMeters, 1000);
  });
  test('PRIVACY public payload protected and private group unchanged', () {
    final payload = {
      'species': 'Lupo',
      'lat': 46.0,
      'lng': 12.0,
      'observedAt': DateTime.now().toIso8601String(),
      'approximate': false,
    };
    final p = WildlifePrivacyService.instance.protectPayload(payload);
    expect(p['approximate'], true);
    expect(p['privacyRadiusM'], 10000);
    expect(p['publishAfter'], isNotNull);
    final group = {...payload, 'groupId': 'private-test'};
    expect(WildlifePrivacyService.instance.protectPayload(group), group);
  });
  test('COMMUNITY visibility disabled blocks location sharing', () {
    final c = CommunityService.instance;
    prefs.visible = false;
    expect(c.canShare, false);
    prefs.visible = true;
    expect(c.canShare, true);
    c.foreground = false;
    expect(c.canShare, false);
    prefs.backgroundSharing = true;
    expect(c.canShare, false);
  });
  test('COMMUNITY outbox persists offline without publishing', () async {
    final c = CommunityService.instance;
    await c.load();
    c.pending.clear();
    c.pending.add({'id': 'test-only', 'species': 'Cervo'});
    await c.saveQueue();
    c.pending.clear();
    await c.load();
    expect(c.pending.single['id'], 'test-only');
    c.pending.clear();
    await c.saveQueue();
  });
  test('STATS biodiversity handles empty and unknown sightings', () {
    final service = WildTrackIntelligenceService.instance;
    expect(service.biodiversity([], []).score, 0);
    expect(
      service.biodiversity([
        row('u', species: 'Specie non identificata'),
      ], []).uniqueSpecies,
      0,
    );
    final r = service.biodiversity(
      [row('1'), row('2', species: 'Volpe')],
      [session('t')],
    );
    expect(r.uniqueSpecies, 2);
    expect(r.evenness, closeTo(1, 0.00001));
    expect(r.score, inInclusiveRange(0, 100));
  });
  test('STATS lifers use earliest record not most recent', () {
    final r = WildTrackIntelligenceService.instance.firstSightings([
      row('new'),
      row('old', at: DateTime(2020)),
      row('u', species: 'Specie non identificata'),
    ]);
    expect(r['Cervo'], DateTime(2020));
    expect(r.keys, ['Cervo']);
  });
  test(
    'SPECIES all 24 records have distinct artwork complete signs and sources',
    () {
      expect(animals, hasLength(24));
      expect(speciesDetails, hasLength(24));
      expect(speciesDetails.values.map((e) => e.asset).toSet(), hasLength(24));
      for (final animal in animals) {
        final d = speciesDetails[animal.name]!;
        expect(d.signs, hasLength(4));
        expect(d.seasons, hasLength(4));
        expect(Uri.parse(d.source).scheme, 'https');
        expect(d.photo, isNotEmpty);
      }
    },
  );
  test('BACKUP rebuild restores records photos and nickname', () async {
    prefs.nickname = 'backup-user';
    await prefs.save();
    final f = File(
      '${(await MediaStorageService.instance.mediaDirectory).path}/backup.jpg',
    );
    await f.writeAsBytes([7, 8, 9]);
    await db.insertSighting(row('backup', photo: f.path));
    await db.replaceSightingPhotos('backup', [f.path]);
    final bytes = await WildTrackBackupService.instance.buildBackup();
    await db.restoreSnapshot(empty);
    prefs.nickname = 'changed';
    await f.delete();
    await WildTrackBackupService.instance.restore(bytes);
    expect((await db.getSightings()).single.id, 'backup');
    expect(prefs.nickname, 'backup-user');
    expect(await f.readAsBytes(), [7, 8, 9]);
  });
  test('BACKUP camera profile must restore with settings', () async {
    prefs.cameraLabel = 'Original';
    prefs.cameraIso = 1600;
    await prefs.save();
    final bytes = await WildTrackBackupService.instance.buildBackup();
    prefs.cameraLabel = 'Changed';
    prefs.cameraIso = 100;
    await prefs.save();
    await WildTrackBackupService.instance.restore(bytes);
    expect(prefs.cameraLabel, 'Original');
    expect(prefs.cameraIso, 1600);
  });
  test('BACKUP moving devices must reconnect restored photo paths', () async {
    final media = await MediaStorageService.instance.mediaDirectory;
    final f = File('${media.path}/transfer.jpg');
    await f.writeAsBytes([3, 4]);
    await db.insertSighting(
      row('transfer', photo: '/old-device/wildtrack_media/transfer.jpg'),
    );
    await db.replaceSightingPhotos('transfer', [
      '/old-device/wildtrack_media/transfer.jpg',
    ]);
    final bytes = await WildTrackBackupService.instance.buildBackup();
    await WildTrackBackupService.instance.restore(bytes);
    final s = (await db.getSightings()).single;
    expect(s.photoPath, f.path);
    expect(await db.getSightingPhotos('transfer'), [f.path]);
  });
  test('BACKUP invalid format rejected without clearing database', () async {
    await db.insertSighting(row('keep'));
    await expectLater(
      WildTrackBackupService.instance.restore(
        Uint8List.fromList(utf8.encode('{"format":"wrong"}')),
      ),
      throwsFormatException,
    );
    expect((await db.getSightings()).single.id, 'keep');
  });
  test('BACKUP invalid media must not destroy existing data', () async {
    await db.insertSighting(row('keep'));
    final corrupt = {
      'format': 'wildtrack-backup',
      'backupVersion': 1,
      'appData': {
        'database': empty,
        'media': [
          {'name': 'broken.jpg', 'data': '%%%'},
        ],
      },
    };
    await expectLater(
      WildTrackBackupService.instance.restore(
        Uint8List.fromList(utf8.encode(jsonEncode(corrupt))),
      ),
      throwsFormatException,
    );
    final remaining = await db.getSightings();
    expect(remaining, hasLength(1));
    expect(remaining.single.id, 'keep');
  });
  test('AUDIO stop cancels pending requests through native bridge', () async {
    var stops = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioService.channel, (call) async {
          if (call.method == 'stop') stops++;
          return null;
        });
    AudioService.instance.current = 'Cervo';
    final old = AudioService.instance.request;
    await AudioService.instance.stop();
    expect(AudioService.instance.current, null);
    expect(AudioService.instance.request, greaterThan(old));
    expect(stops, 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioService.channel, null);
  });

  Future<void> mount(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(411, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: wildTrackTheme(Brightness.light), home: screen),
    );
    await tester.pumpAndSettle();
  }

  Future<void> click(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('UI ACCESS empty credentials show validation', (tester) async {
    await mount(tester, const AccessScreen(home: SizedBox()));
    await click(tester, find.text('Accedi').last);
    expect(find.text('Inserisci nome utente e password.'), findsOneWidget);
  });
  testWidgets(
    'UI SOS opens and handles GPS disabled without calling emergency services',
    (tester) async {
      final old = GeolocatorPlatform.instance, fake = TestGps(enabled: false);
      GeolocatorPlatform.instance = fake;
      try {
        await mount(tester, const SosScreen());
        expect(find.text('Attiva la posizione del telefono.'), findsOneWidget);
      } finally {
        GeolocatorPlatform.instance = old;
        await fake.stream.close();
      }
    },
  );
  testWidgets('UI ACCESS password visibility can toggle', (tester) async {
    await mount(tester, const AccessScreen(home: SizedBox()));
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      true,
    );
    await click(tester, find.byIcon(Icons.visibility_off_outlined));
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      false,
    );
  });
  testWidgets('UI ACCESS passkey is explicitly not implemented', (
    tester,
  ) async {
    await mount(tester, const AccessScreen(home: SizedBox()));
    await click(tester, find.text('Accedi con passkey'));
    expect(
      find.text('Per ora l’accesso locale usa nome utente e password.'),
      findsOneWidget,
    );
  });
  testWidgets('UI ACCESS password recovery currently only displays message', (
    tester,
  ) async {
    await mount(tester, const AccessScreen(home: SizedBox()));
    await click(tester, find.text('Hai dimenticato la password?'));
    expect(
      find.text('Recupero password disponibile con account cloud.'),
      findsOneWidget,
    );
  });
  testWidgets('UI SIGHTING count starts at one and increments', (tester) async {
    await mount(tester, const PremiumSightingScreen());
    await click(tester, find.byIcon(Icons.add).last);
    expect(find.text('2'), findsOneWidget);
    await click(tester, find.byIcon(Icons.remove));
    expect(find.text('1'), findsOneWidget);
  });
  testWidgets('UI SIGHTING private save persists entered note without GPS', (
    tester,
  ) async {
    await mount(tester, const PremiumSightingScreen());
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'nota funzionale');
    await click(tester, find.text('Salva privato'));
    await tester.runAsync(() async {
      for (var i = 0; i < 50; i++) {
        if ((await db.getSightings()).isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(db.getSightings);
    expect(rows, hasLength(1));
    expect(rows!.single.notes, 'nota funzionale');
    expect(rows.single.hasPosition, false);
  });
  testWidgets('UI SPECIES full explanations open on tap', (tester) async {
    await mount(
      tester,
      PremiumAnimalScreen(animals.firstWhere((e) => e.name == 'Cervo')),
    );
    await click(tester, find.text('Specie autoctona'));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.text(animals.firstWhere((e) => e.name == 'Cervo').description),
      findsWidgets,
    );
  });
  testWidgets(
    'UI HEATMAP coordinate edits must repaint even with unchanged record count',
    (tester) async {
      final initial = [row('first'), row('second')];
      await mount(tester, RealHeatmap(sightings: initial));
      final finder = find.descendant(
        of: find.byType(RealHeatmap),
        matching: find.byType(CustomPaint),
      );
      final oldPainter = tester.widget<CustomPaint>(finder).painter!;
      final changed = [
        initial.first,
        Sighting(
          id: 'second',
          species: 'Cervo',
          count: 1,
          notes: '',
          latitude: 47,
          longitude: 13,
          timestamp: DateTime(2026),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: wildTrackTheme(Brightness.light),
          home: RealHeatmap(sightings: changed),
        ),
      );
      await tester.pump();
      final next = tester.widget<CustomPaint>(finder).painter!;
      expect(next.shouldRepaint(oldPainter), true);
    },
  );
}
