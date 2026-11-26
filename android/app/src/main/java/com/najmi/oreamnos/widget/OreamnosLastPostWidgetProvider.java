package com.najmi.oreamnos.widget;

import android.content.Context;
import android.content.SharedPreferences;
import android.view.View;
import android.widget.RemoteViews;

import com.najmi.oreamnos.R;

/**
 * Read-only "time since my newest published post".
 *
 * <p>Unlike the engagement widget this does not wait for cached metrics — a
 * freshly published post is exactly the one whose insights have not arrived
 * yet. The source instant is the post's scheduled time when it went live via a
 * schedule, otherwise its local creation time; both are computed in Dart.
 *
 * <p>There are deliberately no click targets: this widget is a glanceable
 * readout, and relative time advances on the periodic 30-minute render without
 * opening the app.
 */
public class OreamnosLastPostWidgetProvider extends BaseOreamnosWidget {

    private enum Shape {
        ROW,
        SQUARE,
        EXPANDED
    }

    @Override
    protected int layoutFor(int widthDp, int heightDp) {
        switch (shapeFor(widthDp, heightDp)) {
            case ROW:
                return R.layout.oreamnos_last_post_widget_row;
            case SQUARE:
                return R.layout.oreamnos_last_post_widget_square;
            case EXPANDED:
            default:
                return R.layout.oreamnos_last_post_widget;
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
        long postedAt = readLongOrNone(data, KEY_LAST_PUBLISHED_AT);
        boolean hasPost = postedAt > 0;
        long now = System.currentTimeMillis();
        boolean stale = isStale(data, now);

        views.setTextColor(R.id.lp_kicker, theme.primary);
        views.setTextColor(R.id.lp_when, theme.muted);
        views.setTextViewText(R.id.lp_kicker, shape == Shape.ROW ? "LAST" : "LAST POST");

        String age;
        if (hasPost) {
            age = durationLabel(now - postedAt) + " ago";
            views.setTextColor(R.id.lp_age, theme.onSurface);
            views.setTextViewText(R.id.lp_age, age);
            views.setTextViewText(R.id.lp_when, whenLabel(context, postedAt));
        } else {
            age = "No posts yet";
            views.setTextColor(R.id.lp_age, theme.muted);
            views.setTextViewText(R.id.lp_age, age);
            views.setTextViewText(R.id.lp_when, "");
        }

        boolean showWhen = hasPost && shape != Shape.ROW;
        views.setViewVisibility(R.id.lp_when, showWhen ? View.VISIBLE : View.GONE);

        String footer = "";
        if (shape == Shape.EXPANDED) {
            footer = bindFooter(views, data, now, stale, theme.muted, "");
        } else {
            views.setViewVisibility(R.id.widget_updated, View.GONE);
        }

        StringBuilder description = new StringBuilder();
        description.append(hasPost ? "Last published " + age : age);
        if (hasPost) description.append(". ").append(whenLabel(context, postedAt));
        if (!footer.isEmpty()) description.append(". ").append(footer);
        views.setContentDescription(R.id.widget_root, description.toString());
    }
}
