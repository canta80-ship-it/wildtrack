import 'radar_habitat_service.dart';
import 'species_ecology_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/sighting.dart';
import '../models/track_session.dart';
import 'database_service.dart';
import 'package:flutter/services.dart';
import 'community_service.dart' show communityUrl;
import 'solar_context_service.dart';
import 'radar_profile_service.dart';
import 'radar_survey_service.dart';

class HabitatContext {
  const HabitatContext({required this.primary, required this.tags, this.elevation, this.mapped = false, this.fetchedAt, this.latitude, this.longitude});
  final bool mapped;
  final double? latitude, longitude;
  final DateTime? fetchedAt;
  final String primary;
  final Set<String> tags;
  final double? elevation;
}

class WeatherContext {
  const WeatherContext({
    this.temperature,
    this.wind,
    this.precipitation,
    this.humidity,
    this.weatherCode,
    this.sunrise,
    this.sunset,
    this.fetchedAt,
  });
  final DateTime? fetchedAt;
  final double? temperature;
  final double? wind;
  final double? precipitation;
  final double? humidity;
  final int? weatherCode;
  final DateTime? sunrise;
  final DateTime? sunset;
}

class SpeciesForecast {
  const SpeciesForecast({
    required this.name,
    required this.score,
    required this.confidence,
    required this.reason,
    required this.bestWindow,
    this.presenceSupported = false, this.quality = 'Limitata',
  });
  final bool presenceSupported;
  final String quality;
  String get conditions => score >= 65 ? 'Buone' : score >= 40 ? 'Discrete' : 'Limitate';
  final String name;
  final int score;
  final int confidence;
  final String reason;
  final String bestWindow;
}

class IntelligenceSnapshot {
  const IntelligenceSnapshot({
    required this.activity,
    required this.species,
    required this.habitat,
    required this.weather,
    required this.generatedAt,
    required this.hasPosition,
    this.listening = const [], this.solar, this.latitude, this.longitude, this.evidenceAvailable = false,
  });
  final List<SpeciesForecast> listening;
  final SolarContext? solar;
  final double? latitude, longitude;
  final bool evidenceAvailable;
  final String activity;
  final List<SpeciesForecast> species;
  final HabitatContext habitat;
  final WeatherContext weather;
  final DateTime generatedAt;
  final bool hasPosition;
}

class BiodiversityReport {
  const BiodiversityReport({
    required this.score,
    required this.richness,
    required this.evenness,
    required this.spatialCoverage,
    required this.seasonCoverage,
    required this.effort,
    required this.uniqueSpecies,
    required this.geoCells,
    required this.seasons,
  });
  final int score;
  final double richness;
  final double evenness;
  final double spatialCoverage;
  final double seasonCoverage;
  final double effort;
  final int uniqueSpecies;
  final int geoCells;
  final int seasons;
}

class DynamicMission {
  const DynamicMission({
    required this.title,
    required this.description,
    required this.progress,
    required this.iconKey,
  });
  final String title;
  final String description;
  final double progress;
  final String iconKey;
}

class NatureTimelineInsight {
  const NatureTimelineInsight(this.title, this.body, this.date);
  final String title;
  final String body;
  final DateTime date;
}

class RadarEvidence {
  const RadarEvidence(this.id,this.species,this.latitude,this.longitude,this.at,this.source);
  final String id,species,source;
  final double latitude,longitude;
  final DateTime at;
}

class WildTrackIntelligenceService {
  static final instance = WildTrackIntelligenceService();
  static const Distance _distance = Distance();

