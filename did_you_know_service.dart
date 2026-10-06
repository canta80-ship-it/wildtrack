import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';

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
        DateTime.tryParse('${json['publishedAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0),
    link: json['link'] as String?,
    isLive: json['isLive'] == true,
  );
}

class DidYouKnowFeed {
  const DidYouKnowFeed({
    required this.items,
    required this.updatedAt,
    required this.fromCache,
    this.warning,
  });
  final List<DidYouKnowItem> items;
  final DateTime updatedAt;
  final bool fromCache;
  final String? warning;
}

class DidYouKnowService {
  DidYouKnowService({File? cacheFile, Future<List<DidYouKnowItem>> Function()? newsLoader, DateTime Function()? clock}) : _cacheFile = cacheFile, _newsLoader = newsLoader, _clock = clock ?? DateTime.now;
  final Future<List<DidYouKnowItem>> Function()? _newsLoader;
  final DateTime Function() _clock;
  static final instance = DidYouKnowService();
  File? _cacheFile;
  static const Duration refreshInterval = Duration(hours: 1);

  /// Bundled editorial cards remain available even with an older cached feed.
  static List<DidYouKnowItem> ferrataCards() {
    final reviewed = DateTime(2026, 10, 2);
    DidYouKnowItem card(String id, String title, String body, String source, String link) => DidYouKnowItem(
      id: 'ferrata-$id', category: 'FERRATE', title: title, body: body,
      asset: 'intro_marmotta.jpg', source: source, publishedAt: reviewed, link: link,
    );
    return [
      card('contin', 'Contin · Monte Cavallo', 'Friuli Venezia Giulia · Udine · moderatamente difficile. Dalle vicinanze del Passo di Pramollo al Monte Cavallo, in ambiente delle Alpi Carniche. La relazione descrive due rientri ad anello. Apri Ferrate365 per relazione, meteo e stato del percorso.', 'Ferrate365', 'https://www.ferrate365.it/vie-ferrate/ferrata-contin-monte-cavallo/'),
      card('biondi', 'Biondi · Val Rosandra', 'Friuli Venezia Giulia · Trieste · moderatamente difficile. Percorso a bassa quota nella zona delle Rose d’Inverno, con traversi e brevi tratti verticali. Alcuni passaggi richiedono allenamento. Apri Ferrate365 per relazione, meteo e stato del percorso.', 'Ferrate365', 'https://www.ferrate365.it/vie-ferrate/ferrata-biondi-rose-d-inverno/'),
      card('zuc', 'Zuc della Guardia', 'Friuli Venezia Giulia · Udine · moderatamente difficile. Una breve via attrezzata nelle Alpi Carniche, con partenza dal Passo del Cason di Lanza e salita al torrione dello Zuc. Apri Ferrate365 per relazione, meteo e stato del percorso.', 'Ferrate365', 'https://www.ferrate365.it/vie-ferrate/ferrata-degli-alpini-zuc-guardia/'),
      card('gusela', 'Ra Gusela · Nuvolau', 'Veneto · Belluno · facile. Percorso sul versante meridionale del Nuvolau con partenza dal Passo Giau. La difficoltà della ferrata resta distinta dall’impegno di avvicinamento e rientro. Apri Ferrate365 per relazione, meteo e stato del percorso.', 'Ferrate365', 'https://www.ferrate365.it/vie-ferrate/ferrata-ra-gusela-nuvolau/'),
      card('averau', 'Averau · Dolomiti Ampezzane', 'Veneto · Belluno · moderatamente difficile. Breve salita attrezzata vicino al rifugio Averau: pochi passaggi più impegnativi interrompono i tratti più semplici. Accesso dai versanti Giau o Falzarego. Apri Ferrate365 per relazione, meteo e stato del percorso.', 'Ferrate365', 'https://www.ferrate365.it/vie-ferrate/ferrata-averau/'),
      card('fanes', 'Cascate di Fanes', 'Veneto · Belluno · facile. Cenge e passaggi vicino alle cascate del Rio Fanes. La relazione comprende Giovanni Barbara, Lucio Delaiti e Cengia di Mattia; attenzione ai tratti umidi. Apri Ferrate365 per relazione, meteo e stato del percorso.', 'Ferrate365', 'https://www.ferrate365.it/vie-ferrate/ferrata-giovanni-barbara-lucio-dalaiti-cengia-mattia-cascate-fanes/'),
      card('riosecco', 'Rio Secco · Cadino', 'Trentino · Trento · moderatamente difficile. Via attrezzata in una forra, con una successione varia di passaggi e alcuni tratti atletici. Il nome non garantisce l’assenza di acqua nel rio. Apri Ferrate365 per relazione, meteo e stato del percorso.', 'Ferrate365', 'https://www.ferrate365.it/vie-ferrate/ferrata-rio-secco-cadino/'),
      card('giovanelli', 'Burrone Giovanelli', 'Trentino · Mezzocorona · facile. Sentiero attrezzato in una forra, con alcuni passaggi esposti. Un itinerario a bassa quota che richiede comunque l’attrezzatura per ferrata. Apri Ferrate365 per relazione, meteo e stato del percorso.', 'Ferrate365', 'https://www.ferrate365.it/vie-ferrate/sentiero-attrezzato-burrone-giovanelli-mezzocorona/'),
      card('sallagoni', 'Rio Sallagoni · Drena',
        'Garda Trentino · difficoltà tecnica C; itinerario medio. 2,7 km · 2 h 30 min · +205 m, inclusi avvicinamento e rientro. Una gola con cascate e passaggi attrezzati. Apri la fonte per condizioni e percorribilità.',
        'Garda Trentino · Visit Trentino', 'https://www.visittrentino.info/it/guida/tour/via-ferrata-rio-sallagoni_tour_10449288'),
      card('colodri', 'Colodri–Colt · Arco',
        'Garda Trentino · difficoltà tecnica A/B; itinerario medio. 4 km · 2 h · +280 m, inclusi avvicinamento e rientro. Un percorso sopra Arco con vista sulla Valle del Sarca. Controlla meteo e avvisi nella fonte.',
        'Garda Trentino · Visit Trentino', 'https://www.visittrentino.info/it/guida/tour/via-ferrata-colodri-colt_tour_8279464'),
      card('tridentina', 'Tridentina · Pisciadú',
        'Colfosco, Gruppo del Sella · difficile. Itinerario: 4,4 km · 3 h 45 min · +704 m. Pareti verticali e ponte sospeso verso il rifugio Pisciadú; rientro per la Val Setus. Verifica condizioni e difficoltà nella fonte.',
        'Alta Badia', 'https://www.altabadia.org/it/dolomites/in-parete/dettaglio/oa/via-ferrata-brigata-alpina-tridentina-al-pisciadu'),
      card('preparazione', 'Ferrate: prima di partire',
        'Casco, imbragatura e set con dissipatore sono essenziali. Scegli una via adatta alla tua preparazione e controlla meteo, stato delle attrezzature e rientro. La scheda ufficiale spiega anche le precauzioni per la progressione.',
        'Garda Trentino · Visit Trentino', 'https://www.visittrentino.info/it/guida/tour/via-ferrata-colodri-colt_tour_8279464'),
    ];
  }

