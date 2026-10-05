package it.wildtrack.wildtrack_mvp

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.work.*
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit
import org.json.JSONArray
import org.json.JSONObject

object CommunityNotifications {
    const val channel = "wildtrack_community"
    private const val preferences = "wildtrack_notifications"
    @Synchronized fun configure(context: Context, token: String, enabled: Boolean) {
        val p = context.getSharedPreferences(preferences, Context.MODE_PRIVATE)
        val changed = p.getString("token", "") != token
        val edit = p.edit().putString("token", token).putBoolean("enabled", enabled)
        if (changed) edit.putLong("since", System.currentTimeMillis()).putStringSet("seen", emptySet())
        edit.commit()
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(channel, "Avvistamenti della community", NotificationManager.IMPORTANCE_DEFAULT))
        val work = WorkManager.getInstance(context)
        if (!enabled) {work.cancelUniqueWork("wildtrack-community-check"); return}
        val request = PeriodicWorkRequestBuilder<CommunityNotificationWorker>(15, TimeUnit.MINUTES)
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()).build()
        work.enqueueUniquePeriodicWork("wildtrack-community-check", ExistingPeriodicWorkPolicy.KEEP, request)
    }
    @Synchronized fun display(context: Context, row: JSONObject) {
        val p = context.getSharedPreferences(preferences, Context.MODE_PRIVATE)
        if (!p.getBoolean("enabled", false) || row.optInt("mine") == 1 || !row.isNull("groupId")) return
        val id = row.optString("id")
        if (id.isEmpty() || row.optLong("createdAt") <= p.getLong("since", Long.MAX_VALUE)) return
        val seen = p.getStringSet("seen", emptySet())!!.toMutableSet()
        if (seen.contains(id)) return
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        intent.putExtra("sightingId", id)
        val pending = PendingIntent.getActivity(context, id.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(context, channel).setSmallIcon(context.resources.getIdentifier("wildtrack_logo", "drawable", context.packageName))
            .setContentTitle("${row.optString("authorName", "Un esploratore")} · ${row.optString("species", "Avvistamento")}")
            .setContentText("Nuovo avvistamento nella community WildTrack")
            .setContentIntent(pending).setAutoCancel(true).build()
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).notify(id.hashCode(), notification)
        seen.add(id)
        p.edit().putStringSet("seen", seen).commit()
    }
    fun check(context: Context) {
        val p = context.getSharedPreferences(preferences, Context.MODE_PRIVATE)
        if (!p.getBoolean("enabled", false)) return
        val token = p.getString("token", "") ?: return
        val since = p.getLong("since", Long.MAX_VALUE)
        var offset = 0
        val fresh = mutableListOf<JSONObject>()
        while (true) {
            val c = URL("https://wildtrack-community.canta80.chatgpt.site/api/sightings?offset=$offset").openConnection() as HttpURLConnection
            val data: JSONObject
            try {
                c.connectTimeout = 10000; c.readTimeout = 15000
                c.setRequestProperty("Authorization", "Bearer $token")
                if (c.responseCode != 200) throw IllegalStateException("Community unavailable")
                data = JSONObject(c.inputStream.bufferedReader().use { it.readText() })
            } finally { c.disconnect() }
            val rows = data.getJSONArray("items")
            var reachedOld = false
            for (i in 0 until rows.length()) {
                val row = rows.getJSONObject(i)
                if (row.optLong("createdAt") <= since) {reachedOld = true; break}
                fresh.add(row)
            }
            if (reachedOld || data.isNull("nextOffset")) break
            offset = data.getInt("nextOffset")
            if (offset > 100000) throw IllegalStateException("Feed too large")
        }
        for (row in fresh.asReversed()) display(context, row)
        // Advance only after every new item is processed; retain equal-time ids.
        if (fresh.isNotEmpty()) {
            val newest = fresh.maxOf { it.optLong("createdAt") }
            synchronized(this) {
                if (p.getString("token", "") == token) p.edit().putLong("since", newest - 1)
                    .putStringSet("seen", fresh.filter { it.optLong("createdAt") == newest }.map { it.optString("id") }.toSet()).commit()
            }
        }
    }
}
class CommunityNotificationWorker(context: Context, params: WorkerParameters): Worker(context, params) {
    override fun doWork(): Result = try { CommunityNotifications.check(applicationContext); Result.success() } catch (_: Exception) { Result.retry() }
}
