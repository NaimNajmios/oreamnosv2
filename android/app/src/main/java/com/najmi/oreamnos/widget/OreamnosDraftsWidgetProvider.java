package com.najmi.oreamnos.widget;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.view.View;
import android.widget.RemoteViews;

import com.najmi.oreamnos.R;

/**
 * "Drafts": what is half-written and one tap from being continued.
 *
 * <p>Deliberately the least busy widget. A draft has no schedule and no
 * metrics, so the only honest thing to show is the count, the newest draft's
 * opening words and how long ago it was touched. The caption is subject to the
 * same "show post caption" switch as the other widgets: a home screen is a
 * shared surface.
 */
public class OreamnosDraftsWidgetProvider extends BaseOreamnosWidget {

    private enum Shape {
        ROW,
        SQUARE,
        EXPANDED
    }

    @Override
    protected int layoutFor(int widthDp, int heightDp) {
        switch (shapeFor(widthDp, heightDp)) {
            case ROW:
                return R.layout.oreamnos_drafts_widget_row;
            case SQUARE:
                return R.layout.oreamnos_drafts_widget_square;
            case EXPANDED:
            default:
                return R.layout.oreamnos_drafts_widget;
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
        int count = (int) readLong(data, KEY_DRAFT_COUNT);
        String title = clean(data.getString(KEY_DRAFT_TITLE, ""));
        long updatedAt = readLong(data, KEY_DRAFT_UPDATED_AT);
        long now = System.currentTimeMillis();
        boolean stale = isStale(data, now);

        views.setTextColor(R.id.draft_kicker, theme.primary);
        views.setTextColor(R.id.draft_cta, theme.primary);
        views.setTextColor(R.id.draft_count, theme.primary);

        String kicker;
        String meta;
        if (count <= 0) {
            kicker = "DRAFTS";
            title = "No drafts";
            meta = "Tap to start one";
            views.setTextColor(R.id.draft_title, theme.muted);
            views.setTextViewText(R.id.draft_count, "0");
        } else {
            kicker = count == 1 ? "DRAFT" : "DRAFTS · " + count;
            if (TextUtils.isEmpty(title)) title = "Untitled draft";
            meta = updatedAt > 0
                    ? "edited " + durationLabel(now - updatedAt) + " ago"
                    : "Tap to continue";
            views.setTextColor(R.id.draft_title, theme.onSurface);
            views.setTextViewText(R.id.draft_count, String.valueOf(count));
        }

        views.setTextViewText(R.id.draft_kicker, kicker);
        views.setTextViewText(R.id.draft_title, title);
        views.setTextViewText(R.id.draft_meta, meta);
        views.setTextColor(R.id.draft_meta, theme.muted);

        boolean showCount = shape == Shape.EXPANDED;
        views.setViewVisibility(
                R.id.draft_count, showCount ? View.VISIBLE : View.GONE);

        boolean showCta = shape == Shape.EXPANDED && count > 0;
        views.setViewVisibility(
                R.id.draft_cta, showCta ? View.VISIBLE : View.GONE);
        if (showCta) {
            bindClick(context, views, R.id.draft_cta, URI_COMPOSE, REQ_ACTION);
        }

        // One line in the square: the title alone would be ambiguous, so the
        // count rides along.
        if (shape == Shape.SQUARE && count > 1) {
            views.setTextViewText(R.id.draft_title, title + "  ·  +" + (count - 1));
        }

        String footer = "";
        if (shape == Shape.EXPANDED) {
            footer = bindFooter(views, data, now, stale, theme.muted, "");
        } else {
            views.setViewVisibility(R.id.widget_updated, View.GONE);
        }

        bindClick(context, views, R.id.widget_root, URI_COMPOSE, REQ_ROOT);
        bindClick(context, views, R.id.draft_title, URI_COMPOSE, REQ_HEADLINE);

        StringBuilder description = new StringBuilder();
        if (count <= 0) {
            description.append("No drafts. Tap to start one.");
        } else {
            description.append(count == 1 ? "1 draft" : count + " drafts");
            description.append(". ").append(title).append(". ").append(meta);
        }
        if (!footer.isEmpty()) description.append(". ").append(footer);
        views.setContentDescription(R.id.widget_root, description.toString());
    }
}
