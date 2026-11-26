package com.najmi.oreamnos.widget;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.text.format.DateFormat;
import android.view.View;
import android.widget.RemoteViews;

import com.najmi.oreamnos.MainActivity;
import com.najmi.oreamnos.R;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

import es.antonborri.home_widget.HomeWidgetLaunchIntent;
import es.antonborri.home_widget.HomeWidgetProvider;

/**
 * Shared plumbing for the five purpose-built widgets.
 *
 * <p>Every widget renders from the same string payload written by
 * {@code HomeWidgetService} through the {@code home_widget} plugin. No widget
 * talks to the network, reads a token or acts in the background: the payload is
 * display-only data the Flutter side already computed, and every tap opens
 * {@link MainActivity} with an {@code oreamnos://} URI that Dart maps onto a
 * go_router location.
 *
 * <p>Subclasses own exactly two decisions: which layout fits the box, and what
 * to write into it. Everything that has bitten us before — the payload version
 * gate, RemoteViews-safe surfaces, per-widget config cleanup, PendingIntent
 * identity, the staleness footer — lives here once.
 */
public abstract class BaseOreamnosWidget extends HomeWidgetProvider {

    // Payload keys. Kept in sync with HomeWidgetKeys on the Dart side.
    protected static final String KEY_VERSION = "widget_version";
    static final String PAYLOAD_VERSION = "5";
    protected static final String KEY_UPDATED_AT = "updated_at";
    protected static final String KEY_NEXT_SNIPPET = "next_snippet";
    protected static final String KEY_NEXT_PAGE = "next_page";
    protected static final String KEY_NEXT_AT = "next_at";
    protected static final String KEY_NEXT_IS_STORY = "next_is_story";
    protected static final String KEY_SCHEDULED_COUNT = "scheduled_count";
    protected static final String KEY_DRAFT_COUNT = "draft_count";
    protected static final String KEY_DRAFT_TITLE = "draft_title";
    protected static final String KEY_DRAFT_TITLES = "draft_titles_json";
    protected static final String KEY_DRAFT_UPDATED_AT = "draft_updated_at";
    protected static final String KEY_QUOTA_JSON = "quota_json";
    protected static final String KEY_ACTIVE_PROVIDER = "active_provider";
    protected static final String KEY_FALLBACK_PROVIDER = "fallback_provider";
    protected static final String KEY_PAGE_NAME = "page_name";
    protected static final String KEY_PAGE_CONNECTED = "page_connected";
    protected static final String KEY_PAGE_EXPIRED = "page_expired";
    protected static final String KEY_SURFACE = "theme_surface";
    protected static final String KEY_ON_SURFACE = "theme_on_surface";
    protected static final String KEY_MUTED = "theme_muted";
    protected static final String KEY_PRIMARY = "theme_primary";
    protected static final String KEY_LAST_POST_SNIPPET = "last_post_snippet";
    protected static final String KEY_LAST_POST_REACTIONS = "last_post_reactions";
    protected static final String KEY_LAST_POST_COMMENTS = "last_post_comments";
    protected static final String KEY_LAST_POST_SHARES = "last_post_shares";
    protected static final String KEY_LAST_POST_IMPRESSIONS = "last_post_impressions";
    protected static final String KEY_LAST_POST_UNIQUE_VIEWERS = "last_post_unique_viewers";
    protected static final String KEY_LAST_POST_AT = "last_post_at";
    protected static final String KEY_WEEK_REACTIONS = "week_reactions";
    protected static final String KEY_WEEK_COMMENTS = "week_comments";
    protected static final String KEY_WEEK_SHARES = "week_shares";
    protected static final String KEY_BEST_SLOT_LABEL = "best_slot_label";
    protected static final String KEY_BEST_SLOT_DETAIL = "best_slot_detail";
    protected static final String KEY_BEST_SLOT_CONFIDENT = "best_slot_confident";
    protected static final String KEY_BEST_SLOT_NEXT_AT = "best_slot_next_at";
    protected static final String KEY_BEST_SLOT_SAMPLES = "best_slot_samples";
    protected static final String KEY_STORY_FAILED = "story_failed_count";
    protected static final String KEY_WEEK_POST_COUNT = "week_post_count";
    protected static final String KEY_PAGES_JSON = "pages_json";
    protected static final String KEY_LAST_PUBLISHED_AT = "last_published_at";
    protected static final String KEY_PAGE_VIEWS = "page_views";
    protected static final String KEY_PAGE_ENGAGEMENTS = "page_engagements";
    protected static final String KEY_PAGE_FOLLOWS = "page_follows";
    protected static final String KEY_PAGE_VIEWS_DELTA = "page_views_delta";
    protected static final String KEY_PAGE_ENGAGEMENTS_DELTA =
            "page_engagements_delta";
    protected static final String KEY_PAGE_RANGE_DAYS = "page_range_days";
    protected static final String KEY_PAGE_INSIGHTS_AT = "page_insights_at";

