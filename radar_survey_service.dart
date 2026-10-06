import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';

/// Explicit observation effort. A GPS walk without sightings is never inferred
/// to be a negative survey. Survey outcomes describe only that visit.
class RadarSurvey {
  const RadarSurvey({required this.species, required this.latitude, required this.longitude, required this.at, required this.minutes, required this.seen, required this.phase});
  final String species, phase;
  final double latitude, longitude;
  final DateTime at;
  final int minutes;
  final bool seen;
  Map<String,dynamic> toJson() => {'species':species,'lat':latitude,'lng':longitude,'at':at.toIso8601String(),'minutes':minutes,'seen':seen,'phase':phase};
  static RadarSurvey fromJson(Map<String,dynamic> j) => RadarSurvey(species:j['species'] as String,latitude:(j['lat'] as num).toDouble(),longitude:(j['lng'] as num).toDouble(),at:DateTime.parse(j['at'] as String),minutes:j['minutes'] as int,seen:j['seen'] as bool,phase:j['phase'] as String);
}
class RadarSurveyService {
  static final instance = RadarSurveyService();
  Future<void> _writes = Future.value();
  Future<File> get _file async => File('${await getDatabasesPath()}/wildtrack_radar_surveys.json');
  Future<List<RadarSurvey>> load() async {
    final f = await _file;
    if (!await f.exists()) return [];
    final raw = jsonDecode(await f.readAsString()) as List;
    return raw.map((e)=>RadarSurvey.fromJson(Map<String,dynamic>.from(e as Map))).toList();
  }
  Future<void> add(RadarSurvey survey) {
    if (survey.minutes < 5 || survey.minutes > 720 || !survey.latitude.isFinite || survey.latitude.abs()>90 || !survey.longitude.isFinite || survey.longitude.abs()>180) return Future.error(ArgumentError('Controllo non valido'));
    final write = _writes.then((_) async {
      final rows = await load(); rows.add(survey);
      final f = await _file, tmp = File('${(await _file).path}.tmp');
      await tmp.writeAsString(jsonEncode(rows.map((s)=>s.toJson()).toList()),flush:true);
      await tmp.rename(f.path);
    });
    _writes = write.catchError((Object _) {}); return write;
  }
}
