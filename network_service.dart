import 'dart:async';
import 'dart:convert';
import 'dart:io';

class JsonNetwork {
  static final _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 20)
    ..maxConnectionsPerHost = 4;

  static Future<Map<String, dynamic>> request(
    Uri uri, {
    String method = 'GET',
    Map<String, String> headers = const {},
    Object? body,
    bool form = false,
    Duration timeout = const Duration(seconds: 40),
    int maxBytes = 8 * 1024 * 1024,
  }) async {
    if (uri.scheme != 'https') throw ArgumentError('È richiesta HTTPS');
    HttpClientRequest? request;
    var active = true;
    final operation = () async {
      request = await _client.openUrl(method, uri);
      final req = request!;
      if (!active) {
        req.abort();
        throw TimeoutException('Richiesta scaduta');
      }
      req.followRedirects = false;
      headers.forEach(req.headers.set);
      req.headers.set('Accept', 'application/json');
      if (body != null) {
        req.headers.contentType = form
            ? ContentType('application', 'x-www-form-urlencoded')
            : ContentType.json;
        req.write(form ? body : jsonEncode(body));
      }
      final response = await req.close();
      final bytes = <int>[];
      await for (final chunk in response) {
        if (bytes.length + chunk.length > maxBytes) {
          throw const FormatException('Risposta troppo grande');
        }
        bytes.addAll(chunk);
      }
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Risposta del servizio non valida');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          value['error'] is String
              ? value['error'] as String
              : 'Servizio non disponibile',
        );
      }
      return value;
    }();
    try {
      return await operation.timeout(timeout);
    } finally {
      active = false;
      request?.abort();
    }
  }
}

bool validCoordinates(Object? lat, Object? lng) =>
    lat is num &&
    lng is num &&
    lat.isFinite &&
    lng.isFinite &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180;

List<Map<String, dynamic>> records(Object? value, String kind) {
  if (value is! List) throw const FormatException('Elenco non valido');
  return value.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).where((
    x,
  ) {
    bool text(String key) => x[key] is String;
    switch (kind) {
      case 'sightings':
        return text('id') &&
            text('species') &&
            x['count'] is num &&
            validCoordinates(x['lat'], x['lng']) &&
            (x['notes'] == null || text('notes')) &&
            (x['photo'] == null ||
                x['photo'] is String ||
                x['photo'] is num ||
                x['photo'] is bool) &&
            (x['groupId'] == null || text('groupId')) &&
            (x['groupName'] == null || text('groupName'));
      case 'community':
        return text('id') &&
            text('nickname') &&
            x['updated'] is num &&
            validCoordinates(x['lat'], x['lng']);
      case 'messages':
        return text('sender') &&
            text('recipient') &&
            text('body') &&
            text('senderName') &&
            text('recipientName');
      case 'maps':
        return text('id') && text('name');
      case 'members':
        return text('id') && text('mapId') && text('nickname');
      case 'nature':
        final url = Uri.tryParse('${x['url']}');
        return validCoordinates(x['lat'], x['lng']) &&
            (x['name'] == null || text('name')) &&
            url != null &&
            url.scheme == 'https' &&
            (url.host == 'www.gbif.org' || url.host == 'gbif.org');
      default:
        return true;
    }
  }).toList();
}