    protected static final String PREFERENCES = "HomeWidgetPreferences";

    protected static final String URI_SCHEDULED = "oreamnos://scheduled";
    protected static final String URI_HISTORY = "oreamnos://history";
    protected static final String URI_USAGE = "oreamnos://usage";
    protected static final String URI_COMPOSE = "oreamnos://compose";
    protected static final String URI_PUBLISH = "oreamnos://publish";
    protected static final String URI_PERFORMANCE = "oreamnos://performance";

    // One request code per widget family. A widget only ever has a handful of
    // distinct tap targets, and PendingIntent identity ignores extras, so any
    // two targets sharing a code would overwrite each other.
    protected static final int REQ_ROOT = 11;
    protected static final int REQ_HEADLINE = 12;
    protected static final int REQ_ACTION = 13;
    protected static final int REQ_SECOND = 14;
    protected static final int REQ_THIRD = 15;

    protected static final int COLOR_AMBER = 0xFFF59E0B;
    protected static final int COLOR_RED = 0xFFEF4444;

    /** Home-screen surfaces go stale quietly; after this they say so. */
    protected static final long STALE_AFTER_MS = 24L * 60 * 60 * 1000;

    protected static final long PUBLISHING_WINDOW_MS = 15L * 60 * 1000;

    // Size thresholds in dp, shared so every widget buckets the same way.
    protected static final int WIDE_MIN_WIDTH_DP = 250;
    protected static final int TALL_MIN_HEIGHT_DP = 110;
    protected static final int STRIP_MIN_HEIGHT_DP = 60;
    protected static final int SQUARE_MAX_DP = 170;

    @Override
    public void onUpdate(
            Context context,
            AppWidgetManager appWidgetManager,
            int[] appWidgetIds,
            SharedPreferences widgetData) {
        for (int appWidgetId : appWidgetIds) {
            appWidgetManager.updateAppWidget(
                    appWidgetId,
                    buildViews(context, appWidgetManager, appWidgetId, widgetData));
        }
    }

    @Override
    public void onAppWidgetOptionsChanged(
            Context context,
            AppWidgetManager appWidgetManager,
            int appWidgetId,
            Bundle newOptions) {
        // Resizing must re-render immediately: waiting for the 30-minute
        // periodic update would leave a stale frame inside a new box.
        SharedPreferences data =
                context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
        appWidgetManager.updateAppWidget(
                appWidgetId, buildViews(context, appWidgetManager, appWidgetId, data));
    }

