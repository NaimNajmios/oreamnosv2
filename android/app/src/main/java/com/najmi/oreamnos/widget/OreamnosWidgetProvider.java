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

import org.json.JSONArray;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;

import es.antonborri.home_widget.HomeWidgetLaunchIntent;
import es.antonborri.home_widget.HomeWidgetProvider;

/**
 * "Next up + quota" home-screen widget, payload v2.
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
    private static final String KEY_VERSION = "widget_version";
    private static final String PAYLOAD_VERSION = "2";
    private static final String KEY_UPDATED_AT = "updated_at";
    private static final String KEY_NEXT_SNIPPET = "next_snippet";
    private static final String KEY_NEXT_PAGE = "next_page";
    private static final String KEY_NEXT_AT = "next_at";
    private static final String KEY_NEXT_IS_STORY = "next_is_story";
    private static final String KEY_SCHEDULED_COUNT = "scheduled_count";
    private static final String KEY_DRAFT_COUNT = "draft_count";
    private static final String KEY_DRAFT_TITLE = "draft_title";
    private static final String KEY_QUOTA_MODEL = "quota_model";
    private static final String KEY_QUOTA_USED = "quota_used";
    private static final String KEY_QUOTA_BUDGET = "quota_budget";
    private static final String KEY_QUOTA_RESET_AT = "quota_reset_at";
    private static final String KEY_QUOTA_AVERAGE = "quota_average";
    private static final String KEY_PAGE_NAME = "page_name";
    private static final String KEY_PAGE_CONNECTED = "page_connected";
    private static final String KEY_PAGE_EXPIRED = "page_expired";
    private static final String KEY_SURFACE = "theme_surface";
    private static final String KEY_ON_SURFACE = "theme_on_surface";
    private static final String KEY_MUTED = "theme_muted";
    private static final String KEY_PRIMARY = "theme_primary";
    private static final String KEY_SECOND_ROW = "second_row_mode";
    private static final String KEY_LAST_POST_SNIPPET = "last_post_snippet";
    private static final String KEY_LAST_POST_REACTIONS = "last_post_reactions";
    private static final String KEY_LAST_POST_COMMENTS = "last_post_comments";
    private static final String KEY_LAST_POST_SHARES = "last_post_shares";
    private static final String KEY_LAST_POST_AT = "last_post_at";
    private static final String KEY_BEST_SLOT_LABEL = "best_slot_label";
    private static final String KEY_BEST_SLOT_DETAIL = "best_slot_detail";
    private static final String KEY_STORY_FAILED = "story_failed_count";
    private static final String KEY_WEEK_POST_COUNT = "week_post_count";
    private static final String KEY_PAGES_JSON = "pages_json";

    private static final String URI_SCHEDULED = "oreamnos://scheduled";
    private static final String URI_USAGE = "oreamnos://usage";
    private static final String URI_COMPOSE = "oreamnos://compose";
    private static final String URI_PUBLISH = "oreamnos://publish";

    // One request code per tap target. Never share a code: PendingIntent
    // identity ignores extras, so two targets with the same code would
    // overwrite each other's intent.
    private static final int REQ_ROOT = 11;
    private static final int REQ_SNIPPET = 12;
    private static final int REQ_QUOTA = 13;
    private static final int REQ_COMPOSE = 14;
    private static final int REQ_STORY = 15;
    private static final int REQ_SECONDARY = 16;

    private static final int COLOR_AMBER = 0xFFF59E0B;
    private static final int COLOR_RED = 0xFFEF4444;

    private static final int WIDE_MIN_WIDTH_DP = 250;
    private static final int TALL_MIN_HEIGHT_DP = 110;

    /** Size bucket for one placed widget. */
    private enum WidgetSize {
        /** Narrow and one row: status + next-up only. */
        SMALL,
        /** Narrow and two or more rows. */
        COMPACT,
        /** Wide and one row: a single editorial strip. */
        WIDE,
        /** Wide and two or more rows: the full widget. */
        EXPANDED
    }

    /** Home-screen surfaces go stale quietly; after this they say so. */
    private static final long STALE_AFTER_MS = 24L * 60 * 60 * 1000;

    private static final long PUBLISHING_WINDOW_MS = 15L * 60 * 1000;

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

    @Override
    public void onAppWidgetOptionsChanged(
            Context context,
            AppWidgetManager appWidgetManager,
            int appWidgetId,
            Bundle newOptions) {
        SharedPreferences data = context.getSharedPreferences(
                "HomeWidgetPreferences", Context.MODE_PRIVATE);
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
        WidgetSize size = resolveSize(manager, appWidgetId);
        boolean dense = size == WidgetSize.COMPACT;
        boolean shortSize = size == WidgetSize.SMALL || size == WidgetSize.WIDE;
        boolean showSecondHalf = !shortSize;

        RemoteViews views = new RemoteViews(
                context.getPackageName(), layoutFor(size));

        int surface = parseColor(data.getString(KEY_SURFACE, null), 0xFF1C1C1C);
        int onSurface = parseColor(data.getString(KEY_ON_SURFACE, null), 0xFFFFFFFF);
        int muted = parseColor(data.getString(KEY_MUTED, null), 0xFFB0B3B8);
        int primary = parseColor(data.getString(KEY_PRIMARY, null), 0xFF0095F6);

        applySurface(views, surface);
        views.setTextColor(R.id.widget_kicker, primary);
        views.setTextColor(R.id.widget_page, muted);
        views.setTextColor(R.id.widget_snippet, onSurface);
        views.setTextColor(R.id.widget_when, muted);
        views.setTextColor(R.id.widget_countdown, muted);
        views.setTextColor(R.id.widget_quota_label, muted);
        views.setTextColor(R.id.widget_quota_reset, muted);
        views.setTextColor(R.id.widget_quota_value, primary);
        views.setTextColor(R.id.widget_secondary_label, muted);
        views.setTextColor(R.id.widget_secondary_value, primary);
        views.setTextColor(R.id.widget_secondary_meta, muted);
        views.setTextColor(R.id.widget_compose, primary);
        views.setInt(R.id.widget_divider, "setBackgroundColor", withAlpha(muted, 51));

        // The whole widget is one tap target per state; the chip is the only
        // sibling action and needs the expanded height to breathe.
        boolean showCompose = size == WidgetSize.EXPANDED;
        views.setViewVisibility(
                R.id.widget_compose, showCompose ? View.VISIBLE : View.GONE);
        if (showCompose) {
            bindClick(context, views, R.id.widget_compose, URI_COMPOSE, REQ_COMPOSE);
        }
        // A one-row strip has no room for the divider or the footer.
        views.setViewVisibility(
                R.id.widget_divider, showSecondHalf ? View.VISIBLE : View.GONE);
        views.setViewVisibility(
                R.id.widget_updated, showSecondHalf ? View.VISIBLE : View.GONE);

        long now = System.currentTimeMillis();
        long updatedAt = readLong(data, KEY_UPDATED_AT);
        boolean stale = updatedAt > 0 && now - updatedAt > STALE_AFTER_MS;

        // 1. A payload written by an older app must not render half-missing.
        if (!PAYLOAD_VERSION.equals(data.getString(KEY_VERSION, ""))) {
            views.setTextViewText(R.id.widget_kicker, "UPDATE");
            views.setTextViewText(R.id.widget_page, "Oreamnos");
            views.setTextViewText(
                    R.id.widget_snippet, "Open Oreamnos to update this widget");
            views.setTextViewText(R.id.widget_when, "Tap to refresh");
            hideDynamicBlocks(views);
            views.setViewVisibility(R.id.widget_countdown, View.GONE);
            views.setViewVisibility(R.id.widget_divider, View.GONE);
            views.setViewVisibility(R.id.widget_updated, View.GONE);
            views.setViewVisibility(R.id.widget_compose, View.GONE);
            bindRootAndSnippet(context, views, URI_PUBLISH);
            views.setTextViewText(R.id.widget_updated, "");
            views.setContentDescription(
                    R.id.widget_root,
                    "Oreamnos widget needs an update. Tap to open the app.");
            return views;
        }

        WidgetConfigTarget target = resolvePage(context, appWidgetId, data);
        long nextAt = target.nextAt;
        int scheduledCount = (int) readLong(data, KEY_SCHEDULED_COUNT);
        int draftCount = (int) readLong(data, KEY_DRAFT_COUNT);
        boolean connected = readBool(data, KEY_PAGE_CONNECTED);
        boolean expired = readBool(data, KEY_PAGE_EXPIRED);

        String kicker;
        String snippet;
        String when;
        String tapUri;
        boolean futureNext = false;

        if (!connected) {
            kicker = "PUBLISH";
            snippet = "Connect a Page";
            when = "Open Oreamnos to publish";
            tapUri = URI_PUBLISH;
            nextAt = 0;
        } else if (expired) {
            kicker = "RECONNECT";
            snippet = "Page needs reconnecting";
            when = "Tap to fix the connection";
            tapUri = URI_PUBLISH;
            nextAt = 0;
        } else if (nextAt > now) {
            futureNext = true;
            kicker = scheduledCount > 1 ? "NEXT UP · " + scheduledCount : "NEXT UP";
            snippet = nextSnippet(target, scheduledCount);
            when = whenLabel(context, nextAt);
            tapUri = calendarUri(nextAt);
        } else if (nextAt > 0) {
            // A sync gap, not an error: keep the normal colours.
            long overdue = now - nextAt;
            kicker = "NEXT UP";
            snippet = nextSnippet(target, scheduledCount);
            when = overdue < PUBLISHING_WINDOW_MS
                    ? "Publishing now"
                    : "Scheduled time passed";
            tapUri = URI_SCHEDULED;
            nextAt = 0;
        } else if (draftCount > 0) {
            kicker = "DRAFTS";
            snippet = draftLabel(data, draftCount);
            when = "Tap to continue";
            tapUri = URI_COMPOSE;
        } else {
            String best = clean(data.getString(KEY_BEST_SLOT_LABEL, ""));
            if (TextUtils.isEmpty(best)) {
                kicker = "NEXT UP";
                snippet = "Nothing scheduled";
                when = "Tap to create a post";
            } else {
                kicker = "BEST TIME";
                snippet = "Nothing scheduled";
                when = best;
            }
            tapUri = URI_COMPOSE;
        }

        String pageLabel = target.name;
        if (TextUtils.isEmpty(pageLabel)) pageLabel = data.getString(KEY_PAGE_NAME, "");
        pageLabel = TextUtils.isEmpty(pageLabel) ? "No Page" : pageLabel;
        if (expired && connected) pageLabel = pageLabel + " · reconnect";

        views.setTextViewText(R.id.widget_kicker, kicker);
        views.setTextViewText(R.id.widget_page, pageLabel);
        views.setTextViewText(R.id.widget_snippet, snippet);
        views.setTextViewText(R.id.widget_when, when);

        bindRootAndSnippet(context, views, tapUri);

        // A live countdown only makes sense soon, never over stale data, and
        // never in the one-row strip where it would crowd out the time.
        long delta = nextAt - now;
        boolean showCountdown =
                futureNext
                        && !stale
                        && size != WidgetSize.SMALL
                        && delta > 0
                        && delta < 24L * 60 * 60 * 1000;
        views.setViewVisibility(
                R.id.widget_countdown,
                showCountdown ? View.VISIBLE : View.GONE);
        if (showCountdown && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            long base = SystemClock.elapsedRealtime() + delta;
            views.setChronometerCountDown(R.id.widget_countdown, true);
            views.setChronometer(R.id.widget_countdown, base, "in %s", true);
        }

        String quotaSummary = null;
        if (showSecondHalf) {
            quotaSummary =
                    bindSecondHalf(
                            context, views, data, appWidgetId, dense, primary, muted);
        } else {
            hideDynamicBlocks(views);
        }
        String footer =
                showSecondHalf ? bindFooter(views, data, now, stale, muted) : "";
        if (footer.isEmpty()) {
            views.setViewVisibility(R.id.widget_updated, View.GONE);
        }

        String description = snippet + ". " + when;
        if (quotaSummary != null) description = description + ". " + quotaSummary;
        description = description + ". " + pageLabel;
        views.setContentDescription(R.id.widget_root, description);

        return views;
    }

    /** Page + next-up for this widget: per-widget config, else the flat keys. */
    private static final class WidgetConfigTarget {
        String name = "";
        long nextAt = 0;
        String snippet = "";
        boolean isStory = false;
    }

    private WidgetConfigTarget resolvePage(
            Context context, int appWidgetId, SharedPreferences data) {
        WidgetConfigTarget target = new WidgetConfigTarget();
        target.name = data.getString(KEY_NEXT_PAGE, "");
        target.nextAt = readLong(data, KEY_NEXT_AT);
        target.snippet = data.getString(KEY_NEXT_SNIPPET, "");
        target.isStory = readBool(data, KEY_NEXT_IS_STORY);

        String configured = WidgetConfig.page(context, appWidgetId);
        if (TextUtils.isEmpty(configured)) return target;

        String raw = data.getString(KEY_PAGES_JSON, "[]");
        try {
            JSONArray array = new JSONArray(raw == null ? "[]" : raw);
            for (int i = 0; i < array.length(); i++) {
                JSONObject page = array.optJSONObject(i);
                if (page == null) continue;
                if (!configured.equals(page.optString("id", ""))) continue;
                target.name = page.optString("name", target.name);
                target.nextAt = page.optLong("nextAt", 0L);
                target.snippet = page.optString("snippet", "");
                target.isStory = page.optBoolean("isStory", false);
                return target;
            }
        } catch (Exception ignored) {
            // Corrupt JSON degrades to the flat payload keys.
        }
        return target;
    }

    private static String nextSnippet(
            WidgetConfigTarget target, int scheduledCount) {
        String snippet = clean(target.snippet);
        if (TextUtils.isEmpty(snippet)) {
            snippet = target.isStory ? "Story" : "Scheduled post";
            if (scheduledCount > 1) {
                snippet = snippet + " · 1 of " + scheduledCount;
            }
            return snippet;
        }
        if (target.isStory) snippet = snippet + " · Story";
        return snippet;
    }

    private static String draftLabel(SharedPreferences data, int draftCount) {
        if (draftCount == 1) {
            String title = clean(data.getString(KEY_DRAFT_TITLE, ""));
            return "Draft: " + (TextUtils.isEmpty(title) ? "Untitled draft" : title);
        }
        return draftCount + " drafts waiting";
    }

    /** Paints exactly one second-half block and returns its a11y summary. */
    private String bindSecondHalf(
            Context context,
            RemoteViews views,
            SharedPreferences data,
            int appWidgetId,
            boolean compact,
            int primary,
            int muted) {
        views.setViewVisibility(R.id.widget_quota, View.GONE);
        views.setViewVisibility(R.id.widget_secondary, View.GONE);
        views.setViewVisibility(R.id.widget_badge, View.GONE);

        // Story retry outranks every informational block.
        int storyFailed = (int) readLong(data, KEY_STORY_FAILED);
        if (storyFailed > 0) {
            views.setViewVisibility(R.id.widget_badge, View.VISIBLE);
            views.setTextViewText(
                    R.id.widget_badge,
                    storyFailed == 1 ? "Story needs retry" : storyFailed + " Stories need retry");
            bindClick(context, views, R.id.widget_badge, URI_PUBLISH, REQ_STORY);
            return "Story needs retry";
        }

        String mode = WidgetConfig.row(context, appWidgetId);
        if (TextUtils.isEmpty(mode)) {
            mode = data.getString(KEY_SECOND_ROW, WidgetConfig.ROW_QUOTA);
        }
        if (TextUtils.isEmpty(mode)) mode = WidgetConfig.ROW_QUOTA;

        switch (mode) {
            case WidgetConfig.ROW_ENGAGEMENT:
                if (bindEngagement(context, views, data, primary, muted)) return null;
                return bindQuota(context, views, data, compact, primary, muted);
            case WidgetConfig.ROW_DRAFTS:
                if (bindDrafts(context, views, data, primary, muted)) return null;
                if (bindBestTime(views, data, primary, muted)) return null;
                return bindQuota(context, views, data, compact, primary, muted);
            case WidgetConfig.ROW_BEST_TIME:
                if (bindBestTime(views, data, primary, muted)) return null;
                return bindQuota(context, views, data, compact, primary, muted);
            default:
                String summary = bindQuota(context, views, data, compact, primary, muted);
                if (summary != null) return summary;
                bindEngagement(context, views, data, primary, muted);
                if (bindBestTime(views, data, primary, muted)) return null;
                return null;
        }
    }

    private String bindQuota(
            Context context,
            RemoteViews views,
            SharedPreferences data,
            boolean compact,
            int primary,
            int muted) {
        long used = readLongOrNone(data, KEY_QUOTA_USED);
        long budget = readLongOrNone(data, KEY_QUOTA_BUDGET);
        if (used < 0 || budget <= 0) return null;

        views.setViewVisibility(R.id.widget_quota, View.VISIBLE);
        bindClick(context, views, R.id.widget_quota, URI_USAGE, REQ_QUOTA);

        long clampedUsed = Math.min(used, budget);
        int percent = (int) Math.round((used * 100.0) / budget);
        int quotaColor = used >= budget ? COLOR_RED : (percent >= 80 ? COLOR_AMBER : primary);

        String model = data.getString(KEY_QUOTA_MODEL, "");
        String label = TextUtils.isEmpty(model)
                ? "GEMINI QUOTA"
                : "GEMINI · " + model.toUpperCase(Locale.ROOT);
        if (used >= budget) label = "QUOTA REACHED";

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
        StringBuilder reset = new StringBuilder();
        if (!compact && resetAt > System.currentTimeMillis()) {
            reset.append("resets ").append(durationLabel(resetAt - System.currentTimeMillis()));
        }
        long average = readLongOrNone(data, KEY_QUOTA_AVERAGE);
        if (!compact && average > 0) {
            if (reset.length() > 0) reset.append(" · ");
            reset.append("avg ").append(average).append("/day");
        }
        views.setTextViewText(R.id.widget_quota_reset, reset.toString());
        // The provider is the only owner of this row's visibility.
        views.setViewVisibility(
                R.id.widget_quota_reset,
                reset.length() > 0 ? View.VISIBLE : View.GONE);

        return "Gemini " + clampedUsed + " of " + budget;
    }

    private boolean bindEngagement(
            Context context,
            RemoteViews views,
            SharedPreferences data,
            int primary,
            int muted) {
        if (readLong(data, KEY_LAST_POST_AT) <= 0) return false;
        Long reactions = optionalLong(data, KEY_LAST_POST_REACTIONS);
        Long comments = optionalLong(data, KEY_LAST_POST_COMMENTS);
        Long shares = optionalLong(data, KEY_LAST_POST_SHARES);
        if (reactions == null && comments == null && shares == null) return false;

        List<String> parts = new ArrayList<>();
        if (reactions != null) parts.add(reactions + " reactions");
        if (comments != null) parts.add(comments + " comments");
        if (shares != null) parts.add(shares + " shares");

        String value;
        if (parts.size() == 1) {
            value = parts.get(0);
        } else {
            StringBuilder compactValue = new StringBuilder();
            if (reactions != null) compactValue.append(reactions);
            if (comments != null) {
                if (compactValue.length() > 0) compactValue.append(" · ");
                compactValue.append(comments);
            }
            if (shares != null) {
                if (compactValue.length() > 0) compactValue.append(" · ");
                compactValue.append(shares);
            }
            value = compactValue.toString();
        }

        String snippet = clean(data.getString(KEY_LAST_POST_SNIPPET, ""));
        long at = readLong(data, KEY_LAST_POST_AT);
        String meta = TextUtils.isEmpty(snippet)
                ? "posted " + durationLabel(System.currentTimeMillis() - at) + " ago"
                : snippet + " · " + durationLabel(System.currentTimeMillis() - at) + " ago";

        showSecondary(context, views, "LAST POST", value, meta, URI_SCHEDULED, primary, muted);
        return true;
    }

    private boolean bindDrafts(
            Context context,
            RemoteViews views,
            SharedPreferences data,
            int primary,
            int muted) {
        int count = (int) readLong(data, KEY_DRAFT_COUNT);
        if (count <= 0) return false;
        String title = clean(data.getString(KEY_DRAFT_TITLE, ""));
        if (TextUtils.isEmpty(title)) title = "Untitled draft";
        int weekCount = (int) readLong(data, KEY_WEEK_POST_COUNT);
        String meta = weekCount > 0
                ? weekCount + (weekCount == 1 ? " post this week" : " posts this week")
                : "Tap to continue writing";
        showSecondary(
                context,
                views,
                count == 1 ? "DRAFT" : "DRAFTS",
                count == 1 ? "1" : String.valueOf(count),
                title + " · " + meta,
                URI_COMPOSE,
                primary,
                muted);
        return true;
    }

    private boolean bindBestTime(
            RemoteViews views, SharedPreferences data, int primary, int muted) {
        String label = clean(data.getString(KEY_BEST_SLOT_LABEL, ""));
        if (TextUtils.isEmpty(label)) return false;
        String detail = clean(data.getString(KEY_BEST_SLOT_DETAIL, ""));
        showSecondary(
                views,
                "BEST TIME",
                label,
                TextUtils.isEmpty(detail) ? "From your post history" : detail,
                primary,
                muted);
        return true;
    }

    private void showSecondary(
            Context context,
            RemoteViews views,
            String label,
            String value,
            String meta,
            String tapUri,
            int primary,
            int muted) {
        views.setViewVisibility(R.id.widget_secondary, View.VISIBLE);
        views.setTextViewText(R.id.widget_secondary_label, label);
        views.setTextViewText(R.id.widget_secondary_value, value);
        views.setTextColor(R.id.widget_secondary_value, primary);
        views.setTextViewText(R.id.widget_secondary_meta, meta);
        views.setTextColor(R.id.widget_secondary_meta, muted);
        bindClick(context, views, R.id.widget_secondary, tapUri, REQ_SECONDARY);
    }

    private void showSecondary(
            RemoteViews views,
            String label,
            String value,
            String meta,
            int primary,
            int muted) {
        views.setViewVisibility(R.id.widget_secondary, View.VISIBLE);
        views.setTextViewText(R.id.widget_secondary_label, label);
        views.setTextViewText(R.id.widget_secondary_value, value);
        views.setTextColor(R.id.widget_secondary_value, primary);
        views.setTextViewText(R.id.widget_secondary_meta, meta);
        views.setTextColor(R.id.widget_secondary_meta, muted);
    }

    private String bindFooter(
            RemoteViews views,
            SharedPreferences data,
            long now,
            boolean stale,
            int muted) {
        long updatedAt = readLong(data, KEY_UPDATED_AT);
        int weekCount = (int) readLong(data, KEY_WEEK_POST_COUNT);
        StringBuilder footer = new StringBuilder();
        if (weekCount > 0) {
            footer.append(weekCount).append(" this week");
        }
        if (updatedAt > 0) {
            if (footer.length() > 0) footer.append(" · ");
            footer.append("updated ").append(durationLabel(now - updatedAt)).append(" ago");
        }
        String text = footer.toString();
        // A clear stale warning beats a prettier footer.
        if (stale) text = "Out of date · " + text;
        views.setTextViewText(R.id.widget_updated, text);
        views.setTextColor(R.id.widget_updated, stale ? COLOR_AMBER : muted);
        return text;
    }

    private void hideDynamicBlocks(RemoteViews views) {
        views.setViewVisibility(R.id.widget_quota, View.GONE);
        views.setViewVisibility(R.id.widget_secondary, View.GONE);
        views.setViewVisibility(R.id.widget_badge, View.GONE);
        views.setViewVisibility(R.id.widget_quota_reset, View.GONE);
    }

    private void bindRootAndSnippet(Context context, RemoteViews views, String uri) {
        bindClick(context, views, R.id.widget_root, uri, REQ_ROOT);
        bindClick(context, views, R.id.widget_snippet, uri, REQ_SNIPPET);
    }

    private void applySurface(RemoteViews views, int surface) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ launchers clip widget corners; the drawable adds the
            // radius and the palette tint keeps the nine themes honest.
            views.setInt(R.id.widget_root, "setBackgroundResource", R.drawable.widget_background);
            views.setColorStateList(
                    R.id.widget_root,
                    "setBackgroundTintList",
                    ColorStateList.valueOf(surface));
        } else {
            views.setInt(R.id.widget_root, "setBackgroundColor", surface);
        }
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
        int flags = PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE;
        PendingIntent pendingIntent = PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                flags);
        views.setOnClickPendingIntent(viewId, pendingIntent);
    }

    private static String calendarUri(long epoch) {
        String day = new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date(epoch));
        return "oreamnos://calendar?date=" + day;
    }

    private static WidgetSize resolveSize(
            AppWidgetManager manager, int appWidgetId) {
        Bundle options = manager.getAppWidgetOptions(appWidgetId);
        // MIN_* is the smaller of the portrait/landscape spans, so it is the
        // stable dimension to bucket on. Defaults keep the full layout.
        int minWidth = options.getInt(
                AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 320);
        int minHeight = options.getInt(
                AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 160);
        boolean wide = minWidth >= WIDE_MIN_WIDTH_DP;
        boolean tall = minHeight >= TALL_MIN_HEIGHT_DP;
        if (wide) return tall ? WidgetSize.EXPANDED : WidgetSize.WIDE;
        return tall ? WidgetSize.COMPACT : WidgetSize.SMALL;
    }

    private static int layoutFor(WidgetSize size) {
        switch (size) {
            case SMALL:
                return R.layout.oreamnos_widget_small;
            case WIDE:
                return R.layout.oreamnos_widget_wide;
            case COMPACT:
                return R.layout.oreamnos_widget_compact;
            case EXPANDED:
            default:
                return R.layout.oreamnos_widget;
        }
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

    /** "3h 12m" / "45m" / "2d 4h" - same shape as the Publish tab countdown. */
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

    private static Long optionalLong(SharedPreferences data, String key) {
        long value = readLongOrNone(data, key);
        return value < 0 ? null : value;
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

    private static String clean(String value) {
        if (value == null) return "";
        return value.replaceAll("\\s+", " ").trim();
    }
}
