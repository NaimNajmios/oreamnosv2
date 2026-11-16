package com.najmi.oreamnos.widget;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.util.LruCache;

/**
 * Draws the quota ring as a bitmap.
 *
 * <p>RemoteViews cannot host a custom view, and a determinate circular
 * {@code ProgressBar} cannot be tinted per theme before Android 12. A bitmap
 * handed over with {@code setImageViewBitmap} works on every API level, honours
 * the nine palettes, and keeps the centre label a real {@code TextView} so it
 * scales with the user's font size.
 *
 * <p>The arc starts at twelve o'clock and sweeps clockwise. Only the two statics
 * matters: the ring is decorative, the percentage is text.
 */
final class WidgetRing {

    /** Small enough that a launcher never has to recycle a visible bitmap. */
    private static final LruCache<String, Bitmap> CACHE = new LruCache<>(8);

    private WidgetRing() {}

    /**
     * @param sizeDp outer diameter
     * @param strokeDp arc thickness
     * @param percent 0..100, clamped
     */
    static Bitmap draw(
            Context context,
            int sizeDp,
            int strokeDp,
            int percent,
            int progressColor,
            int trackColor) {
        int clamped = Math.max(0, Math.min(100, percent));
        float density = context.getResources().getDisplayMetrics().density;
        int strokePx = Math.max(1, Math.round(strokeDp * density));
        int sizePx = Math.max(strokePx * 3, Math.round(sizeDp * density));

        String key = sizePx + "|" + strokePx + "|" + clamped + "|" + progressColor + "|" + trackColor;
        Bitmap cached = CACHE.get(key);
        if (cached != null) return cached;

        Bitmap bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888);
        bitmap.setDensity(context.getResources().getDisplayMetrics().densityDpi);

        Canvas canvas = new Canvas(bitmap);
        float inset = strokePx / 2f;
        RectF box = new RectF(inset, inset, sizePx - inset, sizePx - inset);

        Paint track = new Paint(Paint.ANTI_ALIAS_FLAG);
        track.setStyle(Paint.Style.STROKE);
        track.setStrokeWidth(strokePx);
        track.setColor(trackColor);
        canvas.drawArc(box, 0f, 360f, false, track);

        if (clamped > 0) {
            Paint arc = new Paint(Paint.ANTI_ALIAS_FLAG);
            arc.setStyle(Paint.Style.STROKE);
            arc.setStrokeWidth(strokePx);
            arc.setStrokeCap(Paint.Cap.ROUND);
            arc.setColor(progressColor);
            canvas.drawArc(box, -90f, 360f * clamped / 100f, false, arc);
        }

        CACHE.put(key, bitmap);
        return bitmap;
    }
}
