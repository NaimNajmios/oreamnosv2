package com.najmi.oreamnos;

import android.content.Intent;
import io.flutter.embedding.android.FlutterActivity;
import java.net.URLEncoder;

public class MainActivity extends FlutterActivity {
    @Override
    public String getInitialRoute() {
        Intent intent = getIntent();
        String action = intent.getAction();
        String type = intent.getType();
        
        if ("com.najmi.oreamnos.VIEW_GENERATED".equals(action)) {
            String generatedText = intent.getStringExtra("generated_text");
            if (generatedText != null) {
                try {
                    String encodedText = URLEncoder.encode(generatedText, "UTF-8");
                    return "/reading-mode?content=" + encodedText;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        return super.getInitialRoute();
    }
}
