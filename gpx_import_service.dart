import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/track_point.dart';
import '../models/track_session.dart';
import 'database_service.dart';
import 'file_import_service.dart';

class GpxImport {
  const GpxImport(this.session, this.points);
  final TrackSession session;
  final List<TrackPoint> points;
}
class GpxImportService {
  static GpxImport parse(String xml, String filename) {
    if (xml.contains('<!DOCTYPE') || xml.contains('<!ENTITY')) throw const FormatException('GPX non valido');
    final doc = XmlDocument.parse(xml);
    if (doc.rootElement.name.local != 'gpx') throw const FormatException('Seleziona un file GPX');
    String text(XmlElement element, String key) => element.childElements.where((e) => e.name.local == key).map((e) => e.innerText.trim()).firstOrNull ?? '';
    final groups = doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'trkseg' || e.name.local == 'rte').toList();
    final points = <TrackPoint>[];
    final times = <DateTime>[];
    double distance = 0, ascent = 0, descent = 0;
    final origin = DateTime.now();
    for (var segment = 0; segment < groups.length; segment++) {
      LatLng? previous; double? previousAltitude;
      for (final node in groups[segment].childElements.where((e) => e.name.local == 'trkpt' || e.name.local == 'rtept')) {
        if (points.length >= 50000) throw const FormatException('GPX troppo lungo: massimo 50.000 punti');
        final lat = double.tryParse(node.getAttribute('lat') ?? ''), lng = double.tryParse(node.getAttribute('lon') ?? '');
        if (lat == null || lng == null || !lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) throw const FormatException('Coordinate GPX non valide');
        final elevation = double.tryParse(text(node, 'ele'));
        if (elevation != null && !elevation.isFinite) throw const FormatException('Quota GPX non valida');
        final current = LatLng(lat, lng);
        if (previous != null) distance += const Distance().as(LengthUnit.Meter, previous, current);
        if (elevation != null && previousAltitude != null) {
          final change = elevation - previousAltitude;
          if (change > 0) ascent += change; else descent -= change;
        }
        final time = DateTime.tryParse(text(node, 'time'));
        if (time != null) times.add(time);
        // Preserve source point order even when GPX times are absent or repeated.
        points.add(TrackPoint(latitude: lat, longitude: lng, altitude: elevation ?? 0, segment: segment, timestamp: origin.add(Duration(microseconds: points.length))));
        previous = current; previousAltitude = elevation;
      }
    }
    if (points.length < 2) throw const FormatException('Il GPX deve contenere almeno due punti di traccia o percorso');
    final info = doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'trk' || e.name.local == 'rte').firstOrNull;
    final name = info == null ? '' : text(info, 'name');
    final description = info == null ? '' : text(info, 'desc');
    final orderedTimes = times.length == points.length && times.asMap().entries.every((e) => e.key == 0 || !e.value.isBefore(times[e.key - 1]));
    final start = orderedTimes ? times.first : origin, end = orderedTimes ? times.last : origin;
    return GpxImport(TrackSession(id: const Uuid().v4(), name: name.isEmpty ? filename.replaceFirst(RegExp(r'\.gpx$', caseSensitive: false), '') : name, notes: description, imported: true, startedAt: start, endedAt: end, distanceMeters: distance, ascentMeters: ascent, descentMeters: descent), points);
  }
  static Future<TrackSession?> pickAndImport() async {
    final file = await PickedWildFile.pick();
    if (file == null) return null;
    final parsed = parse(utf8.decode(file.bytes), file.name);
    await DatabaseService.instance.saveSession(parsed.session, parsed.points);
    return parsed.session;
  }
}
