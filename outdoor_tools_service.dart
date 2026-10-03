import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

enum ReturnPointKind { auto, bivio, postazione }
extension ReturnPointKindLabel on ReturnPointKind {
  String get label => switch(this) { ReturnPointKind.auto=>'Auto',ReturnPointKind.bivio=>'Bivio',ReturnPointKind.postazione=>'Postazione' };
}
class ReturnPoint {
  const ReturnPoint({required this.id,required this.name,required this.kind,required this.latitude,required this.longitude,required this.accuracy,required this.savedAt});
  final String id,name;
  final ReturnPointKind kind;
  final double latitude,longitude,accuracy;
  final DateTime savedAt;
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'kind':kind.name,'lat':latitude,'lon':longitude,'accuracy':accuracy,'savedAt':savedAt.toUtc().toIso8601String()};
  factory ReturnPoint.fromJson(Map<String,dynamic> j) {
    final p=ReturnPoint(id:j['id'] as String,name:j['name'] as String,kind:ReturnPointKind.values.byName(j['kind'] as String),latitude:(j['lat'] as num).toDouble(),longitude:(j['lon'] as num).toDouble(),accuracy:(j['accuracy'] as num).toDouble(),savedAt:DateTime.parse(j['savedAt'] as String));
    if(p.id.isEmpty||p.name.trim().isEmpty||p.name.length>80||!validCoordinates(p.latitude,p.longitude)||!p.accuracy.isFinite||p.accuracy<=0||p.accuracy>100)throw const FormatException('Punto non valido');
    return p;
  }
}
bool validCoordinates(double lat,double lon)=>lat.isFinite&&lon.isFinite&&lat.abs()<=90&&lon.abs()<=180;
bool usablePointFix(Position p,DateTime now)=>validCoordinates(p.latitude,p.longitude)&&p.accuracy.isFinite&&p.accuracy>0&&p.accuracy<=100&&now.difference(p.timestamp)<=const Duration(minutes:1)&&now.difference(p.timestamp)>=const Duration(seconds:-30);

class ReturnGuidance {
  const ReturnGuidance(this.distance,this.bearing,this.near,this.relativeBearing);
  final double distance,bearing;
  final bool near;
  final double? relativeBearing;
  String get cardinal=>const ['N','NE','E','SE','S','SO','O','NO'][((bearing+22.5)/45).floor()%8];
  String get distanceLabel=>distance<1000?'Circa ${distance.round()} m':'Circa ${(distance/1000).toStringAsFixed(2)} km';
  static ReturnGuidance? calculate(Position current,ReturnPoint target,DateTime now) {
    if(!usablePointFix(current,now)||!validCoordinates(target.latitude,target.longitude))return null;
    const r=6371000.0;
    final p1=current.latitude*math.pi/180,p2=target.latitude*math.pi/180;
    final dl=(target.longitude-current.longitude)*math.pi/180,dp=p2-p1;
    final a=(math.pow(math.sin(dp/2),2)+math.cos(p1)*math.cos(p2)*math.pow(math.sin(dl/2),2)).clamp(0.0,1.0);
    final distance=2*r*math.atan2(math.sqrt(a),math.sqrt(1-a));
    final angle=(math.atan2(math.sin(dl)*math.cos(p2),math.cos(p1)*math.sin(p2)-math.sin(p1)*math.cos(p2)*math.cos(dl))*180/math.pi+360)%360;
    final moving=current.speed.isFinite&&current.speed>=1&&current.heading.isFinite&&current.heading>=0&&current.heading<360&&current.headingAccuracy.isFinite&&current.headingAccuracy>0&&current.headingAccuracy<=30;
    return ReturnGuidance(distance,angle,distance<=math.max(10,current.accuracy+target.accuracy),moving?(angle-current.heading+360)%360:null);
  }
}
abstract class PointLocationSource {
  Future<Position> current({bool requestPermission=false});
  Stream<Position> watch();
}
class GpsPointLocationSource implements PointLocationSource {
  @override Future<Position> current({bool requestPermission=false})async {
    if(!await Geolocator.isLocationServiceEnabled())throw const PointLocationException('Attiva il GPS del telefono e riprova.');
    var p=await Geolocator.checkPermission();
    if(p==LocationPermission.denied&&requestPermission)p=await Geolocator.requestPermission();
    if(p!=LocationPermission.always&&p!=LocationPermission.whileInUse)throw const PointLocationException('Autorizza la posizione per salvare e ritrovare un punto.');
    try {
      final fix=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,timeLimit:Duration(seconds:15)));
      if(!usablePointFix(fix,DateTime.now()))throw const PointLocationException('GPS non abbastanza recente o preciso. Attendi all’aperto e aggiorna.');
      return fix;
    } on PointLocationException {rethrow;} catch(_){throw const PointLocationException('Posizione non disponibile. Aggiorna il GPS e riprova.');}
  }
  @override Stream<Position> watch()=>Geolocator.getPositionStream(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,distanceFilter:3));
}
class PointLocationException implements Exception {
  const PointLocationException(this.message);final String message;
  @override String toString()=>message;
}

