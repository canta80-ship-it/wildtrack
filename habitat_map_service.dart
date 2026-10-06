import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'preferences_service.dart';
import 'radar_profile_service.dart';

class HabitatPatch {
  const HabitatPatch(this.id, this.kind, this.name, this.points, this.holes, {this.urban = false, this.urbanCore = false});
  final String id, kind, name;
  final bool urban, urbanCore;
  final List<LatLng> points;
  final List<List<LatLng>> holes;
  Map<String, dynamic> toJson() => {'id': id, 'urban': urban, 'urbanCore': urbanCore, 'kind': kind, 'name': name, 'points': points.map((p) => [p.latitude, p.longitude]).toList(), 'holes': holes.map((ring) => ring.map((p) => [p.latitude, p.longitude]).toList()).toList()};
}

class HabitatMapService {
  static final instance = HabitatMapService();
  static const profiles = <String, Set<String>>{
 'Riccio': {'forest','grass','farmland','park','scrub'}, 'Gallo cedrone': {'forest'}, 'Gallo forcello': {'forest','grass','scrub'},
 'Lince': {'forest','rock'}, 'Tritone': {'water','wetland','forest'}, 'Rospo': {'forest','water','wetland','park'}, 'Salamandra': {'forest','water'},
    'Cervo': {'forest','grass'}, 'Capriolo': {'forest','grass','farmland'}, 'Volpe': {'forest','grass','farmland','scrub','park'},
    'Camoscio alpino': {'rock','grass','forest'}, 'Stambecco': {'rock','grass'}, 'Cinghiale': {'forest','scrub','farmland'},
    'Aquila reale': {'rock','grass'}, 'Grifone': {'rock','grass'}, 'Poiana': {'forest','grass','farmland'},
    'Allocco': {'forest','park'}, 'Picchio nero': {'forest'}, 'Airone cenerino': {'water','wetland'}, 'Germano reale': {'water','wetland'},
    'Falco di palude': {'wetland'}, 'Orso bruno': {'forest','grass'}, 'Lupo': {'forest','grass','rock'},
    'Sciacallo dorato': {'forest','farmland','scrub'}, 'Marmotta': {'grass','rock'}, 'Ermellino': {'grass','rock'},
    'Tasso': {'forest','farmland','grass'}, 'Gracchio alpino': {'rock','grass'}, 'Gufo reale': {'rock','grass','forest'},
    'Barbagianni': {'farmland','grass'}, 'Ghiandaia': {'forest','park'},
    "Lepre": {"grass","farmland"},
    "Scoiattolo": {"forest","park"},
    "Upupa": {"grass","farmland","park"},
    "Gheppio": {"grass","farmland","rock"},
    "Assiolo": {"farmland","park","scrub"},
    "Nibbio reale": {"grass","farmland","forest"},
    "Nibbio bruno": {"water","wetland","forest","farmland"},

  };
  static const _selectors = <String, List<String>>{
    'forest': ['[landuse=forest]','[natural=wood]'],
    'grass': ['[landuse=meadow]','[natural=grassland]'],
    'farmland': ['[landuse=farmland]','[landuse=orchard]'],
    'scrub': ['[natural=scrub]','[natural=heath]'],
    'rock': ['[natural=bare_rock]','[natural=scree]','[natural=shingle]'],
    'water': ['[natural=water]','[waterway=riverbank]'],
    'wetland': ['[natural=wetland]'],
    'park': ['[leisure=park]'],
  };
  static const urbanLanduses = {'residential', 'commercial', 'industrial', 'retail', 'institutional', 'education', 'garages', 'construction', 'brownfield'};
  static const labels = {'forest':'Boschi', 'grass':'Prati e pascoli', 'farmland':'Campagne', 'scrub':'Macchia', 'rock':'Rocce e ghiaioni', 'water':'Acque', 'wetland':'Zone umide', 'park':'Parchi alberati'};

  Set<String>? kindsFor(String species) => species == '__radar__' ? _selectors.keys.toSet() : profiles[species];