  static List<DidYouKnowItem> withFerrate(List<DidYouKnowItem> input, {int limit = 32}) {
    final cards = ferrataCards();
    final other = input.where((item) => !item.id.startsWith('ferrata-')).take(limit - cards.length).toList();
    final result = <DidYouKnowItem>[];
    for (var i = 0; i < other.length || i < cards.length; i++) {
      if (i < other.length) result.add(other[i]);
      if (i < cards.length) result.add(cards[i]);
    }
    return result;
  }

  Future<File> get _file async {
    if (_cacheFile != null) return _cacheFile!;
    _cacheFile = File('${await getDatabasesPath()}/wildtrack_sapevi_che.json');
    return _cacheFile!;
  }

  Future<DidYouKnowFeed> load({bool force = false}) async {
    final cached = await _readCache();
    if (!force &&
        cached != null &&
        _clock().difference(cached.updatedAt) >= Duration.zero &&
        _clock().difference(cached.updatedAt) < refreshInterval) {
      return DidYouKnowFeed(items: freshItems(cached.items), updatedAt: cached.updatedAt, fromCache: true);
    }

    final remote = <DidYouKnowItem>[];
    final batches = _newsLoader != null ? [await _newsLoader!().timeout(const Duration(seconds: 25)).catchError((_) => <DidYouKnowItem>[])] : await Future.wait<List<DidYouKnowItem>>([
      _mountainBlog().then((rows) => freshItems(rows).isEmpty ? _mountainRss() : Future.value(rows)).catchError((_) => _mountainRss().catchError((_) => const <DidYouKnowItem>[])),
      _parksNews().catchError((_) => const <DidYouKnowItem>[]),
    ]);
    for (final batch in batches) {
      remote.addAll(freshItems(batch));
    }

    final merged = _dedupeAndRank([...remote, ..._evergreen()]);

    if (remote.isNotEmpty) {
      final feed = DidYouKnowFeed(
        items: withFerrate(merged),
        updatedAt: _clock(),
        fromCache: false,
      );
      // A storage failure must not discard successfully fetched news.
      try { await _writeCache(feed); } catch (_) {}
      return feed;
    }

    if (cached != null) return DidYouKnowFeed(items: withFerrate(_dedupeAndRank(freshItems(cached.items))), updatedAt: cached.updatedAt, fromCache: true, warning: 'Fonti non raggiungibili. Ultimo aggiornamento disponibile: ${cached.updatedAt.toLocal()}.');
    return DidYouKnowFeed(
      items: withFerrate(_dedupeAndRank(_evergreen())),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      fromCache: true,
      warning: 'Notizie online non disponibili. Mostro le curiosità e le guide salvate.',
    );
  }

