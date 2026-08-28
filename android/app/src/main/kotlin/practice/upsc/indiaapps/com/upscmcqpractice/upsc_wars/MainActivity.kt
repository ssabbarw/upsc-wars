package practice.upsc.indiaapps.com.upscmcqpractice

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "UpscWarsIntent"
        private const val SHARE_CHANNEL = "upsc_wars/share"
        private const val SHARE_EVENTS = "upsc_wars/share/events"
        private const val CONSUMED_EXTRA = "upsc_wars_share_consumed"
    }

    @Volatile
    private var pendingArticleUrl: String? = null
    private var shareEvents: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "consumeSharedArticleUrl") {
                    val url = pendingArticleUrl
                    pendingArticleUrl = null
                    Log.i(TAG, "consumeSharedArticleUrl=$url")
                    result.success(url)
                } else {
                    result.notImplemented()
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_EVENTS)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        shareEvents = events
                        pendingArticleUrl?.let { url ->
                            events?.success(url)
                        }
                    }

                    override fun onCancel(arguments: Any?) {
                        shareEvents = null
                    }
                },
            )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        logIntent("onCreate", intent)
        rewriteShareIntent(intent)
        super.onCreate(savedInstanceState)
        ensureNotificationChannel()
    }

    /** Dumps action/data/extras so notification-tap delivery can be traced. */
    private fun logIntent(where: String, intent: Intent?) {
        if (intent == null) {
            Log.i(TAG, "$where intent=null")
            return
        }
        val extras = intent.extras
        val keys = extras?.keySet()?.joinToString(",") ?: "none"
        val payload = extras?.getString("payload")
        Log.i(
            TAG,
            "$where action=${intent.action} data=${intent.data} " +
                "type=${intent.type} flags=0x${Integer.toHexString(intent.flags)} " +
                "extraKeys=[$keys] payload=$payload",
        )
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
            NotificationManager.IMPORTANCE_MAX,
        ).apply {
            description = "Breaking news quizzes and battle invites"
            enableVibration(true)
        }
        nm.createNotificationChannel(channel)
    }

    override fun onNewIntent(intent: Intent) {
        logIntent("onNewIntent", intent)
        rewriteShareIntent(intent)
        setIntent(intent)
        super.onNewIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        rewriteShareIntent(intent)
    }

    /**
     * Chrome/Samsung Internet share a page as ACTION_SEND text / ClipData.
     * Convert that to upscwars://pulse-article?url=… so app_links can open
     * the Pulse article screen, and also keep the URL for a Dart MethodChannel
     * fallback (app_links often ignores ACTION_SEND).
     */
    private fun rewriteShareIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.getBooleanExtra(CONSUMED_EXTRA, false)) return
        val articleUrl = extractSharedHttpUrl(intent) ?: return
        intent.putExtra(CONSUMED_EXTRA, true)
        captureArticleUrl(articleUrl)
        if (Intent.ACTION_SEND != intent.action &&
            Intent.ACTION_SEND_MULTIPLE != intent.action
        ) {
            return
        }
        val dest = Uri.Builder()
            .scheme("upscwars")
            .authority("pulse-article")
            .appendQueryParameter("url", articleUrl)
            .build()
        intent.action = Intent.ACTION_VIEW
        intent.data = dest
        intent.addCategory(Intent.CATEGORY_BROWSABLE)
        Log.i(TAG, "rewrote share -> $dest")
    }

    private fun captureArticleUrl(url: String) {
        pendingArticleUrl = url
        shareEvents?.success(url)
    }

    private fun extractSharedHttpUrl(intent: Intent): String? {
        val chunks = mutableListOf<String>()
        extraText(intent, Intent.EXTRA_TEXT)?.let(chunks::add)
        extraText(intent, Intent.EXTRA_SUBJECT)?.let(chunks::add)
        extraText(intent, Intent.EXTRA_HTML_TEXT)?.let(chunks::add)
        extraText(intent, Intent.EXTRA_PROCESS_TEXT)?.let(chunks::add)
        intent.dataString?.let(chunks::add)

        val clip = intent.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) {
                val item = clip.getItemAt(i)
                item.text?.toString()?.let(chunks::add)
                item.htmlText?.let(chunks::add)
                item.uri?.toString()?.let(chunks::add)
            }
        }

        streamUri(intent)?.toString()?.let(chunks::add)
        collectExtraStrings(intent, chunks)

        for (chunk in chunks) {
            val url = firstHttpUrl(chunk)
            if (url != null) return url
        }
        return null
    }

    @Suppress("DEPRECATION")
    private fun collectExtraStrings(intent: Intent, chunks: MutableList<String>) {
        val extras = intent.extras ?: return
        for (key in extras.keySet()) {
            if (key == CONSUMED_EXTRA) continue
            when (val value = extras.get(key)) {
                is CharSequence -> chunks.add(value.toString())
                is Uri -> chunks.add(value.toString())
                is Array<*> -> value.forEach { item ->
                    when (item) {
                        is CharSequence -> chunks.add(item.toString())
                        is Uri -> chunks.add(item.toString())
                    }
                }
            }
        }
    }

    private fun extraText(intent: Intent, key: String): String? {
        return intent.getCharSequenceExtra(key)?.toString()
            ?: intent.getStringExtra(key)
    }

    private fun streamUri(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun firstHttpUrl(text: String): String? {
        val trimmed = text.trim().trim('<', '>')
        if (trimmed.startsWith("upscwars://", ignoreCase = true)) {
            val nested = Uri.parse(trimmed).getQueryParameter("url")
            if (!nested.isNullOrBlank()) return firstHttpUrl(nested)
        }
        val regex = Regex("""https?://[^\s<>"'\)\]]+""", RegexOption.IGNORE_CASE)
        val match = regex.find(trimmed)
        if (match != null) {
            return match.value.trim().trimEnd('.', ',', ']', ')')
        }
        if (trimmed.startsWith("www.", ignoreCase = true)) {
            return "https://$trimmed"
        }
        return null
    }
}
