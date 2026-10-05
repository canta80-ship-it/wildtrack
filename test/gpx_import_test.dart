import 'package:flutter_test/flutter_test.dart';
import '../lib/services/gpx_import_service.dart';
void main(){
 test('Reads namespace, labels and disconnected segments',(){
 final r=GpxImportService.parse('<gpx xmlns="http://www.topografix.com/GPX/1/1"><trk><name>Il mio percorso</name><desc>Descrizione</desc><trkseg><trkpt lat="46" lon="13"><ele>100</ele></trkpt><trkpt lat="46.001" lon="13"><ele>110</ele></trkpt></trkseg><trkseg><trkpt lat="47" lon="14"><ele>1000</ele></trkpt><trkpt lat="47.001" lon="14"><ele>1005</ele></trkpt></trkseg></trk></gpx>','route.gpx');
 expect(r.session.name,'Il mio percorso');expect(r.session.notes,'Descrizione');expect(r.session.imported,true);expect(r.points.length,4);expect(r.points.last.segment,1);expect(r.session.distanceMeters,inExclusiveRange(200,240));expect(r.session.ascentMeters,15);expect(r.session.duration,Duration.zero);
 });
 test('Rejects invalid and empty GPX',(){
 expect(()=>GpxImportService.parse('<gpx><rte><rtept lat="91" lon="13"/><rtept lat="46" lon="13"/></rte></gpx>','x.gpx'),throwsFormatException);
 expect(()=>GpxImportService.parse('<gpx/>','x.gpx'),throwsFormatException);
 });
 test('Reads GPX time span and rejects external entities',(){
 final r=GpxImportService.parse('<gpx><rte><rtept lat="46" lon="13"><time>2026-10-01T10:00:00Z</time></rtept><rtept lat="46.001" lon="13"><time>2026-10-01T11:00:00Z</time></rtept></rte></gpx>','x.gpx');expect(r.session.duration,const Duration(hours:1));
 expect(()=>GpxImportService.parse('<!DOCTYPE gpx><gpx/>','x.gpx'),throwsFormatException);
 });
}
