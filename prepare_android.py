from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text()
for permission in ['INTERNET','ACCESS_COARSE_LOCATION','ACCESS_FINE_LOCATION','ACCESS_BACKGROUND_LOCATION','CAMERA','FOREGROUND_SERVICE','FOREGROUND_SERVICE_LOCATION','WAKE_LOCK','POST_NOTIFICATIONS']:
    if 'android.permission.'+permission not in s:
        s=s.replace('<application', f'<uses-permission android:name="android.permission.{permission}" />\n    <application',1)
s=s.replace('android:label="wildtrack_mvp"','android:label="WildTrack Preview"')
p.write_text(s)
k=Path('android/app/src/main/kotlin/it/wildtrack/wildtrack_mvp/MainActivity.kt')
k.parent.mkdir(parents=True,exist_ok=True)
k.write_text('''package it.wildtrack.wildtrack_mvp

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var player: MediaPlayer? = null
    private var channel: MethodChannel? = null
    private var backupChannel: MethodChannel? = null
    private var backupResult: MethodChannel.Result? = null
    private var remaining = 0
    private var generation = 0
    private val backupRequestCode = 4011
    private val prefsName = "wildtrack_backup"
    private val folderKey = "tree_uri"

    private val noisy = object: BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) { stopAudio() }
    }

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "wildtrack/audio")
        backupChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "wildtrack/backup")
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

        backupChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFolder" -> pickBackupFolder(result)
                "folderInfo" -> folderInfo(result)
                "clearFolder" -> {
                    getSharedPreferences(prefsName, Context.MODE_PRIVATE).edit().remove(folderKey).apply()
                    result.success(null)
                }
                "writeBackup" -> {
                    val name = call.argument<String>("name") ?: "WildTrack-backup.wildtrack"
                    val bytes = call.argument<ByteArray>("data") ?: byteArrayOf()
                    writeBackup(name, bytes, result)
                }
                "readLatest" -> readLatestBackup(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickBackupFolder(result: MethodChannel.Result) {
        if (backupResult != null) {
            result.error("BUSY", "Selettore backup già aperto", null)
            return
        }
        backupResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        startActivityForResult(intent, backupRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == backupRequestCode) {
            val pending = backupResult
            backupResult = null
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri = data.data!!
                val flags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                try { contentResolver.takePersistableUriPermission(uri, flags) } catch (_: Exception) {}
                getSharedPreferences(prefsName, Context.MODE_PRIVATE).edit().putString(folderKey, uri.toString()).apply()
                pending?.success(mapOf("uri" to uri.toString(), "label" to documentName(uri)))
            } else {
                pending?.success(null)
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun savedTreeUri(): Uri? {
        val raw = getSharedPreferences(prefsName, Context.MODE_PRIVATE).getString(folderKey, null) ?: return null
        return try { Uri.parse(raw) } catch (_: Exception) { null }
    }

    private fun documentName(uri: Uri): String {
        return try {
            val docId = DocumentsContract.getTreeDocumentId(uri)
            val docUri = DocumentsContract.buildDocumentUriUsingTree(uri, docId)
            contentResolver.query(docUri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else "Cartella backup"
            } ?: "Cartella backup"
        } catch (_: Exception) {
            "Cartella backup"
        }
    }

    private fun folderInfo(result: MethodChannel.Result) {
        val uri = savedTreeUri()
        if (uri == null) {
            result.success(null)
            return
        }
        result.success(mapOf("uri" to uri.toString(), "label" to documentName(uri)))
    }

    private fun children(tree: Uri): MutableList<Triple<String, Long, String>> {
        val rows = mutableListOf<Triple<String, Long, String>>()
        val parentId = DocumentsContract.getTreeDocumentId(tree)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1) ?: ""
                val modified = if (cursor.isNull(2)) 0L else cursor.getLong(2)
                rows.add(Triple(id, modified, name))
            }
        }
        return rows
    }

    private fun pruneOldBackups(tree: Uri) {
        try {
            val backups = children(tree)
                .filter { it.third.endsWith(".wildtrack") }
                .sortedByDescending { it.second }
            for (entry in backups.drop(5)) {
                val uri = DocumentsContract.buildDocumentUriUsingTree(tree, entry.first)
                try { DocumentsContract.deleteDocument(contentResolver, uri) } catch (_: Exception) {}
            }
        } catch (_: Exception) {}
    }

    private fun writeBackup(name: String, bytes: ByteArray, result: MethodChannel.Result) {
        val tree = savedTreeUri()
        if (tree == null) {
            result.error("NO_FOLDER", "Scegli prima una cartella backup", null)
            return
        }
        try {
            val parentId = DocumentsContract.getTreeDocumentId(tree)
            val parentUri = DocumentsContract.buildDocumentUriUsingTree(tree, parentId)
            val created = DocumentsContract.createDocument(contentResolver, parentUri, "application/octet-stream", name)
                ?: throw IllegalStateException("Impossibile creare il backup")
            contentResolver.openOutputStream(created, "w")!!.use { it.write(bytes) }
            pruneOldBackups(tree)
            result.success(mapOf("name" to name, "bytes" to bytes.size))
        } catch (e: Exception) {
            result.error("WRITE", e.message ?: "Backup non riuscito", null)
        }
    }

    private fun readLatestBackup(result: MethodChannel.Result) {
        val tree = savedTreeUri()
        if (tree == null) {
            result.error("NO_FOLDER", "Scegli prima una cartella backup", null)
            return
        }
        try {
            val latest = children(tree)
                .filter { it.third.endsWith(".wildtrack") }
                .maxByOrNull { it.second }
                ?: run {
                    result.success(null)
                    return
                }
            val uri = DocumentsContract.buildDocumentUriUsingTree(tree, latest.first)
            val bytes = contentResolver.openInputStream(uri)!!.use { it.readBytes() }
            result.success(mapOf("name" to latest.third, "data" to bytes))
        } catch (e: Exception) {
            result.error("READ", e.message ?: "Ripristino non riuscito", null)
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

d=Path('android/app/src/main/res/drawable/wildtrack_logo.xml')
d.parent.mkdir(parents=True,exist_ok=True)
d.write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
<path android:fillColor="#254D38" android:pathData="M0,0H108V108H0Z"/>
<path android:fillColor="#5F7A61" android:pathData="M0,0H108V22L0,88Z"/>
<path android:fillColor="#DDE8DA" android:pathData="M54,47C43,47 42,61 34,67C25,77 32,86 42,83C49,79 59,79 66,83C77,87 84,76 75,67C66,61 65,47 54,47Z M30,32a7,10 0,1 0,0.1,0Z M46,23a7,10 0,1 0,0.1,0Z M63,23a7,10 0,1 0,0.1,0Z M79,32a7,10 0,1 0,0.1,0Z"/>
</vector>''')
s=p.read_text().replace('android:icon="@mipmap/ic_launcher"','android:icon="@drawable/wildtrack_logo"')
p.write_text(s)

# Fresh stable application id for the next-generation WildTrack family.
# It avoids signature collisions with the earlier v5/v6 preview packages.
build=Path('android/app/build.gradle.kts')
s=build.read_text().replace('applicationId = "it.wildtrack.wildtrack_mvp"','applicationId = "it.wildtrack.preview"')
s=s.replace('    buildTypes {', '    signingConfigs {\n        create("wildtrackPreview") {\n            storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")\n            storePassword = "android"\n            keyAlias = "androiddebugkey"\n            keyPassword = "android"\n        }\n    }\n    buildTypes {')
s=s.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("wildtrackPreview")')
build.write_text(s)
