import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../premium_ui.dart';

Marker premiumPositionMarker(LatLng point) => Marker(point: point, width: 46, height: 46, child: Semantics(label: 'La tua posizione', child: Container(key: const ValueKey('live-position-marker'), padding: const EdgeInsets.all(9), decoration: BoxDecoration(shape: BoxShape.circle, color: WildColors.forest.withValues(alpha: .18)), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: WildColors.forest, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Color(0x50000000), blurRadius: 5)])))));
