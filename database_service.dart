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

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'wildtrack.db');
    _db = await openDatabase(
      path,
      version: 2,
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
    );
    return _db!;
  }

  Future<void> insertSighting(Sighting sighting) async {
    final db = await database;
    await db.insert(
      'sightings',
      sighting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    changes.value++;
  }

  Future<void> deleteSighting(String id) async {
    final db = await database;
    await db.delete('sightings', where: 'id = ?', whereArgs: [id]);
    changes.value++;
  }

  Future<List<Sighting>> getSightings() async {
    final db = await database;
    final rows = await db.query('sightings', orderBy: 'timestamp DESC');
    return rows.map(Sighting.fromMap).toList();
  }

  Future<void> saveSession(
    TrackSession session,
    List<TrackPoint> points,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final batch = txn.batch();
      for (final p in points) {
        batch.insert('track_points', p.toMap(session.id));
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> appendTrackPoint(TrackSession session, TrackPoint? point) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (point != null)
        await txn.insert('track_points', point.toMap(session.id));
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
