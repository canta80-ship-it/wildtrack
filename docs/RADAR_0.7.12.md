# WildTrack 0.7.12 — Radar e catalogo

## Comportamento

La home mostra le specie realmente ordinate dal Radar, con condizioni qualitative e motivazioni. Nessun valore di esempio o percentuale viene usato come probabilità di incontro. Se manca una posizione recente e accurata non vengono inventate previsioni locali.

Il catalogo, i profili Radar e le mappe habitat coprono 31 specie. Le nuove schede sono Lepre (Lepus europaeus), Scoiattolo (Sciurus vulgaris), Upupa, Gheppio, Assiolo, Nibbio reale e Nibbio bruno. Mantengono tutte le sezioni delle schede esistenti, compreso Periodo migliore, e aggiungono spiegazioni di alimentazione, riproduzione e comportamento. I nibbi sono due record distinti.

## Dati e limiti

- Posizione autorizzata, età massima 5 minuti, accuratezza orizzontale ≤200 m. La quota è usata solo con accuratezza verticale dichiarata ≤100 m.
- Fase solare calcolata da istante, latitudine e longitudine; alba/tramonto sono approssimazioni astronomiche, non luce garantita sul terreno.
- Meteo Open-Meteo: temperatura, vento, pioggia, umidità e codice. Cache in memoria 10 minuti; mai valori simulati in caso di errore.
- Habitat © OpenStreetMap contributors / ODbL: modi e multipoligoni nel raggio di 1,4 km. Mosaico vicino, non verifica puntuale. Nessuna deduzione dell'habitat dalla sola altitudine. Cache 1 ora.
- Storico personale: incontri di animali con coordinate entro 25 km e 365 giorni; peso ridotto con età e distanza. Tracce non equiparate a incontri visivi.
- GBIF: campione massimo 300 record georeferenziati di osservazioni umane o automatiche negli ultimi 730 giorni; supporto entro 40 km. Non costituisce un areale completo, una misura d'abbondanza o presenza in tempo reale.
- Community: sola lettura di avvistamenti pubblici, non verificati. Non attiva condivisione della posizione e non accede alle mappe private.
- Controlli locali espliciti: specie, durata, esito, fase solare e posizione. Confronti descrittivi entro 2 km, stessa fase, ultimi 90 giorni e durata ≥15 minuti. Non inferiti dai percorsi e non trasformati in probabilità.
- Fototrappole live: nessuna sorgente autorizzata configurata; dichiarato nella schermata Dati.

Aggiornamento home ogni 2 minuti in primo piano, alla ripresa e quando cambiano i dati locali; richieste concomitanti accorpate e contesti riutilizzati dalla cache. Nessun nuovo servizio a pagamento.

## Fonti del catalogo nuovo

- Lepre europea: Woodland Trust, https://www.woodlandtrust.org.uk/blog/2023/03/why-do-hares-box/ ; Mammal Society, https://mammal.org.uk/british-mammals/brown-hare ; distinzione dalle altre lepri italiane: https://www.parcoabruzzo.it/fauna.schede.dettaglio.php?id=304
- Scoiattolo comune: https://www.woodlandtrust.org.uk/trees-woods-and-wildlife/animals/mammals/red-squirrel/ ; https://www.britishredsquirrel.org/red-squirrels/characteristics/
- Upupa: https://www.lipu.it/uccelli/conoscerli-proteggerli/upupa
- Gheppio: https://www.lipu.it/uccelli/conoscerli-proteggerli/gheppio
- Assiolo: https://www.lipu.it/uccelli/conoscerli-proteggerli/assiolo
- Nibbio reale: https://www.lipu.it/uccelli/conoscerli-proteggerli/nibbio-reale ; la fonte italiana contiene un errore evidente sul peso, non ripreso: confronto https://www.rspb.org.uk/birds-and-wildlife/red-kite
- Nibbio bruno: https://www.lipu.it/uccelli/conoscerli-proteggerli/nibbio-bruno
- API GBIF: https://techdocs.gbif.org/en/openapi/v1/occurrence

Illustrazioni generate appositamente con il tool integrato: sette paesaggi con un singolo animale e sette tavole di quattro segni su fondo avorio. Stile: acquerello e matita naturalistica; niente interfaccia né testo, soggetti completi. Le tavole nuove usano quattro quadranti, gestiti dal renderer; le precedenti tavole orizzontali restano compatibili. Asset: assets/radar_species/. Anatomia e qualità controllate visivamente; la tavola dell'assiolo è stata corretta per mostrare due dita avanti e due dietro.

## Verifica

La suite Radar aggiunge prove deterministiche su copertura catalogo/asset, fase solare, posizione mancante/scaduta/imprecisa, esclusione rapaci diurni di notte, ascolto notturno, capriolo al crepuscolo, migratori e letargo, storico vecchio/lontano/tracce, evidenze regionali, habitat sconosciuto, controlli negativi e ranking mostrato dalla home. Eseguire insieme alle suite funzionali, mappe e layout. Le prove native usano GPS simulato e non certificano incontri reali né accuratezza biologica delle previsioni.
