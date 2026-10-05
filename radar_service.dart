import 'package:geolocator/geolocator.dart';
import 'wildtrack_intelligence_service.dart';
import 'solar_context_service.dart';
import 'radar_habitat_service.dart';
import 'package:latlong2/latlong.dart';

class RadarSpecies {
  const RadarSpecies(this.name,this.score,{this.confidence=0,this.reason='',this.bestWindow='',this.presenceSupported=false,this.quality='Limitata'});
  final String name,reason,bestWindow,quality;
  final int score,confidence;
  final bool presenceSupported;
  String get conditions=>score>=65?'Buone':score>=40?'Discrete':'Limitate';
}
class RadarSnapshot {
  const RadarSnapshot({required this.activity,required this.species,this.listening=const [],this.temperature,this.wind,this.precipitation,this.humidity,this.habitat='unknown',this.elevation,this.weatherAvailable=false,this.hasPosition=false,this.generatedAt,this.solar,this.latitude,this.longitude,this.weatherAt,this.habitatAt,this.evidenceAvailable=false});
  final String activity,habitat;
  final List<RadarSpecies> species,listening;
  final double? temperature,wind,precipitation,humidity,elevation,latitude,longitude;
  final bool weatherAvailable,hasPosition,evidenceAvailable;
  final DateTime? generatedAt,weatherAt,habitatAt;
  final SolarContext? solar;
}
class RadarService {
  RadarService({Future<RadarSnapshot> Function(Position?)? loader, DateTime Function()? clock, Future<Position?> Function()? positionProvider})
      : _loader = loader ?? ((position) async => fromIntelligence(await WildTrackIntelligenceService.instance.load(position: position, requestPosition:false))),
        _positionProvider = positionProvider ?? (loader == null ? WildTrackIntelligenceService.instance.authorizedPosition : (() async => null)),
        _clock = clock ?? DateTime.now;
  static final instance = RadarService();
  static const refreshInterval = Duration(hours: 1);
  final Future<RadarSnapshot> Function(Position?) _loader;
  final Future<Position?> Function() _positionProvider;
  final DateTime Function() _clock;
  final Map<String,Future<RadarSnapshot>> _pending = {};
  RadarSnapshot? _cached;
  DateTime? _loadedAt;
  int _generation=0;

  Future<RadarSnapshot> load({Position? position, bool forceRefresh = false}) async {
    final candidate=position ?? await _positionProvider();
    final pos=candidate!=null && WildTrackIntelligenceService.validPosition(candidate,_clock())?candidate:null;
    final key=pos==null?'none':'${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)},${pos.altitude.toStringAsFixed(0)},${pos.altitudeAccuracy.toStringAsFixed(0)}';
    if(_pending.containsKey(key))return _pending[key]!;
    final c=_cached, age=_loadedAt==null?null:_clock().difference(_loadedAt!);
    final sameArea=pos==null ? c?.hasPosition==false : c?.hasPosition==true && c?.latitude!=null && c?.longitude!=null && RadarHabitatService.distance.as(LengthUnit.Meter,LatLng(pos.latitude,pos.longitude),LatLng(c!.latitude!,c.longitude!))<=RadarHabitatService.reuseDistance;
    final altitude=pos!=null&&pos.altitude.isFinite&&pos.altitudeAccuracy>0&&pos.altitudeAccuracy<=100?pos.altitude:null;
    final sameAltitude=altitude==null?c?.elevation==null:c?.elevation!=null&&(altitude-c!.elevation!).abs()<=100;
    if(!forceRefresh && sameAltitude && sameArea && c!=null && age!=null && age>=Duration.zero && age<refreshInterval)return c;
    final generation=++_generation;
    final future=_loader(pos).then((value){
      if(generation==_generation){_cached=value;_loadedAt=_clock();}
      return value;
    });
    _pending[key]=future;
    try{return await future;}finally{_pending.remove(key);}
  }
  static RadarSnapshot fromIntelligence(IntelligenceSnapshot s){
    RadarSpecies convert(SpeciesForecast f)=>RadarSpecies(f.name,f.score,confidence:f.confidence,reason:f.reason,bestWindow:f.bestWindow,presenceSupported:f.presenceSupported,quality:f.quality);
    return RadarSnapshot(activity:s.activity,species:s.species.map(convert).toList(),listening:s.listening.map(convert).toList(),temperature:s.weather.temperature,wind:s.weather.wind,precipitation:s.weather.precipitation,humidity:s.weather.humidity,habitat:s.habitat.primary,elevation:s.habitat.elevation,weatherAvailable:s.weather.temperature!=null||s.weather.wind!=null||s.weather.precipitation!=null,hasPosition:s.hasPosition,generatedAt:s.generatedAt,solar:s.solar,latitude:s.latitude,longitude:s.longitude,weatherAt:s.weather.fetchedAt,habitatAt:s.habitat.fetchedAt,evidenceAvailable:s.evidenceAvailable);
  }
}

