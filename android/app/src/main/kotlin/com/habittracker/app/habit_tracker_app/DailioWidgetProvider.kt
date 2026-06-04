package com.anhar.dailio

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

/**
 * AppWidgetProvider utama untuk Dailio Home Screen Widget.
 * Mendukung 3 ukuran: Small, Medium, dan Large.
 * Data dibaca dari SharedPreferences yang disimpan oleh Flutter via home_widget package.
 */
class DailioWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Handle update broadcast dari Flutter side
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)

            // Update all widget variants
            val smallIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, DailioWidgetSmall::class.java)
            )
            val mediumIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, DailioWidgetMedium::class.java)
            )
            val largeIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, DailioWidgetLarge::class.java)
            )

            for (id in smallIds) updateSmallWidget(context, appWidgetManager, id)
            for (id in mediumIds) updateMediumWidget(context, appWidgetManager, id)
            for (id in largeIds) updateLargeWidget(context, appWidgetManager, id)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Default update — subclasses override behavior
    }

    companion object {
        /**
         * Membaca SharedPreferences yang disimpan oleh home_widget Flutter package.
         * Key default: HomeWidgetPlugin menggunakan "HomeWidgetPreferences"
         */
        fun getWidgetPrefs(context: Context): SharedPreferences {
            return context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        }

        /**
         * Membuat PendingIntent untuk membuka aplikasi saat widget di-tap
         */
        fun createOpenAppIntent(context: Context): PendingIntent {
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent()
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        /**
         * Parse daftar habit dari JSON string
         */
        fun parseHabits(habitsJson: String?): List<Pair<String, Boolean>> {
            if (habitsJson.isNullOrEmpty()) return emptyList()
            return try {
                val jsonArray = JSONArray(habitsJson)
                val habits = mutableListOf<Pair<String, Boolean>>()
                for (i in 0 until jsonArray.length()) {
                    val obj = jsonArray.getJSONObject(i)
                    val name = obj.optString("name", "—")
                    val done = obj.optBoolean("done", false)
                    habits.add(Pair(name, done))
                }
                habits
            } catch (e: Exception) {
                emptyList()
            }
        }

        /**
         * Format teks habit item dengan status ikon
         */
        fun formatHabitText(name: String, done: Boolean): String {
            return if (done) "✓ $name" else "○ $name"
        }

        /**
         * Update Small Widget
         */
        fun updateSmallWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = getWidgetPrefs(context)
            val streak = prefs.getInt("streak", 0)
            val completed = prefs.getInt("completed", 0)
            val total = prefs.getInt("total", 0)

            val views = RemoteViews(context.packageName, R.layout.widget_small)

            views.setTextViewText(R.id.tv_streak, "🔥 $streak Hari Streak")
            views.setTextViewText(R.id.tv_progress, "$completed/$total")

            // Tap to open app
            views.setOnClickPendingIntent(R.id.widget_small_root, createOpenAppIntent(context))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /**
         * Update Medium Widget
         */
        fun updateMediumWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = getWidgetPrefs(context)
            val streak = prefs.getInt("streak", 0)
            val completed = prefs.getInt("completed", 0)
            val total = prefs.getInt("total", 0)
            val habitsJson = prefs.getString("habits_json", null)

            val views = RemoteViews(context.packageName, R.layout.widget_medium)

            views.setTextViewText(R.id.tv_streak, "🔥 $streak")
            views.setTextViewText(R.id.tv_progress, "$completed/$total")

            // Progress bar
            val progressPercent = if (total > 0) (completed * 100 / total) else 0
            views.setProgressBar(R.id.progress_bar, 100, progressPercent, false)

            // Parse dan tampilkan 3 habit pertama
            val habits = parseHabits(habitsJson)
            val habitViews = listOf(R.id.tv_habit_1, R.id.tv_habit_2, R.id.tv_habit_3)

            for (i in habitViews.indices) {
                if (i < habits.size) {
                    val (name, done) = habits[i]
                    views.setTextViewText(habitViews[i], formatHabitText(name, done))
                    views.setTextColor(
                        habitViews[i],
                        if (done) context.getColor(R.color.widget_done)
                        else context.getColor(R.color.widget_text_secondary)
                    )
                    views.setViewVisibility(habitViews[i], View.VISIBLE)
                } else {
                    views.setViewVisibility(habitViews[i], View.GONE)
                }
            }

            // Tap to open app
            views.setOnClickPendingIntent(R.id.widget_medium_root, createOpenAppIntent(context))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /**
         * Update Large Widget
         */
        fun updateLargeWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = getWidgetPrefs(context)
            val streak = prefs.getInt("streak", 0)
            val completed = prefs.getInt("completed", 0)
            val total = prefs.getInt("total", 0)
            val habitsJson = prefs.getString("habits_json", null)

            val views = RemoteViews(context.packageName, R.layout.widget_large)

            views.setTextViewText(R.id.tv_streak, "🔥 $streak")
            views.setTextViewText(R.id.tv_progress, "$completed/$total")

            // Progress bar
            val progressPercent = if (total > 0) (completed * 100 / total) else 0
            views.setProgressBar(R.id.progress_bar, 100, progressPercent, false)

            // Setup ListView with RemoteViewsService
            val habits = parseHabits(habitsJson)
            if (habits.isEmpty()) {
                views.setViewVisibility(R.id.lv_habits, View.GONE)
                views.setViewVisibility(R.id.tv_empty, View.VISIBLE)
                views.setOnClickPendingIntent(R.id.tv_empty, createOpenAppIntent(context))
            } else {
                views.setViewVisibility(R.id.lv_habits, View.VISIBLE)
                views.setViewVisibility(R.id.tv_empty, View.GONE)

                val serviceIntent = Intent(context, DailioWidgetListService::class.java)
                serviceIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                serviceIntent.data = android.net.Uri.parse(serviceIntent.toUri(Intent.URI_INTENT_SCHEME))
                views.setRemoteAdapter(R.id.lv_habits, serviceIntent)
                
                // Set PendingIntent template to launch the app when list items are clicked
                views.setPendingIntentTemplate(R.id.lv_habits, createOpenAppIntent(context))
            }

            // Tap to open app
            views.setOnClickPendingIntent(R.id.widget_large_root, createOpenAppIntent(context))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

/**
 * Widget provider untuk ukuran Small (2×1)
 */
class DailioWidgetSmall : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            DailioWidgetProvider.updateSmallWidget(context, appWidgetManager, appWidgetId)
        }
    }
}

/**
 * Widget provider untuk ukuran Medium (4×2)
 */
class DailioWidgetMedium : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            DailioWidgetProvider.updateMediumWidget(context, appWidgetManager, appWidgetId)
        }
    }
}

/**
 * Widget provider untuk ukuran Large (4×4)
 */
class DailioWidgetLarge : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            DailioWidgetProvider.updateLargeWidget(context, appWidgetManager, appWidgetId)
        }
    }
}
