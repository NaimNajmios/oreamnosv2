package com.najmi.oreamnos.widget;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Per-widget personalisation: which Page, and which two AI providers the quota
 * widget follows.
 *
 * <p>Stored in a dedicated prefs file, never in the {@code home_widget} plugin's
 * {@code HomeWidgetPreferences}: a Dart payload push must never clobber a user's
 * per-widget choice.
 */
final class WidgetConfig {

    static final String PREFS = "oreamnos_widget_config";

    /** Explicit "no second slot" for the quota widget. */
    static final String NONE = "-";

    private static final String KEY_PAGE_PREFIX = "page_";
    private static final String KEY_PRIMARY_PREFIX = "primary_";
    private static final String KEY_SECONDARY_PREFIX = "secondary_";

    private WidgetConfig() {}

    /** Empty when the Next-up widget follows the app's active Page. */
    static String page(Context context, int appWidgetId) {
        String value = prefs(context).getString(KEY_PAGE_PREFIX + appWidgetId, "");
        return value == null ? "" : value;
    }

    /** Empty when the quota widget follows the app's active provider. */
    static String primaryProvider(Context context, int appWidgetId) {
        String value = prefs(context).getString(KEY_PRIMARY_PREFIX + appWidgetId, "");
        return value == null ? "" : value;
    }

    /**
     * Empty means "not configured — use the fallback provider"; {@link #NONE}
     * means the user explicitly hid the second slot.
     */
    static String secondaryProvider(Context context, int appWidgetId) {
        String value = prefs(context).getString(KEY_SECONDARY_PREFIX + appWidgetId, "");
        return value == null ? "" : value;
    }

    static void savePage(Context context, int appWidgetId, String page) {
        write(context, KEY_PAGE_PREFIX + appWidgetId, page);
    }

    static void saveProviders(
            Context context, int appWidgetId, String primary, String secondary) {
        SharedPreferences.Editor editor = prefs(context).edit();
        put(editor, KEY_PRIMARY_PREFIX + appWidgetId, primary);
        put(editor, KEY_SECONDARY_PREFIX + appWidgetId, secondary);
        editor.apply();
    }

    /** Called from {@code onDeleted}; leaves sibling widgets untouched. */
    static void delete(Context context, int appWidgetId) {
        prefs(context)
                .edit()
                .remove(KEY_PAGE_PREFIX + appWidgetId)
                .remove(KEY_PRIMARY_PREFIX + appWidgetId)
                .remove(KEY_SECONDARY_PREFIX + appWidgetId)
                .apply();
    }

    private static void write(Context context, String key, String value) {
        SharedPreferences.Editor editor = prefs(context).edit();
        put(editor, key, value);
        editor.apply();
    }

    private static void put(
            SharedPreferences.Editor editor, String key, String value) {
        if (value == null || value.isEmpty()) {
            editor.remove(key);
        } else {
            editor.putString(key, value);
        }
    }

    private static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }
}
