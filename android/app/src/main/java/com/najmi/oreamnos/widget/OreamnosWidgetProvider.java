package com.najmi.oreamnos.widget;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.SystemClock;
import android.text.TextUtils;
import android.view.View;
import android.widget.RemoteViews;

import com.najmi.oreamnos.R;

import org.json.JSONArray;
import org.json.JSONObject;

/**
 * "Next up": when the next scheduled Page post goes live.
 *
 * <p>This is the component that shipped before the widgets were split, so it
 * keeps its class name: a placed widget is bound to its provider component and
 * repurposing it is the only way an upgrade does not leave "Problem loading
 * widget" on every existing home screen.
 *
 * <p>States, in priority order: not connected, token expired, next post
 * scheduled (with a live chronometer), scheduled time just passed, drafts
 * waiting, nothing scheduled. Taps open the calendar on the day of the post.
 */
public class OreamnosWidgetProvider extends BaseOreamnosWidget {

    @Override
    protected int layoutFor(int widthDp, int heightDp) {
        boolean wide = widthDp >= WIDE_MIN_WIDTH_DP;
        boolean tall = heightDp >= TALL_MIN_HEIGHT_DP;
        if (wide) return tall ? R.layout.oreamnos_widget : R.layout.oreamnos_widget_wide;
        return tall
                ? R.layout.oreamnos_widget_compact
                : R.layout.oreamnos_widget_small;
    }

    @Override
    protected void bind(
            Context context,
            RemoteViews views,
            SharedPreferences data,
            int appWidgetId,
            int widthDp,
            int heightDp,
            WidgetTheme theme) {
        boolean wide = widthDp >= WIDE_MIN_WIDTH_DP;
        boolean tall = heightDp >= TALL_MIN_HEIGHT_DP;
        boolean oneRow = !tall;

        views.setTextColor(R.id.widget_kicker, theme.primary);
        views.setTextColor(R.id.widget_page, theme.muted);
        views.setTextColor(R.id.widget_snippet, theme.onSurface);
        views.setTextColor(R.id.widget_when, theme.muted);
        views.setTextColor(R.id.widget_countdown, theme.muted);
        views.setTextColor(R.id.widget_badge, COLOR_AMBER);
        views.setTextColor(R.id.widget_compose, theme.primary);

        // The whole widget is one tap target per state; the chip is the only
        // sibling action and needs the expanded height to breathe.
        boolean showCompose = wide && tall;
        views.setViewVisibility(
                R.id.widget_compose, showCompose ? View.VISIBLE : View.GONE);
        if (showCompose) {
            bindClick(context, views, R.id.widget_compose, URI_COMPOSE, REQ_ACTION);
        }

        long now = System.currentTimeMillis();
        boolean stale = isStale(data, now);
        Target target = resolvePage(context, appWidgetId, data);
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

        bindClick(context, views, R.id.widget_root, tapUri, REQ_ROOT);
        bindClick(context, views, R.id.widget_snippet, tapUri, REQ_HEADLINE);

        // A live countdown only makes sense soon, never over stale data, and
        // never in a one-row strip where it would crowd out the time.
        long delta = nextAt - now;
        boolean showCountdown =
                futureNext
                        && !stale
                        && !oneRow
                        && delta > 0
                        && delta < 24L * 60 * 60 * 1000;
        views.setViewVisibility(
                R.id.widget_countdown, showCountdown ? View.VISIBLE : View.GONE);
        if (showCountdown && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            long base = SystemClock.elapsedRealtime() + delta;
            views.setChronometerCountDown(R.id.widget_countdown, true);
            views.setChronometer(R.id.widget_countdown, base, "in %s", true);
        }

        // Story retry is the one publishing-health warning this widget owns.
        int storyFailed = (int) readLong(data, KEY_STORY_FAILED);
        boolean showBadge = storyFailed > 0;
        views.setViewVisibility(
                R.id.widget_badge, showBadge ? View.VISIBLE : View.GONE);
        if (showBadge) {
            views.setTextViewText(
                    R.id.widget_badge,
                    storyFailed == 1
                            ? "Story needs retry"
                            : storyFailed + " Stories need retry");
            bindClick(context, views, R.id.widget_badge, URI_PUBLISH, REQ_SECOND);
        }

        int weekCount = (int) readLong(data, KEY_WEEK_POST_COUNT);
        String leading =
                weekCount > 0
                        ? (weekCount == 1 ? "1 post this week" : weekCount + " posts this week")
                        : "";
        String footer = bindFooter(views, data, now, stale, theme.muted, leading);

        String description = snippet + ". " + when + ". " + pageLabel;
        if (showBadge) description = description + ". " + storyFailed + " Stories need retry";
        if (!footer.isEmpty()) description = description + ". " + footer;
        views.setContentDescription(R.id.widget_root, description);
    }

    /** Page + next-up for this widget: per-widget config, else the flat keys. */
    private static final class Target {
        String name = "";
        long nextAt = 0;
        String snippet = "";
        boolean isStory = false;
    }

    private Target resolvePage(
            Context context, int appWidgetId, SharedPreferences data) {
        Target target = new Target();
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

    private static String nextSnippet(Target target, int scheduledCount) {
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
}
