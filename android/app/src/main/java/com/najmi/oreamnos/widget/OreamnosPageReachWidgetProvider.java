package com.najmi.oreamnos.widget;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.view.View;
import android.widget.RemoteViews;

import com.najmi.oreamnos.R;

import java.util.Locale;

/**
 * Page-level reach for the window selected in the app's Performance screen.
 *
 * <p>The window (7/28/90 days) is read from the payload on every push, so the
 * widget follows the app setting instead of hard-coding one range. All values
 * come from a cache written by Dart: this receiver never touches a token and
 * never makes a network call.
 */
public class OreamnosPageReachWidgetProvider extends BaseOreamnosWidget {

    private enum Shape {
        ROW,
        SQUARE,
        EXPANDED
    }

    @Override
    protected int layoutFor(int widthDp, int heightDp) {
        switch (shapeFor(widthDp, heightDp)) {
            case ROW:
                return R.layout.oreamnos_page_reach_widget_row;
            case SQUARE:
                return R.layout.oreamnos_page_reach_widget_square;
            case EXPANDED:
            default:
                return R.layout.oreamnos_page_reach_widget;
        }
    }

    private static Shape shapeFor(int widthDp, int heightDp) {
        if (heightDp < TALL_MIN_HEIGHT_DP) return Shape.ROW;
        if (widthDp < WIDE_MIN_WIDTH_DP) return Shape.SQUARE;
        return Shape.EXPANDED;
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
        Shape shape = shapeFor(widthDp, heightDp);
        long now = System.currentTimeMillis();
        boolean stale = isStale(data, now);

        long rawDays = readLong(data, KEY_PAGE_RANGE_DAYS);
        int days = rawDays == 7 || rawDays == 28 || rawDays == 90 ? (int) rawDays : 28;
        Long viewsCount = optionalLong(data, KEY_PAGE_VIEWS);
        Long engagements = optionalLong(data, KEY_PAGE_ENGAGEMENTS);
        Long follows = optionalLong(data, KEY_PAGE_FOLLOWS);
        String viewsDelta = clean(data.getString(KEY_PAGE_VIEWS_DELTA, ""));
        String engagementsDelta = clean(data.getString(KEY_PAGE_ENGAGEMENTS_DELTA, ""));
        long insightsAt = readLongOrNone(data, KEY_PAGE_INSIGHTS_AT);

        boolean connected = readBool(data, KEY_PAGE_CONNECTED);
        boolean hasCache =
                insightsAt > 0
                        || viewsCount != null
                        || engagements != null
                        || follows != null;

        views.setTextColor(R.id.pr_kicker, theme.primary);
        views.setTextColor(R.id.pr_views_label, theme.muted);
        views.setTextColor(R.id.pr_engagements_label, theme.muted);
        views.setTextColor(R.id.pr_follows_label, theme.muted);
        views.setTextColor(R.id.pr_note, theme.muted);
        views.setTextViewText(
                R.id.pr_kicker,
                shape == Shape.ROW ? "REACH" : days + "-DAY REACH");

        if (!connected) {
            showEmpty(views, theme, "Connect a Page", "Open Performance after connecting");
        } else if (!hasCache) {
            showEmpty(views, theme, "No Page insights yet", "Open Performance to load them");
        } else {
            views.setTextColor(R.id.pr_views, theme.onSurface);
            views.setTextColor(R.id.pr_engagements, theme.onSurface);
            views.setTextColor(R.id.pr_follows, theme.onSurface);
            views.setTextViewText(
                    R.id.pr_views, viewsCount == null ? "—" : compact(viewsCount));
            views.setTextViewText(R.id.pr_views_label, "media views");
            views.setTextViewText(
                    R.id.pr_engagements,
                    engagements == null ? "—" : compact(engagements));
            views.setTextViewText(R.id.pr_engagements_label, "engagements");
            views.setTextViewText(
                    R.id.pr_follows, follows == null ? "—" : compact(follows));
            views.setTextViewText(R.id.pr_follows_label, "followers");
            bindDelta(views, R.id.pr_delta, viewsDelta, theme);
            bindDelta(views, R.id.pr_engagement_delta, engagementsDelta, theme);
        }

        // Only the expanded size has room to say how old the cached insight is.
        boolean showNote = shape == Shape.EXPANDED;
        views.setViewVisibility(R.id.pr_note, showNote ? View.VISIBLE : View.GONE);
        if (showNote) {
            String note;
            if (!connected || !hasCache) {
                note = "Data appears after a Performance refresh";
            } else if (insightsAt > 0) {
                long age = now - insightsAt;
                note = age > STALE_AFTER_MS
                        ? "Insights out of date · fetched " + durationLabel(age) + " ago"
                        : "Insights fetched " + durationLabel(age) + " ago";
            } else {
                note = days + "-day window";
            }
            views.setTextViewText(R.id.pr_note, note);
        }

        String footer = "";
        if (shape == Shape.EXPANDED) {
            footer = bindFooter(views, data, now, stale, theme.muted, "");
        } else {
            views.setViewVisibility(R.id.widget_updated, View.GONE);
        }

        bindClick(context, views, R.id.widget_root, URI_PERFORMANCE, REQ_ROOT);

        StringBuilder description = new StringBuilder();
        if (!connected) {
            description.append("Connect a Page to see reach.");
        } else if (!hasCache) {
            description.append("No Page insights yet.");
        } else {
            description.append(days).append("-day reach: ");
            if (viewsCount != null) {
                description.append(viewsCount).append(" media views");
                if (!TextUtils.isEmpty(viewsDelta)) {
                    description.append(", ").append(viewsDelta).append(" vs previous");
                }
            } else {
                description.append("media views unavailable");
            }
            if (engagements != null) {
                description.append(". ").append(engagements).append(" engagements");
            }
            if (follows != null) {
                description.append(". ").append(follows).append(" followers");
            }
        }
        if (!footer.isEmpty()) description.append(". ").append(footer);
        views.setContentDescription(R.id.widget_root, description.toString());
    }

    private void showEmpty(RemoteViews views, WidgetTheme theme, String title, String detail) {
        views.setTextColor(R.id.pr_views, theme.muted);
        views.setTextViewText(R.id.pr_views, title);
        views.setTextViewText(R.id.pr_views_label, detail);
        views.setTextViewText(R.id.pr_engagements, "");
        views.setTextViewText(R.id.pr_engagements_label, "");
        views.setTextViewText(R.id.pr_delta, "");
        views.setTextViewText(R.id.pr_follows, "");
        views.setTextViewText(R.id.pr_follows_label, "");
        views.setTextViewText(R.id.pr_engagement_delta, "");
        views.setViewVisibility(R.id.pr_delta, View.GONE);
        views.setViewVisibility(R.id.pr_engagement_delta, View.GONE);
    }

    private void bindDelta(RemoteViews views, int id, String delta, WidgetTheme theme) {
        boolean visible = !TextUtils.isEmpty(delta);
        views.setViewVisibility(id, visible ? View.VISIBLE : View.GONE);
        if (!visible) return;
        views.setTextViewText(id, delta.equals("same") ? "same" : delta + " vs prev");
        views.setTextColor(
                id,
                delta.startsWith("-") ? COLOR_AMBER : theme.primary);
    }

    private static String compact(long value) {
        if (value >= 1000000L) {
            return String.format(Locale.US, "%.1fm", value / 1000000.0);
        }
        if (value >= 1000L) {
            return String.format(Locale.US, "%.1fk", value / 1000.0);
        }
        return Long.toString(value);
    }
}