  Future<Position?> authorizedPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) return null;
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)));
      return validPosition(p, DateTime.now()) ? p : null;
    } catch (_) { return null; }
  }
  static bool validPosition(Position p, DateTime now) => p.latitude.isFinite && p.longitude.isFinite && p.latitude.abs() <= 90 && p.longitude.abs() <= 180 && p.accuracy.isFinite && p.accuracy >= 0 && p.accuracy <= 200 && now.difference(p.timestamp).abs() <= const Duration(minutes: 5);

  final Map<String, (DateTime, WeatherContext)> _weatherCache = {};
  final Map<String, (DateTime, HabitatContext)> _habitatCache = {};
  final Map<String, (DateTime, List<RadarEvidence>)> _evidenceCache = {};
  final Map<String, Future<IntelligenceSnapshot>> _pending = {};
  String _cell(Position p) => '${(p.latitude*200).floor()}:${(p.longitude*200).floor()}';
  Future<IntelligenceSnapshot> load({Position? position, bool requestPosition = true}) async {
    final now = DateTime.now();
    final raw = position ?? (requestPosition ? await authorizedPosition() : null);
    final pos = raw != null && validPosition(raw, now) ? raw : null;
    final key = pos == null ? 'none' : '${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)}';
    if (_pending.containsKey(key)) return _pending[key]!;
    final future = _loadContext(pos, now);
    _pending[key] = future;
    try { return await future; } finally { _pending.remove(key); }
  }
  Future<IntelligenceSnapshot> _loadContext(Position? pos, DateTime now) async {
    final sightings = await DatabaseService.instance.getSightings();
    var surveys = <RadarSurvey>[];
    try { surveys = await RadarSurveyService.instance.load(); } catch (_) {}
    if (pos == null) return evaluate(now:now, history:sightings, surveys:surveys);
    final values = await Future.wait<Object>([
      _weather(pos).catchError((_)=>const WeatherContext()),
      _habitat(pos).catchError((_)=>const HabitatContext(primary:'unknown',tags:{'unknown'})),
      _regionalEvidence(pos).catchError((_)=>const <RadarEvidence>[]),
    ]);
    return evaluate(now:now,position:pos,weather:values[0] as WeatherContext,habitat:values[1] as HabitatContext,history:sightings,evidence:values[2] as List<RadarEvidence>,surveys:surveys);
  }

  /// Pure calculation: fixtures can test night, migration, missing data and
  /// old / distant sightings without any external request.
  IntelligenceSnapshot evaluate({required DateTime now, Position? position, WeatherContext weather = const WeatherContext(), HabitatContext habitat = const HabitatContext(primary:'unknown',tags:{'unknown'}), List<Sighting> history = const [], List<RadarEvidence> evidence = const [], List<RadarSurvey> surveys = const []}) {
    final pos = position != null && validPosition(position,now) ? position : null;
    if (pos == null) return IntelligenceSnapshot(activity:'DATI INSUFFICIENTI',species:const [],habitat:const HabitatContext(primary:'unknown',tags:{'unknown'}),weather:const WeatherContext(),generatedAt:now,hasPosition:false);
    final age = habitat.fetchedAt == null ? Duration.zero : now.difference(habitat.fetchedAt!);
    final local = habitat.latitude == null || habitat.longitude == null || RadarHabitatService.distance.as(LengthUnit.Meter, LatLng(pos.latitude,pos.longitude), LatLng(habitat.latitude!,habitat.longitude!)) <= RadarHabitatService.reuseDistance;
    if (!habitat.mapped || habitat.tags.isEmpty || habitat.tags.contains('unknown') || age < Duration.zero || age >= const Duration(hours:1) || !local) {
      return IntelligenceSnapshot(activity:'HABITAT NON DISPONIBILE',species:const [],listening:const [],habitat:const HabitatContext(primary:'unknown',tags:{'unknown'}),weather:weather,generatedAt:now,hasPosition:true,solar:SolarContext.at(now,pos.latitude,pos.longitude),latitude:pos.latitude,longitude:pos.longitude,evidenceAvailable:evidence.isNotEmpty);
    }
    final sun = SolarContext.at(now,pos.latitude,pos.longitude);
    final visual = <SpeciesForecast>[], listening = <SpeciesForecast>[];
    for (final entry in radarProfiles.entries) {
      final result = _forecast(entry.key,entry.value,now,pos,weather,habitat,history,evidence,surveys,sun);
      if (result.score >= 20 && (!sun.dark || entry.value.cycle != 'diurnal')) visual.add(result);
      if (entry.value.audible && sun.dark && entry.value.cycle == 'nocturnal' && result.presenceSupported && result.score >= 20) {
        listening.add(SpeciesForecast(name:result.name,score:math.min(80,result.score+25),confidence:result.confidence,reason:'Ascolto passivo: attività notturna; ${result.reason}',bestWindow:'Dopo il tramonto, senza playback',presenceSupported:true,quality:result.quality));
      }
    }
    visual.sort((a,b)=>b.score.compareTo(a.score));
    listening.sort((a,b)=>b.score.compareTo(a.score));
    final top = visual.take(4).toList();
    final average = top.isEmpty ? 0 : top.fold<int>(0,(n,s)=>n+s.score)/top.length;
    return IntelligenceSnapshot(activity:top.isEmpty?'DATI INSUFFICIENTI':average>=65?'BUONE':average>=40?'DISCRETE':'LIMITATE',species:visual,listening:listening,habitat:habitat,weather:weather,generatedAt:now,hasPosition:true,solar:sun,latitude:pos.latitude,longitude:pos.longitude,evidenceAvailable:evidence.isNotEmpty);
  }

  SpeciesForecast _forecast(String name, RadarProfile p, DateTime now, Position pos, WeatherContext w, HabitatContext h, List<Sighting> history, List<RadarEvidence> evidence, List<RadarSurvey> surveys, SolarContext sun) {
    var score = 25.0, qualityPoints = 1;
    final reasons = <String>[];
    final habitatKnown = h.mapped && !h.tags.contains('unknown');
    final compatible = h.tags.any(p.habitats.contains);
    if (habitatKnown) { qualityPoints++; score += compatible?18:-20; reasons.add(compatible?'habitat cartografato compatibile nelle vicinanze':'habitat cartografato poco compatibile'); }
    else reasons.add('habitat non disponibile');
    if (p.cycle == 'diurnal') score += sun.phase=='day'?25:sun.twilight?8:-40;
    if (p.cycle == 'crepuscular') score += sun.twilight?28:sun.dark?0:10;
    if (p.cycle == 'nocturnal') score += sun.dark?14:sun.twilight?20:-10;
    reasons.add(sun.label.toLowerCase());
    if (sun.dark) { score = math.min(score,32.0); reasons.add('visibilità ridotta: attività non equivale a incontro visivo'); }
    if (p.peak.contains(now.month)) {score+=10; reasons.add('periodo favorevole');}
    final inSeason = p.months.isEmpty || p.months.contains(now.month);
    final dormant = p.dormant.contains(now.month);
    if (!inSeason) {score-=30; reasons.add('fuori dalla stagione tipica italiana');}
    if (dormant) {score-=35; reasons.add('periodo di quiescenza o letargo: possibili eccezioni locali');}
    final ecology=speciesEcology[name]!;
    reasons.add('Ambiente della specie: ${ecology.habitat}');
    final altitude = h.elevation;
    final outsideQuota=altitude!=null && altitude.isFinite && ecology.outside(altitude);
    final mountainSpecies=p.alpine || name=='Gracchio alpino';
    final mountainUncertain=mountainSpecies && (altitude==null || altitude<700); 
    if (altitude != null && altitude.isFinite) {
      qualityPoints++;
      reasons.add('Quota GPS ${altitude.round()} m: ${ecology.altitudeNote}');
      if(outsideQuota){score-=12;reasons.add('quota fuori dalla fascia tipica documentata');}
      else if(ecology.minimum!=null || ecology.maximum!=null)score+=5;
    } else reasons.add('quota non affidabile');
    final sources = <String>{};
    var weightedHistory = 0.0, recentCount = 0;
    for (final s in history) {
      if (s.species != name || !s.hasPosition || s.kind != 'Animale') continue;
      final age = now.difference(s.timestamp).inHours/24;
      if (age<0 || age>365) continue;
      final km = _distance.as(LengthUnit.Kilometer,LatLng(pos.latitude,pos.longitude),LatLng(s.latitude!,s.longitude!));
      if (km>25 || (s.accuracy != null && s.accuracy!>1000)) continue;
      recentCount++;
      final phase = SolarContext.at(s.timestamp,s.latitude!,s.longitude!).phase;
      weightedHistory += math.exp(-age/120)*(km<=5?2:km<=10?1:.3)*(phase==sun.phase?1.3:1);
      sources.add('personale');
    }
    var recentRemote = 0;
    final unique = <String>{};
    for (final e in evidence) {
      if (e.species != name || !unique.add(e.id)) continue;
      final age = now.difference(e.at).inHours/24;
      if (age<0 || age>730 || e.latitude.abs()>90 || e.longitude.abs()>180) continue;
      final km = _distance.as(LengthUnit.Kilometer,LatLng(pos.latitude,pos.longitude),LatLng(e.latitude,e.longitude));
      if (km>40) continue;
      sources.add(e.source); recentRemote++;
    }
    final supported = recentCount>0 || recentRemote>0;
    if (supported) {qualityPoints++; score+=math.min(12,weightedHistory*3+math.min(6,recentRemote*1.5)); reasons.add('${sources.join(' + ')}: segnalazioni recenti nella zona');}
    else {score=math.min(score,48.0); reasons.add('presenza locale non confermata dai dati disponibili');}
    // Regional records are positive evidence, never a complete range map.
    // Strict exclusion is reserved for explicit geographical incompatibility.
    if (p.alpine && pos.latitude<44 && !supported) score=0;
    if (p.localised && !supported) score=math.min(score,24.0);
    if (w.temperature != null) {qualityPoints++; if(w.temperature!>30 && p.cycle!='nocturnal') {score-=5; reasons.add('caldo penalizzante');}}
    if (w.wind != null && w.wind!>25) {score-=8; reasons.add('vento forte');}
    if (w.precipitation != null && w.precipitation!>2) {score-=8; reasons.add('pioggia intensa');}
    if (!habitatKnown) score=math.min(score,38.0);
    if (habitatKnown && !compatible) score=math.min(score,15.0);
    if ((outsideQuota || mountainUncertain) && !supported)score=math.min(score,15.0);
    if(name=='Marmotta' && altitude!=null && altitude<800)score=math.min(score,15.0);
    if (!inSeason || dormant) score=math.min(score,15.0);
    if (sun.dark) score=math.min(score,32.0);
    final visits = surveys.where((s)=>s.species==name && s.phase==sun.phase && s.minutes>=15 && now.difference(s.at)>=Duration.zero && now.difference(s.at).inDays<=90 && _distance.as(LengthUnit.Kilometer,LatLng(pos.latitude,pos.longitude),LatLng(s.latitude,s.longitude))<=2).toList();
    if (visits.isNotEmpty) reasons.add('controlli comparabili: ${visits.where((s)=>s.seen).length}/${visits.length} con incontro, durata ≥15 min; dato descrittivo');
    final quality = qualityPoints>=5?'Buona':qualityPoints>=3?'Parziale':'Limitata';
    final window = p.cycle=='nocturnal'?'Dopo il tramonto ${SolarContext.clock(sun.sunset)}; ascolto passivo':p.cycle=='crepuscular'?'Alba ${SolarContext.clock(sun.sunrise)} · tramonto ${SolarContext.clock(sun.sunset)}':'Ore di luce ${SolarContext.clock(sun.sunrise)}–${SolarContext.clock(sun.sunset)}';
    return SpeciesForecast(name:name,score:score.round().clamp(0,90),confidence:qualityPoints*20,reason:reasons.join('; '),bestWindow:window,presenceSupported:supported,quality:quality);
  }

  Future<Map<String,dynamic>> _json(Uri uri, {String? body}) async {
    final client = HttpClient()..connectionTimeout=const Duration(seconds:4);
    try {
      return await (() async {
        final req = await client.openUrl(body==null?'GET':'POST',uri);
        req.headers.set(HttpHeaders.userAgentHeader,'WildTrack/0.7.12 (non-commercial wildlife field guide)');
        if (body!=null) {req.headers.contentType=ContentType('application','x-www-form-urlencoded');req.write(body);}
        final response = await req.close();
        if(response.statusCode!=200) throw const HttpException('Servizio non disponibile');
        return Map<String,dynamic>.from(jsonDecode(await response.transform(utf8.decoder).join()) as Map);
      })().timeout(const Duration(seconds:8));
    } finally {client.close(force:true);}
  }
  Future<WeatherContext> _weather(Position p) async {
    final key=_cell(p), now=DateTime.now(), cached=_weatherCache[_cell(p)];
    if(cached!=null && now.difference(cached.$1)<const Duration(minutes:10)) return cached.$2;
    final data=await _json(Uri.https('api.open-meteo.com','/v1/forecast',{'latitude':'${p.latitude}','longitude':'${p.longitude}','current':'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m','forecast_days':'1','timezone':'auto'}));
    final c=data['current'] as Map? ?? const {};
    final result=WeatherContext(temperature:(c['temperature_2m'] as num?)?.toDouble(),wind:(c['wind_speed_10m'] as num?)?.toDouble(),precipitation:(c['precipitation'] as num?)?.toDouble(),humidity:(c['relative_humidity_2m'] as num?)?.toDouble(),weatherCode:(c['weather_code'] as num?)?.toInt(),fetchedAt:now);
    _weatherCache[key]=(now,result); if(_weatherCache.length>30)_weatherCache.remove(_weatherCache.keys.first); return result;
  }
  Future<HabitatContext> _habitat(Position p) async {
    final key='${(p.latitude*1000).floor()}:${(p.longitude*1000).floor()}', now=DateTime.now();
    final cached=_habitatCache[key];
    final elevation=p.altitude.isFinite && p.altitudeAccuracy>0 && p.altitudeAccuracy<=100?p.altitude:null;
    if(cached!=null && now.difference(cached.$1)<const Duration(hours:1) && cached.$2.latitude!=null && RadarHabitatService.distance.as(LengthUnit.Meter,LatLng(p.latitude,p.longitude),LatLng(cached.$2.latitude!,cached.$2.longitude!))<=RadarHabitatService.reuseDistance) {
      return HabitatContext(primary:cached.$2.primary,tags:cached.$2.tags,elevation:elevation,mapped:true,fetchedAt:cached.$2.fetchedAt,latitude:cached.$2.latitude,longitude:cached.$2.longitude);
    }
    final query=RadarHabitatService.query(p);
    Map<String,dynamic>? data;
    for(final endpoint in ['https://overpass-api.de/api/interpreter','https://overpass.private.coffee/api/interpreter']) {
      try {data=await _json(Uri.parse(endpoint),body:'data=${Uri.encodeQueryComponent(query)}');if(data['remark']==null)break;data=null;}catch(_){}
    }
    final tags=data==null ? <String>{} : RadarHabitatService.tags(data,p);
    final result=HabitatContext(primary:tags.isEmpty?'unknown':tags.length>1?'mosaic':tags.first,tags:tags.isEmpty?const {'unknown'}:tags,elevation:elevation,mapped:tags.isNotEmpty,fetchedAt:DateTime.now(),latitude:p.latitude,longitude:p.longitude);
    if(tags.isNotEmpty){_habitatCache[key]=(now,result);if(_habitatCache.length>30)_habitatCache.remove(_habitatCache.keys.first);}return result;
  }
  Future<List<RadarEvidence>> _regionalEvidence(Position p) async {
    final key='${(p.latitude*10).floor()}:${(p.longitude*10).floor()}', now=DateTime.now(), cached=_evidenceCache['${(p.latitude*10).floor()}:${(p.longitude*10).floor()}'];
    if(cached!=null && now.difference(cached.$1)<const Duration(hours:6))return cached.$2;
    final out=<RadarEvidence>[];
    try {
      final bundled=jsonDecode(await rootBundle.loadString('nature_assets.json')) as Map;
      final taxa=(bundled['taxa'] as Map).values.map((e)=>'$e').toList();
      final deltaLat=.38, deltaLon=.38/math.cos(p.latitude*math.pi/180).abs().clamp(.2,1);
      final q=<String,dynamic>{'taxonKey':taxa,'hasCoordinate':'true','hasGeospatialIssue':'false','occurrenceStatus':'PRESENT','basisOfRecord':['HUMAN_OBSERVATION','MACHINE_OBSERVATION'],'eventDate':'${now.subtract(const Duration(days:730)).toUtc().toIso8601String().split('T').first},${now.toUtc().toIso8601String().split('T').first}','decimalLatitude':'${(p.latitude-deltaLat).clamp(-90,90)},${(p.latitude+deltaLat).clamp(-90,90)}','decimalLongitude':'${(p.longitude-deltaLon).clamp(-180,180)},${(p.longitude+deltaLon).clamp(-180,180)}','limit':'300'};
      final data=await _json(Uri.https('api.gbif.org','/v1/occurrence/search',q));
      final byLatin={for(final e in radarProfiles.entries)e.value.latin:e.key};
      for(final r in data['results'] as List? ?? const []) {
        final e=r as Map, name=byLatin[e['species']], at=DateTime.tryParse('${e['eventDate']}');
        if(name==null||at==null||e['decimalLatitude'] is!num||e['decimalLongitude'] is!num)continue;
        final uncertainty=e['coordinateUncertaintyInMeters'];if(uncertainty is num&&uncertainty>2000)continue;
        out.add(RadarEvidence('gbif:${e['key']}',name,(e['decimalLatitude'] as num).toDouble(),(e['decimalLongitude'] as num).toDouble(),at,'GBIF (campione regionale)'));
      }
    }catch(_){}
    // Community is read-only: no presence publication and no private map access.
    try {
      final data=await _json(Uri.parse('$communityUrl/api/sightings'));
      for(final raw in (data['items'] as List? ?? const []).take(300)) {
        final e=raw as Map, name='${e['species']}', at=DateTime.tryParse('${e['timestamp'] ?? e['observed_at'] ?? ''}');
        final lat=e['lat']??e['latitude'], lon=e['lng']??e['longitude'];
        if(!radarProfiles.containsKey(name)||at==null||lat is!num||lon is!num)continue;
        out.add(RadarEvidence('community:${e['id']}',name,lat.toDouble(),lon.toDouble(),at,'Community (non verificata)'));
      }
    }catch(_){}
    if(out.isNotEmpty){_evidenceCache[key]=(now,out);if(_evidenceCache.length>20)_evidenceCache.remove(_evidenceCache.keys.first);}return out;
  }

  BiodiversityReport biodiversity(List<Sighting> sightings, List<TrackSession> sessions) {
    final valid = sightings.where((s) => s.species.trim().isNotEmpty && s.species != 'Specie non identificata').toList();
    final counts = <String, int>{};
    for (final s in valid) counts[s.species] = (counts[s.species] ?? 0) + math.max(1, s.count);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    var shannon = 0.0;
    if (total > 0) {
      for (final c in counts.values) {
        final p = c / total;
        shannon -= p * math.log(p);
      }
    }
    final evenness = counts.length <= 1 ? (counts.isEmpty ? 0.0 : 1.0) : (shannon / math.log(counts.length)).clamp(0.0, 1.0);
    final cells = <String>{};
    final seasons = <int>{};
    for (final s in valid) {
      if (s.hasPosition) cells.add('${(s.latitude! * 20).floor()}:${(s.longitude! * 20).floor()}');
      seasons.add(((s.timestamp.month - 1) ~/ 3));
    }
    final richness = (counts.length / 30).clamp(0.0, 1.0);
    final spatial = (cells.length / 20).clamp(0.0, 1.0);
    final seasonal = (seasons.length / 4).clamp(0.0, 1.0);
    final effort = (sessions.length / 20).clamp(0.0, 1.0);
    final score = (100 * (richness * .35 + evenness * .25 + spatial * .15 + seasonal * .15 + effort * .10)).round().clamp(0, 100);
    return BiodiversityReport(score: score, richness: richness, evenness: evenness, spatialCoverage: spatial, seasonCoverage: seasonal, effort: effort, uniqueSpecies: counts.length, geoCells: cells.length, seasons: seasons.length);
  }

  Map<String, DateTime> firstSightings(List<Sighting> sightings) {
    final out = <String, DateTime>{};
    for (final s in sightings.where((e) => e.species.isNotEmpty && e.species != 'Specie non identificata')) {
      final current = out[s.species];
      if (current == null || s.timestamp.isBefore(current)) out[s.species] = s.timestamp;
    }
    return out;
  }

  List<NatureTimelineInsight> timeline(List<Sighting> sightings) {
    final now = DateTime.now();
    final out = <NatureTimelineInsight>[];
    final first = firstSightings(sightings);
    for (final e in first.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) {
      out.add(NatureTimelineInsight('Primo ${e.key}', 'La prima osservazione registrata di ${e.key} nel tuo archivio.', e.value));
    }
    final priorYears = sightings.where((s) => s.timestamp.year < now.year && s.timestamp.month == now.month).toList();
    if (priorYears.isNotEmpty) {
      final bySpecies = <String, int>{};
      for (final s in priorYears) bySpecies[s.species] = (bySpecies[s.species] ?? 0) + 1;
      final top = bySpecies.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      out.insert(0, NatureTimelineInsight('In questo periodo negli anni scorsi', 'Nel mese di ${now.month} hai registrato soprattutto ${top.take(3).map((e) => e.key).join(', ')}.', DateTime(now.year, now.month, 1)));
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out.take(20).toList();
  }

  List<DynamicMission> missions(IntelligenceSnapshot snapshot, List<Sighting> sightings, List<TrackSession> sessions) {
    final report = biodiversity(sightings, sessions);
    final out = <DynamicMission>[];
    final top = snapshot.species.isEmpty ? null : snapshot.species.first;
    if (top != null) {
      out.add(DynamicMission(title: 'Finestra ${top.name}', description: 'Osservazione non invasiva: ${top.bestWindow}. ${top.reason}.', progress: sightings.any((s) => s.species == top.name && DateTime.now().difference(s.timestamp).inDays < 30) ? 1 : 0.15, iconKey: 'species'));
    }
    if ((snapshot.weather.precipitation ?? 0) > .5) {
      out.add(const DynamicMission(title: 'Tracce dopo la pioggia', description: 'Cerca impronte, fatte e passaggi su fango o terreno umido. Fotografa con riferimento metrico, senza seguire l’animale.', progress: .1, iconKey: 'tracks'));
    }
    if (snapshot.habitat.tags.contains('forest')) {
      out.add(DynamicMission(title: 'Lettura del bosco', description: 'Registra tre segni di presenza diversi nello stesso habitat: impronta, sfregamento, penna, fatta o verso.', progress: math.min(1, sightings.where((s) => const {'Impronta', 'Traccia', 'Fatta', 'Verso'}.contains(s.kind)).length / 3), iconKey: 'forest'));
    }
    if (report.seasons < 4) {
      out.add(DynamicMission(title: 'Completa le stagioni', description: 'Il tuo passaporto copre ${report.seasons}/4 stagioni. Documenta un’uscita nella stagione meno rappresentata.', progress: report.seasons / 4, iconKey: 'season'));
    }
    if (report.geoCells < 8) {
      out.add(DynamicMission(title: 'Habitat nuovo', description: 'Esplora responsabilmente una nuova area e registra almeno un habitat diverso dai tuoi luoghi abituali.', progress: (report.geoCells / 8).clamp(0, 1), iconKey: 'map'));
    }
    return out.take(5).toList();
  }
}
