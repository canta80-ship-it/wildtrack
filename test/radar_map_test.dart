import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildtrack_mvp/services/habitat_map_service.dart';
import 'package:wildtrack_mvp/services/radar_map_service.dart';

void main() {
  final now = DateTime.utc(2026,10,5,12);
  const center = LatLng(46,13);
  final ring = [center,const LatLng(46,13.01),const LatLng(46.01,13.01),const LatLng(46.01,13),center];
  final forest = HabitatPatch('wood','forest','Bosco',ring,[]);
  test('Only recent public observations with valid coordinates enter the amber layer', () {
    Map<String,dynamic> row(String id, {double lat=46,String? at,String? group}) => {'id':id,'species':'Capriolo','lat':lat,'lng':13,'observedAt':at??now.toIso8601String(),'groupId':group};
    final rows = [row('recent'), row('old',at:now.subtract(const Duration(days:8)).toIso8601String()), row('future',at:now.add(const Duration(hours:1)).toIso8601String()),row('private',group:'group'),row('far',lat:47),row('invalid',lat:double.nan)];
    expect(RadarMapService.observations(rows,center,5,now).map((r)=>r['id']),['recent']);
    expect(RadarMapService.observations(rows,center,5,now,species:'Cervo'),isEmpty);
  });
  test('Habitat suggestions do not invent sightings or localised range evidence', () {
    final suggestions = RadarMapService.possible([forest],[],now);
    expect(suggestions.any((s)=>s.name=='Capriolo'),true);
    expect(suggestions.any((s)=>s.name=='Lince'||s.name=='Orso bruno'),false);
    expect(suggestions.every((s)=>s.recentCount==0),true);
    final observed = [{'species':'Lince','lat':46.005,'lng':13.005}];
    expect(RadarMapService.possible([forest],observed,now).firstWhere((s)=>s.name=='Lince').recentCount,1);
  });
  test('Seasonal and habitat filtering survives species search', () {
    expect(RadarMapService.possible([forest],[{'species':'Capriolo','lat':46.005,'lng':13.005}],now,species:'Capriolo').single.name,'Capriolo');
    expect(RadarMapService.possible([forest],[],now,species:'Upupa'),isEmpty);
    expect(RadarMapService.possible([],[],now),isEmpty);
  });
  test('Species labels are separated at map scale while habitat polygons remain available', () {
    final duplicate=HabitatPatch('duplicate','forest','Bosco',ring,[]);
    expect(RadarMapService.labelPatches([forest,duplicate],center,12),hasLength(1));
  });
  test('Deer is not a generic forest suggestion and nearby reports do not colour distant woods', () {
    expect(RadarMapService.possible([forest],[],now,species:'Cervo'),isEmpty);
    final rows = [{'species':'Cervo','lat':46.005,'lng':13.005}];
    expect(RadarMapService.possible([forest],rows,now,species:'Cervo'),hasLength(1));
    expect(RadarMapService.possible([forest],[{'species':'Cervo','lat':46.1,'lng':13}],now,species:'Cervo'),isEmpty);
  });
  test('Urban masks remove enclosed parks, edge overlaps and crossing strips, preserving rural habitats', () {
    Map<String,dynamic> area(int id, String kind, double south, double west, double north, double east) => {'type':'way','id':id,'tags':{'landuse':kind},'geometry':[for(final p in [LatLng(south,west),LatLng(south,east),LatLng(north,east),LatLng(north,west),LatLng(south,west)]) {'lat':p.latitude,'lon':p.longitude}]};
    final town=area(1,'residential',46,13,46.01,13.01);
    final data={'elements':[town,area(2,'forest',46.002,13.002,46.004,13.004),area(3,'meadow',46.009,13.009,46.012,13.012),area(4,'forest',46.003,12.99,46.004,13.02),area(5,'forest',46.03,13.03,46.04,13.04)]};
    final patches=HabitatMapService.instance.parse(data,'__radar__');
    expect(patches,hasLength(4));
    expect(patches.first.urbanCore,true);
    expect(patches.last.urban,false);
    expect(HabitatMapService.instance.parse(data,'Capriolo').map((p)=>p.id),['way-3-0','way-4-0','way-5-0']);
    expect(HabitatMapService.instance.query('__radar__',center),contains('[landuse=residential]'));
  });
  test('Multipolygon urban masks exclude green enclaves even when mapped as inner landuse holes', () {
    final urban={'type':'relation','id':1,'tags':{'type':'multipolygon','landuse':'residential'},'members':[{'type':'way','role':'outer','geometry':[for(final p in ring) {'lat':p.latitude,'lon':p.longitude}]}]};
    final wood={'type':'way','id':2,'tags':{'natural':'wood'},'geometry':[for(final p in [const LatLng(46.002,13.002),const LatLng(46.002,13.004),const LatLng(46.004,13.004),const LatLng(46.004,13.002),const LatLng(46.002,13.002)]) {'lat':p.latitude,'lon':p.longitude}]};
    final patches=HabitatMapService.instance.parse({'elements':[urban,wood]},'__radar__');
    expect(patches.single.urbanCore,true);
    expect(RadarMapService.possible(patches,[],now).any((s)=>s.name=='Allocco'),true);
    expect(RadarMapService.possible(patches,[],now).any((s)=>s.name=='Cervo'||s.name=='Capriolo'),false);
  });
  test('Rounded display ring closes, keeps source intact and bounds corner displacement', () {
    final original = List<LatLng>.from(ring);
    final softened = RadarMapService.softRing(ring);
    expect(softened.first,softened.last);
    expect(softened.length,greaterThan(ring.length));
    expect(ring,original);
    for(final p in softened) {
      expect(original.any((corner)=>RadarMapService.distance.as(LengthUnit.Meter,p,corner)<=46),true);
    }
  });
  test('Route intersection handles sparse crossings and never bridges GPX segments', () {
    expect(RadarMapService.onRoute(forest,[[const LatLng(46.005,12.99),const LatLng(46.005,13.02)]]),true);
    expect(RadarMapService.onRoute(forest,[[const LatLng(46.005,12.99)],[const LatLng(46.005,13.02)]]),false);
    final withHole = HabitatPatch('hole','forest','Bosco',ring,[[const LatLng(46.002,13.002),const LatLng(46.002,13.008),const LatLng(46.008,13.008),const LatLng(46.008,13.002),const LatLng(46.002,13.002)]]);
    expect(RadarMapService.onRoute(withHole,[[const LatLng(46.005,13.005)]]),false);
  });
  test('Radar query includes all habitat types and validates incomplete OSM responses', () {
    final service = HabitatMapService.instance;
    final query = service.query('__radar__',center,radiusKm:10);
    expect(query,contains('natural=wood'));
    expect(query,contains('natural=wetland'));
    expect(()=>service.parse({'elements':[],'remark':'timeout'},'__radar__'),throwsFormatException);
  });
}
