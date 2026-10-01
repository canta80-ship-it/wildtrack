import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sighting.dart';
import '../models/track_point.dart';
import '../models/track_session.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  Database? _db;
  final changes = ValueNotifier<int>(0);

  Future<String> get databasePath async => join(await getDatabasesPath(), 'wildtrack.db');

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      await databasePath,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE sightings(
          id TEXT PRIMARY KEY, species TEXT NOT NULL, count INTEGER NOT NULL,
          notes TEXT, latitude REAL, longitude REAL, timestamp TEXT NOT NULL,
          photo_path TEXT, kind TEXT NOT NULL DEFAULT 'Animale', accuracy REAL,
          position_source TEXT NOT NULL DEFAULT 'gps')''');
        await db.execute('''CREATE TABLE sighting_photos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sighting_id TEXT NOT NULL,
          path TEXT NOT NULL,
          position INTEGER NOT NULL DEFAULT 0
        )''');
        await db.execute('''CREATE TABLE sessions(
          id TEXT PRIMARY KEY,
          started_at TEXT NOT NULL,
          ended_at TEXT NOT NULL,
          distance_m REAL NOT NULL,
          ascent_m REAL NOT NULL,
          descent_m REAL NOT NULL DEFAULT 0,
          notes TEXT NOT NULL DEFAULT '',
          is_public INTEGER NOT NULL DEFAULT 0,
          published_at TEXT
        )''');
        await db.execute('''CREATE TABLE track_points(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          altitude REAL NOT NULL,
          timestamp TEXT NOT NULL
        )''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE sightings RENAME TO sightings_v1');
          await db.execute('''CREATE TABLE sightings(
            id TEXT PRIMARY KEY, species TEXT NOT NULL, count INTEGER NOT NULL,
            notes TEXT, latitude REAL, longitude REAL, timestamp TEXT NOT NULL,
            photo_path TEXT, kind TEXT NOT NULL DEFAULT 'Animale', accuracy REAL,
            position_source TEXT NOT NULL DEFAULT 'gps')''');
          await db.execute('''INSERT INTO sightings
            (id,species,count,notes,latitude,longitude,timestamp,photo_path)
            SELECT id,species,count,notes,latitude,longitude,timestamp,photo_path FROM sightings_v1''');
          await db.execute('DROP TABLE sightings_v1');
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE sessions ADD COLUMN descent_m REAL NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE sessions ADD COLUMN notes TEXT NOT NULL DEFAULT ''");
          await db.execute("ALTER TABLE sessions ADD COLUMN is_public INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE sessions ADD COLUMN published_at TEXT");
        }
        if (oldVersion < 4) {
          await db.execute('''CREATE TABLE IF NOT EXISTS sighting_photos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sighting_id TEXT NOT NULL,
            path TEXT NOT NULL,
            position INTEGER NOT NULL DEFAULT 0
          )''');
          await db.execute("INSERT INTO sighting_photos(sighting_id,path,position) SELECT id,photo_path,0 FROM sightings WHERE photo_path IS NOT NULL AND photo_path != ''");
        }
      },
    );
    return _db!;
  }

  Future<void> insertSighting(Sighting sighting) async {
    final db = await database;
    await db.insert('sightings', sighting.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    changes.value++;
  }

  Future<void> deleteSighting(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sighting_photos', where: 'sighting_id = ?', whereArgs: [id]);
      await txn.delete('sightings', where: 'id = ?', whereArgs: [id]);
    });
    changes.value++;
  }

  Future<List<Sighting>> getSightings() async {
    final db = await database;
    final rows = await db.query('sightings', orderBy: 'timestamp DESC');
    return rows.map(Sighting.fromMap).toList();
  }

  Future<void> replaceSightingPhotos(String sightingId, List<String> paths) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sighting_photos', where: 'sighting_id=?', whereArgs: [sightingId]);
      for (var i = 0; i < paths.length; i++) {
        await txn.insert('sighting_photos', {'sighting_id': sightingId, 'path': paths[i], 'position': i});
      }
    });
    changes.value++;
  }

  Future<List<String>> getSightingPhotos(String sightingId) async {
    final db = await database;
    final rows = await db.query('sighting_photos', columns: ['path'], where: 'sighting_id=?', whereArgs: [sightingId], orderBy: 'position ASC,id ASC');
    return rows.map((e) => e['path'] as String).toList();
  }

  Future<void> saveSession(TrackSession session, List<TrackPoint> points) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      final batch = txn.batch();
      for (final p in points) { batch.insert('track_points', p.toMap(session.id)); }
      await batch.commit(noResult: true);
    });
    changes.value++;
  }

  Future<void> updateSession(TrackSession session) async {
    final db = await database;
    await db.insert('sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    changes.value++;
  }

  Future<void> appendTrackPoint(TrackSession session, TrackPoint? point) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      if (point != null) await txn.insert('track_points', point.toMap(session.id));
    });
    changes.value++;
  }

  Future<List<Map<String, Object?>>> getTrackPoints(String id) async {
    final db = await database;
    return db.query('track_points', where: 'session_id=?', whereArgs: [id], orderBy: 'timestamp ASC,id ASC');
  }

  Future<List<TrackSession>> getSessions() async {
    final db = await database;
    final rows = await db.query('sessions', orderBy: 'started_at DESC');
    return rows.map(TrackSession.fromMap).toList();
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    final db = await database;
    return {
      'schemaVersion': 4,
      'sightings': await db.query('sightings', orderBy: 'timestamp ASC'),
      'sightingPhotos': await db.query('sighting_photos', orderBy: 'sighting_id ASC,position ASC,id ASC'),
      'sessions': await db.query('sessions', orderBy: 'started_at ASC'),
      'trackPoints': await db.query('track_points', orderBy: 'session_id ASC,timestamp ASC,id ASC'),
    };
  }

  Future<void> restoreSnapshot(Map<String, dynamic> snapshot) async {
    final version = (snapshot['schemaVersion'] as num?)?.toInt() ?? 0;
    if (version < 1 || version > 4) throw const FormatException('Versione backup database non supportata');
    final sightings = (snapshot['sightings'] as List? ?? const []).cast<Map>();
    final sightingPhotos = (snapshot['sightingPhotos'] as List? ?? const []).cast<Map>();
    final sessions = (snapshot['sessions'] as List? ?? const []).cast<Map>();
    final trackPoints = (snapshot['trackPoints'] as List? ?? const []).cast<Map>();
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sighting_photos');
      await txn.delete('track_points');
      await txn.delete('sessions');
      await txn.delete('sightings');
      for (final raw in sightings) await txn.insert('sightings', Map<String, Object?>.from(raw), conflictAlgorithm: ConflictAlgorithm.replace);
      if (sightingPhotos.isEmpty) {
        for (final raw in sightings) {
          final row = Map<String, Object?>.from(raw);
          final photo = row['photo_path'] as String?;
          if (photo != null && photo.isNotEmpty) await txn.insert('sighting_photos', {'sighting_id': row['id'], 'path': photo, 'position': 0});
        }
      } else {
        for (final raw in sightingPhotos) {
          final row = Map<String, Object?>.from(raw)..remove('id');
          await txn.insert('sighting_photos', row);
        }
      }
      for (final raw in sessions) {
        final row = Map<String, Object?>.from(raw);
        row.putIfAbsent('descent_m', () => 0.0);
        row.putIfAbsent('notes', () => '');
        row.putIfAbsent('is_public', () => 0);
        row.putIfAbsent('published_at', () => null);
        await txn.insert('sessions', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final raw in trackPoints) {
        final row = Map<String, Object?>.from(raw)..remove('id');
        await txn.insert('track_points', row);
      }
    });
    changes.value++;
  }
}
