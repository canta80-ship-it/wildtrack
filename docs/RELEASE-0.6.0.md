# WildTrack 0.6.0 — restyling e correzioni

Restyling outdoor premium approvato: bosco, salvia, avorio, tema scuro, titoli serif, schede arrotondate, sfumature, pulsanti e transizioni. L'apertura usa logo, foto e crediti originali. Restano i cinque tab, le funzioni, la guida e i dati naturalistici esistenti. Le animazioni rispettano la riduzione del movimento; i tab conservano lo stato.

Le 17 aree del rapporto iniziale sono state affrontate nel client:

| Punto | Intervento |
| --- | --- |
| 1 | Preferenze e transazioni degli itinerari serializzate; file temporanei distinti. |
| 2 | Snapshot privato associato alla coda; conversione pubblica dopo risposta e solo se la riga non è modificata. Nessuna cancellazione basata sui risultati GET. |
| 3 | Backup JSON, errori espliciti e schermata iniziale con Riprova. Archivi illeggibili conservati. |
| 4 | Cambiamenti della condivisione GPS serializzati; controlli dopo permessi asincroni e scarto delle risposte obsolete. |
| 5 | Polling solo per app, route e tab visibili; caricamenti non sovrapposti e HTTP riutilizzato. |
| 6 | Un coordinatore GPS sceglie e aggiorna gli intervalli tra registrazione, navigazione e condivisione. |
| 7 | La coda visibile cambia soltanto dopo il salvataggio persistente riuscito. |
| 8 | Coordinate approssimate prima di persistenza e invio, anche per le code precedenti. Metadati privati di confronto esclusi dal payload. |
| 9 | Migrazione della stessa credenziale in AES-GCM con chiave Android Keystore; verifica prima della rimozione del token in chiaro; credenziali escluse dai backup. |
| 10 | Decodifica delle foto d'apertura limitata alla densità del display, massimo 1600 px; asset originali conservati. |
| 11 | Catalogo, geometrie, lunghezze, polilinee e distanza dal tracciato memorizzati. |
| 12 | SQLite v2→v3 con indici aggiuntivi; notifiche solo per eliminazioni reali e statistiche via SQL. |
| 13 | Scritture GPS drenate prima della nuova sessione; metriche aggiornate dopo commit; errore GPS distinto da storage. Filtri del rumore orizzontale e mediana/isteresi della quota. |
| 14 | Cache metadati audio/foto, rimozione delle Future fallite, timeout completo e limite HTTP. |
| 15 | Recupero picker Android; pulizia dei soli file locali non referenziati dopo commit/rollback, rispettando la coda. |
| 16 | Tipi e coordinate validati alla ricezione; geometrie controllate prima del rendering; fonti GBIF/OSM limitate agli URL previsti. |
| 17 | Operazioni comuni estratte, codice inutilizzato rimosso, Flutter fissato, lockfile/test in CI e firma persistente obbligatoria. |

Le metriche dei percorsi già salvati non vengono ricalcolate. I filtri influenzano le nuove registrazioni e richiedono confronto sul campo.

Passano i **14 test** in `test/regression_test.dart`: SQLite reale, migrazione con dati, token conservato, concorrenza, corruzione, annullamento fallito, modifica durante POST, conversione dopo risposta, GPS condiviso, rumore delle metriche, privacy della coda precedente, dati malformati, lifecycle e layout su telefono piccolo con testo ingrandito. Keystore e GPS usano una piattaforma sostituita nei test: non sono prove su hardware Android.

Il backend non è nel repository: autorizzazioni, idempotenza, retention, log e scadenza della presenza restano da verificare sul server. Non sono stati misurati batteria o GPS su dispositivo reale.

Aggiornamento: package `it.wildtrack.wildtrack_v5`, versione `0.6.0+6`, certificato uguale all'APK `0.5.0` di riferimento conservato in workspace. La corrispondenza con l'app sul telefono non è stata verificata: non disinstallare né cancellare i dati in caso di incompatibilità. Dettagli, SHA-256 e confronto sono in `/workspace/releases/WildTrack-0.6.0-verifica.json`.
