package com.anhar.dailio

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

/**
 * RemoteViewsService untuk menyuplai data daftar habit ke ListView
 * pada Large Widget.
 */
class DailioWidgetListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return DailioWidgetListFactory(applicationContext)
    }
}

/**
 * Factory yang menyuplai data item-item habit untuk ListView pada Large Widget.
 * Data dibaca dari SharedPreferences yang disimpan oleh Flutter via home_widget.
 */
class DailioWidgetListFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private var habits: List<Pair<String, Boolean>> = emptyList()

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    override fun onDestroy() {
        habits = emptyList()
    }

    override fun getCount(): Int = habits.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_habit_item)

        if (position < habits.size) {
            val (name, done) = habits[position]
            val text = if (done) "✓ $name" else "○ $name"
            views.setTextViewText(R.id.tv_habit_item, text)
            views.setTextColor(
                R.id.tv_habit_item,
                if (done) context.getColor(R.color.widget_done)
                else context.getColor(R.color.widget_text_secondary)
            )
            
            // Set fill-in intent to support click events in ListView
            val fillInIntent = Intent()
            views.setOnClickFillInIntent(R.id.tv_habit_item, fillInIntent)
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false

    /**
     * Memuat data habit dari SharedPreferences
     */
    private fun loadData() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val habitsJson = prefs.getString("habits_json", null)

        habits = if (!habitsJson.isNullOrEmpty()) {
            try {
                val jsonArray = JSONArray(habitsJson)
                val list = mutableListOf<Pair<String, Boolean>>()
                for (i in 0 until jsonArray.length()) {
                    val obj = jsonArray.getJSONObject(i)
                    val name = obj.optString("name", "—")
                    val done = obj.optBoolean("done", false)
                    list.add(Pair(name, done))
                }
                list
            } catch (e: Exception) {
                emptyList()
            }
        } else {
            emptyList()
        }
    }
}
