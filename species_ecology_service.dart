/// Primary habitat sources checked 2026-10-05. Numeric bands describe typical
/// habitat use, not absolute distribution limits or encounter probabilities.
class SpeciesEcology {
 const SpeciesEcology(this.habitat,this.source,this.altitudeNote,{this.minimum,this.maximum});
 final String habitat,source,altitudeNote;
 final double? minimum,maximum;
 bool outside(double altitude)=>minimum!=null&&altitude<minimum! || maximum!=null&&altitude>maximum!;
}
const speciesEcology=<String,SpeciesEcology>{
"Riccio": SpeciesEcology("Siepi, margini boschivi, prati, giardini e parchi con vegetazione e passaggi fra aree verdi.","https://parcoabruzzo.it/fauna.schede.dettaglio.php?id=291","Pianura e collina; conta la continuità degli spazi verdi"),
"Gallo cedrone": SpeciesEcology("Foreste montane mature e strutturate di Alpi e Prealpi, con radure e sottobosco; la presenza è localizzata.","https://www.lipu.it/uccelli/conoscerli-proteggerli/gallo-cedrone","Fascia montana tipica, non limite assoluto",minimum:700,maximum:2200),
"Gallo forcello": SpeciesEcology("Mosaico alpino al limite del bosco: arbusti, radure, prati e alberi sparsi, in zone poco disturbate.","https://www.lipu.it/uccelli/conoscerli-proteggerli/fagiano-monte","Fascia montana tipica, non limite assoluto",minimum:700,maximum:2900),
"Lince": SpeciesEcology("Boschi con copertura vegetale e versanti rocciosi","https://www.kora.ch/en/species/lynx/profile","Nessun intervallo altitudinale universale nella fonte"),
"Tritone": SpeciesEcology("Stagni e pozze, anche in boschi e giardini; rifugi terrestri umidi","https://www.infofauna.ch/it/servizio-di-consulenza/anfibi-karch/gli-anfibi/specie/tritone-alpino","Presente sia in pianura sia in montagna; la quota non sostituisce uno stagno"),
"Rospo": SpeciesEcology("Boschi, giardini e ambienti aperti; laghi e stagni per riprodursi","https://www.infofauna.ch/it/servizio-di-consulenza/anfibi-karch/gli-anfibi/specie/rospo-comune","Quota variabile; contano rifugi terrestri e acqua riproduttiva"),
"Salamandra": SpeciesEcology("Boschi freschi e umidi; ruscelli forestali e sorgenti per le larve","https://www.infofauna.ch/it/servizio-di-consulenza/anfibi-karch/gli-anfibi/specie/salamandra-pezzata","Le quote riportate per la Svizzera non sono un limite italiano"),
"Cervo": SpeciesEcology("Boschi con radure e praterie; fondovalle in inverno","https://www.parcoabruzzo.it/fauna.schede.dettaglio.php?id=313","Dalle basse quote a circa 2500 m, secondo il Parco Abruzzo",minimum:0,maximum:2500),
"Capriolo": SpeciesEcology("Boschi di latifoglie alternati a prati e campi","https://ambiente.regione.emilia-romagna.it/it/parchi-natura2000/sistema-regionale/fauna/mammiferi/schede/capriolo-1","Pianura, collina e montagna"),
"Volpe": SpeciesEcology("Boschi, prati, campagne e zone antropizzate","https://www.parcoabruzzo.it/fauna.schede.dettaglio.php?id=314","Ampia adattabilità; nessun limite numerico uniforme nella fonte"),
"Camoscio alpino": SpeciesEcology("Praterie montane, pareti rocciose e boschi di versante","https://www.parchialpicozie.it/it/parcopedia/camoscio/","Quote tipiche 1000–3500 m; possibili discese al fondovalle",minimum:1000,maximum:3500),
"Stambecco": SpeciesEcology("Praterie alpine e pareti rocciose","https://www.pngp.it/natura-e-ricerca/fauna/praterie-e-ambienti-rocciosi/lo-stambecco","Alta quota, con discesa ai prati di fondovalle in primavera"),
"Cinghiale": SpeciesEcology("Boschi di querce e faggete, con copertura e acqua","https://www.gransassolagapark.it/pagina.php?id=261","Può frequentare anche boschi montani"),
"Aquila reale": SpeciesEcology("Pareti rocciose e prati aperti per cacciare","https://www.lipu.it/uccelli/conoscerli-proteggerli/aquila-reale","Più diffusa a 800–2200 m; giovani anche a quote inferiori",minimum:800,maximum:2200),
"Grifone": SpeciesEcology("Rupi, pascoli e mosaici mediterranei","https://www.lipu.it/uccelli/conoscerli-proteggerli/grifone","Nessun intervallo uniforme: presenza italiana localizzata"),
"Poiana": SpeciesEcology("Boschi con alberi alti, radure, prati e coltivi","https://www.lipu.it/uccelli/conoscerli-proteggerli/poiana","Più diffusa dal mare a 1500 m; segnalata anche più in alto",minimum:0,maximum:1500),
"Allocco": SpeciesEcology("Boschi e parchi alberati","https://www.lipu.it/uccelli/conoscerli-proteggerli/allocco","Habitat arboreo; nessun intervallo uniforme adottato"),
"Picchio nero": SpeciesEcology("Foreste mature con alberi grandi e legno morto","https://www.lipu.it/uccelli/conoscerli-proteggerli/picchio-nero","Foreste montane e anche corridoi fluviali di pianura"),
"Airone cenerino": SpeciesEcology("Zone umide, rive, risaie e campagne","https://www.lipu.it/uccelli/conoscerli-proteggerli/airone-cenerino","Valutare acqua e coltivi; nessun limite numerico uniforme"),
"Germano reale": SpeciesEcology("Laghi, stagni, fiumi e zone umide","https://www.lipu.it/uccelli/conoscerli-proteggerli/germano-reale","La presenza di acqua conta più di una quota generica"),
"Falco di palude": SpeciesEcology("Zone umide e ripariali, canneti e coltivi vicini","https://www.lipu.it/uccelli/conoscerli-proteggerli/falco-palude","Habitat umido necessario per un suggerimento conservativo"),
"Orso bruno": SpeciesEcology("Boschi tranquilli, prati montani e coltivi stagionali","https://www.parcoabruzzo.it/scheda-orso.php","Diversi livelli altitudinali; presenza italiana localizzata"),
"Lupo": SpeciesEcology("Boschi e ambienti aperti con prede e rifugi","https://www.parcoabruzzo.it/fauna.schede.dettaglio.php?id=21","Può usare diversi livelli altitudinali"),
"Sciacallo dorato": SpeciesEcology("Ambienti con copertura, acqua e zone umide","https://www.kora.ch/en/species/golden-jackal/profile","Evita aree alte con neve persistente; non esiste una soglia unica"),
"Marmotta": SpeciesEcology("Praterie alpine e subalpine con terreno adatto alle tane","https://www.pngp.it/natura-e-ricerca/fauna/praterie-e-ambienti-rocciosi/la-marmotta","Di solito 2000–3000 m; anche da 800 m in zone senza alberi",minimum:800,maximum:3000),
"Ermellino": SpeciesEcology("Prati, siepi, boschi, paludi e ghiaioni con copertura","https://www.pngp.it/natura-e-ricerca/fauna/carnivori/l-ermellino","Non è limitato all’alta montagna"),
"Tasso": SpeciesEcology("Boschi con sottobosco e incolti; suoli drenati adatti alle tane","https://ambiente.regione.emilia-romagna.it/it/parchi-natura2000/sistema-regionale/fauna/mammiferi/schede/tasso","Pianura e montagna fino a circa 2000 m nella fonte regionale",minimum:0,maximum:2000),
"Gracchio alpino": SpeciesEcology("Pareti rocciose montane vicine a pascoli e praterie","https://www.lipu.it/uccelli/conoscerli-proteggerli/gracchio-alpino","Quote elevate, con differenze tra Alpi e Appennini e discese stagionali"),
"Gufo reale": SpeciesEcology("Pareti rocciose vicine ad ambienti aperti e corsi d’acqua","https://www.lipu.it/uccelli/conoscerli-proteggerli/gufo-reale","Può frequentare versanti anche vicino ai centri abitati"),
"Barbagianni": SpeciesEcology("Campagne a mosaico, prati, siepi e caseggiati rurali","https://www.lipu.it/uccelli/conoscerli-proteggerli/barbagianni","Prevalentemente ambienti aperti; nessun limite uniforme adottato"),
"Ghiandaia": SpeciesEcology("Boschi misti e di latifoglie, anche parchi alberati","https://www.lipu.it/uccelli/conoscerli-proteggerli/ghiandaia","Il bosco conta più di una quota generica"),
"Lepre": SpeciesEcology("Campi coltivati, prati, brughiere e margini del bosco","https://ambiente.regione.emilia-romagna.it/it/parchi-natura2000/sistema-regionale/fauna/mammiferi/schede/lepre","Pianura, collina e montagna fino a circa 2000 m nella fonte regionale",minimum:0,maximum:2000),
"Scoiattolo": SpeciesEcology("Boschi di conifere e latifoglie, parchi alberati","https://www.woodlandtrust.org.uk/trees-woods-and-wildlife/animals/mammals/red-squirrel/","Necessita di alberi; nessun intervallo uniforme adottato"),
"Upupa": SpeciesEcology("Frutteti, vigneti e prati con alberi sparsi, caldi e assolati","https://www.lipu.it/uccelli/conoscerli-proteggerli/upupa","Preferenza per paesaggi agricoli e versanti caldi"),
"Gheppio": SpeciesEcology("Prati, coltivi, rupi e aree urbane con spazi aperti","https://www.lipu.it/uccelli/conoscerli-proteggerli/gheppio","Ampia varietà di quote e ambienti"),
"Assiolo": SpeciesEcology("Coltivi e boschi radi alternati a radure, parchi e giardini","https://www.lipu.it/uccelli/conoscerli-proteggerli/assiolo","Nidifica generalmente sotto 500 m; eccezioni documentate fino a 1550 m",minimum:0,maximum:500),
"Nibbio reale": SpeciesEcology("Boschi radi alternati a prati, pascoli e campagne","https://www.lipu.it/uccelli/conoscerli-proteggerli/nibbio-reale","La quota da sola non conferma la presenza, localizzata in Italia"),
"Nibbio bruno": SpeciesEcology("Boschi vicini a laghi, fiumi e zone umide; prati e coltivi","https://www.lipu.it/uccelli/conoscerli-proteggerli/nibbio-bruno","Per nidificare raramente supera 700–1000 m; non è un limite al volo",minimum:0,maximum:1000),
};
