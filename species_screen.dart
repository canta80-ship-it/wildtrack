import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/preferences_service.dart';
import 'exploration_screen.dart';
import '../premium_ui.dart';
import 'species_detail_screen.dart';
import 'premium_animal_screen.dart';

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
      description,
      habitat,
      behaviour,
      ecology,
      source,
      voice;
  final String? audio;
}

const animals = <Animal>[
  Animal("Lince", "Lynx lynx", "Mammiferi", "Felino europeo con zampe lunghe, coda corta dall’estremità nera, ciuffi sulle orecchie e mantello maculato. La coda e la sagoma la distinguono dal gatto selvatico.", "Foreste estese con sottobosco, rocce e zone tranquille. La distribuzione è frammentata: habitat adatto non significa presenza certa. Nelle Alpi e nelle Prealpi l’osservazione diretta è rara.", "Solitaria e territoriale, caccia soprattutto all’agguato. È attiva principalmente al crepuscolo e di notte; evita il disturbo e percorre territori molto ampi.", "Predatore di ungulati e piccoli vertebrati. La frammentazione delle foreste e gli investimenti stradali ostacolano le popolazioni. Le coordinate pubbliche vanno mantenute approssimate.", "https://www.kora.ch/en/species/lynx/profile"),
  Animal("Tritone", "Ichthyosaura alpestris", "Anfibi", "Piccolo anfibio dalla coda compressa lateralmente e ventre arancione in genere privo di macchie. Nel maschio riproduttivo il dorso può essere bluastro con una bassa cresta. Tritone è un nome generico: altre specie hanno caratteri diversi.", "La scheda riguarda il tritone alpestre. Stagni, pozze e piccoli specchi d’acqua senza pesci, con boschi e rifugi umidi nelle vicinanze. Negli ambienti alpini i tempi riproduttivi dipendono da quota e disgelo.", "Durante la riproduzione vive in acqua; fuori dalla stagione acquatica usa rifugi umidi a terra. Il corteggiamento avviene con movimenti della coda e segnali chimici.", "Predatore di piccoli invertebrati e parte delle reti alimentari delle zone umide. La perdita di stagni, l’introduzione di pesci e il prosciugamento degli habitat ne riducono le possibilità di riproduzione.", "https://www.froglife.org/info-advice/amphibians-and-reptiles/alpine-newt/"),
  Animal("Rospo", "Bufo bufo", "Anfibi", "Corpo robusto, pelle verrucosa, occhi color rame con pupilla orizzontale e ghiandole parotoidi dietro gli occhi. Bufo bufo non rappresenta tutti i rospi italiani: alcune popolazioni e specie richiedono confronto specialistico.", "La scheda riguarda il rospo comune. Boschi, prati, siepi e giardini con rifugi freschi; per riprodursi raggiunge stagni e raccolte d’acqua. Le migrazioni possono attraversare strade.", "Si muove spesso camminando e con brevi salti. Caccia piccoli invertebrati; in primavera può migrare in massa verso l’acqua riproduttiva.", "Consuma invertebrati e contribuisce alle reti alimentari terrestri e acquatiche. Mortalità stradale, pesticidi e perdita di zone umide sono minacce importanti.", "https://www.parcoforestecasentinesi.it/it/natura/biodiversita/la-fauna/anfibi-e-rettili-nel-parco-nazionale-0"),
  Animal("Salamandra", "Salamandra salamandra", "Anfibi", "Corpo nero lucido con macchie gialle variabili, coda lunga e arrotondata e zampe corte. Il disegno delle macchie può differire molto tra individui.", "La scheda riguarda la salamandra pezzata. Boschi freschi di latifoglie, lettiera umida, ruscelli e pozze con acqua pulita. Non va confusa con la salamandra alpina, nera e con diversa biologia riproduttiva.", "Si rifugia sotto legno morto, pietre e lettiera; emerge con umidità elevata. Si muove lentamente e usa secrezioni cutanee come difesa.", "Collega le reti alimentari dei boschi e dei corsi d’acqua. Alterazione dei ruscelli, siccità, traffico e patogeni degli anfibi minacciano gli habitat.", "https://www.parcoforestecasentinesi.it/it/natura/biodiversita/la-fauna/anfibi-e-rettili-nel-parco-nazionale-0"),

  Animal(
    'Cervo',
    'Cervus elaphus',
    'Mammiferi',
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
    'Rapace dalle ali lunghe; vola spesso basso sopra la vegetazione palustre.',
    'Canneti e zone umide, comprese le aree della Foce dell’Isonzo.',
    'Caccia perlustrando l’ambiente con volo lento. Il piumaggio varia con sesso ed età.',
    'Predatore delle zone umide; resta nei capanni e sui percorsi consentiti.',
    'https://www.parks.it/riserva.foce.isonzo/par.php',
  ),
  Animal(
    "Orso bruno",
    "Ursus arctos",
    "Mammiferi",
    "Grande mammifero dal corpo robusto e dalle orecchie arrotondate.",
    "In Appennino centrale vive la popolazione marsicana; la presenza italiana non è uniforme.",
    "Osserva da lontano senza cercare di avvicinarlo o seguirlo.",
    "Non lasciare cibo e rispetta le indicazioni locali di osservazione.",
    "https://www.parcoabruzzo.it/mammiferi.php",
    audio: 'Yellowstone sound library - Grizzly Bears Roar - 001.mp3',
    voice: 'Vocalizzazione · orso bruno, registrazione nordamericana',
  ),
  Animal(
    "Lupo",
    "Canis lupus",
    "Mammiferi",
    "Canide selvatico; non attribuire la specie dalla sola somiglianza con un cane.",
    "Presente anche nel Parco nazionale di Abruzzo, Lazio e Molise.",
    "Elusivo; le osservazioni dirette possono essere rare.",
    "Mantieni la distanza e non offrire cibo.",
    "https://www.parcoabruzzo.it/mammiferi.php",
    audio: 'Wolf howls.ogg',
    voice: 'Ululato',
  ),
  Animal(
    "Sciacallo dorato",
    "Canis aureus",
    "Mammiferi",
    "Canide dal mantello generalmente fulvo e dal muso affusolato.",
    "Presenza documentata in Friuli Venezia Giulia; distribuzione in evoluzione.",
    "Fotografa a distanza e annota luogo e ora per documentare la segnalazione.",
    "Non attirarlo con cibo o richiami.",
    "https://www.consiglio.regione.fvg.it/pagineinterne/Portale/comunicatiStampaDettaglio.aspx?ID=964510",
    audio: 'Jackal.ogg',
    voice: 'Ululato',
  ),
  Animal(
    "Marmotta",
    "Marmota marmota",
    "Mammiferi",
    "Roditore alpino robusto che utilizza sistemi di tane nel terreno.",
    "Praterie alpine, comprese quelle del Gran Paradiso.",
    "Osserva senza avvicinarti agli ingressi delle tane.",
    "Erbivora, fa parte delle reti alimentari degli ambienti alpini.",
    "https://www.pngp.it/notizie/dieci-anni-di-ricerca-sulle-marmotte-nel-parco",
    audio: '2006, Murmeldjur BHW 2006.ogg',
    voice: 'Fischio di allarme',
  ),
  Animal(
    "Ermellino",
    "Mustela erminea",
    "Mammiferi",
    "Piccolo mustelide dal corpo allungato; la punta della coda rimane nera anche nel mantello invernale bianco.",
    "Presente tra i mammiferi del Gran Paradiso.",
    "Rapido ed elusivo; documenta più caratteri per distinguerlo da altri mustelidi.",
    "Non spostare pietre né esplorare rifugi per cercarlo.",
    "https://www.pngp.it/natura-e-ricerca/fauna-0",
  ),
  Animal(
    "Tasso",
    "Meles meles",
    "Mammiferi",
    "Mustelide robusto con caratteristiche bande scure sul muso chiaro.",
    "Nel Parco di Abruzzo frequenta ambienti dai coltivi alle praterie in quota.",
    "Osserva senza sostare presso le tane.",
    "Non ostruire ingressi e passaggi.",
    "https://www.parcoabruzzo.it/mammiferi.php",
    audio: 'European Badger (Meles meles) (W1CDR0001490 BD4).ogg',
    voice: 'Richiamo',
  ),
  Animal(
    "Gracchio alpino",
    "Pyrrhocorax graculus",
    "Uccelli",
    "Corvide nero dal becco giallo, distinto dal gracchio corallino.",
    "Ambienti montani e pareti rocciose.",
    "Può spostarsi in gruppo; osserva il becco per distinguerlo dagli altri corvidi.",
    "Consuma invertebrati e frutti. Non alimentarlo presso rifugi e sentieri.",
    "https://www.lipu.it/uccelli/conoscerli-proteggerli/gracchio-alpino",
    audio: 'Pyrrhocorax graculus - Alpine Chough XC496675.mp3',
    voice: 'Richiamo in volo',
  ),
  Animal(
    "Gufo reale",
    "Bubo bubo",
    "Rapaci",
    "Grande rapace notturno con ciuffi auricolari e occhi arancioni.",
    "Ambienti con pareti e siti riparati; presenza da verificare localmente.",
    "Evita flash, richiami e avvicinamenti ai siti riproduttivi.",
    "Il disturbo dei siti di nidificazione è una minaccia per la specie.",
    "https://www.lipu.it/uccelli/conoscerli-proteggerli/gufo-reale",
    audio: 'BuboBuboMariankaSlovakia2012.ogg',
    voice: 'Richiamo territoriale',
  ),
  Animal(
    "Barbagianni",
    "Tyto alba",
    "Rapaci",
    "Rapace notturno dal disco facciale chiaro a forma di cuore e dagli occhi scuri.",
    "Paesaggi rurali; utilizza anche edifici con cavità adatte.",
    "Osserva dall’esterno senza entrare nei luoghi di riposo o nidificazione.",
    "La perdita di siti adatti negli edifici può limitarne la presenza.",
    "https://www.lipu.it/uccelli/conoscerli-proteggerli/barbagianni",
    audio: 'Barn Owl (Tyto alba) (W TYTO ALBA R1 C16).ogg',
    voice: 'Stridio',
  ),
  Animal(
    "Ghiandaia",
    "Garrulus glandarius",
    "Uccelli",
    "Corvide dal piumaggio bruno rosato con evidente pannello azzurro e nero sulle ali.",
    "Ambienti alberati e boschivi.",
    "Documenta i dettagli delle ali e del capo senza inseguirla.",
    "Rispetta il bosco e non avvicinarti ai nidi.",
    "https://www.lipu.it/uccelli/conoscerli-proteggerli/ghiandaia",
    audio: 'Eichelhaeher.ogg',
    voice: 'Richiami',
  ),
  Animal("Lepre",
    "Lepus europaeus",
    "Mammiferi",
    "Lepre europea: orecchie lunghe con apice nero, arti posteriori robusti e mantello bruno. Diversa da coniglio, lepre variabile e lepre italica.",
    "Mosaici di campi, prati e margini con siepi. La scheda tratta la lepre europea, non tutte le lepri italiane.",
    "Può restare immobile prima di fuggire a balzi. I piccoli nascono già coperti di pelo e con occhi aperti; la madre torna ad allattarli, quindi un piccolo solo non è necessariamente abbandonato.",
    "Erbivoro e preda di molti carnivori. Rispetta il covo, evita inseguimenti e lascia indisturbati i piccoli.",
    "https://www.woodlandtrust.org.uk/blog/2023/03/why-do-hares-box/"),
  Animal("Scoiattolo",
    "Sciurus vulgaris",
    "Mammiferi",
    "Scoiattolo rosso o comune: coda folta, ventre chiaro e ciuffi auricolari più evidenti in inverno. Il mantello può essere anche scuro.",
    "Boschi di conifere, latifoglie e parchi alberati. La scheda riguarda Sciurus vulgaris.",
    "Arboricolo e agile, costruisce nidi globosi fra i rami e immagazzina semi. Resta attivo in inverno: non va in letargo. Si può fermare e agitare la coda quando è allarmato.",
    "Il trasporto e l'interramento di semi contribuiscono alla dispersione delle piante. Evita cibo, richiami e accesso ai nidi.",
    "https://www.woodlandtrust.org.uk/trees-woods-and-wildlife/animals/mammals/red-squirrel/"),
  Animal("Upupa",
    "Upupa epops",
    "Uccelli",
    "Cresta erettile, becco lungo e curvo, corpo color cannella e ali bianche e nere. Sessi simili.",
    "Campagne tradizionali, prati corti, frutteti e filari con cavità.",
    "Cerca il cibo a terra con il becco. Nidifica in cavità; i voli ripetuti con prede possono indicare un nido: non seguirli.",
    "Consuma molti invertebrati. Conservare alberi vecchi e agricoltura con pochi pesticidi favorisce le risorse; non disturbare le cavità.",
    "https://www.lipu.it/uccelli/conoscerli-proteggerli/upupa"),
  Animal("Gheppio",
    "Falco tinnunculus",
    "Rapaci",
    "Piccolo falco dalle ali appuntite e coda lunga. Il maschio ha capo grigio e dorso rossiccio macchiettato; femmina e giovani più barrati.",
    "Prati, coltivi, rupi e ambienti urbani con aree aperte.",
    "Caccia da posatoi o restando sospeso in volo, lo 'spirito santo'. È diurno; il buio non è una finestra favorevole per osservarlo cacciare.",
    "Preda piccoli vertebrati e invertebrati. Agricoltura intensiva e pesticidi riducono le risorse; evita soste pericolose sulle strade.",
    "https://www.lipu.it/uccelli/conoscerli-proteggerli/gheppio"),
  Animal("Assiolo",
    "Otus scops",
    "Rapaci",
    "Piccolo gufo con ciuffi auricolari, occhi giallastri e piumaggio simile alla corteccia.",
    "Paesaggi caldi con alberi sparsi, prati, frutteti e filari.",
    "Di giorno resta mimetizzato; di notte caccia soprattutto insetti. Il canto regolare rivela spesso la presenza prima dell'avvistamento.",
    "Dipende da grandi insetti e cavità. Conserva alberi vecchi; niente playback, flash o torce dirette.",
    "https://www.lipu.it/uccelli/conoscerli-proteggerli/assiolo"),
  Animal("Nibbio reale",
    "Milvus milvus",
    "Rapaci",
    "Rapace con coda rossiccia profondamente forcuta, capo chiaro e finestre bianche sotto le ali. Distinto dal nibbio bruno.",
    "Campagne e pascoli con boschetti e grandi alberi; distribuzione italiana localizzata.",
    "Plana e manovra con la lunga coda forcuta. Può riunirsi in dormitori; osserva dai percorsi senza avvicinarti agli alberi occupati.",
    "Predatore opportunista e consumatore di carcasse; vulnerabile ad avvelenamento e alterazione dell'habitat.",
    "https://www.lipu.it/uccelli/conoscerli-proteggerli/nibbio-reale"),
  Animal("Nibbio bruno",
    "Milvus migrans",
    "Rapaci",
    "Piumaggio bruno, capo un po' più chiaro e coda con forcella poco profonda. Non ha la coda rossiccia del nibbio reale.",
    "Zone umide e corsi d'acqua con boschi vicini, anche coltivi e prati.",
    "Veleggia con coda leggermente forcuta; può aggregarsi presso risorse alimentari. Mantieni distanza da nidi e gruppi in riposo.",
    "Predatore opportunista e necrofago, legato anche agli ambienti acquatici. Non attirarlo con cibo o carcasse.",
    "https://www.lipu.it/uccelli/conoscerli-proteggerli/nibbio-bruno"),
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
    if (!thumbnail) {
      try {
        final manifest = jsonDecode(await rootBundle.loadString('assets/audio/manifest.json')) as Map<String,dynamic>;
        final info = manifest[title] as Map<String,dynamic>?;
        if (info != null) {
          final asset = info['asset'] as String;
          final target = File('${await getDatabasesPath()}/wildtrack_audio/${asset.split('/').last}');
          if (!await target.exists()) {
            await target.parent.create(recursive:true);
            final bytes = await rootBundle.load(asset);
            final temporary = File('${target.path}.tmp');
            await temporary.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes,bytes.lengthInBytes),flush:true);
            await temporary.rename(target.path);
          }
          return CommonsMedia(target.path, '${info['credit']}', '${info['page']}');
        }
      } catch (_) {}
    }
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
                fit: BoxFit.contain,
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
                    SpeciesIcon(widget.animal.name, size: 64),
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
      backgroundColor: const Color(0xFFF8F5ED),
      appBar: AppBar(
        title: const Text(
          'Tutte le specie',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF8F5ED),
        foregroundColor: WildColors.forest,
      ),
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
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        '${speciesDetails[a.name]!.newArtwork ? 'assets/radar_species' : 'assets/approved'}/${speciesDetails[a.name]!.asset}_hero.jpg',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: Text(
                      a.name,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w800,
                        color: WildColors.ink,
                      ),
                    ),
                    subtitle: Text(a.latin),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PremiumAnimalScreen(a),
                      ),
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
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ExplorationScreen(species: a.name),
              ),
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text("Presenze in Italia e sentieri"),
          ),
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
                      leading: SpeciesIcon(a.name, size: 44),
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
    final type = const {'Volpe', 'Lupo', 'Sciacallo dorato'}.contains(name)
        ? 'canide'
        : const {'Orso bruno', 'Tasso', 'Ermellino'}.contains(name)
        ? 'cinque_dita'
        : name == 'Marmotta'
        ? 'roditore'
        : animal.group == 'Mammiferi'
        ? 'zoccolo'
        : name == 'Germano reale'
        ? 'palmata'
        : name == 'Picchio nero' ||
              name == 'Allocco' ||
              name == 'Gufo reale' ||
              name == 'Barbagianni'
        ? 'due_due'
        : 'uccello';
    final description = switch (name) {
      'Orso bruno' => 'Piede plantigrado con cinque dita. Il posteriore lascia un’impronta allungata; fango e neve possono deformarla. Documenta più impronte senza seguire l’animale.',
      'Lupo' => 'Quattro dita e cuscinetto centrale, spesso unghie visibili. Le impronte possono essere indistinguibili da quelle di un cane: una foto isolata non conferma il lupo.',
      'Sciacallo dorato' => 'Impronta di canide a quattro dita, confondibile con volpe e cane. Dimensioni, pista e contesto aiutano ma non costituiscono prova della specie.',
      'Marmotta' => 'Zampe anteriori e posteriori hanno forma diversa; sul terreno le dita non sono sempre tutte impresse. Considera anche habitat e sequenza delle tracce.',
      'Ermellino' => 'Piccole impronte a cinque dita, spesso in coppie durante i balzi. Confondibile con altri piccoli mustelidi: conserva foto con riferimento metrico.',
      'Tasso' => 'Cinque dita allineate ad arco, cuscinetto largo e unghie anteriori sviluppate. La qualità del terreno cambia molto l’aspetto.',
      'Gracchio alpino' || 'Ghiandaia' => 'Tre dita anteriori e una posteriore. Le impronte da sole non distinguono in modo affidabile questi corvidi.',
      'Gufo reale' || 'Barbagianni' => 'Dita robuste con artigli; il dito esterno può orientarsi posteriormente. Usa lo schema solo per riconoscere il tipo di piede.',
      'Cervo' => 'Due unghioni affiancati. Può essere difficile distinguerla da quella di altri cervidi: valuta dimensioni, sequenza e ambiente.',
      'Capriolo' => 'Due unghioni affiancati, come negli altri cervidi. Non basta una singola impronta per attribuirla con certezza al capriolo.',
      'Volpe' => 'Quattro dita e cuscinetto centrale; spesso sono visibili le unghie. La forma tende a essere stretta. Può confondersi con un piccolo cane.',
      'Cinghiale' => 'Zoccolo diviso in due unghioni. Sul terreno cedevole possono comparire anche i segni degli speroni posteriori; osserva più impronte.',
      'Camoscio alpino' || 'Stambecco' => 'Zoccolo diviso in due unghioni. Sulle rocce le tracce sono poco evidenti; neve e fango conservano meglio i segni. Lo schema non distingue i due caprini.',
      'Germano reale' => 'Tre dita anteriori unite da una membrana: nel fango può apparire la tipica impronta palmata delle anatre.',
      'Picchio nero' => 'Due dita rivolte in avanti e due indietro. Le impronte sul terreno sono poco frequenti; lo schema rappresenta la disposizione delle dita.',
      'Allocco' => 'Può lasciare due dita in avanti e due indietro; la posizione del dito esterno è variabile. Non identificare la specie dalla sola impronta.',
      'Airone cenerino' => 'Dita lunghe e aperte, tre anteriori e una posteriore. Cerca le tracce sul fango ai margini dell’acqua, restando sui percorsi.',
      _ => 'Piede da rapace con dita e artigli. Le impronte a terra sono difficili da attribuire alla specie: lo schema è generale, non una chiave di identificazione.',
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
            const SizedBox(height: 12),
            Text(
              'Fatte e altri segni',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(scatDescription(name, animal.group)),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(
                  name == 'Lupo'
                      ? 'https://www.lifewolfalps.eu/wp-content/uploads/2021/12/LWA_Istruzioni_Raccolta_Segni_presenza.pdf'
                      : 'https://www.parcoantola.it/pagina.php?id=31',
                ),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Approfondisci i segni di presenza'),
            ),
            const Text(
              'Non toccare o raccogliere escrementi. Fotografa sul posto con un riferimento metrico, senza spostarli.',
            ),
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
    } else if (type == 'cinque_dita' || type == 'roditore') {
      final n = type == 'roditore' ? 4 : 5;
      for (var i = 0; i < n; i++) {
        final x = 20.0 + i * (90 / (n - 1));
        final y = 25.0 + (i - (n - 1) / 2).abs() * 10;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 15, height: 23),
          fill,
        );
        canvas.drawLine(
          Offset(x, y - 14),
          Offset(x, y - 24),
          Paint()
            ..color = color
            ..strokeWidth = 3,
        );
      }
      canvas.drawOval(const Rect.fromLTWH(29, 65, 72, 59), fill);
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

