import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/preferences_service.dart';

const prealpsSource =
    'https://www.parcoprealpigiulie.it/it/principale/territorio/fauna';
const cansiglioSource =
    'https://cansiglio.venetoagricoltura.org/informazioni-scopri-il-cansiglio-flora-fauna-geologia/';
const birdsSource = 'https://www.parks.it/riserva.foce.isonzo/cheklist.html';

class Animal {
  const Animal(
    this.name,
    this.latin,
    this.group,
    this.emoji,
    this.description,
    this.habitat,
    this.behaviour,
    this.ecology,
    this.source, {
    this.audio,
    this.voice = 'Verso',
  });
  final String name,
      latin,
      group,
      emoji,
      description,
      habitat,
      behaviour,
      ecology,
      source,
      voice;
  final String? audio;
}

const animals = <Animal>[
  Animal(
    'Cervo',
    'Cervus elaphus',
    'Mammiferi',
    '🦌',
    'Grande cervide; i maschi adulti portano palchi ramificati, rinnovati annualmente.',
    'Boschi con radure e pascoli. Cansiglio e Prealpi Giulie.',
    'Spesso attivo al crepuscolo. Nel periodo riproduttivo autunnale i maschi bramiscono e possono difendere le femmine: osservali a distanza.',
    'Erbivoro che influenza la vegetazione; evita di interrompere alimentazione e spostamenti.',
    cansiglioSource,
    audio: 'Hirsch roehrt.ogg',
    voice: 'Bramito',
  ),
  Animal(
    'Capriolo',
    'Capreolus capreolus',
    'Mammiferi',
    '🦌',
    'Cervide piccolo e slanciato, con evidente zona chiara posteriore.',
    'Margini boschivi, radure e mosaici agricoli. Cansiglio e Prealpi Giulie.',
    'Elusivo e sensibile al disturbo; frequenta radure nelle ore tranquille. Il richiamo d’allarme ricorda un abbaio.',
    'Si nutre di germogli e foglie. Non toccare i piccoli nascosti nell’erba.',
    cansiglioSource,
    audio: 'Male roe deer growl.ogg',
    voice: 'Abbaio del maschio',
  ),
  Animal(
    'Volpe',
    'Vulpes vulpes',
    'Mammiferi',
    '🦊',
    'Canide dal muso affusolato e dalla lunga coda folta.',
    'Boschi, campagne e ambienti periurbani; presente anche in Cansiglio.',
    'Adattabile, spesso crepuscolare o notturna; può essere attiva di giorno. Non confondere la confidenza con domesticità.',
    'Preda piccoli animali e consuma anche frutti e resti. Non alimentarla e non attirarla sulle strade.',
    'https://old.venetoagricoltura.org/2006/08/uncategorized/foresta-demaniale-regionale-del-cansiglio/',
    audio: 'Bellender Fuchs.ogg',
    voice: 'Abbaio',
  ),
  Animal(
    'Camoscio alpino',
    'Rupicapra rupicapra',
    'Mammiferi',
    '🐐',
    'Ungulato agile, con corna sottili ricurve e maschera scura sul muso.',
    'Praterie montane, rocce e boschi ripidi. Prealpi Giulie.',
    'Vigile; si sposta con facilità sui versanti scoscesi. In inverno limita gli spostamenti per risparmiare energia.',
    'Erbivoro degli ambienti montani. Non costringerlo a fuggire, soprattutto sulla neve.',
    prealpsSource,
  ),
  Animal(
    'Stambecco',
    'Capra ibex',
    'Mammiferi',
    '🐐',
    'Caprino robusto; i maschi adulti hanno grandi corna arcuate con rilievi anteriori.',
    'Pendii rocciosi e pascoli alpini; popolazioni presenti nelle Prealpi Giulie.',
    'Può sembrare tollerante ma resta selvatico. Non stringerlo fra persone e pareti.',
    'Erbivoro; rispetta le vie di passaggio e non offrire sale o cibo.',
    prealpsSource,
  ),
  Animal(
    'Cinghiale',
    'Sus scrofa',
    'Mammiferi',
    '🐗',
    'Suide robusto dal muso allungato e mantello setoloso.',
    'Boschi, macchia e margini agricoli; presente nelle Prealpi Giulie.',
    'Spesso attivo di notte o al crepuscolo. Lascia sempre una via di fuga e non avvicinarti ai piccoli.',
    'Onnivoro; smuove il suolo cercando alimenti. Non lasciare scarti alimentari.',
    prealpsSource,
  ),
  Animal(
    'Aquila reale',
    'Aquila chrysaetos',
    'Rapaci',
    '🦅',
    'Grande rapace dalle ali ampie e dalla nuca dorata.',
    'Rilievi aperti, pareti rocciose e praterie montane. Prealpi Giulie.',
    'Sfrutta il volo planato e le correnti ascensionali; il territorio di una coppia è molto vasto.',
    'Predatore e consumatore di carcasse. Osservala da lontano senza cercare il nido.',
    prealpsSource,
    audio: 'Golden Eagle (Aquila chrysaetos) (W1CDR0001387 BD6).ogg',
    voice: 'Richiamo',
  ),
  Animal(
    'Grifone',
    'Gyps fulvus',
    'Rapaci',
    '🦅',
    'Grande avvoltoio dalle ali molto larghe e dalla coda corta.',
    'Pareti e spazi aperti delle Prealpi; colonia nell’area di Cornino.',
    'Spesso sociale; percorre grandi distanze sfruttando le correnti.',
    'Necrofago: consuma carcasse. Usa i percorsi e i punti di osservazione autorizzati.',
    'https://www.riservacornino.it/chi-siamo/la-riserva/',
  ),
  Animal(
    'Poiana',
    'Buteo buteo',
    'Rapaci',
    '🦅',
    'Rapace di medie dimensioni, ali larghe e piumaggio molto variabile.',
    'Campagne alternate a boschi, colline e margini forestali; anche Prealpi Giulie.',
    'Caccia da posatoi o volteggiando. Il verso è un richiamo acuto e lamentoso.',
    'Preda piccoli vertebrati e altri animali. Non fermarti in punti pericolosi per fotografarla lungo una strada.',
    prealpsSource,
    audio: 'Buteo buteo warning the fledglings 7643.ogg',
    voice: 'Richiamo di allarme',
  ),
  Animal(
    'Allocco',
    'Strix aluco',
    'Rapaci',
    '🦉',
    'Rapace notturno con testa rotonda, occhi scuri e senza ciuffi auricolari.',
    'Boschi maturi, parchi e ambienti alberati. Prealpi Giulie.',
    'Prevalentemente notturno; spesso lo si sente più che vederlo. Evita torce puntate e flash.',
    'Predatore di piccoli animali; usa cavità arboree per nidificare. Non sollecitarlo con richiami.',
    prealpsSource,
    audio: 'Tawny Owl (Strix aluco) (W1CDR0001427 BD9).ogg',
    voice: 'Richiamo',
  ),
  Animal(
    'Picchio nero',
    'Dryocopus martius',
    'Uccelli',
    '🐦',
    'Grande picchio nero con zona rossa sul capo, più estesa nel maschio.',
    'Boschi con alberi maturi e legno morto. Presente in Cansiglio.',
    'Emette forti richiami e tambureggia sui tronchi. Osserva senza sostare presso le cavità.',
    'Le cavità scavate vengono usate anche da altre specie. Il legno morto è parte importante dell’habitat.',
    'https://old.venetoagricoltura.org/2006/08/uncategorized/foresta-demaniale-regionale-del-cansiglio/',
    audio: 'Black woodpecker Dryocopus martius, flying call.ogg',
    voice: 'Richiamo in volo',
  ),
  Animal(
    'Airone cenerino',
    'Ardea cinerea',
    'Uccelli',
    '🐦',
    'Grande uccello acquatico grigio con collo e zampe lunghi.',
    'Zone umide, fiumi, lagune e campagne; Foce dell’Isonzo.',
    'Caccia restando immobile o avanzando lentamente in acqua bassa. In volo ripiega il collo.',
    'Si alimenta di pesci e altre piccole prede. Non avvicinarti alle colonie riproduttive.',
    birdsSource,
  ),
  Animal(
    'Germano reale',
    'Anas platyrhynchos',
    'Uccelli',
    '🦆',
    'Anatra di superficie; nel piumaggio riproduttivo il maschio ha testa verde, la femmina è bruna screziata.',
    'Laghi, fiumi, paludi e lagune. Foce dell’Isonzo.',
    'Si alimenta in superficie e in acqua bassa; può formare gruppi numerosi.',
    'Consuma vegetali e piccoli invertebrati. Evita pane e alimentazione artificiale.',
    birdsSource,
    audio: 'Anas platyrhynchos - Mallard - XC62258.ogg',
    voice: 'Richiamo della femmina',
  ),
  Animal(
    'Falco di palude',
    'Circus aeruginosus',
    'Rapaci',
    '🦅',
    'Rapace dalle ali lunghe; vola spesso basso sopra la vegetazione palustre.',
    'Canneti e zone umide, comprese le aree della Foce dell’Isonzo.',
    'Caccia perlustrando l’ambiente con volo lento. Il piumaggio varia con sesso ed età.',
    'Predatore delle zone umide; resta nei capanni e sui percorsi consentiti.',
    'https://www.parks.it/riserva.foce.isonzo/par.php',
  ),
];

