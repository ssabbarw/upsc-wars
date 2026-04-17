package practice.upsc.indiaapps.com.upscmcqpractice.upsc_wars

import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class PrelimsCountdownWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: android.appwidget.AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.os.Bundle
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prelims_countdown_widget)
            val daysLabel = widgetData.getString("prelims_days_label", "UPSC Prelims soon")
            val quote = widgetData.getString("prelims_quote", "Show up daily. Results follow.")

            views.setTextViewText(R.id.prelims_days_label, daysLabel)
            views.setTextViewText(R.id.prelims_quote, quote)

            val pendingIntent = HomeWidgetPlugin.getLaunchPendingIntent(context)
            views.setOnClickPendingIntent(R.id.prelims_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