/// Local vector artwork: each catalogue species has its own identifying features.
class SpeciesIcon extends StatelessWidget {
  const SpeciesIcon(this.species, {super.key, this.size = 44});
  final String species;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: species.isEmpty ? 'Specie non identificata' : species,
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: SpeciesIconPainter(species)),
    ),
  );
}

class SpeciesIconPainter extends CustomPainter {
  const SpeciesIconPainter(this.species);
  final String species;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    const ink = Color(0xFF25352D);
    const cream = Color(0xFFF5EBD4);
    const brown = Color(0xFF986A43);
    const grey = Color(0xFF87938C);
    void oval(double x, double y, double w, double h, Color color) =>
        canvas.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
    void shape(List<Offset> points, Color color) {
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(path, Paint()..color = color);
    }

    void line(List<Offset> points, Color color, [double width = 3]) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    void eyes([double y = 35]) {
      oval(23, y, 4, 4, ink);
      oval(37, y, 4, 4, ink);
    }

    canvas.drawCircle(
      const Offset(32, 32),
      31,
      Paint()..color = const Color(0xFFE8EDD9),
    );
    final name = species.trim().toLowerCase();
    final canonical =
        animals
            .where(
              (a) =>
                  a.name.toLowerCase() == name || a.latin.toLowerCase() == name,
            )
            .firstOrNull
            ?.name ??
        species;
    switch (canonical) {
      case 'Cervo':
      case 'Capriolo':
        final deer = canonical == 'Cervo';
        for (final flip in [false, true]) {
          canvas.save();
          if (flip) {
            canvas.translate(64, 0);
            canvas.scale(-1, 1);
          }
          line(
            [
              const Offset(26, 29),
              Offset(deer ? 19 : 24, 18),
              Offset(deer ? 15 : 23, 5),
            ],
            brown,
            deer ? 3 : 2,
          );
          line(
            [Offset(deer ? 19 : 24, 18), Offset(deer ? 9 : 18, deer ? 14 : 12)],
            brown,
            2,
          );
          if (deer) {
            line([const Offset(17, 12), const Offset(24, 7)], brown, 2);
          }
          oval(11, 25, 15, 8, brown);
          canvas.restore();
        }
        oval(deer ? 22 : 20, 26, deer ? 20 : 24, deer ? 31 : 26, brown);
        oval(26, 43, 12, 12, cream);
        eyes(35);
        oval(29, 46, 6, 5, ink);
      case 'Volpe':
        shape(const [
          Offset(14, 12),
          Offset(30, 24),
          Offset(48, 12),
          Offset(50, 37),
          Offset(32, 56),
          Offset(12, 37),
        ], const Color(0xFFD37432));
        shape(const [
          Offset(16, 34),
          Offset(32, 46),
          Offset(48, 34),
          Offset(32, 55),
        ], cream);
        eyes(31);
        oval(29, 46, 6, 5, ink);
      case 'Camoscio alpino':
      case 'Stambecco':
        final ibex = canonical == 'Stambecco';
        for (final flip in [false, true]) {
          canvas.save();
          if (flip) {
            canvas.translate(64, 0);
            canvas.scale(-1, 1);
          }
          if (ibex) {
            line(
              const [
                Offset(25, 29),
                Offset(17, 21),
                Offset(12, 12),
                Offset(15, 6),
                Offset(22, 7),
              ],
              brown,
              6,
            );
            for (final y in [11.0, 16.0, 21.0]) {
              line(
                [
                  Offset(12 + (y - 11) / 2, y),
                  Offset(17 + (y - 11) / 2, y - 2),
                ],
                cream,
                1.5,
              );
            }
          } else {
            line(
              const [
                Offset(26, 27),
                Offset(25, 9),
                Offset(20, 7),
                Offset(18, 12),
              ],
              ink,
              3,
            );
          }
          oval(12, 26, 14, 7, brown);
          canvas.restore();
        }
        oval(21, 25, 23, 30, ibex ? brown : cream);
        if (!ibex) {
          line(const [Offset(23, 29), Offset(24, 40), Offset(29, 47)], ink, 4);
          line(const [Offset(41, 29), Offset(40, 40), Offset(35, 47)], ink, 4);
        }
        if (ibex) {
          shape(const [Offset(27, 50), Offset(32, 61), Offset(37, 50)], ink);
        }
        eyes(34);
        oval(28, 46, 8, 5, ink);
      case 'Cinghiale':
        oval(12, 19, 40, 34, const Color(0xFF62554B));
        shape(const [Offset(14, 27), Offset(13, 12), Offset(26, 21)], ink);
        shape(const [Offset(38, 21), Offset(51, 12), Offset(50, 27)], ink);
        oval(21, 37, 22, 16, brown);
        eyes(29);
        oval(26, 42, 4, 5, ink);
        oval(35, 42, 4, 5, ink);
        shape(const [Offset(19, 48), Offset(16, 37), Offset(25, 47)], cream);
        shape(const [Offset(45, 48), Offset(48, 37), Offset(39, 47)], cream);
      case 'Allocco':
        oval(13, 13, 38, 43, brown);
        oval(17, 20, 17, 25, cream);
        oval(31, 20, 17, 25, cream);
        oval(22, 27, 7, 9, ink);
        oval(36, 27, 7, 9, ink);
        shape(const [
          Offset(28, 38),
          Offset(36, 38),
          Offset(32, 46),
        ], const Color(0xFFB99A4A));
      case 'Picchio nero':
        oval(19, 22, 24, 33, ink);
        oval(24, 13, 20, 22, ink);
        shape(const [
          Offset(24, 17),
          Offset(30, 8),
          Offset(43, 17),
        ], const Color(0xFFC34739));
        shape(const [Offset(41, 21), Offset(58, 25), Offset(41, 28)], grey);
        oval(36, 20, 3, 3, cream);
        line(const [Offset(19, 42), Offset(11, 58), Offset(29, 49)], ink, 4);
      case 'Airone cenerino':
        oval(12, 35, 29, 15, grey);
        line(const [Offset(36, 41), Offset(29, 28), Offset(38, 17)], cream, 7);
        oval(33, 11, 14, 10, grey);
        shape(const [
          Offset(45, 14),
          Offset(61, 19),
          Offset(44, 20),
        ], const Color(0xFFC79739));
        line(const [Offset(35, 13), Offset(26, 12)], ink, 2);
        oval(41, 14, 2, 2, ink);
        line(const [Offset(22, 47), Offset(21, 59)], ink, 2);
        line(const [Offset(31, 47), Offset(34, 59)], ink, 2);
      case 'Germano reale':
        oval(9, 32, 40, 22, grey);
        oval(34, 14, 18, 23, const Color(0xFF327257));
        line(const [Offset(36, 34), Offset(48, 34)], cream, 3);
        shape(const [
          Offset(49, 24),
          Offset(61, 26),
          Offset(59, 31),
          Offset(49, 31),
        ], const Color(0xFFD4A132));
        oval(44, 21, 3, 3, ink);
        oval(21, 38, 18, 9, brown);
      case 'Grifone':
        oval(11, 31, 39, 24, brown);
        line(const [Offset(38, 38), Offset(32, 23), Offset(36, 13)], cream, 10);
        oval(30, 9, 15, 14, cream);
        shape(const [
          Offset(43, 14),
          Offset(53, 19),
          Offset(47, 25),
          Offset(44, 20),
        ], ink);
        oval(38, 13, 3, 3, ink);
        line(const [Offset(25, 33), Offset(33, 38), Offset(43, 33)], cream, 5);
      case 'Aquila reale':
        shape(const [
          Offset(8, 48),
          Offset(19, 30),
          Offset(24, 12),
          Offset(42, 12),
          Offset(46, 35),
          Offset(53, 54),
        ], brown);
        shape(const [
          Offset(23, 17),
          Offset(19, 31),
          Offset(32, 35),
          Offset(35, 19),
        ], const Color(0xFFC7A35A));
        shape(const [
          Offset(40, 21),
          Offset(56, 27),
          Offset(49, 35),
          Offset(48, 29),
          Offset(39, 29),
        ], ink);
        line(const [Offset(32, 19), Offset(42, 21)], ink, 3);
        oval(37, 23, 3, 3, cream);
      case 'Poiana':
        oval(16, 23, 32, 32, brown);
        oval(23, 11, 23, 25, brown);
        oval(26, 31, 15, 20, cream);
        for (final y in [35.0, 41.0, 47.0]) {
          line([Offset(29, y), Offset(37, y + 1)], brown, 2);
        }
        shape(const [Offset(43, 21), Offset(54, 25), Offset(46, 30)], ink);
        oval(37, 19, 3, 3, ink);
      case 'Falco di palude':
        shape(const [
          Offset(31, 33),
          Offset(4, 13),
          Offset(10, 34),
          Offset(27, 42),
          Offset(24, 57),
          Offset(39, 57),
          Offset(36, 42),
          Offset(54, 32),
          Offset(60, 10),
          Offset(34, 33),
        ], brown);
        shape(const [
          Offset(4, 13),
          Offset(10, 34),
          Offset(18, 37),
          Offset(12, 21),
        ], ink);
        shape(const [
          Offset(60, 10),
          Offset(54, 32),
          Offset(46, 36),
          Offset(51, 21),
        ], ink);
        oval(27, 24, 10, 13, cream);
        oval(31, 27, 2, 2, ink);
      case 'Orso bruno':
        oval(10, 10, 17, 18, brown);
        oval(37, 10, 17, 18, brown);
        oval(14, 14, 9, 10, cream);
        oval(41, 14, 9, 10, cream);
        oval(11, 17, 42, 39, brown);
        oval(21, 35, 22, 19, cream);
        eyes(29);
        oval(27, 37, 10, 7, ink);
        line(const [Offset(32, 44), Offset(32, 49)], ink, 2);
      case 'Lupo':
        shape(const [
          Offset(13, 8),
          Offset(29, 21),
          Offset(35, 21),
          Offset(51, 8),
          Offset(49, 29),
          Offset(57, 41),
          Offset(43, 46),
          Offset(32, 58),
          Offset(21, 46),
          Offset(7, 41),
          Offset(15, 29),
        ], grey);
        shape(const [Offset(17, 16), Offset(24, 23), Offset(17, 26)], ink);
        shape(const [Offset(47, 16), Offset(40, 23), Offset(47, 26)], ink);
        shape(const [
          Offset(18, 37),
          Offset(28, 40),
          Offset(32, 33),
          Offset(36, 40),
          Offset(46, 37),
          Offset(32, 54),
        ], cream);
        line(const [Offset(21, 31), Offset(27, 33)], ink, 3);
        line(const [Offset(37, 33), Offset(43, 31)], ink, 3);
        oval(28, 45, 8, 6, ink);
      case 'Sciacallo dorato':
        shape(const [
          Offset(17, 31),
          Offset(15, 5),
          Offset(29, 22),
          Offset(36, 22),
          Offset(49, 5),
          Offset(47, 33),
          Offset(43, 44),
          Offset(32, 57),
          Offset(21, 44),
        ], const Color(0xFFC19A55));
        shape(const [Offset(19, 15), Offset(25, 25), Offset(19, 27)], brown);
        shape(const [Offset(45, 15), Offset(39, 25), Offset(45, 27)], brown);
        shape(const [
          Offset(24, 38),
          Offset(32, 43),
          Offset(40, 38),
          Offset(32, 54),
        ], cream);
        eyes(31);
        oval(29, 46, 6, 5, ink);
      case 'Marmotta':
        oval(13, 17, 10, 12, brown);
        oval(41, 17, 10, 12, brown);
        oval(13, 21, 38, 37, const Color(0xFFAD865D));
        oval(21, 37, 22, 17, cream);
        eyes(31);
        oval(28, 38, 8, 5, ink);
        shape(const [
          Offset(27, 46),
          Offset(37, 46),
          Offset(36, 54),
          Offset(28, 54),
        ], cream);
        line(const [Offset(32, 46), Offset(32, 53)], brown, 1.5);
        line(const [Offset(16, 43), Offset(23, 44)], brown, 2);
        line(const [Offset(41, 44), Offset(48, 43)], brown, 2);
      case 'Ermellino':
        line(
          const [
            Offset(41, 49),
            Offset(51, 46),
            Offset(55, 32),
            Offset(51, 23),
          ],
          cream,
          7,
        );
        line(const [Offset(55, 32), Offset(51, 23)], ink, 7);
        oval(19, 30, 23, 29, cream);
        oval(13, 13, 10, 12, cream);
        oval(34, 13, 10, 12, cream);
        oval(15, 16, 6, 7, brown);
        oval(36, 16, 6, 7, brown);
        oval(14, 19, 29, 22, cream);
        oval(21, 26, 3, 3, ink);
        oval(33, 26, 3, 3, ink);
        oval(26, 33, 6, 4, ink);
      case 'Tasso':
        oval(12, 12, 12, 14, grey);
        oval(40, 12, 12, 14, grey);
        shape(const [
          Offset(18, 20),
          Offset(32, 15),
          Offset(46, 20),
          Offset(50, 37),
          Offset(36, 55),
          Offset(28, 55),
          Offset(14, 37),
        ], cream);
        shape(const [
          Offset(20, 20),
          Offset(28, 22),
          Offset(26, 34),
          Offset(30, 48),
          Offset(19, 38),
        ], ink);
        shape(const [
          Offset(44, 20),
          Offset(36, 22),
          Offset(38, 34),
          Offset(34, 48),
          Offset(45, 38),
        ], ink);
        oval(22, 29, 3, 3, cream);
        oval(39, 29, 3, 3, cream);
        oval(27, 47, 10, 7, ink);
      case 'Gracchio alpino':
        oval(14, 29, 33, 24, ink);
        oval(33, 14, 18, 20, ink);
        shape(const [
          Offset(48, 22),
          Offset(60, 24),
          Offset(58, 28),
          Offset(48, 28),
        ], const Color(0xFFE6BE35));
        shape(const [Offset(17, 40), Offset(4, 53), Offset(25, 49)], ink);
        oval(43, 20, 3, 3, cream);
        line(
          const [Offset(28, 51), Offset(25, 59)],
          const Color(0xFFB34E35),
          2,
        );
        line(
          const [Offset(38, 51), Offset(37, 59)],
          const Color(0xFFB34E35),
          2,
        );
      case 'Gufo reale':
        shape(const [
          Offset(13, 5),
          Offset(28, 18),
          Offset(36, 18),
          Offset(51, 5),
          Offset(48, 32),
          Offset(16, 32),
        ], brown);
        oval(13, 19, 38, 38, brown);
        oval(17, 23, 15, 18, cream);
        oval(32, 23, 15, 18, cream);
        oval(21, 27, 9, 10, const Color(0xFFE4942C));
        oval(34, 27, 9, 10, const Color(0xFFE4942C));
        oval(24, 29, 4, 6, ink);
        oval(36, 29, 4, 6, ink);
        shape(const [Offset(29, 39), Offset(35, 39), Offset(32, 45)], ink);
        line(const [Offset(23, 46), Offset(25, 52)], cream, 2);
        line(const [Offset(40, 46), Offset(38, 52)], cream, 2);
      case 'Barbagianni':
        oval(13, 10, 38, 47, const Color(0xFFBFA16F));
        oval(16, 15, 19, 23, cream);
        oval(29, 15, 19, 23, cream);
        shape(const [
          Offset(16, 28),
          Offset(48, 28),
          Offset(44, 41),
          Offset(32, 52),
          Offset(20, 41),
        ], cream);
        oval(22, 26, 6, 8, ink);
        oval(36, 26, 6, 8, ink);
        shape(const [Offset(29, 37), Offset(35, 37), Offset(32, 44)], brown);
      case 'Ghiandaia':
        oval(12, 30, 35, 23, const Color(0xFFBD8A76));
        oval(32, 14, 18, 23, const Color(0xFFBD8A76));
        shape(const [Offset(32, 19), Offset(34, 7), Offset(41, 16)], cream);
        shape(const [Offset(47, 23), Offset(59, 27), Offset(47, 30)], ink);
        line(const [Offset(43, 29), Offset(41, 36)], ink, 3);
        oval(43, 20, 3, 3, ink);
        oval(19, 36, 18, 12, const Color(0xFF5798C0));
        for (final x in [23.0, 28.0, 33.0]) {
          line([Offset(x, 38), Offset(x - 2, 45)], ink, 2);
        }
        shape(const [Offset(16, 43), Offset(5, 55), Offset(23, 50)], ink);
      default:
        // Unknown records have no assigned animal silhouette.
        oval(29, 15, 6, 6, ink);
        line(const [Offset(32, 28), Offset(32, 47)], ink, 4);
    }
  }

  @override
  bool shouldRepaint(covariant SpeciesIconPainter oldDelegate) =>
      oldDelegate.species != species;
}

