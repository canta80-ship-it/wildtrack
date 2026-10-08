import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sighting.dart';
import '../models/track_point.dart';
import '../models/track_session.dart';
import 'storage_service.dart';
import 'photo_service.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  Database? _db;
  Future<Database>? _opening;
  final _mutations = SerialExecutor();
  final changes = ValueNotifier<int>(0);

  Future<Database> get database =>
      _opening ??= _open().catchError((Object e, StackTrace st) {
        _opening = null;
        Error.throwWithStackTrace(e, st);
      });
  Future<Database> _open() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'wildtrack.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE sightings(
          id TEXT PRIMARY KEY,
          species TEXT NOT NULL,
          count INTEGER NOT NULL,
          notes TEXT,
          latitude REAL,
          longitude REAL,
          timestamp TEXT NOT NULL,
          photo_path TEXT,
          kind TEXT NOT NULL DEFAULT 'Animale',
          accuracy REAL,
          position_source TEXT NOT NULL DEFAULT 'gps'
        )
      ''');
        await db.execute('''
        CREATE TABLE sessions(
          id TEXT PRIMARY KEY,
          started_at TEXT NOT NULL,
          ended_at TEXT NOT NULL,
          distance_m REAL NOT NULL,
          ascent_m REAL NOT NULL
        )
      ''');
        await db.execute('''
        CREATE TABLE track_points(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          altitude REAL NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
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
            SELECT id,species,count,notes,latitude,longitude,timestamp,photo_path
            FROM sightings_v1''');
          await db.execute('DROP TABLE sightings_v1');
        }
      },
      onOpen: (db) async {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS track_points_session_time ON track_points(session_id,timestamp,id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS sightings_time ON sightings(timestamp DESC)',
        );
      },
    );
    return _db!;
  }

  Future<void> insertSighting(Sighting sighting) => _mutations.run(() async {
    final db = await database;
    final old = await db.query(
      'sightings',
      where: 'id=?',
      whereArgs: [sighting.id],
    );
    await db.insert(
      'sightings',
      sighting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    changes.value++;
    if (old.isNotEmpty)
      await PhotoService.deleteIfUnreferenced(
        old.first['photo_path'] as String?,
      );
  });

  Future<void> deleteSighting(String id) => _mutations.run(() async {
    final db = await database;
    final old = await db.query('sightings', where: 'id=?', whereArgs: [id]);
    final removed = await db.delete(
      'sightings',
      where: 'id=?',
      whereArgs: [id],
    );
    if (removed > 0) {
      changes.value++;
      await PhotoService.deleteIfUnreferenced(
        old.first['photo_path'] as String?,
      );
    }
  });

  Future<Map<String, Object?>?> sightingSnapshot(String id) async {
    final rows = await (await database).query(
      'sightings',
      where: 'id=?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : Sighting.fromMap(rows.first).toMap();
  }

  Future<void> deleteIfUnchanged(String id, Map snapshot) =>
      _mutations.run(() async {
        final db = await database;
        String? photo;
        final deleted = await db.transaction((txn) async {
          final rows = await txn.query(
            'sightings',
            where: 'id=?',
            whereArgs: [id],
          );
          if (rows.isEmpty) return 0;
          final current = Sighting.fromMap(rows.first).toMap();
          if (snapshot.length != current.length ||
              !current.entries.every((e) => snapshot[e.key] == e.value))
            return 0;
          photo = current['photo_path'] as String?;
          return txn.delete('sightings', where: 'id=?', whereArgs: [id]);
        });
        if (deleted > 0) {
          changes.value++;
          await PhotoService.deleteIfUnreferenced(photo);
        }
      });

  Future<Map<String, num>> statistics() async {
    final db = await database;
    final s = (await db.rawQuery(
      'SELECT COUNT(*) AS n, COALESCE(SUM(count),0) AS animals FROM sightings',
    )).first;
    final r = (await db.rawQuery(
      'SELECT COUNT(*) AS n, COALESCE(SUM(distance_m),0) AS distance FROM sessions',
    )).first;
    return {
      'sightings': s['n'] as num,
      'animals': s['animals'] as num,
      'sessions': r['n'] as num,
      'distance': r['distance'] as num,
    };
  }

  Future<List<Sighting>> getSightings() async {
    final db = await database;
    final rows = await db.query('sightings', orderBy: 'timestamp DESC');
    return rows.map(Sighting.fromMap).toList();
  }

  Future<void> appendTrackPoint(TrackSession session, TrackPoint? point) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (point != null) {
        await txn.insert('track_points', point.toMap(session.id));
      }
    });
  }

  Future<List<Map<String, Object?>>> getTrackPoints(String id) async {
    final db = await database;
    return db.query(
      'track_points',
      where: 'session_id=?',
      whereArgs: [id],
      orderBy: 'timestamp ASC,id ASC',
    );
  }

  Future<List<TrackSession>> getSessions() async {
    final db = await database;
    final rows = await db.query('sessions', orderBy: 'started_at DESC');
    return rows.map(TrackSession.fromMap).toList();
  }
}
