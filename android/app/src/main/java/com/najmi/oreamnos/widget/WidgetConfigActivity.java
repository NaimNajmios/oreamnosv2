package com.najmi.oreamnos.widget;

import android.app.Activity;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Spinner;
import android.widget.Toast;

import com.najmi.oreamnos.R;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * Native configuration screen shown when the widget is added.
 *
 * <p>Deliberately not routed through {@code MainActivity}: the plugin's
 * {@code finishHomeWidgetConfigure()} calls {@code finish()} on the hosting
 * activity, which would close the app right after the user adds a widget.
 */
public class WidgetConfigActivity extends Activity {

    private int appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID;

    private RadioGroup rows;
    private Spinner pageSpinner;
    private final List<String> pageIds = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Abandoning the screen must abandon adding the widget.
        setResult(RESULT_CANCELED);

        Bundle extras = getIntent().getExtras();
        if (extras != null) {
            appWidgetId = extras.getInt(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID);
        }
        if (!isOurWidget(appWidgetId)) {
            finish();
            return;
        }

        setContentView(R.layout.widget_config);
        rows = findViewById(R.id.widget_config_rows);
        pageSpinner = findViewById(R.id.widget_config_page);
        Button save = findViewById(R.id.widget_config_save);

        String row = WidgetConfig.row(this, appWidgetId);
        if (row.isEmpty()) {
            row = globalRow();
        }
        selectRow(row);
        populatePages();

        save.setOnClickListener(v -> saveAndFinish());
    }

    private boolean isOurWidget(int id) {
        if (id == AppWidgetManager.INVALID_APPWIDGET_ID) return false;
        try {
            AppWidgetManager manager = AppWidgetManager.getInstance(this);
            if (manager.getAppWidgetInfo(id) == null) return false;
            ComponentName provider = manager.getAppWidgetInfo(id).provider;
            return new ComponentName(this, OreamnosWidgetProvider.class)
                    .equals(provider);
        } catch (RuntimeException ignored) {
            return false;
        }
    }

    /** The app-wide preference, mirrored into the payload by Dart. */
    private String globalRow() {
        SharedPreferences data = getSharedPreferences(
                "HomeWidgetPreferences", Context.MODE_PRIVATE);
        String value = data.getString("second_row_mode", WidgetConfig.ROW_QUOTA);
        return value == null || value.isEmpty() ? WidgetConfig.ROW_QUOTA : value;
    }

    private void selectRow(String row) {
        int id;
        switch (row) {
            case WidgetConfig.ROW_ENGAGEMENT:
                id = R.id.widget_config_row_engagement;
                break;
            case WidgetConfig.ROW_DRAFTS:
                id = R.id.widget_config_row_drafts;
                break;
            case WidgetConfig.ROW_BEST_TIME:
                id = R.id.widget_config_row_best_time;
                break;
            default:
                id = R.id.widget_config_row_quota;
                break;
        }
        rows.check(id);
    }

    private String selectedRow() {
        int id = rows.getCheckedRadioButtonId();
        if (id == R.id.widget_config_row_engagement) return WidgetConfig.ROW_ENGAGEMENT;
        if (id == R.id.widget_config_row_drafts) return WidgetConfig.ROW_DRAFTS;
        if (id == R.id.widget_config_row_best_time) return WidgetConfig.ROW_BEST_TIME;
        return WidgetConfig.ROW_QUOTA;
    }

    private void populatePages() {
        List<String> labels = new ArrayList<>();
        pageIds.add("");
        labels.add(getString(R.string.widget_config_active_page));

        SharedPreferences data = getSharedPreferences(
                "HomeWidgetPreferences", Context.MODE_PRIVATE);
        String raw = data.getString("pages_json", "[]");
        try {
            JSONArray array = new JSONArray(raw == null ? "[]" : raw);
            for (int i = 0; i < array.length(); i++) {
                JSONObject page = array.optJSONObject(i);
                if (page == null) continue;
                String id = page.optString("id", "");
                String name = page.optString("name", "");
                if (id.isEmpty()) continue;
                pageIds.add(id);
                labels.add(name.isEmpty() ? id : name);
            }
        } catch (Exception ignored) {
            // Corrupt payload: keep just "Active page".
        }

        ArrayAdapter<String> adapter = new ArrayAdapter<>(
                this, android.R.layout.simple_spinner_item, labels);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        pageSpinner.setAdapter(adapter);

        String configured = WidgetConfig.page(this, appWidgetId);
        int index = pageIds.indexOf(configured);
        if (index > 0) pageSpinner.setSelection(index);
        pageSpinner.setEnabled(pageIds.size() > 1);
    }

    private void saveAndFinish() {
        String row = selectedRow();
        int index = pageSpinner.getSelectedItemPosition();
        String page = index >= 0 && index < pageIds.size() ? pageIds.get(index) : "";
        WidgetConfig.save(this, appWidgetId, row, page);

        Intent update = new Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
        update.setComponent(new ComponentName(this, OreamnosWidgetProvider.class));
        update.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, new int[] {appWidgetId});
        sendBroadcast(update);

        Toast.makeText(this, R.string.widget_config_save, Toast.LENGTH_SHORT).show();
        Intent result = new Intent();
        result.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId);
        setResult(RESULT_OK, result);
        finish();
    }
}