Future<Map<String, dynamic>> getJson(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    final request = await client.getUrl(uri);
    request.headers.set(
      'User-Agent',
      'WildTrack/0.2 (nature education; https://github.com/canta80-ship-it/wildtrack)',
    );
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Rete');
    return jsonDecode(await response.transform(utf8.decoder).join())
        as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

String cleanCredit(String x) => x
    .replaceAll(RegExp('<[^>]*>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .trim();

class CommonsMedia {
  const CommonsMedia(this.url, this.credit, this.page);
  final String url, credit, page;
  static final cache = <String, Future<CommonsMedia>>{};
  static Future<CommonsMedia> file(
    String title, {
    bool thumbnail = false,
  }) async {
    final data = await getJson(
      Uri.https('commons.wikimedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata',
        'iiurlwidth': '800',
        'titles': 'File:$title',
      }),
    );
    final pages = data['query']['pages'] as Map<String, dynamic>;
    final info =
        (pages.values.first['imageinfo'] as List).first as Map<String, dynamic>;
    final meta = info['extmetadata'] as Map<String, dynamic>? ?? {};
    final author = cleanCredit(
      meta['Artist']?['value'] as String? ?? 'Autore nella fonte',
    );
    final license = cleanCredit(
      meta['LicenseShortName']?['value'] as String? ?? 'Licenza nella fonte',
    );
    return CommonsMedia(
      (thumbnail ? info['thumburl'] : null) as String? ?? info['url'] as String,
      '$author · $license',
      info['descriptionurl'] as String,
    );
  }

  static Future<CommonsMedia> photo(Animal a) =>
      cache.putIfAbsent(a.latin, () async {
        final data = await getJson(
          Uri.https('en.wikipedia.org', '/w/api.php', {
            'action': 'query',
            'format': 'json',
            'redirects': '1',
            'prop': 'pageimages',
            'piprop': 'name',
            'titles': a.latin,
          }),
        );
        final pages = data['query']['pages'] as Map<String, dynamic>;
        final title = pages.values.first['pageimage'] as String?;
        if (title == null) throw Exception('Foto non disponibile');
        return file(title, thumbnail: true);
      });
}

class AudioService extends ChangeNotifier {
  static final instance = AudioService();
  static const channel = MethodChannel('wildtrack/audio');
  String? current;
  String? error;
  int request = 0;
  AudioService() {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'stopped') {
        current = null;
      }
      if (call.method == 'error') {
        current = null;
        error = call.arguments as String?;
      }
      notifyListeners();
    });
  }
  Future<void> stop() async {
    request++;
    current = null;
    notifyListeners();
    try {
      await channel.invokeMethod('stop');
    } catch (_) {}
  }

  Future<void> play(Animal animal) async {
    if (current == animal.name) {
      await stop();
      return;
    }
    await stop();
    if (animal.audio == null) return;
    final id = ++request;
    current = animal.name;
    error = null;
    notifyListeners();
    try {
      final file = await CommonsMedia.file(animal.audio!);
      if (id != request) return;
      await channel.invokeMethod('play', {
        'url': file.url,
        'repeats': PreferencesService.instance.repeats.clamp(1, 5),
      });
    } catch (_) {
      if (id == request) {
        current = null;
        error = 'Audio non disponibile. Controlla la connessione e riprova.';
        notifyListeners();
      }
    }
  }
}

