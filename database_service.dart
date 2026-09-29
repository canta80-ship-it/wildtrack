import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sighting.dart';
import '../models/track_point.dart';
import '../models/track_session.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'wildtrack.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE sightings(
          id TEXT PRIMARY KEY,
          species TEXT NOT NULL,
          count INTEGER NOT NULL,
          notes TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp TEXT NOT NULL,
          photo_path TEXT
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

  Future<List<TrackSession>> getSessions() async {
    final db = await database;
    final rows = await db.query('sessions', orderBy: 'started_at DESC');
    return rows.map(TrackSession.fromMap).toList();
  }
}
