package com.bhakti.bhakti

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class BhaktiWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.bhakti_widget_layout).apply {
                val title = widgetData.getString("widget_title", "Gayatri Maha Mantra") ?: "Gayatri Maha Mantra"
                val subtitle = widgetData.getString("widget_subtitle", "Om Bhur Bhuvaḥ Swaḥ • Divine Blessings") ?: "Om Bhur Bhuvaḥ Swaḥ • Divine Blessings"
                val panchanga = widgetData.getString("widget_panchanga", "Daily Vedic Panchanga") ?: "Daily Vedic Panchanga"

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_subtitle, subtitle)
                setTextViewText(R.id.widget_panchanga, panchanga)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
