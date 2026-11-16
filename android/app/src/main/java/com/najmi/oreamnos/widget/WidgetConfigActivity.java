package com.najmi.oreamnos.widget;

import android.app.Activity;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.Spinner;
import android.widget.Toast;

import com.najmi.oreamnos.R;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * Native configuration screen for the two widgets that have a choice to make:
 * Next up pins a Page, AI quota picks the two providers it shows side by side.
 *
 * <p>Deliberately not routed through {@code MainActivity}: the plugin's
 * {@code finishHomeWidgetConfigure()} calls {@code finish()} on the hosting
 * activity, which would close the app right after the user adds a widget.
 *
 * <p>The engagement, drafts and best-time widgets declare no
 * {@code android:configure}, so this screen is never shown for them.
 */
public class WidgetConfigActivity extends Activity {

    /** The app's provider order; ids match the Dart payload. */
    private static final String[] PROVIDER_IDS = {
        "gemini", "groq", "openrouter", "cerebras"
    };
    private static final String[] PROVIDER_NAMES = {
        "Gemini", "Groq", "OpenRouter", "Cerebras"
    };

    private static final String PREFS = "HomeWidgetPreferences";
    private static final String KEY_PAGES_JSON = "pages_json";

    private enum Kind {
        NEXT_UP,
        QUOTA
    }

    private int appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID;
    private Kind kind = Kind.NEXT_UP;

    private View pageSection;
    private View providersSection;
    private Spinner pageSpinner;
    private Spinner primarySpinner;
    private Spinner secondarySpinner;

    private final List<String> pageIds = new ArrayList<>();
    private final List<String> primaryIds = new ArrayList<>();
    private final List<String> secondaryIds = new ArrayList<>();

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
        if (!resolveKind()) {
            finish();
            return;
        }

        setContentView(R.layout.widget_config);
        pageSection = findViewById(R.id.widget_config_page_section);
        providersSection = findViewById(R.id.widget_config_providers_section);
        pageSpinner = findViewById(R.id.widget_config_page);
        primarySpinner = findViewById(R.id.widget_config_primary);
        secondarySpinner = findViewById(R.id.widget_config_secondary);
        Button save = findViewById(R.id.widget_config_save);

        if (kind == Kind.NEXT_UP) {
            pageSection.setVisibility(View.VISIBLE);
            populatePages();
        } else {
            providersSection.setVisibility(View.VISIBLE);
            populateProviders();
        }

        save.setOnClickListener(v -> saveAndFinish());
    }

    /** True when this widget id belongs to one of our configurable providers. */
    private boolean resolveKind() {
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return false;
        try {
            AppWidgetManager manager = AppWidgetManager.getInstance(this);
            if (manager.getAppWidgetInfo(appWidgetId) == null) return false;
            ComponentName provider = manager.getAppWidgetInfo(appWidgetId).provider;
            if (provider == null) return false;
            String className = provider.getClassName();
            if (className.equals(
                    new ComponentName(this, OreamnosWidgetProvider.class)
                            .getClassName())) {
                kind = Kind.NEXT_UP;
                return true;
            }
            if (className.equals(
                    new ComponentName(this, OreamnosQuotaWidgetProvider.class)
                            .getClassName())) {
                kind = Kind.QUOTA;
                return true;
            }
        } catch (RuntimeException ignored) {
            // Fall through: a foreign widget id must not open this screen.
        }
        return false;
    }

    private void populatePages() {
        List<String> labels = new ArrayList<>();
        pageIds.add("");
        labels.add(getString(R.string.widget_config_active_page));

        SharedPreferences data = getSharedPreferences(PREFS, MODE_PRIVATE);
        String raw = data.getString(KEY_PAGES_JSON, "[]");
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

    private void populateProviders() {
        List<String> primaryLabels = new ArrayList<>();
        primaryIds.add("");
        primaryLabels.add(getString(R.string.widget_config_active_provider));
        for (int i = 0; i < PROVIDER_IDS.length; i++) {
            primaryIds.add(PROVIDER_IDS[i]);
            primaryLabels.add(PROVIDER_NAMES[i]);
        }

        List<String> secondaryLabels = new ArrayList<>();
        secondaryIds.add("");
        secondaryLabels.add(getString(R.string.widget_config_fallback_provider));
        for (int i = 0; i < PROVIDER_IDS.length; i++) {
            secondaryIds.add(PROVIDER_IDS[i]);
            secondaryLabels.add(PROVIDER_NAMES[i]);
        }
        // The explicit "hide it" choice is a stored sentinel, not a provider.
        secondaryIds.add(WidgetConfig.NONE);
        secondaryLabels.add(getString(R.string.widget_config_no_second));

        bindSpinner(primarySpinner, primaryLabels, primaryIds,
                WidgetConfig.primaryProvider(this, appWidgetId));
        bindSpinner(secondarySpinner, secondaryLabels, secondaryIds,
                WidgetConfig.secondaryProvider(this, appWidgetId));
    }

    private void bindSpinner(
            Spinner spinner, List<String> labels, List<String> ids, String configured) {
        ArrayAdapter<String> adapter = new ArrayAdapter<>(
                this, android.R.layout.simple_spinner_item, labels);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spinner.setAdapter(adapter);
        int index = ids.indexOf(configured);
        if (index > 0) spinner.setSelection(index);
    }

    private void saveAndFinish() {
        if (kind == Kind.NEXT_UP) {
            String page = selected(pageSpinner, pageIds);
            WidgetConfig.savePage(this, appWidgetId, page);
        } else {
            String primary = selected(primarySpinner, primaryIds);
            String secondary = selected(secondarySpinner, secondaryIds);
            WidgetConfig.saveProviders(this, appWidgetId, primary, secondary);
        }

        ComponentName provider = new ComponentName(
                this,
                kind == Kind.NEXT_UP
                        ? OreamnosWidgetProvider.class
                        : OreamnosQuotaWidgetProvider.class);
        Intent update = new Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
        update.setComponent(provider);
        update.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, new int[] {appWidgetId});
        sendBroadcast(update);

        Toast.makeText(this, R.string.widget_config_saved, Toast.LENGTH_SHORT).show();
        Intent result = new Intent();
        result.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId);
        setResult(RESULT_OK, result);
        finish();
    }

    private static String selected(Spinner spinner, List<String> ids) {
        int index = spinner.getSelectedItemPosition();
        return index >= 0 && index < ids.size() ? ids.get(index) : "";
    }
}