  static List<DidYouKnowItem> rotateGuides(List<DidYouKnowItem> items, int turn) {
    final news = items.where((item) => item.isLive).toList();
    final guides = items.where((item) => !item.isLive).toList();
    if (guides.isEmpty) return news;
    final offset = turn % guides.length;
    final rotated = [...guides.skip(offset), ...guides.take(offset)];
    final result = <DidYouKnowItem>[];
    for (var i = 0; i < news.length || i < rotated.length; i++) {
      if (i < news.length) result.add(news[i]);
      if (i < rotated.length) result.add(rotated[i]);
    }
    return result;
  }

  static List<DidYouKnowItem> freshItems(List<DidYouKnowItem> items, {DateTime? now}) {
    final time = now ?? DateTime.now();
    return items.where((e) => !e.isLive || (!e.publishedAt.isAfter(time.add(const Duration(minutes: 5))) && time.difference(e.publishedAt) <= const Duration(days: 30))).toList();
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
        items: withFerrate(items),
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

  Future<DidYouKnowFeed> loadEvents({bool force = false}) async {
    DidYouKnowFeed? general;
    final batches = await Future.wait<List<DidYouKnowItem>?>([
      load(force: force).then((feed) {
        general = feed;
        return feed.items;
      }),
      for (final term in ['festival montagna', 'mostra montagna', 'raduno alpinismo', 'evento trekking'])
        _mountainBlog(search: term).then<List<DidYouKnowItem>?>((rows) => rows)
            .catchError((_) => null),
    ]);
    final items = mountainEvents(_dedupeAndRank(freshItems([
      for (final batch in batches) ...?batch,
    ], now: _clock())));
    if (items.isEmpty && general?.warning != null &&
        batches.skip(1).every((batch) => batch == null)) {
      throw const HttpException('Fonti eventi non raggiungibili');
    }
    return DidYouKnowFeed(
      items: items,
      updatedAt: _clock(),
      fromCache: false,
    );
  }

  static List<DidYouKnowItem> mountainEvents(List<DidYouKnowItem> items) {
    final event = RegExp(r'\b(fier\w*|festival\w*|event\w*|mostr\w*|expo|radun\w*|convegn\w*|rassegn\w*|incontr\w*|proiezion\w*)\b');
    final mountain = RegExp(r'\b(montagn\w*|alpin\w*|alpi|dolomit\w*|prealp\w*|trekking|escursion\w*|arrampicat\w*|climbing|ferrat\w*|rifugi\w*|cai|soccorso alpino)\b');
    return items.where((item) {
      final text = '${item.title} ${item.body}'.toLowerCase();
      return item.isLive && event.hasMatch(text) && mountain.hasMatch(text);
    }).toList();
  }

  Future<List<DidYouKnowItem>> _mountainBlog({String? search}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final base = Uri.parse(
        'https://www.mountainblog.it/wp-json/wp/v2/posts?per_page=12&orderby=date&order=desc&_fields=id,date,date_gmt,link,title,excerpt,categories&_wt=${DateTime.now().millisecondsSinceEpoch}',
      );
      final uri = search == null ? base : base.replace(queryParameters: {
        ...base.queryParameters,
        'search': search,
        'per_page': '30',
        'after': _clock().toUtc().subtract(const Duration(days: 30)).toIso8601String(),
      });
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        if (search != null) throw HttpException('Fonte eventi: ${res.statusCode}');
        return const [];
      }
      final rows = jsonDecode(await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 10))) as List;
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
                DateTime.tryParse('${row['date_gmt'] ?? ''}Z') ?? DateTime.fromMillisecondsSinceEpoch(0);
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

  Future<List<DidYouKnowItem>> _mountainRss() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.getUrl(Uri.parse('https://www.mountainblog.it/feed/?wt=${DateTime.now().millisecondsSinceEpoch}'));
      req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7.19');
      req.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final xml = XmlDocument.parse(await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 10)));
      return xml.findAllElements('item').take(12).map((item) {
        String field(String key) => item.getElement(key)?.innerText ?? '';
        DateTime date;
        try { date = HttpDate.parse(field('pubDate')); } catch (_) { date = DateTime.fromMillisecondsSinceEpoch(0); }
        final title = _stripHtml(field('title'));
        final body = _stripHtml(field('description'));
        return DidYouKnowItem(id:'mountainblog-rss-${field('guid')}',category:_categoryFor(title),title:title,body:body,asset:_assetFor(title),source:'MountainBlog',publishedAt:date,link:field('link'),isLive:true);
      }).where((e) => e.title.isNotEmpty).toList();
    } finally { client.close(force:true); }
  }

  Future<List<DidYouKnowItem>> _parksNews() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final uri = Uri.parse('https://www.parks.it/news/index.php?wt=${DateTime.now().millisecondsSinceEpoch}');
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'WildTrack/0.7');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];
      final html = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      final links = RegExp(
        r'''href=["']([^"']*dettaglio\.php\?id=\d+[^"']*)["'][^>]*>(.*?)</a>''',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(html);
      final result = <DidYouKnowItem>[];
      for (final match in links) {
        final title = _stripHtml(match.group(2) ?? '');
        if (title.length < 8) continue;
        final rawLink = match.group(1) ?? '';
        final link = Uri.parse('https://www.parks.it/news/index.php').resolve(rawLink.replaceAll('&amp;', '&')).toString();
        final fragment = html.substring(match.end, (match.end + 1800).clamp(0, html.length).toInt());
        final date = parksDate(_stripHtml(fragment));
        if (date == null) continue;
        result.add(
          DidYouKnowItem(
            id: 'parks-${Uri.parse(link).queryParameters['id']}',
            category: _categoryFor(title),
            title: title,
            body: 'Novità da parchi e aree protette italiane. Apri la scheda per dettagli, date e informazioni aggiornate.',
            asset: _assetFor(title),
            source: 'Parks.it',
            publishedAt: date,
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

  static DateTime? parksDate(String text) {
    final match = RegExp(r'\b(\d{1,2})\s+(Gen|Feb|Mar|Apr|Mag|Giu|Lug|Ago|Set|Ott|Nov|Dic)\s+(\d{2,4})\b', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    final month = ['gen','feb','mar','apr','mag','giu','lug','ago','set','ott','nov','dic'].indexOf(match[2]!.toLowerCase()) + 1;
    var year = int.parse(match[3]!); if (year < 100) year += 2000;
    return DateTime(year, month, int.parse(match[1]!));
  }

  List<DidYouKnowItem> _dedupeAndRank(List<DidYouKnowItem> input) {
    final seen = <String>{};
    final rows = <DidYouKnowItem>[];
    for (final item in freshItems(input)) {
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
    return [...normal.where((e) => e.isLive), ...seasonal, ...normal.where((e) => !e.isLive)];
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
    if (RegExp(r'fiera|festival|evento|mostra|expo|raduno|convegno')
        .hasMatch(t))
      return 'EVENTI';
    if (RegExp(r'ferrat').hasMatch(t)) return 'FERRATE';
    if (RegExp(r'foto|fotograf|camera|obiettivo|sony|nikon|canon').hasMatch(t))
      return 'FOTOGRAFIA';
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
