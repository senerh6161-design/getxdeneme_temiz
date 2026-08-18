package com.example.getx_sayac

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Ana ekrandaki (home screen) widget'ı yöneten sınıf. Flutter kodu değil,
 * saf Kotlin/Android kodu — çünkü ana ekran widget'ları Android'in kendi
 * sistemi tarafından, uygulamanın kendisi tamamen kapalıyken bile çizilir.
 *
 * home_widget paketi, Flutter tarafında `HomeWidget.saveWidgetData(...)`
 * ile kaydedilen veriyi burada `HomeWidgetPlugin.getData(context)` ile
 * okumamızı sağlıyor — iki dünya arasındaki köprü bu.
 */
class HomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Flutter tarafının en son kaydettiği veriyi oku.
        val widgetData = HomeWidgetPlugin.getData(context)
        val count = widgetData.getString("count", "0")

        // Ana ekranda bu widget'tan birden fazla eklenmiş olabilir
        // (örn. kullanıcı iki kere eklerse) — hepsini aynı veriyle güncelle.
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.home_widget_layout).apply {
                setTextViewText(R.id.widget_count, count)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
