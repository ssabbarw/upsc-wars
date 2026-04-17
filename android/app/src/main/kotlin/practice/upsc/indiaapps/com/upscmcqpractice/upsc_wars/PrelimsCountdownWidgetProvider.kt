package practice.upsc.indiaapps.com.upscmcqpractice.upsc_wars

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PrelimsCountdownWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: android.appwidget.AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prelims_countdown_widget)
            val timerLabel = widgetData.getString("prelims_timer_label", "0")
            val quote = widgetData.getString("prelims_quote", "“The trouble is, you think you have time.”\n- Buddha")

            views.setTextViewText(R.id.prelims_timer_label, "Days: $timerLabel")
            views.setTextViewText(R.id.prelims_quote, quote)

            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.prelims_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