class AnimalPhoto extends StatefulWidget {
  const AnimalPhoto(this.animal, {super.key});
  final Animal animal;
  @override
  State<AnimalPhoto> createState() => _AnimalPhotoState();
}

class _AnimalPhotoState extends State<AnimalPhoto> {
  late Future<CommonsMedia> future;
  @override
  void initState() {
    super.initState();
    future = CommonsMedia.photo(widget.animal);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CommonsMedia>(
    future: future,
    builder: (context, s) {
      if (s.hasData) {
        final m = s.data!;
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                m.url,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, e, st) => const SizedBox(
                  height: 160,
                  child: Center(child: Text('Foto non disponibile')),
                ),
              ),
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(m.page),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                m.credit,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
      }
      return SizedBox(
        height: 170,
        child: Center(
          child: s.hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.animal.emoji,
                      style: const TextStyle(fontSize: 50),
                    ),
                    TextButton(
                      onPressed: () {
                        CommonsMedia.cache.remove(widget.animal.latin);
                        setState(
                          () => future = CommonsMedia.photo(widget.animal),
                        );
                      },
                      child: const Text('Foto online · Riprova'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}

class SpeciesScreen extends StatefulWidget {
  const SpeciesScreen({super.key});
  @override
  State<SpeciesScreen> createState() => _SpeciesScreenState();
}

class _SpeciesScreenState extends State<SpeciesScreen> {
  String query = '', group = 'Tutte';
  @override
  Widget build(BuildContext context) {
    final list = animals
        .where(
          (a) =>
              (group == 'Tutte' || a.group == group) &&
              ('${a.name} ${a.latin}'.toLowerCase().contains(
                query.toLowerCase(),
              )),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Specie')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cerca specie',
                border: OutlineInputBorder(),
              ),
              onChanged: (s) => setState(() => query = s),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final g in ['Tutte', 'Mammiferi', 'Rapaci', 'Uccelli'])
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ChoiceChip(
                      label: Text(g),
                      selected: group == g,
                      onSelected: (_) => setState(() => group = g),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: Text(
                      a.emoji,
                      style: const TextStyle(fontSize: 34),
                    ),
                    title: Text(a.name),
                    subtitle: Text(a.latin),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => AnimalScreen(a)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnimalScreen extends StatelessWidget {
  const AnimalScreen(this.animal, {super.key});
  final Animal animal;
  @override
  Widget build(BuildContext context) {
    final a = animal;
    return Scaffold(
      appBar: AppBar(title: Text(a.name)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AnimalPhoto(a),
          Text(a.latin, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(a.description),
          for (final section in [
            ('Dove vive', a.habitat),
            ('Abitudini e comportamento', a.behaviour),
            ('Ecologia e rispetto', a.ecology),
          ]) ...[
            const SizedBox(height: 18),
            Text(section.$1, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(section.$2),
          ],
          const SizedBox(height: 18),
          TrackCard(a),
          const SizedBox(height: 18),
          if (a.audio != null)
            AudioTile(a)
          else
            const Text(
              'Registrazione verificata non ancora disponibile per questa specie.',
            ),
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(a.source),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Fonte naturalistica'),
          ),
          const Text(
            'Le aree indicate descrivono presenze e habitat generali, non avvistamenti in tempo reale. Foto e versi richiedono Internet.',
          ),
        ],
      ),
    );
  }
}

class AudioTile extends StatelessWidget {
  const AudioTile(this.animal, {super.key});
  final Animal animal;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AudioService.instance,
    builder: (context, _) {
      final audio = AudioService.instance;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                onPressed: () => audio.play(animal),
                icon: Icon(
                  audio.current == animal.name ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(
                  audio.current == animal.name
                      ? 'Ferma ${animal.name}'
                      : '${animal.voice} · ${PreferencesService.instance.repeats}×',
                ),
              ),
              if (audio.error != null) Text(audio.error!),
              const Text(
                'Cuffie o altoparlante secondo l’uscita Android. Massimo 5 ripetizioni; non usare per attirare animali.',
              ),
              FutureBuilder<CommonsMedia>(
                future: CommonsMedia.file(animal.audio!),
                builder: (context, s) => s.hasData
                    ? TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(s.data!.page),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(
                          s.data!.credit,
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showSounds(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: .78,
        child: Column(
          children: [
            ListTile(
              title: const Text('Versi degli animali'),
              subtitle: const Text('Ascolta senza disturbare la fauna'),
              trailing: IconButton(
                tooltip: 'Stop audio',
                onPressed: () => AudioService.instance.stop(),
                icon: const Icon(Icons.stop_circle),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final a in animals.where((a) => a.audio != null))
                    ListTile(
                      leading: Text(
                        a.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      title: Text(a.name),
                      subtitle: Text(a.voice),
                      trailing: const Icon(Icons.play_circle_outline),
                      onTap: () => AudioService.instance.play(a),
                    ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: AudioService.instance,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  AudioService.instance.error ??
                      (AudioService.instance.current == null
                          ? 'Riproduzione ferma'
                          : 'In riproduzione: ${AudioService.instance.current}'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await AudioService.instance.stop();
}

class TrackCard extends StatelessWidget {
  const TrackCard(this.animal, {super.key});
  final Animal animal;
  @override
  Widget build(BuildContext context) {
    final name = animal.name;
    final type = name == 'Volpe'
        ? 'canide'
        : animal.group == 'Mammiferi'
        ? 'zoccolo'
        : name == 'Germano reale'
        ? 'palmata'
        : name == 'Picchio nero' || name == 'Allocco'
        ? 'due_due'
        : 'uccello';
    final description = switch (name) {
      'Cervo' =>
        'Due unghioni affiancati. Può essere difficile distinguerla da quella di altri cervidi: valuta dimensioni, sequenza e ambiente.',
      'Capriolo' =>
        'Due unghioni affiancati, come negli altri cervidi. Non basta una singola impronta per attribuirla con certezza al capriolo.',
      'Volpe' =>
        'Quattro dita e cuscinetto centrale; spesso sono visibili le unghie. La forma tende a essere stretta. Può confondersi con un piccolo cane.',
      'Cinghiale' =>
        'Zoccolo diviso in due unghioni. Sul terreno cedevole possono comparire anche i segni degli speroni posteriori; osserva più impronte.',
      'Camoscio alpino' || 'Stambecco' =>
        'Zoccolo diviso in due unghioni. Sulle rocce le tracce sono poco evidenti; neve e fango conservano meglio i segni. Lo schema non distingue i due caprini.',
      'Germano reale' =>
        'Tre dita anteriori unite da una membrana: nel fango può apparire la tipica impronta palmata delle anatre.',
      'Picchio nero' =>
        'Due dita rivolte in avanti e due indietro. Le impronte sul terreno sono poco frequenti; lo schema rappresenta la disposizione delle dita.',
      'Allocco' =>
        'Può lasciare due dita in avanti e due indietro; la posizione del dito esterno è variabile. Non identificare la specie dalla sola impronta.',
      'Airone cenerino' =>
        'Dita lunghe e aperte, tre anteriori e una posteriore. Cerca le tracce sul fango ai margini dell’acqua, restando sui percorsi.',
      _ =>
        'Piede da rapace con dita e artigli. Le impronte a terra sono difficili da attribuire alla specie: lo schema è generale, non una chiave di identificazione.',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Impronte e tracce',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Center(
              child: Semantics(
                label: 'Schema di impronta: $type',
                image: true,
                child: CustomPaint(
                  size: const Size(130, 150),
                  painter: TrackPainter(
                    type,
                    Theme.of(context).colorScheme.primary,
                    name == 'Cinghiale',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Schema orientativo del tipo di piede · non in scala',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(description),
            const SizedBox(height: 10),
            const Text(
              'Fotografa dall’alto con un righello accanto, senza alterare la traccia. Annota terreno e dimensioni e riprendi anche la sequenza: fango, neve e andatura cambiano la forma. Non seguire le tracce fino a tane o nidi.',
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://icwdm.org/identification/tracks/'),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Guida alle impronte · ICWDM'),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackPainter extends CustomPainter {
  const TrackPainter(this.type, this.color, this.dewclaws);
  final String type;
  final Color color;
  final bool dewclaws;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 130, size.height / 150);
    final fill = Paint()..color = color;
    if (type == 'zoccolo') {
      final left = Path()
        ..moveTo(57, 18)
        ..cubicTo(24, 35, 24, 100, 51, 110)
        ..quadraticBezierTo(62, 100, 57, 18)
        ..close();
      canvas.drawPath(left, fill);
      canvas.save();
      canvas.translate(130, 0);
      canvas.scale(-1, 1);
      canvas.drawPath(left, fill);
      canvas.restore();
      if (dewclaws) {
        canvas.drawOval(const Rect.fromLTWH(26, 118, 15, 19), fill);
        canvas.drawOval(const Rect.fromLTWH(89, 118, 15, 19), fill);
      }
    } else if (type == 'canide') {
      for (final r in [
        const Rect.fromLTWH(22, 53, 22, 30),
        const Rect.fromLTWH(44, 28, 19, 31),
        const Rect.fromLTWH(68, 28, 19, 31),
        const Rect.fromLTWH(90, 53, 22, 30),
      ]) {
        canvas.drawOval(r, fill);
        canvas.drawPath(
          Path()
            ..moveTo(r.center.dx - 3, r.top - 5)
            ..lineTo(r.center.dx, r.top - 15)
            ..lineTo(r.center.dx + 3, r.top - 5)
            ..close(),
          fill,
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(64, 75)
          ..quadraticBezierTo(32, 88, 40, 116)
          ..quadraticBezierTo(65, 105, 90, 116)
          ..quadraticBezierTo(99, 88, 64, 75)
          ..close(),
        fill,
      );
    } else {
      final stroke = Paint()
        ..color = color
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      const center = Offset(65, 85);
      final tips = type == 'due_due'
          ? const [
              Offset(28, 24),
              Offset(99, 24),
              Offset(33, 132),
              Offset(98, 132),
            ]
          : const [
              Offset(19, 42),
              Offset(65, 14),
              Offset(111, 42),
              Offset(54, 133),
            ];
      if (type == 'palmata') {
        canvas.drawPath(
          Path()
            ..moveTo(65, 85)
            ..lineTo(19, 42)
            ..quadraticBezierTo(45, 54, 65, 14)
            ..quadraticBezierTo(84, 54, 111, 42)
            ..close(),
          Paint()..color = color.withValues(alpha: .30),
        );
      }
      for (final tip in tips) {
        canvas.drawLine(center, tip, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TrackPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.color != color ||
      oldDelegate.dewclaws != dewclaws;
}
