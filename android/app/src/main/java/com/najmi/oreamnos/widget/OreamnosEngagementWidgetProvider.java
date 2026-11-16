package com.najmi.oreamnos.widget;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.view.View;
import android.widget.RemoteViews;

import com.najmi.oreamnos.R;

/**
 * "Engagement": how the last published post — and this week — are doing.
 *
 * <p>Metrics come from the cached post records; a post with no cached metrics
 * is skipped by the payload builder, so this widget never shows a row of
 * zeroes for a post nobody has measured yet. The caption is only present when
 * the user opted into showing it on the home screen.
 */
public class OreamnosEngagementWidgetProvider extends BaseOreamnosWidget {

    private enum Shape {
        ROW,
        GRID,
        EXPANDED
    }

    @Override
    protected int layoutFor(int widthDp, int heightDp) {
        switch (shapeFor(widthDp, heightDp)) {
            case ROW:
                return R.layout.oreamnos_engagement_widget_row;
            case GRID:
                return R.layout.oreamnos_engagement_widget_grid;
            case EXPANDED:
            default:
                return R.layout.oreamnos_engagement_widget;
        }
    }

    private static Shape shapeFor(int widthDp, int heightDp) {
        if (heightDp < TALL_MIN_HEIGHT_DP) return Shape.ROW;
        if (widthDp < WIDE_MIN_WIDTH_DP) return Shape.GRID;
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
        boolean combined = shape == Shape.GRID;
        boolean showFooter = shape != Shape.ROW;

        long postedAt = readLong(data, KEY_LAST_POST_AT);
        Long reactions = optionalLong(data, KEY_LAST_POST_REACTIONS);
        Long comments = optionalLong(data, KEY_LAST_POST_COMMENTS);
        Long shares = optionalLong(data, KEY_LAST_POST_SHARES);
        boolean hasPost =
                postedAt > 0
                        && (reactions != null || comments != null || shares != null);

        views.setTextColor(R.id.eng_kicker, theme.primary);
        views.setTextColor(R.id.eng_meta, theme.muted);
        views.setTextColor(R.id.eng_caption, theme.muted);
        int[] valueIds = {
            R.id.eng_r_value, R.id.eng_c_value, R.id.eng_s_value
        };
        int[] labelIds = {
            R.id.eng_r_label, R.id.eng_c_label, R.id.eng_s_label
        };
        for (int id : valueIds) views.setTextColor(id, hasPost ? theme.onSurface : theme.muted);
        for (int id : labelIds) views.setTextColor(id, theme.muted);

        if (!hasPost) {
            views.setTextViewText(R.id.eng_kicker, "ENGAGEMENT");
            views.setTextViewText(R.id.eng_meta, "no posts yet");
            setMetric(views, valueIds[0], reactions, "reactions", combined);
            setMetric(views, valueIds[1], comments, "comments", combined);
            setMetric(views, valueIds[2], shares, "shares", combined);
            showLabels(views, labelIds, !combined);
            if (combined) {
                // Nothing to share yet: say so once, not three times.
                views.setTextViewText(R.id.eng_r_value, "No engagement yet");
                views.setViewVisibility(R.id.eng_c_value, View.GONE);
                views.setViewVisibility(R.id.eng_s_value, View.GONE);
            }
            views.setViewVisibility(R.id.eng_caption, View.GONE);
            String footer = bindFooter(views, data, System.currentTimeMillis(), false, theme.muted, "");
            bindClick(context, views, R.id.widget_root, URI_HISTORY, REQ_ROOT);
            views.setContentDescription(
                    R.id.widget_root,
                    "No engagement yet. Tap to see your posts."
                            + (footer.isEmpty() ? "" : " " + footer));
            return;
        }

        long now = System.currentTimeMillis();
        boolean stale = isStale(data, now);
        String age = durationLabel(now - postedAt) + " ago";
        views.setTextViewText(R.id.eng_kicker, "LAST POST");
        views.setTextViewText(
                R.id.eng_meta, shape == Shape.ROW ? durationLabel(now - postedAt) : age);

        setMetric(views, valueIds[0], reactions, "reactions", combined);
        setMetric(views, valueIds[1], comments, "comments", combined);
        setMetric(views, valueIds[2], shares, "shares", combined);
        showLabels(views, labelIds, !combined);

        String caption = clean(data.getString(KEY_LAST_POST_SNIPPET, ""));
        boolean showCaption = shape == Shape.EXPANDED && !TextUtils.isEmpty(caption);
        views.setViewVisibility(
                R.id.eng_caption, showCaption ? View.VISIBLE : View.GONE);
        if (showCaption) views.setTextViewText(R.id.eng_caption, caption);

        int weekTotal =
                (int) readLong(data, KEY_WEEK_REACTIONS)
                        + (int) readLong(data, KEY_WEEK_COMMENTS)
                        + (int) readLong(data, KEY_WEEK_SHARES);
        int weekPosts = (int) readLong(data, KEY_WEEK_POST_COUNT);
        String leading = "";
        if (weekPosts > 0) {
            leading =
                    weekTotal
                            + (weekTotal == 1 ? " interaction this week" : " interactions this week");
        } else if (weekTotal > 0) {
            leading = weekTotal + " this week";
        }

        String footer = "";
        if (showFooter) {
            footer = bindFooter(views, data, now, stale, theme.muted, leading);
        } else {
            views.setViewVisibility(R.id.widget_updated, View.GONE);
        }

        bindClick(context, views, R.id.widget_root, URI_HISTORY, REQ_ROOT);
        bindClick(context, views, R.id.eng_kicker, URI_HISTORY, REQ_HEADLINE);

        StringBuilder description = new StringBuilder();
        description.append("Last post ").append(age).append(". ");
        description.append(metricPhrase("reactions", reactions));
        description.append(", ").append(metricPhrase("comments", comments));
        description.append(", ").append(metricPhrase("shares", shares));
        if (showCaption) description.append(". ").append(caption);
        if (!footer.isEmpty()) description.append(". ").append(footer);
        views.setContentDescription(R.id.widget_root, description.toString());
    }

    private static void setMetric(
            RemoteViews views, int valueId, Long value, String label, boolean combined) {
        String text;
        if (value == null) {
            text = "—";
        } else {
            text = combined ? value + " " + label : String.valueOf(value);
        }
        views.setTextViewText(valueId, text);
        views.setViewVisibility(valueId, View.VISIBLE);
    }

    private static void showLabels(RemoteViews views, int[] labelIds, boolean visible) {
        for (int id : labelIds) {
            views.setViewVisibility(id, visible ? View.VISIBLE : View.GONE);
        }
    }

    private static String metricPhrase(String label, Long value) {
        if (value == null) return "no " + label + " data";
        return value + " " + label;
    }
}
