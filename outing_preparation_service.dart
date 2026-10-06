import 'dart:convert';
import '../screens/species_detail_screen.dart';
import 'radar_profile_service.dart';

enum OutingSeason { primavera,estate,autunno,inverno }
extension OutingSeasonName on OutingSeason {
  String get label=>switch(this){OutingSeason.primavera=>'Primavera',OutingSeason.estate=>'Estate',OutingSeason.autunno=>'Autunno',OutingSeason.inverno=>'Inverno'};
  static OutingSeason at(DateTime d)=>d.month>=3&&d.month<=5?OutingSeason.primavera:d.month>=6&&d.month<=8?OutingSeason.estate:d.month>=9&&d.month<=11?OutingSeason.autunno:OutingSeason.inverno;
}
enum OutingActivity { osservazione,fotografia,ascolto,escursione }
extension OutingActivityName on OutingActivity {
  String get label=>switch(this){OutingActivity.osservazione=>'Osservazione',OutingActivity.fotografia=>'Fotografia',OutingActivity.ascolto=>'Ascolto',OutingActivity.escursione=>'Escursione'};
}
class PreparationItem {
  const PreparationItem(this.id,this.title,this.detail,this.section);
  final String id,title,detail,section;
}
class PreparationPlan {
  const PreparationPlan(this.species,this.season,this.activity,this.items,this.seasonNote,this.bestPeriod);
  final String species,seasonNote,bestPeriod;
  final OutingSeason season;final OutingActivity activity;
  final List<PreparationItem> items;
  String get key=>jsonEncode([species,season.name,activity.name]);
}
class OutingPreparationService {
  static PreparationPlan build({required String species,required OutingSeason season,required OutingActivity activity}) {
    final d=speciesDetails[species],p=radarProfiles[species];
    if(d==null||p==null)throw ArgumentError('Specie non presente nel catalogo');
    final items=<PreparationItem>[
      const PreparationItem('weather','Meteo e avvisi locali','Controlla pioggia, vento, temperatura e condizioni del percorso prima di partire.','Prima di partire'),
      const PreparationItem('route','Percorso e rientro','Definisci un percorso praticabile, un orario di rientro e condividi il programma con una persona fidata.','Prima di partire'),
      const PreparationItem('phone','Telefono carico e riserva','Carica telefono e power bank; verifica che la posizione funzioni.','Attrezzatura'),
      const PreparationItem('water','Acqua e cibo','Prepara quantità adeguate a durata, temperatura e dislivello.','Attrezzatura'),
      const PreparationItem('shoes','Scarpe e strati adatti','Scegli scarpe, protezione dalla pioggia e abbigliamento per il terreno.','Attrezzatura'),
      const PreparationItem('return_point','Salva il punto di partenza','In “Torna al mio punto” salva auto o bivio prima di allontanarti.','Prima di partire'),
      PreparationItem('species_habitat','Ambiente adatto a $species','Controlla gli habitat della scheda: ${d.tags.join(', ')}.','Specie e stagione'),
      PreparationItem('species_season','Periodo e presenza locale','${d.seasons[season.index]} Non è una garanzia di incontro.','Specie e stagione'),
      const PreparationItem('respect','Distanza e rispetto','Non inseguire animali, non avvicinarti a nidi o tane e lascia i reperti sul posto.','Sul campo'),
    ];
    if(d.seasonLevels[season.index]<=1)items.add(const PreparationItem('low_season','Verifica la presenza in questa stagione','Il periodo è poco favorevole: controlla segnalazioni e indicazioni locali prima di dedicare l’uscita a questa specie.','Specie e stagione'));
    switch(season) {
      case OutingSeason.estate:items.add(const PreparationItem('heat','Protezione dal caldo','Prepara cappello e protezione solare; valuta ore fresche e disponibilità d’acqua.','Specie e stagione'));
      case OutingSeason.inverno:items.add(const PreparationItem('winter','Freddo, neve e ore di luce','Valuta ghiaccio, neve e condizioni locali; scegli un itinerario compatibile con preparazione e attrezzatura.','Specie e stagione'));
      case OutingSeason.primavera:items.add(const PreparationItem('spring','Rispetta la riproduzione','Evita soste presso nidi, tane e piccoli; osserva da lontano.','Specie e stagione'));
      case OutingSeason.autunno:items.add(const PreparationItem('autumn','Luce e condizioni autunnali','Pianifica il rientro prima del buio e considera terreno bagnato e giornate più corte.','Specie e stagione'));
    }
    if(p.cycle=='nocturnal'||p.cycle=='crepuscular'||activity==OutingActivity.ascolto)items.add(const PreparationItem('light','Torcia e batterie','Porta una luce per il rientro; limita l’illuminazione verso la fauna.','Attrezzatura'));
    switch(activity) {
      case OutingActivity.fotografia:
        items.addAll([const PreparationItem('camera','Fotocamera, batterie e schede','Verifica carica, spazio e funzionamento prima di partire.','Fotografia'),PreparationItem('photo_settings','Preparazione fotografica per $species',d.photo,'Fotografia'),const PreparationItem('lens','Ottica e supporto','Prepara un’ottica adatta alla distanza; evita flash verso gli animali.','Fotografia')]);
      case OutingActivity.ascolto:
        items.addAll([const PreparationItem('quiet','Ascolto passivo e silenzio','Silenzia telefono e notifiche; ascolta senza playback o richiami.','Ascolto'),PreparationItem('voice','Riconosci il verso prima di uscire',d.voiceDescription.isEmpty?'Consulta la sezione Versi della scheda di $species.':d.voiceDescription,'Ascolto')]);
      case OutingActivity.osservazione:
        items.add(const PreparationItem('binoculars','Binocolo e appunti','Prepara strumenti per osservare a distanza e annotare ciò che hai realmente visto.','Osservazione'));
      case OutingActivity.escursione:
        items.addAll([const PreparationItem('map','Mappa utilizzabile senza rete','Verifica prima della partenza che la cartografia necessaria sia disponibile senza connessione.','Escursione'),const PreparationItem('kit','Kit personale e piano alternativo','Prepara il necessario per l’itinerario e un’alternativa in caso di meteo o terreno sfavorevoli.','Escursione')]);
    }
    return PreparationPlan(species,season,activity,List.unmodifiable(items),d.seasons[season.index],d.bestPeriod.isEmpty?d.activity:d.bestPeriod);
  }
}
