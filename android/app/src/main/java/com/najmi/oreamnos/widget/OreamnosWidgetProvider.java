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
import android.os.SystemClock;
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
 * "Next up + quota" home-screen widget.
 *
 * <p>Reads the string payload written by {@code HomeWidgetService} through the
 * {@code home_widget} plugin. This class never talks to the network and never
 * reads a token: the payload is display-only data the Flutter side already
 * computed. Every tap opens {@link MainActivity} with an {@code oreamnos://}
 * URI that Dart maps onto a go_router location.
 *
 * <p>The countdown is a {@link android.widget.Chronometer} so it ticks without
 * 30-minute alarm refreshes. Scheduled plugin updates only fire when the next
 * post goes live and when the Pacific quota resets.
 */
public class OreamnosWidgetProvider extends HomeWidgetProvider {

    // Payload keys. Kept in sync with HomeWidgetKeys on the Dart side.
    private static final String KEY_UPDATED_AT = "updated_at";
    private static final String KEY_NEXT_SNIPPET = "next_snippet";
    private static final String KEY_NEXT_AT = "next_at";
    private static final String KEY_NEXT_IS_STORY = "next_is_story";
    private static final String KEY_SCHEDULED_COUNT = "scheduled_count";
    private static final String KEY_DRAFT_COUNT = "draft_count";
    private static final String KEY_QUOTA_MODEL = "quota_model";
    private static final String KEY_QUOTA_USED = "quota_used";
    private static final String KEY_QUOTA_BUDGET = "quota_budget";
    private static final String KEY_QUOTA_RESET_AT = "quota_reset_at";
    private static final String KEY_PAGE_NAME = "page_name";
    private static final String KEY_PAGE_CONNECTED = "page_connected";
    private static final String KEY_PAGE_EXPIRED = "page_expired";
    private static final String KEY_SURFACE = "theme_surface";
    private static final String KEY_ON_SURFACE = "theme_on_surface";
    private static final String KEY_MUTED = "theme_muted";
    private static final String KEY_PRIMARY = "theme_primary";

    private static final String URI_SCHEDULED = "oreamnos://scheduled";
    private static final String URI_USAGE = "oreamnos://usage";
    private static final String URI_COMPOSE = "oreamnos://compose";
    private static final String URI_PUBLISH = "oreamnos://publish";

    private static final int REQ_ROOT = 11;
    private static final int REQ_SNIPPET = 12;
    private static final int REQ_QUOTA = 13;

    private static final int COLOR_AMBER = 0xFFF59E0B;
    private static final int COLOR_RED = 0xFFEF4444;

    private static final int COMPACT_MAX_WIDTH_DP = 250;

    @Override
    public void onUpdate(
            Context context,
            AppWidgetManager appWidgetManager,
            int[] appWidgetIds,
            SharedPreferences widgetData) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = buildViews(context, appWidgetManager, appWidgetId, widgetData);
            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }

    private RemoteViews buildViews(
            Context context,
            AppWidgetManager manager,
            int appWidgetId,
            SharedPreferences data) {
        boolean compact = isCompact(manager, appWidgetId);
        RemoteViews views = new RemoteViews(
                context.getPackageName(),
                compact ? R.layout.oreamnos_widget_compact : R.layout.oreamnos_widget);

        int surface = parseColor(data.getString(KEY_SURFACE, null), 0xFF1C1C1C);
        int onSurface = parseColor(data.getString(KEY_ON_SURFACE, null), 0xFFFFFFFF);
        int muted = parseColor(data.getString(KEY_MUTED, null), 0xFFB0B3B8);
        int primary = parseColor(data.getString(KEY_PRIMARY, null), 0xFF0095F6);

        views.setInt(R.id.widget_root, "setBackgroundColor", surface);
        views.setTextColor(R.id.widget_kicker, primary);
        views.setTextColor(R.id.widget_page, muted);
        views.setTextColor(R.id.widget_snippet, onSurface);
        views.setTextColor(R.id.widget_when, muted);
        views.setTextColor(R.id.widget_countdown, muted);
        views.setTextColor(R.id.widget_quota_label, muted);
        views.setTextColor(R.id.widget_quota_reset, muted);
        views.setTextColor(R.id.widget_updated, muted);

        boolean connected = readBool(data, KEY_PAGE_CONNECTED);
        boolean expired = readBool(data, KEY_PAGE_EXPIRED);
        String pageName = data.getString(KEY_PAGE_NAME, "");
        long nextAt = readLong(data, KEY_NEXT_AT);
        long now = System.currentTimeMillis();
        int scheduledCount = (int) readLong(data, KEY_SCHEDULED_COUNT);
        int draftCount = (int) readLong(data, KEY_DRAFT_COUNT);

        String kicker;
        String snippet;
        String when;
        String tapUri;

        if (!connected) {
            kicker = "PUBLISH";
            snippet = "Connect a Page";
            when = "Open Oreamnos to publish";
            tapUri = URI_PUBLISH;
        } else if (nextAt <= 0) {
            kicker = expired ? "RECONNECT" : "NEXT UP";
            snippet = expired ? "Page needs reconnecting" : "Nothing scheduled";
            when = draftCount > 0
                    ? draftCount + (draftCount == 1 ? " draft waiting" : " drafts waiting")
                    : "Tap to create a post";
            tapUri = expired ? URI_PUBLISH : URI_COMPOSE;
        } else {
            kicker = scheduledCount > 1 ? "NEXT UP · " + scheduledCount : "NEXT UP";
            snippet = data.getString(KEY_NEXT_SNIPPET, "");
            if (TextUtils.isEmpty(snippet)) {
                snippet = readBool(data, KEY_NEXT_IS_STORY) ? "Story" : "Scheduled post";
            } else if (readBool(data, KEY_NEXT_IS_STORY)) {
                snippet = snippet + " · Story";
            }
            when = whenLabel(context, nextAt);
            tapUri = URI_SCHEDULED;
        }

        String pageLabel = TextUtils.isEmpty(pageName) ? "No Page" : pageName;
        if (expired && connected) {
            pageLabel = pageLabel + " · reconnect";
        }

        views.setTextViewText(R.id.widget_kicker, kicker);
        views.setTextViewText(R.id.widget_page, pageLabel);
        views.setTextViewText(R.id.widget_snippet, snippet);
        views.setTextViewText(R.id.widget_when, when);

        bindClick(context, views, R.id.widget_root, tapUri, REQ_ROOT);
        bindClick(context, views, R.id.widget_snippet, tapUri, REQ_SNIPPET);
        views.setContentDescription(
                R.id.widget_root,
                snippet + ". " + when + ". " + pageLabel);

        // A live countdown only makes sense for something happening soon; the
        // absolute label stays the source of truth beyond a day.
        long delta = nextAt - now;
        boolean showCountdown =
                connected && nextAt > 0 && delta > 0 && delta < 24L * 60 * 60 * 1000;
        views.setViewVisibility(
                R.id.widget_countdown,
                showCountdown ? View.VISIBLE : View.GONE);
        if (showCountdown && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            long base = SystemClock.elapsedRealtime() + delta;
            views.setChronometerCountDown(R.id.widget_countdown, true);
            views.setChronometer(R.id.widget_countdown, base, "in %s", true);
        }

        bindQuota(context, views, data, primary, muted);
        bindFooter(views, data, now);

        return views;
    }

    private void bindQuota(
            Context context,
            RemoteViews views,
            SharedPreferences data,
            int primary,
            int muted) {
        long used = readLongOrNone(data, KEY_QUOTA_USED);
        long budget = readLongOrNone(data, KEY_QUOTA_BUDGET);
        if (used < 0 || budget <= 0) {
            views.setViewVisibility(R.id.widget_quota, View.GONE);
            return;
        }

        views.setViewVisibility(R.id.widget_quota, View.VISIBLE);
        bindClick(context, views, R.id.widget_quota, URI_USAGE, REQ_QUOTA);

        long clampedUsed = Math.min(used, budget);
        int percent = (int) Math.round((used * 100.0) / budget);
        int quotaColor = used >= budget ? COLOR_RED : (percent >= 80 ? COLOR_AMBER : primary);

        String model = data.getString(KEY_QUOTA_MODEL, "");
        String label = TextUtils.isEmpty(model)
                ? "GEMINI QUOTA"
                : "GEMINI · " + model.toUpperCase(Locale.ROOT);
        if (used >= budget) {
            label = "QUOTA REACHED";
        }

        views.setTextViewText(R.id.widget_quota_label, label);
        views.setTextViewText(R.id.widget_quota_value, clampedUsed + " / " + budget);
        views.setTextColor(R.id.widget_quota_value, quotaColor);
        views.setProgressBar(R.id.widget_quota_bar, (int) budget, (int) clampedUsed, false);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setColorStateList(
                    R.id.widget_quota_bar,
                    "setProgressTintList",
                    ColorStateList.valueOf(quotaColor));
            views.setColorStateList(
                    R.id.widget_quota_bar,
                    "setProgressBackgroundTintList",
                    ColorStateList.valueOf(withAlpha(muted, 60)));
        }

        long resetAt = readLong(data, KEY_QUOTA_RESET_AT);
        if (resetAt > System.currentTimeMillis()) {
            views.setTextViewText(
                    R.id.widget_quota_reset,
                    "resets " + durationLabel(resetAt - System.currentTimeMillis()));
        } else {
            views.setTextViewText(R.id.widget_quota_reset, "");
        }
    }

    private void bindFooter(RemoteViews views, SharedPreferences data, long now) {
        long updatedAt = readLong(data, KEY_UPDATED_AT);
        String updated =
                updatedAt <= 0 ? "" : "updated " + durationLabel(now - updatedAt) + " ago";
        views.setTextViewText(R.id.widget_updated, updated);
    }

    private void bindClick(
            Context context,
            RemoteViews views,
            int viewId,
            String uri,
            int requestCode) {
        Intent intent = new Intent(context, MainActivity.class);
        intent.setAction(HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION);
        intent.setData(Uri.parse(uri));
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        PendingIntent pendingIntent = PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                flags);
        views.setOnClickPendingIntent(viewId, pendingIntent);
    }

    private static boolean isCompact(AppWidgetManager manager, int appWidgetId) {
        Bundle options = manager.getAppWidgetOptions(appWidgetId);
        int minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 320);
        return minWidth < COMPACT_MAX_WIDTH_DP;
    }

    private static String whenLabel(Context context, long epoch) {
        Calendar now = Calendar.getInstance();
        Calendar target = Calendar.getInstance();
        target.setTimeInMillis(epoch);
        String time = DateFormat.getTimeFormat(context).format(new Date(epoch));

        if (isSameDay(now, target)) return "Today " + time;
        Calendar tomorrow = Calendar.getInstance();
        tomorrow.add(Calendar.DAY_OF_YEAR, 1);
        if (isSameDay(tomorrow, target)) return "Tomorrow " + time;
        return new SimpleDateFormat("EEE d MMM", Locale.getDefault()).format(new Date(epoch))
                + " · " + time;
    }

    private static boolean isSameDay(Calendar a, Calendar b) {
        return a.get(Calendar.YEAR) == b.get(Calendar.YEAR)
                && a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR);
    }

    /** "3h 12m" / "45m" / "2d 4h" — same shape as the Publish tab countdown. */
    private static String durationLabel(long millis) {
        long seconds = Math.max(0, millis / 1000);
        long days = seconds / 86400;
        long hours = (seconds % 86400) / 3600;
        long minutes = (seconds % 3600) / 60;
        if (days > 0) return hours > 0 ? days + "d " + hours + "h" : days + "d";
        if (hours > 0) return minutes > 0 ? hours + "h " + minutes + "m" : hours + "h";
        if (minutes > 0) return minutes + "m";
        return "moments";
    }

    private static boolean readBool(SharedPreferences data, String key) {
        return "1".equals(data.getString(key, "0"));
    }

    private static long readLong(SharedPreferences data, String key) {
        return parseLong(data.getString(key, null), 0L);
    }

    /** Payload uses an empty string for "no value". */
    private static long readLongOrNone(SharedPreferences data, String key) {
        return parseLong(data.getString(key, null), -1L);
    }

    private static long parseLong(String raw, long fallback) {
        if (TextUtils.isEmpty(raw)) return fallback;
        try {
            return Long.parseLong(raw);
        } catch (NumberFormatException ignored) {
            return fallback;
        }
    }

    private static int parseColor(String raw, int fallback) {
        if (TextUtils.isEmpty(raw)) return fallback;
        try {
            return Color.parseColor(raw);
        } catch (IllegalArgumentException ignored) {
            return fallback;
        }
    }

    private static int withAlpha(int color, int alpha) {
        return (color & 0x00FFFFFF) | (Math.max(0, Math.min(255, alpha)) << 24);
    }
}
