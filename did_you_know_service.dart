import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

class DidYouKnowItem {
  const DidYouKnowItem({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.asset,
    required this.source,
    required this.publishedAt,
    this.link,
    this.isLive = false,
  });

  final String id;
  final String category;
  final String title;
  final String body;
  final String asset;
  final String source;
  final DateTime publishedAt;
  final String? link;
  final bool isLive;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'body': body,
    'asset': asset,
    'source': source,
    'publishedAt': publishedAt.toIso8601String(),
    'link': link,
    'isLive': isLive,
  };

  factory DidYouKnowItem.fromJson(Map<String, dynamic> json) => DidYouKnowItem(
    id: '${json['id'] ?? ''}',
    category: '${json['category'] ?? 'NATURA'}',
    title: '${json['title'] ?? ''}',
    body: '${json['body'] ?? ''}',
    asset: '${json['asset'] ?? 'intro_cervo.jpg'}',
    source: '${json['source'] ?? 'WildTrack'}',
    publishedAt:
        DateTime.tryParse('${json['publishedAt'] ?? ''}') ?? DateTime.now(),
    link: json['link'] as String?,
    isLive: json['isLive'] == true,
  );
}

class DidYouKnowFeed {
  const DidYouKnowFeed({
    required this.items,
    required this.updatedAt,
    required this.fromCache,
  });
  final List<DidYouKnowItem> items;
  final DateTime updatedAt;
  final bool fromCache;
}

class DidYouKnowService {
  static final instance = DidYouKnowService();
  File? _cacheFile;
  static const Duration refreshInterval = Duration(hours: 4);

  Future<File> get _file async {
    if (_cacheFile != null) return _cacheFile!;
    _cacheFile = File('${await getDatabasesPath()}/wildtrack_sapevi_che.json');
    return _cacheFile!;
  }

