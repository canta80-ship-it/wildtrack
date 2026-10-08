from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text()
for permission in ['INTERNET','ACCESS_COARSE_LOCATION','ACCESS_FINE_LOCATION','CAMERA','FOREGROUND_SERVICE','FOREGROUND_SERVICE_LOCATION','WAKE_LOCK']:
    if 'android.permission.'+permission not in s:
        s=s.replace('<application', f'<uses-permission android:name="android.permission.{permission}" />\n    <application',1)
s=s.replace('android:label="wildtrack_mvp"','android:label="WildTrack"')
p.write_text(s)
k=Path('android/app/src/main/kotlin/it/wildtrack/wildtrack_mvp/MainActivity.kt')
k.parent.mkdir(parents=True,exist_ok=True)
k.write_text('''package it.wildtrack.wildtrack_mvp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var player: MediaPlayer? = null
    private var channel: MethodChannel? = null
    private var remaining = 0
    private var generation = 0
    private val noisy = object: BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) { stopAudio() }
    }
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "wildtrack/secure").setMethodCallHandler { call, result ->
            try {
                val prefs = getSharedPreferences("wildtrack_credentials", Context.MODE_PRIVATE)
                fun key(): SecretKey {
                    val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
                    val existing = store.getKey("wildtrack.identity.v1", null)
                    if (existing != null) return existing as SecretKey
                    val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
                    generator.init(KeyGenParameterSpec.Builder("wildtrack.identity.v1", KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                        .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
                    return generator.generateKey()
                }
                when (call.method) {
                    "readToken" -> {
                        val encrypted = prefs.getString("token", null)
                        if (encrypted == null) result.success(null)
                        else {
                            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, Base64.decode(prefs.getString("iv", ""), Base64.NO_WRAP)))
                            result.success(String(cipher.doFinal(Base64.decode(encrypted, Base64.NO_WRAP)), Charsets.UTF_8))
                        }
                    }
                    "writeToken" -> {
                        val token = call.argument<String>("token") ?: throw IllegalArgumentException("Credenziale assente")
                        require(token.isNotEmpty() && token.length <= 4096)
                        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                        cipher.init(Cipher.ENCRYPT_MODE, key())
                        val encrypted = cipher.doFinal(token.toByteArray(Charsets.UTF_8))
                        check(prefs.edit().putString("token", Base64.encodeToString(encrypted, Base64.NO_WRAP))
                            .putString("iv", Base64.encodeToString(cipher.iv, Base64.NO_WRAP)).commit())
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { result.error("STORAGE", "Credenziale non leggibile. I dati esistenti sono conservati.", null) }
        }
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "wildtrack/audio")
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(noisy, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY), Context.RECEIVER_NOT_EXPORTED)
        else registerReceiver(noisy, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY))
        channel!!.setMethodCallHandler { call, result ->
            when(call.method) {
                "stop" -> { stopAudio(); result.success(null) }
                "play" -> {
                    val url = call.argument<String>("url") ?: ""
                    if (!url.startsWith("https://upload.wikimedia.org/")) { result.error("SOURCE", "Fonte audio non ammessa", null) }
                    else {
                        stopAudio(false)
                        remaining = (call.argument<Int>("repeats") ?: 1).coerceIn(1,5)
                        val token = generation
                        try {
                            val p = MediaPlayer()
                            player = p
                            p.setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
                            p.isLooping = false
                            p.setDataSource(url)
                            p.setOnPreparedListener { if (generation == token && player === it) { it.start(); channel?.invokeMethod("playing", null) } }
                            p.setOnCompletionListener {
                                if (generation == token && player === it) {
                                    remaining--
                                    if (remaining > 0) { it.seekTo(0); it.start() } else stopAudio()
                                }
                            }
                            p.setOnErrorListener { _, _, _ -> if (generation == token) { stopAudio(); channel?.invokeMethod("error", "Audio non disponibile. Riprova con una connessione Internet.") }; true }
                            p.prepareAsync()
                            result.success(null)
                        } catch(e: Exception) { stopAudio(); result.error("AUDIO", "Impossibile riprodurre il verso", null) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun stopAudio(notify: Boolean = true) {
        generation++
        remaining=0
        player?.let { try { it.stop() } catch (_: Exception) {} ; it.release() }
        player=null
        if (notify) channel?.invokeMethod("stopped",null)
    }
    override fun onPause() { stopAudio(); super.onPause() }
    override fun onDestroy() { stopAudio(); try { unregisterReceiver(noisy) } catch (_: Exception) {}; super.onDestroy() }
}
''')

