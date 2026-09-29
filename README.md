# WildTrack MVP

Prima versione di un'app outdoor per trekking, registrazione GPS e osservazione fauna.

## Funzioni incluse
- Mappa OpenStreetMap con posizione GPS
- Registrazione traccia con distanza, dislivello positivo e punti GPS
- Salvataggio locale SQLite
- Inserimento avvistamenti con specie, numero, note, coordinate e foto
- Elenco percorsi salvati
- Statistiche cumulative

## Avvio rapido
1. Installa Flutter stabile recente (Dart >= 3.12).
2. Crea le cartelle piattaforma se mancano: `flutter create .`
3. Esegui `flutter pub get`.
4. Applica i permessi descritti sotto.
5. Avvia con `flutter run`.

## Android: permessi
Nel file `android/app/src/main/AndroidManifest.xml`, dentro `<manifest>` aggiungi:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
```

Per una registrazione GPS affidabile anche a schermo spento servirà, nella fase successiva, un foreground service Android dedicato.

## iOS: permessi
Nel file `ios/Runner/Info.plist` aggiungi:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>WildTrack usa la posizione per registrare le tue uscite e geolocalizzare gli avvistamenti.</string>
<key>NSCameraUsageDescription</key>
<string>WildTrack usa la fotocamera per associare foto agli avvistamenti.</string>
```

## Nota mappe
L'MVP usa i tile standard OpenStreetMap. Per uso intensivo o distribuzione pubblica va scelto un provider conforme alla policy OSM oppure un server tile proprio. La versione successiva può usare mappe topografiche e download offline.

## Prossimo sviluppo consigliato
- GPX import/export
- mappa topografica outdoor
- cache offline
- heatmap avvistamenti
- alba/tramonto e crepuscolo
- probabilità di avvistamento basata su storico, fascia oraria e meteo
- schermata dettaglio percorso con traccia su mappa

## Build APK automatico
È incluso un workflow GitHub Actions (`.github/workflows/build-apk.yml`) che compila automaticamente l'APK release con Flutter 3.47.3. Vedi `BUILD_APK.md`.
