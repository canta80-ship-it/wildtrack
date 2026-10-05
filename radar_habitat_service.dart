import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Only features containing the GPS point or within its immediate surroundings.
class RadarHabitatService {
  static const radius = 300.0;
  static const reuseDistance = 100.0;
  static const distance = Distance();
  static String query(Position p) => '[out:json][timeout:6];is_in(${p.latitude},${p.longitude})->.here;(area.here[natural];area.here[landuse];area.here[leisure=park];nwr(around:300,${p.latitude},${p.longitude})[natural];nwr(around:300,${p.latitude},${p.longitude})[landuse];nwr(around:300,${p.latitude},${p.longitude})[leisure=park];nwr(around:300,${p.latitude},${p.longitude})[waterway~"^(river|stream|canal)\$"];);out geom;';

  static Set<String> tags(Map<String,dynamic> data, Position p) {
    if(data['remark'] != null) return {};
    final result=<String>{};
    for(final raw in data['elements'] as List? ?? const []) {
      if(raw is! Map)continue;
      final e=Map<String,dynamic>.from(raw);
      if(!_local(e,p))continue;
      final t=e['tags'] as Map? ?? const {}, n=t['natural'], l=t['landuse'];
      if(n=='wood'||l=='forest')result.add('forest');
      if(['grassland','heath'].contains(n)||['meadow','grass','pasture'].contains(l))result.add('meadow');
      if(n=='scrub')result.add('scrub');
      if(n=='wetland')result.add('wetland');
      if(n=='water'||l=='reservoir'){result.add('water');if(t['water']!='river'&&t['water']!='stream')result.add('stillwater');}
      if(['river','stream','canal'].contains(t['waterway'])) { result.add('water'); if(t['waterway']!='canal')result.add(t['waterway'] as String); }
      if(['bare_rock','scree','cliff'].contains(n))result.add('rock');
      if(['farmland','orchard','vineyard'].contains(l))result.add('farmland');
      if(['residential','commercial','industrial'].contains(l))result.add('urban');
      if(t['leisure']=='park')result.add('park');
    }
    return result;
  }
  static List<(double,double)> _geometry(dynamic raw, Position p) {
    final out=<(double,double)>[];
    for(final node in raw is List ? raw : const []) {
      if(node is! Map || node['lat'] is! num || node['lon'] is! num)continue;
      final lat=(node['lat'] as num).toDouble(),lon=(node['lon'] as num).toDouble();
      if(!lat.isFinite||!lon.isFinite||lat.abs()>90||lon.abs()>180)continue;
      var dl=lon-p.longitude;if(dl>180)dl-=360;if(dl< -180)dl+=360;
      out.add((dl*111320*math.cos(p.latitude*math.pi/180),(lat-p.latitude)*111320));
    }
    return out;
  }
  static bool _inside(List<(double,double)> points) {
    if(points.length<4 || points.first!=points.last)return false;
    var inside=false;
    for(var i=0,j=points.length-1;i<points.length;j=i++) {
      final a=points[i],b=points[j];
      if((a.$2>0)!=(b.$2>0) && 0<(b.$1-a.$1)*(-a.$2)/(b.$2-a.$2)+a.$1)inside=!inside;
    }
    return inside;
  }
  static bool _near(List<(double,double)> points) {
    for(var i=0;i<points.length;i++) {
      final a=points[i];if(math.sqrt(a.$1*a.$1+a.$2*a.$2)<=radius)return true;
      if(i==0)continue;final b=points[i-1],dx=b.$1-a.$1,dy=b.$2-a.$2,length=dx*dx+dy*dy;
      if(length==0)continue;
      final t=(-(a.$1*dx+a.$2*dy)/length).clamp(0.0,1.0);
      final x=a.$1+t*dx,y=a.$2+t*dy;
      if(math.sqrt(x*x+y*y)<=radius)return true;
    }
    return false;
  }
  static bool _local(Map<String,dynamic> e, Position p) {
    // Derived areas are returned exclusively by is_in(GPS), not by around.
    if(e['type']=='area')return true;
    if(e['type']=='node')return _near(_geometry([e],p));
    if(e['type']=='way') {final g=_geometry(e['geometry'],p);return _inside(g)||_near(g);}
    if(e['type']=='relation') {
      var outer=false,inner=false,near=false;
      for(final m in e['members'] as List? ?? const []) {
        if(m is! Map)continue;
        final g=_geometry(m['geometry'],p);near=near||_near(g);
        if(m['role']=='inner')inner=inner||_inside(g);else outer=outer||_inside(g);
      }
      return (outer&&!inner)||near;
    }
    return false;
  }
}
