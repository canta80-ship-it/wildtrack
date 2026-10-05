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
    final observed = [{'species':'Lince'}];
    expect(RadarMapService.possible([forest],observed,now).firstWhere((s)=>s.name=='Lince').recentCount,1);
  });
  test('Seasonal and habitat filtering survives species search', () {
    expect(RadarMapService.possible([forest],[],now,species:'Capriolo').single.name,'Capriolo');
    expect(RadarMapService.possible([forest],[],now,species:'Upupa'),isEmpty);
    expect(RadarMapService.possible([],[],now),isEmpty);
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