  String query(String species, LatLng center, {double radiusKm = 5}) {
    final kinds = kindsFor(species);
    if (kinds == null) throw ArgumentError('Specie non presente nel catalogo');
    final dy = radiusKm / 111.32;
    final dx = dy / math.cos(center.latitude * math.pi / 180).abs().clamp(.1, 1);
    final bbox = '${center.latitude-dy},${center.longitude-dx},${center.latitude+dy},${center.longitude+dx}';
    final urban = urbanLanduses.map((kind) => 'way[landuse=$kind]($bbox);relation[type=multipolygon][landuse=$kind]($bbox);').join();
    return '[out:json][timeout:18];($urban${kinds.expand((k) => _selectors[k]!).map((s) => 'way$s($bbox);relation[type=multipolygon]$s($bbox);').join()});out geom;';
  }
  String? _kind(Map tags) {
    if (tags['natural'] == 'wood' || tags['landuse'] == 'forest') return 'forest';
    if (tags['landuse'] == 'meadow' || tags['natural'] == 'grassland') return 'grass';
    if (['farmland','orchard'].contains(tags['landuse'])) return 'farmland';
    if (['scrub','heath'].contains(tags['natural'])) return 'scrub';
    if (['bare_rock','scree','shingle'].contains(tags['natural'])) return 'rock';
    if (tags['natural'] == 'water' || tags['waterway'] == 'riverbank') return 'water';
    if (tags['natural'] == 'wetland') return 'wetland';
    if (tags['leisure'] == 'park') return 'park';
    return null;
  }
  List<LatLng> _coordinates(dynamic raw) {
    if (raw is! List) return [];
    final out = <LatLng>[];
    for (final p in raw) {
      if (p is! Map || p['lat'] is! num || p['lon'] is! num) return [];
      final lat = (p['lat'] as num).toDouble(), lon = (p['lon'] as num).toDouble();
      if (!lat.isFinite || !lon.isFinite || lat.abs()>90 || lon.abs()>180) return [];
      out.add(LatLng(lat,lon));
    }
    return out;
  }
  bool _same(LatLng a, LatLng b) => (a.latitude-b.latitude).abs()<.0000001 && (a.longitude-b.longitude).abs()<.0000001;
  List<List<LatLng>> _rings(List<List<LatLng>> segments) {
    final pending = segments.where((s) => s.length >= 2).map((s) => [...s]).toList();
    final result = <List<LatLng>>[];
    while (pending.isNotEmpty) {
      var line = pending.removeAt(0);
      while (!_same(line.first,line.last)) {
        final index = pending.indexWhere((s) => _same(line.last,s.first) || _same(line.last,s.last) || _same(line.first,s.last) || _same(line.first,s.first));
        if (index<0) break;
        final next=pending.removeAt(index);
        if (_same(line.last,next.first)) { line.addAll(next.skip(1)); }
        else if (_same(line.last,next.last)) { line.addAll(next.reversed.skip(1)); }
        else if (_same(line.first,next.last)) { line=[...next.take(next.length-1),...line]; }
        else { line=[...next.reversed.take(next.length-1),...line]; }
      }
      if (line.length>=4 && _same(line.first,line.last)) result.add(line);
    }
    return result;
  }
  bool _inside(LatLng point, List<LatLng> ring) {
    var inside=false;
    for(var i=0,j=ring.length-1;i<ring.length;j=i++) {
      final a=ring[i],b=ring[j];
      if ((a.latitude>point.latitude)!=(b.latitude>point.latitude) && point.longitude<(b.longitude-a.longitude)*(point.latitude-a.latitude)/(b.latitude-a.latitude)+a.longitude) inside=!inside;
    }
    return inside;
  }
  bool _overlaps(List<LatLng> a, List<LatLng> b) {
    double minLat(List<LatLng> r) => r.map((p) => p.latitude).reduce(math.min);
    double maxLat(List<LatLng> r) => r.map((p) => p.latitude).reduce(math.max);
    double minLng(List<LatLng> r) => r.map((p) => p.longitude).reduce(math.min);
    double maxLng(List<LatLng> r) => r.map((p) => p.longitude).reduce(math.max);
    if (maxLat(a) < minLat(b) || maxLat(b) < minLat(a) || maxLng(a) < minLng(b) || maxLng(b) < minLng(a)) return false;
    if (a.any((p) => _inside(p, b)) || b.any((p) => _inside(p, a))) return true;
    double side(LatLng p, LatLng q, LatLng r) => (q.longitude-p.longitude)*(r.latitude-p.latitude)-(q.latitude-p.latitude)*(r.longitude-p.longitude);
    bool between(double x, double a, double b) => x >= math.min(a,b) && x <= math.max(a,b);
    bool onEdge(LatLng p, LatLng q, LatLng r) => side(p,q,r).abs() < 1e-14 && between(r.latitude,p.latitude,q.latitude) && between(r.longitude,p.longitude,q.longitude);
    for (var i = 1; i < a.length; i++) {
      for (var j = 1; j < b.length; j++) {
        final p = a[i-1], q = a[i], r = b[j-1], t = b[j];
        if (side(p,q,r)*side(p,q,t) < 0 && side(r,t,p)*side(r,t,q) < 0 || onEdge(p,q,r) || onEdge(p,q,t) || onEdge(r,t,p) || onEdge(r,t,q)) return true;
      }
    }
    return false;
  }
  List<HabitatPatch> parse(Map<String,dynamic> data, String species) {
    if (data['elements'] is! List || data['remark'] != null) throw const FormatException('Dati habitat incompleti');
    final allowed=kindsFor(species) ?? const <String>{};
    final out=<HabitatPatch>[];
    final seen = <String>{};
    final urbanRings = <List<LatLng>>[];
    for (final raw in data['elements'] as List) {
      if (raw is! Map || raw['tags'] is! Map || !urbanLanduses.contains(raw['tags']['landuse'])) continue;
      if (raw['type'] == 'way') urbanRings.addAll(_rings([_coordinates(raw['geometry'])]));
      if (raw['type'] == 'relation' && raw['members'] is List) {
        urbanRings.addAll(_rings((raw['members'] as List).whereType<Map>().where((m) => m['type'] == 'way' && (m['role'] == 'outer' || m['role'] == '')).map((m) => _coordinates(m['geometry'])).toList()));
      }
    }
    final elements = List<dynamic>.from(data['elements'] as List)..sort((a,b) => (a is Map && a['type']=='relation' ? 0 : 1).compareTo(b is Map && b['type']=='relation' ? 0 : 1));
    for(final raw in elements) {
      if(raw is! Map) continue;
      final tags=raw['tags'] is Map ? raw['tags'] as Map : const {};
      final kind=_kind(tags);
      if(kind==null || !allowed.contains(kind)) continue;
      List<List<LatLng>> outers=[],holes=[];
      if(raw['type']=='way') { outers=_rings([_coordinates(raw['geometry'])]); }
      else if(raw['type']=='relation' && raw['members'] is List) {
        final members=(raw['members'] as List).whereType<Map>().where((m) => m['type']=='way').toList();
        outers=_rings(members.where((m) => m['role']=='outer' || m['role']=='').map((m) => _coordinates(m['geometry'])).toList());
        holes=_rings(members.where((m) => m['role']=='inner').map((m) => _coordinates(m['geometry'])).toList());
      }
      for(var i=0;i<outers.length;i++) {
        final urban = urbanRings.any((ring) => _overlaps(outers[i], ring));
        final core = urbanRings.any((ring) => outers[i].every((point) => _inside(point, ring)));
        if (species != '__radar__' && core && !(radarProfiles[species]?.urbanGreen ?? false)) continue;
        final signature = outers[i].map((p) => '${p.latitude.toStringAsFixed(7)},${p.longitude.toStringAsFixed(7)}').toSet().toList()..sort();
        if (!seen.add('$kind:${signature.join(';')}')) continue;
        out.add(HabitatPatch('${raw['type']}-${raw['id']}-$i',kind,'${tags['name'] ?? labels[kind]}',outers[i],holes.where((h) => _inside(h.first,outers[i])).toList(),urban:urban,urbanCore:core));
      }
      if(out.length>=400) break;
    }
    return out;
  }
  Future<List<HabitatPatch>> load(String species, LatLng center, {double radiusKm = 5, bool forceRefresh = false}) async {
    final key='ecology_v3_${species.replaceAll(RegExp('[^a-zA-Z0-9]'),'_')}_${center.latitude.toStringAsFixed(4)}_${center.longitude.toStringAsFixed(4)}_$radiusKm';
    final file=File('${PreferencesService.instance.file.parent.path}/wildtrack_habitat_$key.json');
    if (!forceRefresh && await file.exists() && DateTime.now().difference((await file.stat()).modified) < const Duration(hours: 1)) {
      try { return parse(jsonDecode(await file.readAsString()) as Map<String,dynamic>, species); } catch (_) {}
    }
    final client=HttpClient()..connectionTimeout=const Duration(seconds:5);
    try {
      for(final host in ['overpass.private.coffee','overpass-api.de']) {
        try {
          final request=await client.postUrl(Uri.https(host,'/api/interpreter')).timeout(const Duration(seconds:6));
          request.headers.contentType=ContentType('application','x-www-form-urlencoded');
          request.headers.set(HttpHeaders.userAgentHeader,'WildTrack/0.7.10');
          request.write('data=${Uri.encodeQueryComponent(query(species,center,radiusKm:radiusKm))}');
          final response=await request.close().timeout(const Duration(seconds:22));
          if(response.statusCode!=200) continue;
          final bytes=<int>[];
          await for(final chunk in response.timeout(const Duration(seconds:8))) { bytes.addAll(chunk); if(bytes.length>8000000) throw const FormatException('Area troppo estesa'); }
          final raw=jsonDecode(utf8.decode(bytes)) as Map<String,dynamic>;
          final patches=parse(raw,species);
          // Keep raw OSM geometry so cached data passes the same validation.
          try { await file.parent.create(recursive:true); await file.writeAsString(jsonEncode(raw)); } catch (_) {}
          return patches;
        } catch (_) {}
      }
      try { if(await file.exists() && DateTime.now().difference((await file.stat()).modified) < const Duration(days: 1)) return parse(jsonDecode(await file.readAsString()) as Map<String,dynamic>,species); } catch (_) {}
      throw Exception('Habitat non disponibili in questa zona. Sposta la mappa e riprova.');
    } finally { client.close(force:true); }
  }
}

