package com.asifchowdhury.ramadantimes

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

/**
 * Shared base that reads prayer time data written by Flutter via home_widget package.
 * Flutter writes to SharedPreferences named "HomeWidgetPlugin.<packageName>".
 */
abstract class BasePrayerWidget(private val layoutId: Int) : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(
            "HomeWidgetPlugin.${context.packageName}",
            Context.MODE_PRIVATE
        )

        // Launch app on tap
        val tapIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutId)
            bindViews(views, prefs)
            views.setOnClickPendingIntent(android.R.id.content, pendingIntent)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    abstract fun bindViews(
        views: RemoteViews,
        prefs: android.content.SharedPreferences
    )
}

class PrayerWidgetSmall : BasePrayerWidget(R.layout.prayer_widget_small) {
    override fun bindViews(views: RemoteViews, prefs: android.content.SharedPreferences) {
        val name = prefs.getString("next_prayer_name", "Prayer") ?: "Prayer"
        val time = prefs.getString("next_prayer_time", "--:--") ?: "--:--"
        views.setTextViewText(R.id.widget_small_prayer, name)
        views.setTextViewText(R.id.widget_small_time, time)
    }
}

class PrayerWidgetMedium : BasePrayerWidget(R.layout.prayer_widget_medium) {
    override fun bindViews(views: RemoteViews, prefs: android.content.SharedPreferences) {
        views.setTextViewText(R.id.widget_hijri_date, prefs.getString("hijri_date", "") ?: "")
        views.setTextViewText(R.id.widget_fajr_time,    prefs.getString("fajr_time",    "--:--") ?: "--:--")
        views.setTextViewText(R.id.widget_dhuhr_time,   prefs.getString("dhuhr_time",   "--:--") ?: "--:--")
        views.setTextViewText(R.id.widget_asr_time,     prefs.getString("asr_time",     "--:--") ?: "--:--")
        views.setTextViewText(R.id.widget_maghrib_time, prefs.getString("maghrib_time", "--:--") ?: "--:--")
        views.setTextViewText(R.id.widget_isha_time,    prefs.getString("isha_time",    "--:--") ?: "--:--")

        // Highlight next prayer label in gold
        val nextName = prefs.getString("next_prayer_name", "") ?: ""
        highlightNext(views, nextName)
    }

    private fun highlightNext(views: RemoteViews, name: String) {
        val gold  = 0xFFD4A853.toInt()
        val white = 0xFFFFFFFF.toInt()
        val map = mapOf(
            "Fajr"    to R.id.widget_fajr_label,
            "Dhuhr"   to R.id.widget_dhuhr_label,
            "Asr"     to R.id.widget_asr_label,
            "Maghrib" to R.id.widget_maghrib_label,
            "Isha"    to R.id.widget_isha_label,
        )
        for ((n, id) in map) {
            views.setTextColor(id, if (n == name) gold else 0x99FFFFFFu.toInt())
        }
    }
}
