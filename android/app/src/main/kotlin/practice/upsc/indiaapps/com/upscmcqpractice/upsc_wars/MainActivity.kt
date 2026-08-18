package practice.upsc.indiaapps.com.upscmcqpractice

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        rewriteShareIntent(intent)
        super.onCreate(savedInstanceState)
        ensureNotificationChannel()
    }

    /**
     * FCM uses the channel declared in AndroidManifest meta-data.
     * Create it with IMPORTANCE_HIGH so notifications show as heads-up banners.
     * Safe to call multiple times — Android no-ops if the channel already exists.
     */
    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channelId = getString(R.string.default_notification_channel_id)
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(channelId) != null) return
        val channel = NotificationChannel(
            channelId,
            "UPSC Wars Alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Breaking news quizzes and battle invites"
            enableVibration(true)
        }
        nm.createNotificationChannel(channel)
    }

    override fun onNewIntent(intent: Intent) {
        rewriteShareIntent(intent)
        setIntent(intent)
        super.onNewIntent(intent)
    }

    /**
     * Chrome/Samsung Internet share a page as ACTION_SEND text.
     * Convert that to upscwars://pulse-article?url=… so app_links can open
     * the Pulse article screen.
     */
    private fun rewriteShareIntent(intent: Intent?) {
        if (intent == null) return
        if (Intent.ACTION_SEND != intent.action) return
        val text = listOf(
            intent.getStringExtra(Intent.EXTRA_TEXT),
            intent.getStringExtra(Intent.EXTRA_SUBJECT),
        ).filterNotNull().joinToString("\n")
        val articleUrl = firstHttpUrl(text) ?: return
        val dest = Uri.Builder()
            .scheme("upscwars")
            .authority("pulse-article")
            .appendQueryParameter("url", articleUrl)
            .build()
        intent.action = Intent.ACTION_VIEW
        intent.data = dest
    }

    private fun firstHttpUrl(text: String): String? {
        val regex = Regex("""https?://[^\s<>"'\)\]]+""", RegexOption.IGNORE_CASE)
        val match = regex.find(text) ?: return null
        return match.value.trim().trimEnd('.', ',')
    }
}
