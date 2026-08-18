package practice.upsc.indiaapps.com.upscmcqpractice

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        rewriteShareIntent(intent)
        super.onCreate(savedInstanceState)
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
