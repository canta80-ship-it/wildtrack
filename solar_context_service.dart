import 'dart:math' as math;

/// Solar position approximation (equation of time and declination).
/// Uses the instant in UTC and longitude, independent of device time zone.
class SolarContext {
  const SolarContext(this.phase, this.elevation, this.sunrise, this.sunset);
  final String phase;
  final double elevation;
  final DateTime? sunrise, sunset;
  bool get dark => elevation < -6;
  bool get twilight => elevation >= -6 && elevation < 6;
  String get label => switch (phase) {
    'dawn' => 'Alba e crepuscolo', 'dusk' => 'Tramonto e crepuscolo',
    'night' => 'Notte · poca luce', 'day' => 'Giorno', _ => 'Fase solare non disponibile',
  };
  static SolarContext at(DateTime instant, double latitude, double longitude) {
    final utc = instant.toUtc();
    final day = utc.difference(DateTime.utc(utc.year, 1, 1)).inDays + 1;
    final hour = utc.hour + utc.minute / 60 + utc.second / 3600;
    final gamma = 2 * math.pi / 365 * (day - 1 + (hour - 12) / 24);
    final eq = 229.18 * (.000075 + .001868 * math.cos(gamma) - .032077 * math.sin(gamma) - .014615 * math.cos(2 * gamma) - .040849 * math.sin(2 * gamma));
    final dec = .006918 - .399912 * math.cos(gamma) + .070257 * math.sin(gamma) - .006758 * math.cos(2 * gamma) + .000907 * math.sin(2 * gamma) - .002697 * math.cos(3 * gamma) + .00148 * math.sin(3 * gamma);
    final solarMinute = (hour * 60 + eq + longitude * 4) % 1440;
    final ha = (solarMinute / 4 - 180) * math.pi / 180;
    final lat = latitude * math.pi / 180;
    final cosZen = (math.sin(lat) * math.sin(dec) + math.cos(lat) * math.cos(dec) * math.cos(ha)).clamp(-1.0, 1.0);
    final elev = 90 - math.acos(cosZen) * 180 / math.pi;
    final c = (math.cos(90.833 * math.pi / 180) / (math.cos(lat) * math.cos(dec)) - math.tan(lat) * math.tan(dec));
    DateTime? rise, set;
    if (c >= -1 && c <= 1) {
      final halfDay = math.acos(c) * 180 / math.pi * 4;
      final noon = 720 - longitude * 4 - eq;
      final base = DateTime.utc(utc.year, utc.month, utc.day);
      rise = base.add(Duration(seconds: ((noon - halfDay) * 60).round())).toLocal();
      set = base.add(Duration(seconds: ((noon + halfDay) * 60).round())).toLocal();
    }
    final phase = elev < -6 ? 'night' : elev < 6 ? (solarMinute < 720 ? 'dawn' : 'dusk') : 'day';
    return SolarContext(phase, elev, rise, set);
  }
  static String clock(DateTime? t) => t == null ? '—' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
