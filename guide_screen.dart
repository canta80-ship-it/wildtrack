import 'premium_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const fieldGuide = <String, List<(String, String)>>{
  'Osservare': [
    (
      'Prima guarda, poi avanza',
      'Fermati, ascolta e osserva i margini del bosco, le radure e gli specchi d’acqua. Muoviti lentamente, parla sottovoce e resta sui percorsi consentiti. Non inseguire un animale per ottenere una foto.',
    ),
    (
      'La distanza la decide l’animale',
      'Se interrompe l’alimentazione, ti fissa a lungo, emette allarmi o si allontana, arretra. Non esiste una distanza universale sicura: specie, piccoli, stagione e luogo cambiano la risposta.',
    ),
    (
      'Scegli ambiente e momento',
      'Alba e tramonto sono spesso favorevoli ai mammiferi; molti uccelli sono attivi al mattino. I rapaci che sfruttano le correnti ascensionali possono essere più visibili nelle ore calde. Le condizioni locali contano più di una regola fissa.',
    ),
    (
      'Nidi, tane e piccoli',
      'Non avvicinarti, non toccare i piccoli e non pubblicare la posizione precisa di un nido o di una tana. Un piccolo solo non è necessariamente abbandonato. Per un animale evidentemente ferito contatta il centro recupero fauna competente.',
    ),
    (
      'Lascia tutto com’è',
      'Non offrire cibo, non usare esche e non raccogliere animali o vegetazione. Porta via ogni rifiuto; tieni il cane al guinzaglio dove ammesso. Rispetta divieti, proprietà e chiusure stagionali.',
    ),
    (
      'Versi per imparare',
      'Ascolta preferibilmente in cuffia. Evita di riprodurre versi per attirare la fauna, soprattutto presso nidi, dormitori e durante la riproduzione. Il limite di cinque ripetizioni non rende innocuo un richiamo sul campo.',
    ),
  ],
  'Abbigliamento': [
    (
      'Il sistema a strati',
      'Primo strato traspirante, strato isolante e guscio contro vento e pioggia. Regola gli strati mentre cammini; aggiungi isolamento quando ti fermi. Durante un appostamento ci si raffredda più che in movimento.',
    ),
    (
      'Primavera',
      'Pantaloni lunghi leggeri, scarpe adatte a fango e fondo bagnato, pile e guscio nello zaino. Porta un ricambio asciutto. Preparati a escursioni termiche e piogge improvvise.',
    ),
    (
      'Estate',
      'Tessuti leggeri e traspiranti, cappello e protezione dal sole. Pantaloni lunghi aiutano contro vegetazione e insetti. In quota tieni comunque nello zaino uno strato caldo e impermeabile.',
    ),
    (
      'Autunno',
      'Strato termico, pile o giacca isolante per le soste, guscio e calzature con buona aderenza. Guanti sottili e berretto sono utili alle prime e ultime ore. Foglie bagnate e giornate corte richiedono attenzione.',
    ),
    (
      'Inverno',
      'Base termica, isolamento adeguato, guscio, berretto, guanti e ricambio asciutto. Proteggi mani e piedi durante le attese. Neve e ghiaccio richiedono itinerari, competenze e attrezzatura specifici: i ramponcini non sostituiscono i ramponi nei terreni alpinistici.',
    ),
    (
      'Colori e rumore',
      'Preferisci tinte sobrie e tessuti poco fruscianti per osservare, senza sacrificare la visibilità quando serve per la sicurezza. Porta un elemento ben visibile per emergenze. Non è necessario un abbigliamento mimetico completo.',
    ),
  ],
  'Strumenti': [
    (
      'Binocolo',
      'Un 8×32 è compatto; un 8×42 offre un buon compromesso per osservare a mano libera. Il 10× ingrandisce di più ma rende più evidente il tremolio. Prova presa, peso, distanza interpupillare e comfort con gli occhiali prima di acquistare.',
    ),
    (
      'Cannocchiale',
      'Utile per uccelli acquatici e animali lontani da postazioni fisse. Serve un supporto stabile. Più ingrandimento non elimina foschia, turbolenza atmosferica o ostacoli.',
    ),
    (
      'Fotocamera e teleobiettivo',
      'Usa la focale per mantenere la distanza, non per giustificare un avvicinamento. Per soggetti lontani un tele aiuta; peso, stabilizzazione e luce disponibile contano quanto i millimetri. Non esiste un obiettivo universale.',
    ),
    (
      'Supporti e protezione',
      'Monopiede o treppiede aiutano nelle lunghe attese. Porta panno per lenti, copertura antipioggia, scheda e batteria di riserva. Evita di appoggiare l’attrezzatura su muschio, nidi o vegetazione fragile.',
    ),
    (
      'Appunti utili',
      'Registra specie, numero, data, ambiente e comportamento. Se l’identificazione è incerta, dichiaralo; descrivi ciò che hai visto senza trasformarlo in certezza. Una foto di contesto può essere più utile di un ritaglio estremo.',
    ),
  ],
  'Fotografare': [
    (
      'Metti a fuoco l’occhio',
      'Usa autofocus continuo e riconoscimento animali, se disponibili. Se rami o erba confondono il sistema, prova un’area AF più piccola. Controlla il risultato ingrandito senza perdere di vista ciò che succede intorno.',
    ),
    (
      'Tempi di partenza',
      'Come prova iniziale: circa 1/500 s per un soggetto abbastanza fermo, 1/1000 s per movimento moderato, 1/2000 s o più rapido per il volo. Non sono garanzie: velocità, focale, distanza e luce richiedono aggiustamenti.',
    ),
    (
      'Luce e ISO',
      'Con poca luce è spesso meglio aumentare gli ISO che ottenere mosso. Proteggi le alte luci, controlla l’istogramma e prova RAW se vuoi margine in sviluppo. La stabilizzazione riduce il tremolio della mano, non ferma il movimento dell’animale.',
    ),
    (
      'Scatto discreto',
      'Disattiva suoni inutili e flash verso la fauna. L’otturatore elettronico può deformare soggetti molto rapidi: confrontalo con quello meccanico quando presente. Usa raffiche brevi e controllate.',
    ),
    (
      'Composizione ed editing',
      'Cerca sfondi puliti, spazio davanti allo sguardo e comportamenti naturali. Recupera dettaglio con moderazione: nitidezza e riduzione del rumore non ricreano informazioni assenti. Una foto ambientata può raccontare più di un primo piano.',
    ),
  ],
  'Prepararsi': [
    (
      'Prima di partire',
      'Controlla meteo ufficiale, accessi, difficoltà, tempi, quota e luce residua. Comunica a una persona itinerario e orario di rientro. Prevedi un’alternativa breve e rinuncia se le condizioni peggiorano.',
    ),
    (
      'Telefono e orientamento',
      'Porta una power bank e una cartografia utilizzabile senza rete. La mappa online di WildTrack non sostituisce una mappa offline. Il GPS può funzionare senza Internet, ma ottenere una posizione può richiedere tempo e una buona vista del cielo.',
    ),
    (
      'Nello zaino',
      'Acqua e cibo adeguati, guscio, strato caldo, ricambio, torcia frontale, telefono carico, piccolo kit di primo soccorso e sacchetto per i rifiuti. Dimensiona il materiale sulle condizioni e sulla durata prevista.',
    ),
    (
      'Emergenza',
      'In Italia chiama il 112. Indica cosa è successo, quante persone sono coinvolte, coordinate e condizioni del luogo; segui l’operatore. WildTrack mostra le coordinate ma non le trasmette automaticamente ai soccorsi e non garantisce una chiamata senza copertura.',
    ),
    (
      'Segnalazioni responsabili',
      'Pubblica solo ciò che vuoi condividere. Evita volti, targhe, abitazioni e dettagli personali nelle foto o nelle note. Per fauna sensibile usa una posizione approssimata e non divulgare siti riproduttivi.',
    ),
  ],
};

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});
  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final checked = <String>{};
  @override
  Widget build(BuildContext context) => PremiumScaffold(
    appBar: AppBar(title: const Text('Guida sul campo')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PremiumHeading(
          'Osservare senza lasciare traccia.',
          eyebrow: 'Guida sul campo',
        ),
        const Text(
          'Osservare senza lasciare traccia',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Testi disponibili anche senza connessione. Adatta sempre i consigli a luogo, stagione e condizioni reali.',
          ),
        ),
        for (final section in fieldGuide.entries)
          Card(
            child: ExpansionTile(
              title: Text(
                section.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                for (final item in section.value)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(item.$2),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Card(
          child: ExpansionTile(
            title: const Text('Checklist prima di uscire'),
            children: [
              for (final item in [
                'Meteo, accessi e percorso controllati',
                'Itinerario e rientro comunicati',
                'Acqua e cibo',
                'Strato caldo, guscio e ricambio',
                'Telefono, power bank e mappa offline',
                'Frontale e kit di primo soccorso',
                'Binocolo, batterie e schede',
                'Sacchetto per i rifiuti',
              ])
                CheckboxListTile(
                  value: checked.contains(item),
                  title: Text(item),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      checked.add(item);
                    } else {
                      checked.remove(item);
                    }
                  }),
                ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Checklist della sessione: si azzera riaprendo questa pagina.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Approfondimenti',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        for (final source in [
          (
            'CAI · Preparare un’escursione',
            'https://archivio.cai.it/andare-in-montagna/escursionismo/',
          ),
          (
            'LIPU · Osservare gli uccelli',
            'https://www.lipu.it/news/10-consigli-divertirsi-estate-birdwatching',
          ),
          (
            'Soccorso Alpino · Richiesta di soccorso',
            'https://cnsas.sardegna.it/la-richiesta-di-soccorso/',
          ),
        ])
          ListTile(
            title: Text(source.$1),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              try {
                final ok = await launchUrl(
                  Uri.parse(source.$2),
                  mode: LaunchMode.externalApplication,
                );
                if (!ok) throw Exception();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Impossibile aprire la fonte. Verifica la connessione.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
      ],
    ),
  );
}
