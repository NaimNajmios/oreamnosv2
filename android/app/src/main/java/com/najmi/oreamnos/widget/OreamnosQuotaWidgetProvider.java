package com.najmi.oreamnos.widget;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.view.View;
import android.widget.RemoteViews;

import com.najmi.oreamnos.R;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

/**
 * "AI quota": today's request budget for two providers side by side.
 *
 * <p>The ring only appears when the app actually knows a daily budget (the
 * Gemini free tier). For Groq, OpenRouter and Cerebras the same slot renders a
 * plain count with "no daily limit" — a home screen must never imply a limit
 * that does not exist.
 *
 * <p>Two providers are read per widget: the configured primary and secondary,
 * defaulting to the app's active provider and its rate-limit fallback, so a
 * 429 hop is visible before it happens. The second slot can be hidden.
 */
public class OreamnosQuotaWidgetProvider extends BaseOreamnosWidget {

    private static final int RING_OUTER_DP = 76;
    private static final int RING_CARD_DP = 56;
    private static final int RING_BANNER_DP = 40;
    private static final int RING_SQUARE_DP = 52;

    private static final int STROKE_OUTER_DP = 7;
    private static final int STROKE_CARD_DP = 6;
    private static final int STROKE_BANNER_DP = 5;
    private static final int STROKE_SQUARE_DP = 6;

    private enum Shape {
        STRIP,
        SQUARE,
        BANNER,
        CARD,
        EXPANDED
    }

    @Override
    protected int layoutFor(int widthDp, int heightDp) {
        switch (shapeFor(widthDp, heightDp)) {
            case SQUARE:
                return R.layout.oreamnos_quota_widget_square;
            case STRIP:
            case BANNER:
                return R.layout.oreamnos_quota_widget_banner;
            case CARD:
                return R.layout.oreamnos_quota_widget_card;
            case EXPANDED:
            default:
                return R.layout.oreamnos_quota_widget;
        }
    }

