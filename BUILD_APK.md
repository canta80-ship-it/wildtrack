# Generare l'APK di WildTrack

Il progetto include un workflow GitHub Actions in `.github/workflows/build-apk.yml`.

Quando il repository viene caricato su GitHub, il workflow:

1. installa Java 17;
2. installa Flutter 3.47.3;
3. genera i file Android;
4. aggiunge i permessi GPS, Internet e Fotocamera;
5. esegue `flutter analyze`;
6. compila `flutter build apk --release`;
7. pubblica `WildTrack-release.apk` come artifact scaricabile.

In alternativa, su un computer con Flutter installato:

```bash
flutter create --platforms=android --org it.wildtrack --project-name wildtrack_mvp .
python tool/prepare_android.py
flutter pub get
flutter analyze
flutter build apk --release
```

APK generato in:

`build/app/outputs/flutter-apk/app-release.apk`
