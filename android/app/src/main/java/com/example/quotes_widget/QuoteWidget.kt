package com.example.quotes_widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.net.Uri
import android.content.SharedPreferences
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// New import.
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider


/**
 * Implementation of App Widget functionality.
 */
class QuoteWidget : AppWidgetProvider() {
    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            // Get reference to SharedPreferences
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.quote_widget).apply {

                val title = widgetData.getString("author", null)
                setTextViewText(R.id.author, title ?: "No title set")

                val description = widgetData.getString("quote", null)
                setTextViewText(R.id.quote, description ?: "No description set")
            
                val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("quote_widget://refresh"))
                setOnClickPendingIntent(R.id.refresh, refreshIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

}