    private static Shape shapeFor(int widthDp, int heightDp) {
        if (heightDp < STRIP_MIN_HEIGHT_DP) return Shape.STRIP;
        if (heightDp < TALL_MIN_HEIGHT_DP) return Shape.BANNER;
        if (widthDp < SQUARE_MAX_DP) return Shape.SQUARE;
        if (widthDp < WIDE_MIN_WIDTH_DP) return Shape.CARD;
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
        Map<String, Quota> quotas = parseQuotas(data.getString(KEY_QUOTA_JSON, "[]"));

        String primaryId = WidgetConfig.primaryProvider(context, appWidgetId);
        if (primaryId.isEmpty()) primaryId = clean(data.getString(KEY_ACTIVE_PROVIDER, ""));
        if (primaryId.isEmpty()) primaryId = firstId(quotas);

        String secondaryId = WidgetConfig.secondaryProvider(context, appWidgetId);
        boolean secondaryExplicitlyOff = WidgetConfig.NONE.equals(secondaryId);
        if (secondaryId.isEmpty()) {
            secondaryId = clean(data.getString(KEY_FALLBACK_PROVIDER, ""));
        }
        if (secondaryId.equals(primaryId)) secondaryExplicitlyOff = true;
        // A 1x1 has room for exactly one ring.
        boolean showSecond = !secondaryExplicitlyOff
                && !secondaryId.isEmpty()
                && shape != Shape.SQUARE;

        views.setTextColor(R.id.quota_a_pct, theme.onSurface);
        views.setTextColor(R.id.quota_b_pct, theme.onSurface);
        views.setTextColor(R.id.quota_a_name, theme.muted);
        views.setTextColor(R.id.quota_b_name, theme.muted);
        views.setTextColor(R.id.quota_a_meta, theme.muted);
        views.setTextColor(R.id.quota_b_meta, theme.muted);
        views.setTextColor(R.id.quota_window, theme.muted);

        int ringDp = ringSizeFor(shape);
        int strokeDp = strokeSizeFor(shape);
        boolean strip = shape == Shape.STRIP;
        boolean compactChrome =
                shape == Shape.SQUARE || shape == Shape.BANNER || strip;

        Quota primary = quotas.get(primaryId);
        if (primary == null) primary = Quota.empty(primaryId);
        bindSlot(
                context,
                views,
                primary,
                theme,
                ringDp,
                strokeDp,
                compactChrome,
                strip,
                R.id.quota_a_name,
                R.id.quota_a_ringbox,
                R.id.quota_a_ring,
                R.id.quota_a_pct,
                R.id.quota_a_value,
                R.id.quota_a_meta);

        views.setViewVisibility(
                R.id.quota_b_column, showSecond ? View.VISIBLE : View.GONE);
        views.setViewVisibility(
                R.id.quota_divider, showSecond ? View.VISIBLE : View.GONE);
        Quota secondary = null;
        if (showSecond) {
            secondary = quotas.get(secondaryId);
            if (secondary == null) secondary = Quota.empty(secondaryId);
            bindSlot(
                    context,
                    views,
                    secondary,
                    theme,
                    ringDp,
                    strokeDp,
                    compactChrome,
                    strip,
                    R.id.quota_b_name,
                    R.id.quota_b_ringbox,
                    R.id.quota_b_ring,
                    R.id.quota_b_pct,
                    R.id.quota_b_value,
                    R.id.quota_b_meta);
        }

        boolean showWindow = shape == Shape.CARD || shape == Shape.EXPANDED;
        views.setViewVisibility(
                R.id.quota_window, showWindow ? View.VISIBLE : View.GONE);
        if (showWindow) {
            views.setTextViewText(
                    R.id.quota_window,
                    shape == Shape.EXPANDED ? "Pacific day" : "today");
        }

        long now = System.currentTimeMillis();
        boolean stale = isStale(data, now);
        String footer = "";
        if (!compactChrome) {
            footer = bindFooter(views, data, now, stale, theme.muted, "");
        } else {
            views.setViewVisibility(R.id.widget_updated, View.GONE);
        }

        bindClick(context, views, R.id.widget_root, URI_USAGE, REQ_ROOT);
        bindClick(context, views, R.id.quota_a_column, URI_USAGE, REQ_SECOND);
        if (showSecond) {
            bindClick(context, views, R.id.quota_b_column, URI_USAGE, REQ_THIRD);
        }

        StringBuilder description = new StringBuilder(primary.describe());
        if (secondary != null) description.append(". ").append(secondary.describe());
        if (!footer.isEmpty()) description.append(". ").append(footer);
        views.setContentDescription(R.id.widget_root, description.toString());
    }

    private void bindSlot(
            Context context,
            RemoteViews views,
            Quota quota,
            WidgetTheme theme,
            int ringDp,
            int strokeDp,
            boolean compactChrome,
            boolean strip,
            int nameId,
            int ringBoxId,
            int ringId,
            int percentId,
            int valueId,
            int metaId) {
        String name = quota.name.isEmpty()
                ? quota.providerId.toUpperCase(Locale.ROOT)
                : quota.name.toUpperCase(Locale.ROOT);
        if (!compactChrome && !quota.model.isEmpty()) {
            name = name + " · " + quota.model.toUpperCase(Locale.ROOT);
        }
        views.setTextViewText(nameId, name);

        int colour = quota.severity >= 2
                ? COLOR_RED
                : (quota.severity == 1 ? COLOR_AMBER : theme.primary);
        views.setTextColor(valueId, colour);

        boolean hasBudget = quota.budget > 0;
        // A ring needs a real budget and enough height to draw one. A
        // one-row strip has no room for a gauge, so it goes text-only.
        boolean ringVisible = hasBudget && !strip;
        // An unbudgeted provider in a square has no ring to draw, so the count
        // takes the ring's place instead of leaving an empty circle.
        boolean countInRing = compactChrome && !strip;
        boolean showBox = ringVisible || countInRing;

        views.setViewVisibility(
                ringBoxId, showBox ? View.VISIBLE : View.GONE);
        views.setViewVisibility(
                ringId, ringVisible ? View.VISIBLE : View.GONE);
        if (ringVisible) {
            Bitmap ring = WidgetRing.draw(
                    context,
                    ringDp,
                    strokeDp,
                    quota.percent,
                    colour,
                    withAlpha(theme.muted, 60));
            views.setImageViewBitmap(ringId, ring);
        }

        // With a ring the percentage lives inside it and the value carries
        // "used / budget". Without one the count is the whole message.
        boolean showPercent = ringVisible || (!hasBudget && countInRing);
        views.setViewVisibility(
                percentId, showPercent ? View.VISIBLE : View.GONE);
        if (showPercent) {
            views.setTextViewText(
                    percentId,
                    ringVisible ? quota.percent + "%" : String.valueOf(quota.used));
            views.setTextColor(
                    percentId, ringVisible ? theme.onSurface : theme.onSurface);
        }

        boolean countOwnsValue = !hasBudget && countInRing;
        views.setViewVisibility(
                valueId, countOwnsValue ? View.GONE : View.VISIBLE);
        if (!countOwnsValue) {
            // The strip has no room for a gauge, so the percentage rides on
            // the value line instead of disappearing.
            final String valueText;
            if (strip && hasBudget) {
                valueText = quota.used + " / " + quota.budget + " · " + quota.percent + "%";
            } else if (hasBudget) {
                valueText = quota.used + " / " + quota.budget;
            } else {
                valueText = quota.used + " today";
            }
            views.setTextViewText(valueId, valueText);
        }

        String meta = compactChrome || strip ? "" : (hasBudget
                ? (quota.resetAt > 0
                        ? "resets "
                                + durationLabel(quota.resetAt - System.currentTimeMillis())
                                + (quota.average > 0 ? " · avg " + quota.average + "/day" : "")
                        : "")
                : "no daily limit");
        views.setTextViewText(metaId, meta);
        views.setViewVisibility(metaId, meta.isEmpty() ? View.GONE : View.VISIBLE);
    }

