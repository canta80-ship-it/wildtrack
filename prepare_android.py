from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text()
for permission in ['INTERNET','ACCESS_COARSE_LOCATION','ACCESS_FINE_LOCATION','CAMERA','FOREGROUND_SERVICE','FOREGROUND_SERVICE_LOCATION','WAKE_LOCK']:
    if 'android.permission.'+permission not in s:
        s=s.replace('<application', f'<uses-permission android:name="android.permission.{permission}" />\n    <application',1)
s=s.replace('android:label="wildtrack_mvp"','android:label="WildTrack 0.5"')
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
# Install alongside earlier test APKs; their signing keys were not retained.
# The launcher name stays WildTrack; version numbers are internal metadata.
build=Path('android/app/build.gradle.kts')
s=build.read_text().replace('applicationId = "it.wildtrack.wildtrack_mvp"','applicationId = "it.wildtrack.wildtrack_v5"')
build.write_text(s)
