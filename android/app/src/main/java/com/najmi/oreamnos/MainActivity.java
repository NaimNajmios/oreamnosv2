package com.najmi.oreamnos;

import android.content.Intent;
import android.net.Uri;
import androidx.core.content.FileProvider;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.net.URLEncoder;

public class MainActivity extends FlutterActivity {
    private static final String UPDATE_INSTALL_CHANNEL = "oreamnos_update_installer";

    private MethodChannel updateInstallerChannel;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        updateInstallerChannel = new MethodChannel(
            flutterEngine.getDartExecutor(),
            UPDATE_INSTALL_CHANNEL
        );
        updateInstallerChannel.setMethodCallHandler(new UpdateInstallMethodCallHandler());
    }

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

    private final class UpdateInstallMethodCallHandler
        implements MethodChannel.MethodCallHandler {
        @Override
        public void onMethodCall(MethodCall call, MethodChannel.Result result) {
            if ("install".equals(call.method)) {
                Object arguments = call.arguments;
                String apkPath = null;
                if (arguments instanceof java.util.Map) {
                    Object path = ((java.util.Map<?, ?>) arguments).get("apkPath");
                    if (path instanceof String) {
                        apkPath = (String) path;
                    }
                }
                boolean installed = apkPath == null || installApk(apkPath);
                result.success(installed);
            } else {
                result.notImplemented();
            }
        }
    }

    private boolean installApk(String apkPath) {
        try {
            File file = new File(apkPath);
            if (!file.exists()) {
                return false;
            }
            Uri uri = FileProvider.getUriForFile(
                this,
                getPackageName() + ".fileprovider",
                file
            );
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            intent.setType("application/vnd.android.package-archive");
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (intent.resolveActivity(getPackageManager()) != null) {
                startActivity(intent);
                return true;
            }
            return false;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}