String scatDescription(String name, String group) => switch (name) {
  'Orso bruno' => 'Aspetto molto variabile con la dieta: resti vegetali, semi o parti animali. La forma non basta per un’attribuzione certa.',
  'Lupo' || 'Sciacallo dorato' || 'Volpe' => 'Fatte spesso allungate, con peli, frammenti o semi secondo la dieta. Le sovrapposizioni fra canidi impediscono identificazioni certe dalla sola forma; per il lupo può servire l’analisi genetica.',
  'Tasso' => 'Può deporre le fatte in piccole buche utilizzate come latrine. Consistenza e colore dipendono dal cibo; considera l’insieme dei segni.',
  'Ermellino' => 'Piccole fatte allungate, talvolta con peli. Dimensioni e contenuto non escludono altri mustelidi.',
  'Lepre' => 'Pellet tondeggianti e fibrosi; verifica insieme alla pista e non confondere con il coniglio.',
  'Scoiattolo' => 'Piccoli elementi allungati; valuta pigne e noci rosicchiate e habitat.',
  'Marmotta' => 'Fatte di erbivoro con residui vegetali, spesso in punti abituali. Valuta insieme alle impronte e all’habitat.',
  'Cervo' || 'Capriolo' || 'Camoscio alpino' || 'Stambecco' => 'Pellet o gruppi di elementi vegetali; umidità e alimentazione ne modificano la forma. Non distinguere specie simili soltanto dalle dimensioni.',
  'Cinghiale' => 'Aspetto variabile, spesso aggregato o segmentato; dieta onnivora. Cerca anche grufolate, senza entrare nei rifugi.',
  'Gufo reale' || 'Barbagianni' || 'Allocco' || 'Assiolo' => 'Le borre sono rigurgiti di peli, ossa o altri resti e non escrementi. Non avvicinarti ai posatoi occupati o ai nidi.',
  _ =>
    group == 'Mammiferi'
        ? 'Annota forma e contesto: una singola fatta non permette sempre di determinare la specie.'
        : 'Deiezioni con componente bianca di urati. Non identificare la specie soltanto da queste; anche penne e borre richiedono confronto esperto.',
};