    private static int ringSizeFor(Shape shape) {
        switch (shape) {
            case SQUARE:
                return RING_SQUARE_DP;
            case STRIP:
            case BANNER:
                return RING_BANNER_DP;
            case CARD:
                return RING_CARD_DP;
            case EXPANDED:
            default:
                return RING_OUTER_DP;
        }
    }

    private static int strokeSizeFor(Shape shape) {
        switch (shape) {
            case SQUARE:
                return STROKE_SQUARE_DP;
            case STRIP:
            case BANNER:
                return STROKE_BANNER_DP;
            case CARD:
                return STROKE_CARD_DP;
            case EXPANDED:
            default:
                return STROKE_OUTER_DP;
        }
    }

    private static String firstId(Map<String, Quota> quotas) {
        for (String id : quotas.keySet()) return id;
        return "gemini";
    }

    /** Parses `quota_json`; a corrupt payload degrades to an empty map. */
    private static Map<String, Quota> parseQuotas(String raw) {
        Map<String, Quota> parsed = new LinkedHashMap<>();
        try {
            JSONArray array = new JSONArray(raw == null ? "[]" : raw);
            for (int i = 0; i < array.length(); i++) {
                JSONObject entry = array.optJSONObject(i);
                if (entry == null) continue;
                Quota quota = new Quota();
                quota.providerId = entry.optString("p", "");
                if (quota.providerId.isEmpty()) continue;
                quota.name = entry.optString("n", "");
                quota.model = entry.optString("m", "");
                quota.used = entry.optInt("u", 0);
                quota.budget = entry.has("b") ? entry.optInt("b", 0) : 0;
                quota.percent = entry.optInt("pc", 0);
                quota.severity = entry.optInt("s", 0);
                quota.resetAt = entry.optLong("r", 0L);
                quota.average = entry.optInt("a", 0);
                parsed.put(quota.providerId, quota);
            }
        } catch (Exception ignored) {
            // A malformed payload must not blank the widget.
        }
        return parsed;
    }

    private static final class Quota {
        String providerId = "";
        String name = "";
        String model = "";
        int used;
        int budget;
        int percent;
        int severity;
        long resetAt;
        int average;

        static Quota empty(String providerId) {
            Quota quota = new Quota();
            quota.providerId = providerId;
            return quota;
        }

        String describe() {
            String label = name.isEmpty() ? providerId : name;
            if (budget > 0) return label + " " + used + " of " + budget;
            return label + " " + used + " requests today";
        }
    }
}
