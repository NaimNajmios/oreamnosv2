package com.najmi.oreamnos.widget;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Per-widget personalisation (second row + pinned Page).
 *
 * <p>Stored in a dedicated prefs file, never in the {@code home_widget}
 * plugin's {@code HomeWidgetPreferences}: a Dart payload push must never
 * clobber a user's per-widget choice.
 */
final class WidgetConfig {

    static final String PREFS = "oreamnos_widget_config";

    static final String ROW_QUOTA = "quota";
    static final String ROW_ENGAGEMENT = "engagement";
    static final String ROW_DRAFTS = "drafts";
    static final String ROW_BEST_TIME = "bestTime";

    private static final String KEY_ROW_PREFIX = "row_";
    private static final String KEY_PAGE_PREFIX = "page_";

    private WidgetConfig() {}

    /** Empty when the widget follows the global preference. */
    static String row(Context context, int appWidgetId) {
        return prefs(context).getString(KEY_ROW_PREFIX + appWidgetId, "");
    }

    /** Empty when the widget follows the app's active Page. */
    static String page(Context context, int appWidgetId) {
        return prefs(context).getString(KEY_PAGE_PREFIX + appWidgetId, "");
    }

    static void save(Context context, int appWidgetId, String row, String page) {
        SharedPreferences.Editor editor = prefs(context).edit();
        if (row == null || row.isEmpty()) {
            editor.remove(KEY_ROW_PREFIX + appWidgetId);
        } else {
            editor.putString(KEY_ROW_PREFIX + appWidgetId, row);
        }
        if (page == null || page.isEmpty()) {
            editor.remove(KEY_PAGE_PREFIX + appWidgetId);
        } else {
            editor.putString(KEY_PAGE_PREFIX + appWidgetId, page);
        }
        editor.apply();
    }

    /** Called from {@code onDeleted}; leaves sibling widgets untouched. */
    static void delete(Context context, int appWidgetId) {
        prefs(context)
                .edit()
                .remove(KEY_ROW_PREFIX + appWidgetId)
                .remove(KEY_PAGE_PREFIX + appWidgetId)
                .apply();
    }

    private static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }
}
