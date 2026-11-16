package com.najmi.oreamnos.widget;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.view.View;
import android.widget.RemoteViews;

import com.najmi.oreamnos.R;

/**
 * "Best time": the local, non-AI weekday/hour suggestion from
 * {@code BestTimeToPost}.
 *
 * <p>The heuristic is deterministic and computed in Dart; this widget only
 * echoes its label and its basis. Nothing is shown when there is no history —
 * an invented slot would be worse than an empty widget.
 */
public class OreamnosBestTimeWidgetProvider extends BaseOreamnosWidget {

    private enum Shape {
        ROW,
        SQUARE,
        EXPANDED
    }

    @Override
    protected int layoutFor(int widthDp, int heightDp) {
        switch (shapeFor(widthDp, heightDp)) {
            case ROW:
                return R.layout.oreamnos_best_time_widget_row;
            case SQUARE:
                return R.layout.oreamnos_best_time_widget_square;
            case EXPANDED:
            default:
                return R.layout.oreamnos_best_time_widget;
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
        String label = clean(data.getString(KEY_BEST_SLOT_LABEL, ""));
        String detail = clean(data.getString(KEY_BEST_SLOT_DETAIL, ""));
        boolean confident = readBool(data, KEY_BEST_SLOT_CONFIDENT);
        long now = System.currentTimeMillis();
        boolean stale = isStale(data, now);
        boolean hasSlot = !TextUtils.isEmpty(label);

        views.setTextColor(R.id.best_kicker, theme.primary);
        views.setTextColor(R.id.best_detail, theme.muted);
        views.setTextColor(R.id.best_note, theme.muted);

        views.setTextViewText(
                R.id.best_kicker, shape == Shape.ROW ? "BEST" : "BEST TIME");
        if (hasSlot) {
            views.setTextColor(R.id.best_label, theme.onSurface);
            views.setTextViewText(R.id.best_label, label);
            views.setTextViewText(
                    R.id.best_detail,
                    TextUtils.isEmpty(detail) ? "Your usual window" : detail);
        } else {
            views.setTextColor(R.id.best_label, theme.muted);
            views.setTextViewText(R.id.best_label, "Not enough history");
            views.setTextViewText(
                    R.id.best_detail, "Publish a few posts to see a pattern");
        }

        // A confidence caveat is the difference between a suggestion and a
        // claim; only the expanded size has room to state it.
        boolean showNote = shape == Shape.EXPANDED;
        views.setViewVisibility(
                R.id.best_note, showNote ? View.VISIBLE : View.GONE);
        if (showNote) {
            views.setTextViewText(
                    R.id.best_note,
                    hasSlot && !confident
                            ? "Early estimate — based on few posts"
                            : "Based on your published posts");
        }

        String footer = "";
        if (shape == Shape.EXPANDED) {
            footer = bindFooter(views, data, now, stale, theme.muted, "");
        } else {
            views.setViewVisibility(R.id.widget_updated, View.GONE);
        }

        bindClick(context, views, R.id.widget_root, URI_PERFORMANCE, REQ_ROOT);
        bindClick(context, views, R.id.best_label, URI_PERFORMANCE, REQ_HEADLINE);

        StringBuilder description = new StringBuilder();
        if (hasSlot) {
            description.append("Best time ").append(label);
            if (!TextUtils.isEmpty(detail)) description.append(". ").append(detail);
            if (!confident) description.append(". Early estimate.");
        } else {
            description.append("Not enough history for a best time yet.");
        }
        if (!footer.isEmpty()) description.append(". ").append(footer);
        views.setContentDescription(R.id.widget_root, description.toString());
    }
}
