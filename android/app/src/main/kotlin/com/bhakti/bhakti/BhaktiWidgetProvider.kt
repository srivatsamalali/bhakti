package com.bhakti.bhakti

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BhaktiWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_PLAY = "com.bhakti.bhakti.ACTION_TOGGLE_PLAY"
        const val ACTION_PREV = "com.bhakti.bhakti.ACTION_PREV"
        const val ACTION_NEXT = "com.bhakti.bhakti.ACTION_NEXT"
        const val ACTION_TOGGLE_FAV = "com.bhakti.bhakti.ACTION_TOGGLE_FAV"
        const val ACTION_SELECT_SONG = "com.bhakti.bhakti.ACTION_SELECT_SONG"
        const val EXTRA_SONG_INDEX = "extra_song_index"

        val TRACKS = listOf(
            Triple("Gayatri Mantra", "Om Bhur Bhuvah Svah Tat...", "5:16"),
            Triple("Ganesha Mantra", "Om Gam Ganapataye Namaha", "4:20"),
            Triple("Venkateshwara Suprabhatam", "Kausalya Supraja Rama...", "6:45"),
            Triple("Maha Mrityunjaya Mantra", "Om Tryambakam Yajamahe...", "5:30")
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        when (intent.action) {
            ACTION_TOGGLE_PLAY -> {
                val isPlaying = prefs.getBoolean("flutter.widget_is_playing", true)
                prefs.edit().putBoolean("flutter.widget_is_playing", !isPlaying).apply()
                updateAllWidgets(context)
            }
            ACTION_PREV -> {
                val currentIndex = prefs.getInt("flutter.widget_active_index", 0)
                val newIndex = (currentIndex - 1 + TRACKS.size) % TRACKS.size
                selectSong(prefs, newIndex)
                updateAllWidgets(context)
            }
            ACTION_NEXT -> {
                val currentIndex = prefs.getInt("flutter.widget_active_index", 0)
                val newIndex = (currentIndex + 1) % TRACKS.size
                selectSong(prefs, newIndex)
                updateAllWidgets(context)
            }
            ACTION_TOGGLE_FAV -> {
                val isFav = prefs.getBoolean("flutter.widget_is_favorite", true)
                prefs.edit().putBoolean("flutter.widget_is_favorite", !isFav).apply()
                updateAllWidgets(context)
            }
            ACTION_SELECT_SONG -> {
                val songIndex = intent.getIntExtra(EXTRA_SONG_INDEX, 0)
                selectSong(prefs, songIndex)
                updateAllWidgets(context)
            }
        }
    }

    private fun selectSong(prefs: SharedPreferences, index: Int) {
        if (index in TRACKS.indices) {
            val track = TRACKS[index]
            prefs.edit()
                .putString("flutter.widget_title", track.first)
                .putString("flutter.widget_subtitle", track.second)
                .putString("flutter.widget_duration", track.third)
                .putInt("flutter.widget_active_index", index)
                .putBoolean("flutter.widget_is_playing", true)
                .apply()
        }
    }

    private fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val thisWidget = ComponentName(context, BhaktiWidgetProvider::class.java)
        val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        onUpdate(context, appWidgetManager, allWidgetIds, prefs)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.bhakti_widget_layout).apply {
                val title = widgetData.getString("flutter.widget_title", "Gayatri Mantra") ?: "Gayatri Mantra"
                val subtitle = widgetData.getString("flutter.widget_subtitle", "Om Bhur Bhuvah Svah...") ?: "Om Bhur Bhuvah Svah..."
                val isPlaying = widgetData.getBoolean("flutter.widget_is_playing", true)
                val isFavorite = widgetData.getBoolean("flutter.widget_is_favorite", true)
                val activeIndex = widgetData.getInt("flutter.widget_active_index", 0)

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_subtitle, subtitle)
                setTextViewText(R.id.widget_btn_fav, if (isFavorite) "❤️" else "🤍")
                setTextViewText(R.id.widget_play_icon, if (isPlaying) "⏸" else "▶")

                // Pending intents for in-widget zero-open interactivity
                val playIntent = PendingIntent.getBroadcast(
                    context, 101,
                    Intent(context, BhaktiWidgetProvider::class.java).setAction(ACTION_TOGGLE_PLAY),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_play, playIntent)

                val prevIntent = PendingIntent.getBroadcast(
                    context, 102,
                    Intent(context, BhaktiWidgetProvider::class.java).setAction(ACTION_PREV),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_prev, prevIntent)

                val nextIntent = PendingIntent.getBroadcast(
                    context, 103,
                    Intent(context, BhaktiWidgetProvider::class.java).setAction(ACTION_NEXT),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_next, nextIntent)

                val favIntent = PendingIntent.getBroadcast(
                    context, 104,
                    Intent(context, BhaktiWidgetProvider::class.java).setAction(ACTION_TOGGLE_FAV),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_fav, favIntent)

                // Song rows intents
                val songRows = listOf(
                    R.id.widget_song_row_0,
                    R.id.widget_song_row_1,
                    R.id.widget_song_row_2,
                    R.id.widget_song_row_3
                )

                for (i in songRows.indices) {
                    val songIntent = PendingIntent.getBroadcast(
                        context, 200 + i,
                        Intent(context, BhaktiWidgetProvider::class.java)
                            .setAction(ACTION_SELECT_SONG)
                            .putExtra(EXTRA_SONG_INDEX, i),
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(songRows[i], songIntent)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
