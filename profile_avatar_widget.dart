import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../premium_ui.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.url, this.base64, this.radius = 21});
  final String? url, base64;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.person_outline, color: WildColors.forest, size: radius);
    Widget child = fallback;
    if (base64 != null && base64!.isNotEmpty) {
      try {child = Image.memory(base64Decode(base64!), width: radius*2, height: radius*2, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);} catch (_) {}
    } else if (url != null && url!.startsWith('/api/avatar?')) {
      child = Image.network('$communityUrl$url', width: radius*2, height: radius*2, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    }
    return SizedBox(width: radius*2, height: radius*2, child: ClipOval(child: ColoredBox(color: WildColors.sage, child: Center(child: child))));
  }
}
