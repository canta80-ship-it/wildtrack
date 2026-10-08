# Generare e aggiornare l'APK WildTrack

Release corrente: `0.6.0+6`, package `it.wildtrack.wildtrack_v5`.
Per aggiornare conservando i dati occorrono il package e il certificato dell'app installata, con un `versionCode` superiore. Non disinstallare l'app per aggirare un errore di firma.

Il repository mantiene i sorgenti Dart nella radice. CI e setup cloud li copiano nelle cartelle Flutter (`lib/screens`, `lib/services`, `lib/models`, `lib/main.dart`) prima della build. Conservare anche `assets/`, `test/`, dati naturalistici e fotografie della radice.

Toolchain: Flutter **3.47.3**, Java **17**. Nel cloud già configurato:

```bash
source /workspace/wildtrack-onboarding/activate.sh
cd /workspace/wildtrack-dev
python3 tool/prepare_android.py
flutter pub get --enforce-lockfile
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
flutter build apk --release --no-pub
```

`wildtrack-dev` è una copia di compilazione: sincronizzare i sorgenti dal repository prima di compilare modifiche successive. L'APK è `build/app/outputs/flutter-apk/app-release.apk`.

Lo script Android richiede una chiave già esistente: **non genera una nuova identità**. In questo ambiente usa la chiave conservata in `ANDROID_USER_HOME`. Per scegliere una chiave originale diversa, usare `WILDTRACK_KEYSTORE`, `WILDTRACK_STORE_PASSWORD`, `WILDTRACK_KEY_ALIAS` e `WILDTRACK_KEY_PASSWORD` tramite impostazioni sicure dell'ambiente. Non inserire chiavi o password nel repository.

La CI `.github/workflows/build-apk.yml` usa Flutter fissato, lockfile e test. Prima di distribuire con GitHub Actions, configurare la chiave originale nei secret `WILDTRACK_KEYSTORE_B64`, `WILDTRACK_STORE_PASSWORD`, `WILDTRACK_KEY_ALIAS`, `WILDTRACK_KEY_PASSWORD`. In assenza della chiave il workflow si ferma, evitando APK firmati con chiavi temporanee incompatibili. Non sono stati caricati secret su GitHub in questa sessione.

La firma debug preesistente viene conservata per consentire l'aggiornamento della relativa installazione. La dicitura `release` descrive la modalità di compilazione e non sostituisce il confronto del certificato.

I test SQLite desktop usano `sqflite_common_ffi` e `sqlite3` soltanto come dipendenze di sviluppo; su Linux caricano `libsqlite3.so.0`. Non sono componenti aggiunti all'app Android.