    @Override
    public void onDeleted(Context context, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            WidgetConfig.delete(context, appWidgetId);
        }
    }

    private RemoteViews buildViews(
            Context context,
            AppWidgetManager manager,
            int appWidgetId,
            SharedPreferences data) {
        Bundle options = manager.getAppWidgetOptions(appWidgetId);
        int widthDp = widthDp(options);
        int heightDp = heightDp(options);

        RemoteViews views =
                new RemoteViews(context.getPackageName(), layoutFor(widthDp, heightDp));
        WidgetTheme theme = WidgetTheme.from(data);
        applySurface(views, theme.surface);

        if (!PAYLOAD_VERSION.equals(data.getString(KEY_VERSION, ""))) {
            renderOutdated(context, views, theme);
            return views;
        }
        views.setViewVisibility(R.id.widget_notice, View.GONE);
        views.setViewVisibility(R.id.widget_body, View.VISIBLE);
        bind(context, views, data, appWidgetId, widthDp, heightDp, theme);
        return views;
    }

    /** The layout that fits a box of {@code widthDp} x {@code heightDp}. */
    protected abstract int layoutFor(int widthDp, int heightDp);

    /** Writes this widget's content. The payload version is already valid. */
    protected abstract void bind(
            Context context,
            RemoteViews views,
            SharedPreferences data,
            int appWidgetId,
            int widthDp,
            int heightDp,
            WidgetTheme theme);

    // --- Shared rendering helpers -------------------------------------------

    /**
     * A payload written by an older app must not render half-missing. Every
     * layout declares the same notice and body ids so this is one code path.
     */
    protected void renderOutdated(Context context, RemoteViews views, WidgetTheme theme) {
        views.setViewVisibility(R.id.widget_body, View.GONE);
        views.setViewVisibility(R.id.widget_notice, View.VISIBLE);
        views.setTextViewText(
                R.id.widget_notice, "Open Oreamnos to update this widget");
        views.setTextColor(R.id.widget_notice, theme.muted);
        views.setTextViewText(R.id.widget_updated, "");
        views.setViewVisibility(R.id.widget_updated, View.GONE);
        bindClick(context, views, R.id.widget_root, URI_PUBLISH, REQ_ROOT);
        views.setContentDescription(
                R.id.widget_root,
                "Oreamnos widget needs an update. Tap to open the app.");
    }

    protected static int widthDp(Bundle options) {
        return options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 320);
    }

    protected static int heightDp(Bundle options) {
        return options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 160);
    }

    protected void applySurface(RemoteViews views, int surface) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ launchers clip widget corners; the drawable adds the
            // radius and the palette tint keeps the nine themes honest.
            views.setInt(
                    R.id.widget_root,
                    "setBackgroundResource",
                    R.drawable.widget_background);
            views.setColorStateList(
                    R.id.widget_root,
                    "setBackgroundTintList",
                    ColorStateList.valueOf(surface));
        } else {
            views.setInt(R.id.widget_root, "setBackgroundColor", surface);
        }
    }

    /**
     * Footer line: week context, freshness, and an explicit stale warning.
     * Returns the text so callers can fold it into the accessibility summary.
     */
    protected String bindFooter(
            RemoteViews views,
            SharedPreferences data,
            long now,
            boolean stale,
            int muted,
            String leading) {
        long updatedAt = readLong(data, KEY_UPDATED_AT);
        StringBuilder footer = new StringBuilder();
        if (!TextUtils.isEmpty(leading)) footer.append(leading);
        if (updatedAt > 0) {
            if (footer.length() > 0) footer.append(" · ");
            footer.append("updated ").append(durationLabel(now - updatedAt)).append(" ago");
        }
        String text = footer.toString();
        // A clear stale warning beats a prettier footer.
        if (stale) text = "Out of date · " + text;
        views.setTextViewText(R.id.widget_updated, text);
        views.setTextColor(R.id.widget_updated, stale ? COLOR_AMBER : muted);
        views.setViewVisibility(
                R.id.widget_updated, text.isEmpty() ? View.GONE : View.VISIBLE);
        return text;
    }

    protected static boolean isStale(SharedPreferences data, long now) {
        long updatedAt = readLong(data, KEY_UPDATED_AT);
        return updatedAt > 0 && now - updatedAt > STALE_AFTER_MS;
    }

    protected void bindClick(
            Context context, RemoteViews views, int viewId, String uri, int requestCode) {
        views.setOnClickPendingIntent(viewId, pendingIntent(context, requestCode, uri));
    }

    private static PendingIntent pendingIntent(
            Context context, int requestCode, String uri) {
        Intent intent = new Intent(context, MainActivity.class);
        intent.setAction(HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION);
        intent.setData(Uri.parse(uri));
        int flags = PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE;
        return PendingIntent.getActivity(context, requestCode, intent, flags);
    }

    protected static String calendarUri(long epoch) {
        String day =
                new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date(epoch));
        return "oreamnos://calendar?date=" + day;
    }

    protected static String whenLabel(Context context, long epoch) {
        Calendar now = Calendar.getInstance();
        Calendar target = Calendar.getInstance();
        target.setTimeInMillis(epoch);
        String time = DateFormat.getTimeFormat(context).format(new Date(epoch));

        if (isSameDay(now, target)) return "Today " + time;
        Calendar tomorrow = Calendar.getInstance();
        tomorrow.add(Calendar.DAY_OF_YEAR, 1);
        if (isSameDay(tomorrow, target)) return "Tomorrow " + time;
        return new SimpleDateFormat("EEE d MMM", Locale.getDefault())
                .format(new Date(epoch))
                + " · "
                + time;
    }

    protected static boolean isSameDay(Calendar a, Calendar b) {
        return a.get(Calendar.YEAR) == b.get(Calendar.YEAR)
                && a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR);
    }

    /** "3h 12m" / "45m" / "2d 4h" — same shape as the Publish tab countdown. */
    protected static String durationLabel(long millis) {
        long seconds = Math.max(0, millis / 1000);
        long days = seconds / 86400;
        long hours = (seconds % 86400) / 3600;
        long minutes = (seconds % 3600) / 60;
        if (days > 0) return hours > 0 ? days + "d " + hours + "h" : days + "d";
        if (hours > 0) return minutes > 0 ? hours + "h " + minutes + "m" : hours + "h";
        if (minutes > 0) return minutes + "m";
        return "moments";
    }

    protected static boolean readBool(SharedPreferences data, String key) {
        return "1".equals(data.getString(key, "0"));
    }

    protected static long readLong(SharedPreferences data, String key) {
        return parseLong(data.getString(key, null), 0L);
    }

    /** The payload uses an empty string for "no value". */
    protected static long readLongOrNone(SharedPreferences data, String key) {
        return parseLong(data.getString(key, null), -1L);
    }

    protected static Long optionalLong(SharedPreferences data, String key) {
        long value = readLongOrNone(data, key);
        return value < 0 ? null : value;
    }

    protected static long parseLong(String raw, long fallback) {
        if (TextUtils.isEmpty(raw)) return fallback;
        try {
            return Long.parseLong(raw);
        } catch (NumberFormatException ignored) {
            return fallback;
        }
    }

    protected static int parseColor(String raw, int fallback) {
        if (TextUtils.isEmpty(raw)) return fallback;
        try {
            return Color.parseColor(raw);
        } catch (IllegalArgumentException ignored) {
            return fallback;
        }
    }

    protected static int withAlpha(int color, int alpha) {
        return (color & 0x00FFFFFF) | (Math.max(0, Math.min(255, alpha)) << 24);
    }

    protected static String clean(String value) {
        if (value == null) return "";
        return value.replaceAll("\\s+", " ").trim();
    }

    /** Colours mirrored from the active app theme. */
    static final class WidgetTheme {
        final int surface;
        final int onSurface;
        final int muted;
        final int primary;

        private WidgetTheme(int surface, int onSurface, int muted, int primary) {
            this.surface = surface;
            this.onSurface = onSurface;
            this.muted = muted;
            this.primary = primary;
        }

        static WidgetTheme from(SharedPreferences data) {
            return new WidgetTheme(
                    parseColor(data.getString(KEY_SURFACE, null), 0xFF1C1C1C),
                    parseColor(data.getString(KEY_ON_SURFACE, null), 0xFFFFFFFF),
                    parseColor(data.getString(KEY_MUTED, null), 0xFFB0B3B8),
                    parseColor(data.getString(KEY_PRIMARY, null), 0xFF0095F6));
        }
    }
}