/// Private device data; no remote publication or paid service.
class OutdoorToolsStore {
  OutdoorToolsStore({this.directory});
  static final instance=OutdoorToolsStore();
  final Directory? directory;
  Future<void> _writes=Future.value();
  Future<File> get file async {
    final dir=directory??Directory(await getDatabasesPath());
    await dir.create(recursive:true);
    return File('${dir.path}/wildtrack_outdoor_tools.json');
  }
  static Map<String,dynamic> empty()=>{'version':1,'points':<dynamic>[],'checklists':<String,dynamic>{},'selectedPlan':null};
  static Map<String,dynamic> validate(Map<String,dynamic> value) {
    if(value['version']!=1||value['points'] is!List||value['checklists'] is!Map)throw const FormatException('Archivio strumenti non valido');
    final ids=<String>{};
    for(final raw in value['points'] as List) {
      final p=ReturnPoint.fromJson(Map<String,dynamic>.from(raw as Map));
      if(!ids.add(p.id))throw const FormatException('Punti duplicati');
    }
    for(final e in (value['checklists'] as Map).entries) {
      if(e.key is!String||e.value is!List||(e.value as List).any((v)=>v is!String))throw const FormatException('Checklist non valida');
    }
    if(value['selectedPlan']!=null) {
      final p=value['selectedPlan'];
      if(p is!Map||p['species'] is!String||p['season'] is!String||p['activity'] is!String)throw const FormatException('Preparazione non valida');
    }
    return Map<String,dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
  }
  Future<Map<String,dynamic>> _read()async {
    final f=await file;if(!await f.exists())return empty();
    return validate(Map<String,dynamic>.from(jsonDecode(await f.readAsString()) as Map));
  }
  Future<void> _mutate(void Function(Map<String,dynamic>) edit) {
    final write=_writes.then((_)async {
      final data=await _read();edit(data);validate(data);
      final f=await file,tmp=File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(data),flush:true);await tmp.rename(f.path);
    });
    _writes=write.catchError((Object _){});return write;
  }
  Future<List<ReturnPoint>> points()async {
    await _writes;
    final data=await _read();
    return (data['points'] as List).map((p)=>ReturnPoint.fromJson(Map<String,dynamic>.from(p as Map))).toList()..sort((a,b)=>b.savedAt.compareTo(a.savedAt));
  }
  Future<ReturnPoint> savePoint({required String name,required ReturnPointKind kind,required Position position,DateTime? now})async {
    final at=now??DateTime.now();
    if(!usablePointFix(position,at))throw const PointLocationException('Il punto non è stato salvato: serve un GPS recente con precisione entro 100 m.');
    final clean=name.trim().isEmpty?kind.label:name.trim();
    if(clean.length>80)throw const FormatException('Nome troppo lungo');
    final p=ReturnPoint(id:const Uuid().v4(),name:clean,kind:kind,latitude:position.latitude,longitude:position.longitude,accuracy:position.accuracy,savedAt:at);
    await _mutate((data){(data['points'] as List).add(p.toJson());});return p;
  }
  Future<void> removePoint(String id)=>_mutate((data){(data['points'] as List).removeWhere((p)=>(p as Map)['id']==id);});
  Future<Set<String>> checks(String key)async {await _writes;return Set<String>.from(((await _read())['checklists'] as Map)[key] as List? ?? const []);}
  Future<Map<String,dynamic>?> selectedPlan()async {await _writes;final p=(await _read())['selectedPlan'];return p==null?null:Map<String,dynamic>.from(p as Map);}
  Future<void> savePlan(Map<String,dynamic> plan)=>_mutate((d){d['selectedPlan']=plan;});
  Future<void> saveChecks(String key,Set<String> checked)=>_mutate((d){(d['checklists'] as Map)[key]=checked.toList();});
  Future<Map<String,dynamic>> exportSnapshot()async {await _writes;return _read();}
  Future<void> restoreSnapshot(Map<String,dynamic> snapshot) {final copy=validate(snapshot);return _mutate((d){d.clear();d.addAll(copy);});}
}