  Future<DidYouKnowFeed> load({bool force = false}) async {
    final cached = await _readCache();
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.updatedAt) < refreshInterval) {
      return cached;
    }

    final remote = <DidYouKnowItem>[];
    final batches = await Future.wait<List<DidYouKnowItem>>([
      _mountainBlog().catchError((_) => const <DidYouKnowItem>[]),
      _parksNews().catchError((_) => const <DidYouKnowItem>[]),
    ]);
    for (final batch in batches) {
      remote.addAll(batch);
    }

    final merged = _dedupeAndRank([...remote, ..._evergreen()]);

    if (remote.isNotEmpty) {
      final feed = DidYouKnowFeed(
        items: merged.take(18).toList(),
        updatedAt: DateTime.now(),
        fromCache: false,
      );
      await _writeCache(feed);
      return feed;
    }

    if (cached != null) return cached;
    return DidYouKnowFeed(
      items: _dedupeAndRank(_evergreen()).take(12).toList(),
      updatedAt: DateTime.now(),
      fromCache: true,
    );
  }

  Future<DidYouKnowFeed?> _readCache() async {
    try {
      final data = jsonDecode(
        await (await _file).readAsString(),
      ) as Map<String, dynamic>;
      final items = (data['items'] as List? ?? const [])
          .map(
            (e) => DidYouKnowItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .where((e) => e.title.isNotEmpty)
          .toList();
      if (items.isEmpty) return null;
      return DidYouKnowFeed(
        items: items,
        updatedAt:
            DateTime.tryParse('${data['updatedAt'] ?? ''}') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        fromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(DidYouKnowFeed feed) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'updatedAt': feed.updatedAt.toIso8601String(),
        'items': feed.items.map((e) => e.toJson()).toList(),
      }),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  Future<List<DidYouKnowItem>> _mountainBlog() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final uri = Uri.parse(
        'https://www.mountainblog.it/wp-json/wp/v2/posts?per_page=10&_fields=id,date,link,title,excerpt,categories',
      );
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];
      final rows = jsonDecode(await res.transform(utf8.decoder).join()) as List;
      return rows
          .map((raw) {
            final row = Map<String, dynamic>.from(raw as Map);
            final title = _stripHtml(
              '${(row['title'] as Map?)?['rendered'] ?? ''}',
            );
            final excerpt = _stripHtml(
              '${(row['excerpt'] as Map?)?['rendered'] ?? ''}',
            );
            final date =
                DateTime.tryParse('${row['date'] ?? ''}') ?? DateTime.now();
            return DidYouKnowItem(
              id: 'mountainblog-${row['id']}',
              category: _categoryFor('$title $excerpt'),
              title: title,
              body: excerpt,
              asset: _assetFor('$title $excerpt'),
              source: 'MountainBlog',
              publishedAt: date,
              link: '${row['link'] ?? ''}',
              isLive: true,
            );
          })
          .where((e) => e.title.isNotEmpty)
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  Future<List<DidYouKnowItem>> _parksNews() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final uri = Uri.parse('https://www.parks.it/news/index.php');
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];
      final html = await res.transform(utf8.decoder).join();
      final links = RegExp(
        r'href="([^"]*news/dettaglio\.php\?id=\d+[^"]*)"[^>]*>(.*?)</a>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(html);
      final result = <DidYouKnowItem>[];
      for (final match in links) {
        final title = _stripHtml(match.group(2) ?? '');
        if (title.length < 8) continue;
        final rawLink = match.group(1) ?? '';
        final link = rawLink.startsWith('http')
            ? rawLink
            : 'https://www.parks.it/${rawLink.startsWith('/') ? rawLink.substring(1) : rawLink}';
        result.add(
          DidYouKnowItem(
            id: 'parks-${link.hashCode}',
            category: _categoryFor(title),
            title: title,
            body: 'Novità da parchi e aree protette italiane. Apri la scheda per dettagli, date e informazioni aggiornate.',
            asset: _assetFor(title),
            source: 'Parks.it',
            publishedAt: DateTime.now(),
            link: link,
            isLive: true,
          ),
        );
        if (result.length >= 8) break;
      }
      return result;
    } finally {
      client.close(force: true);
    }
  }

  List<DidYouKnowItem> _dedupeAndRank(List<DidYouKnowItem> input) {
    final seen = <String>{};
    final rows = <DidYouKnowItem>[];
    for (final item in input) {
      final key = item.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), ' ')
          .trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      rows.add(item);
    }
    rows.sort((a, b) {
      if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    final month = DateTime.now().month;
    final seasonal = rows
        .where((e) => !e.isLive && e.id.contains('-m$month-'))
        .toList();
    final normal = rows.where((e) => !seasonal.contains(e)).toList();
    return [...seasonal, ...normal];
  }

  List<DidYouKnowItem> _evergreen() {
    final now = DateTime.now();
    final month = now.month;
    DidYouKnowItem item(
      String id,
      String category,
      String title,
      String body,
      String asset, {
      bool seasonal = false,
    }) => DidYouKnowItem(
      id: seasonal ? '$id-m$month-' : id,
      category: category,
      title: title,
      body: body,
      asset: asset,
      source: 'WildTrack',
      publishedAt: DateTime(now.year, month, 1),
    );
    final rows = <DidYouKnowItem>[
      item(
        'deer-rut',
        'FAUNA',
        'Il bramito non è solo un richiamo',
        'Nel cervo il bramito segnala presenza e forza agli altri maschi. Intensità e calendario cambiano con quota, clima e popolazione.',
        'intro_cervo.jpg',
        seasonal: month == 9 || month == 10,
      ),
      item(
        'tracks',
        'FAUNA',
        'Le tracce raccontano più dell’animale',
        'Impronte, fatte, peli, penne e sfregamenti possono rivelare passaggi e comportamento senza obbligarti ad avvicinare la fauna.',
        'intro_lupo.jpg',
      ),
      item(
        'shutter',
        'FOTOGRAFIA',
        'Meglio un tempo rapido che una foto mossa',
        'Con fauna in movimento e focali lunghe, 1/1000–1/2000 s è spesso più utile di un ISO bassissimo. Il rumore si gestisce; il mosso molto meno.',
        'intro_gufo.jpg',
      ),
      item(
        'eye-level',
        'FOTOGRAFIA',
        'Abbassare il punto di ripresa cambia tutto',
        'Fotografare vicino all’altezza degli occhi del soggetto migliora separazione dallo sfondo e coinvolgimento, senza editing pesante.',
        'intro_marmotta.jpg',
      ),
      item(
        'binoculars',
        'ATTREZZATURA',
        'Il binocolo completa il teleobiettivo',
        'Per osservazione naturalistica 8×42 e 10×42 sono formati molto versatili: campo visivo, luminosità e peso restano ben bilanciati.',
        'intro_cervo.jpg',
      ),
      item(
        'cold-battery',
        'ATTREZZATURA',
        'Il freddo riduce l’autonomia',
        'In inverno una batteria di scorta tenuta vicino al corpo mantiene meglio la capacità disponibile rispetto a una lasciata nello zaino esterno.',
        'intro_marmotta.jpg',
        seasonal: {11, 12, 1, 2, 3}.contains(month),
      ),
      item(
        'sunset',
        'MONTAGNA',
        'In valle la luce può sparire prima del tramonto',
        'Pareti e rilievi possono togliere luce molto prima dell’orario astronomico. Il rientro va pianificato sul terreno reale, non solo sull’orologio.',
        'intro_marmotta.jpg',
      ),
      item(
        'layers',
        'OUTDOOR',
        'Durante l’appostamento ci si raffredda molto',
        'Camminando produci calore, fermo no. Uno strato caldo rapidamente accessibile evita movimenti inutili proprio quando la fauna si avvicina.',
        'intro_cervo.jpg',
      ),
    ];
    return rows;
  }

  String _stripHtml(String input) {
    var text = input.replaceAll(RegExp(r'<[^>]+>', multiLine: true), ' ');
    const entities = {
      '&nbsp;': ' ',
      '&amp;': '&',
      '&quot;': '"',
      '&#8217;': '’',
      '&#8211;': '–',
      '&#8230;': '…',
      '&lt;': '<',
      '&gt;': '>',
    };
    for (final e in entities.entries) {
      text = text.replaceAll(e.key, e.value);
    }
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _categoryFor(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'foto|fotograf|camera|obiettivo|sony|nikon|canon').hasMatch(t))
      return 'FOTOGRAFIA';
    if (RegExp(r'fiera|festival|evento|mostra|expo|raduno|convegno')
        .hasMatch(t))
      return 'EVENTI';
    if (RegExp(r'attrezz|zaino|scarpa|guscio|binocolo|gps|orologio')
        .hasMatch(t))
      return 'ATTREZZATURA';
    if (RegExp(r'trekking|sentiero|escursion|cammino|itinerario|trail')
        .hasMatch(t))
      return 'ESCURSIONI';
    if (RegExp(r'cervo|lupo|orso|fauna|uccell|rapace|animale|biodivers')
        .hasMatch(t))
      return 'FAUNA';
    if (RegExp(r'parco|riserva|dolomit|alpi|montagna|valle|bosco').hasMatch(t))
      return 'LUOGHI';
    return 'OUTDOOR';
  }

  String _assetFor(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'lupo|volpe|orso').hasMatch(t)) return 'intro_lupo.jpg';
    if (RegExp(r'gufo|rapace|uccell|aquila|poiana').hasMatch(t))
      return 'intro_gufo.jpg';
    if (RegExp(r'marmotta|stambecco|camoscio|montagna|alpi|dolomit')
        .hasMatch(t))
      return 'intro_marmotta.jpg';
    return 'intro_cervo.jpg';
  }
}