# Green brand mark for the Android launcher as well as the in-app header.
d=Path('android/app/src/main/res/drawable/wildtrack_logo.xml')
d.parent.mkdir(parents=True,exist_ok=True)
d.write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
<path android:fillColor="#294A34" android:pathData="M0,0H108V108H0Z"/>
<path android:fillColor="#647A3F" android:pathData="M0,0H108V22L0,88Z"/>
<path android:fillColor="#D4E1B9" android:pathData="M54,47C43,47 42,61 34,67C25,77 32,86 42,83C49,79 59,79 66,83C77,87 84,76 75,67C66,61 65,47 54,47Z M30,32a7,10 0,1 0,0.1,0Z M46,23a7,10 0,1 0,0.1,0Z M63,23a7,10 0,1 0,0.1,0Z M79,32a7,10 0,1 0,0.1,0Z"/>
</vector>''')
s=p.read_text().replace('android:icon="@mipmap/ic_launcher"','android:icon="@drawable/wildtrack_logo"')
p.write_text(s)
# Retain the v5 package identity for updates over the existing installation.
# The launcher name stays WildTrack; version numbers are internal metadata.
build=Path('android/app/build.gradle.kts')
s=build.read_text().replace('applicationId = "it.wildtrack.wildtrack_mvp"','applicationId = "it.wildtrack.wildtrack_v5"')
build.write_text(s)

# Exclude credentials, retain user observations and tracks in Android backups.
res = Path('android/app/src/main/res/xml')
res.mkdir(parents=True, exist_ok=True)
(res/'backup_rules.xml').write_text('<full-backup-content><exclude domain="sharedpref" path="wildtrack_credentials.xml" /></full-backup-content>')
(res/'data_extraction_rules.xml').write_text('<data-extraction-rules><cloud-backup><exclude domain="sharedpref" path="wildtrack_credentials.xml" /></cloud-backup><device-transfer><exclude domain="sharedpref" path="wildtrack_credentials.xml" /></device-transfer></data-extraction-rules>')
s = p.read_text()
if 'android:fullBackupContent=' not in s:
    s = s.replace('<application', '<application android:fullBackupContent="@xml/backup_rules" android:dataExtractionRules="@xml/data_extraction_rules"', 1)
s = s.replace('android:label="WildTrack 0.5"', 'android:label="WildTrack"')
p.write_text(s)

# Reproducible update signing: the selected keystore must already exist.
s = build.read_text()
if 'create("wildTrack")' not in s:
    s = s.replace('android {', 'android {\n    signingConfigs {\n        create("wildTrack") {\n            val retained = System.getenv("WILDTRACK_KEYSTORE") ?: ((System.getenv("ANDROID_USER_HOME") ?: (System.getProperty("user.home") + "/.android")) + "/debug.keystore")\n            storeFile = file(retained)\n            if (!storeFile!!.isFile) throw GradleException("Chiave di firma originale assente: nessuna nuova identita viene generata")\n            storePassword = System.getenv("WILDTRACK_STORE_PASSWORD") ?: "android"\n            keyAlias = System.getenv("WILDTRACK_KEY_ALIAS") ?: "androiddebugkey"\n            keyPassword = System.getenv("WILDTRACK_KEY_PASSWORD") ?: "android"\n        }\n    }\n', 1)
s = s.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("wildTrack")')
build.write_text(s)
