import 'package:geolocator/geolocator.dart';
import 'wildtrack_intelligence_service.dart';
import 'solar_context_service.dart';

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
  static final instance=RadarService();
  Future<RadarSnapshot> load({Position? position})async=>fromIntelligence(await WildTrackIntelligenceService.instance.load(position:position));
  static RadarSnapshot fromIntelligence(IntelligenceSnapshot s){
    RadarSpecies convert(SpeciesForecast f)=>RadarSpecies(f.name,f.score,confidence:f.confidence,reason:f.reason,bestWindow:f.bestWindow,presenceSupported:f.presenceSupported,quality:f.quality);
    return RadarSnapshot(activity:s.activity,species:s.species.map(convert).toList(),listening:s.listening.map(convert).toList(),temperature:s.weather.temperature,wind:s.weather.wind,precipitation:s.weather.precipitation,humidity:s.weather.humidity,habitat:s.habitat.primary,elevation:s.habitat.elevation,weatherAvailable:s.weather.temperature!=null||s.weather.wind!=null||s.weather.precipitation!=null,hasPosition:s.hasPosition,generatedAt:s.generatedAt,solar:s.solar,latitude:s.latitude,longitude:s.longitude,weatherAt:s.weather.fetchedAt,habitatAt:s.habitat.fetchedAt,evidenceAvailable:s.evidenceAvailable);
  }
}
