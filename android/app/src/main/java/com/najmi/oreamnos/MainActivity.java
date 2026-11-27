package com.najmi.oreamnos;

import android.Manifest;
import android.content.ClipData;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.provider.Settings;
import androidx.core.content.FileProvider;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String UPDATE_INSTALL_CHANNEL = "oreamnos_update_installer";
    private static final String SHARE_INTENT_CHANNEL = "oreamnos_share_intent";
    private static final String APK_MIME_TYPE = "application/vnd.android.package-archive";
    private static final String APK_DIR = Environment.DIRECTORY_DOWNLOADS;
    private static final int REQUEST_WRITE_STORAGE = 1001;

    private MethodChannel updateInstallerChannel;

    // Legacy (API <= 28) Downloads write resumed after the runtime permission prompt.
    private MethodChannel.Result pendingDownloadsResult;
    private String pendingDownloadsApkPath;
    private String pendingDownloadsDisplayName;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        updateInstallerChannel = new MethodChannel(
            flutterEngine.getDartExecutor(),
            UPDATE_INSTALL_CHANNEL
        );
        updateInstallerChannel.setMethodCallHandler(new UpdateInstallMethodCallHandler());
        new MethodChannel(flutterEngine.getDartExecutor(), SHARE_INTENT_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("clearIntent".equals(call.method)) {
                    clearShareIntentFromActivity();
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            });
    }

    @Override
    public void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        if (intent != null && (Intent.ACTION_SEND.equals(intent.getAction())
                || Intent.ACTION_SEND_MULTIPLE.equals(intent.getAction()))) {
            // ReceiveSharingIntentPlugin already dispatched this intent inside
            // super.onNewIntent; clear any stale share payload from getIntent()
            // so future activity re-attachments cannot replay it.
            clearShareIntentFromActivity();
        }
    }

    private void clearShareIntentFromActivity() {
        Intent current = getIntent();
        if (current == null) return;
        String action = current.getAction();
        if (Intent.ACTION_SEND.equals(action)
                || Intent.ACTION_SEND_MULTIPLE.equals(action)) {
            current.removeExtra(Intent.EXTRA_TEXT);
            current.removeExtra(Intent.EXTRA_STREAM);
            current.removeExtra(Intent.EXTRA_MIME_TYPES);
            current.setAction(Intent.ACTION_MAIN);
            current.setType(null);
            setIntent(current);
        }
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

    @Override
    public void onRequestPermissionsResult(
            int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != REQUEST_WRITE_STORAGE) return;

        MethodChannel.Result pending = pendingDownloadsResult;
        String apkPath = pendingDownloadsApkPath;
        String displayName = pendingDownloadsDisplayName;
        pendingDownloadsResult = null;
        pendingDownloadsApkPath = null;
        pendingDownloadsDisplayName = null;
        if (pending == null) return;

        if (grantResults.length > 0
                && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            writeDownloadsLegacy(apkPath, displayName, pending);
        } else {
            pending.error(
                "DOWNLOAD_PERMISSION_REQUIRED",
                "Storage permission is needed to save the update to Downloads.",
                null
            );
        }
    }

    private final class UpdateInstallMethodCallHandler
        implements MethodChannel.MethodCallHandler {
        @Override
        public void onMethodCall(MethodCall call, MethodChannel.Result result) {
            switch (call.method) {
                case "install": {
                    String apkPath = stringArgument(call, "apkPath");
                    if (apkPath == null || apkPath.isEmpty()) {
                        result.error(
                            "APK_NOT_FOUND",
                            "The downloaded update file is missing.",
                            null
                        );
                        return;
                    }
                    installApk(apkPath, result);
                    return;
                }
                case "saveToDownloads": {
                    String apkPath = stringArgument(call, "apkPath");
                    if (apkPath == null || apkPath.isEmpty()) {
                        result.error(
                            "APK_NOT_FOUND",
                            "The downloaded update file is missing.",
                            null
                        );
                        return;
                    }
                    saveToDownloads(apkPath, result);
                    return;
                }
                case "openInstallSettings":
                    result.success(openInstallSettings());
                    return;
                default:
                    result.notImplemented();
            }
        }
    }

    private static String stringArgument(MethodCall call, String key) {
        Object arguments = call.arguments;
        if (arguments instanceof Map) {
            Object value = ((Map<?, ?>) arguments).get(key);
            if (value instanceof String) return (String) value;
        }
        return null;
    }

    /**
     * Hands the verified, app-private APK to the OS package installer.
     *
     * Both the data URI and the read grant are required: setType() would clear
     * the URI, and the installer runs under a different UID so it cannot read
     * the FileProvider content URI without FLAG_GRANT_READ_URI_PERMISSION.
     */
    private void installApk(String apkPath, MethodChannel.Result result) {
        File file = new File(apkPath);
        if (!file.exists() || !file.isFile()) {
            result.error("APK_NOT_FOUND", "The downloaded update file is missing.", null);
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                && !getPackageManager().canRequestPackageInstalls()) {
            result.error(
                "INSTALL_PERMISSION_REQUIRED",
                "Allow Oreamnos to install unknown apps, then try again.",
                null
            );
            return;
        }
        try {
            Uri uri = FileProvider.getUriForFile(
                this,
                getPackageName() + ".fileprovider",
                file
            );
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setDataAndType(uri, APK_MIME_TYPE);
            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_GRANT_READ_URI_PERMISSION
            );
            intent.setClipData(ClipData.newRawUri("update", uri));
            if (intent.resolveActivity(getPackageManager()) == null) {
                result.error(
                    "INSTALL_NO_HANDLER",
                    "No app on this device can install the update.",
                    null
                );
                return;
            }
            startActivity(intent);
            result.success(true);
        } catch (Exception e) {
            e.printStackTrace();
            result.error("INSTALL_FAILED", errorMessage(e), null);
        }
    }

    /** Opens Android's "Install unknown apps" settings for this app. */
    private boolean openInstallSettings() {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true;
            Intent intent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES);
            intent.setData(Uri.parse("package:" + getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (intent.resolveActivity(getPackageManager()) == null) return false;
            startActivity(intent);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Copies the verified APK into the public, shared Downloads folder so it is
     * visible in the phone's Files/Downloads app. The install continues to use
     * the app-private original, which is the FileProvider-served path.
     */
    private void saveToDownloads(String apkPath, MethodChannel.Result result) {
        File source = new File(apkPath);
        if (!source.exists() || !source.isFile()) {
            result.error("APK_NOT_FOUND", "The downloaded update file is missing.", null);
            return;
        }
        String displayName = source.getName();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, displayName);
            values.put(MediaStore.MediaColumns.MIME_TYPE, APK_MIME_TYPE);
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, APK_DIR);
            values.put(MediaStore.MediaColumns.IS_PENDING, 1);
            ContentResolver resolver = getContentResolver();
            Uri uri = null;
            try {
                uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
                if (uri == null) {
                    result.error(
                        "DOWNLOAD_SAVE_FAILED",
                        "The update could not be saved to Downloads.",
                        null
                    );
                    return;
                }
                copyFile(source, resolver.openOutputStream(uri));
            } catch (Exception e) {
                e.printStackTrace();
                if (uri != null) {
                    try {
                        resolver.delete(uri, null, null);
                    } catch (Exception ignored) {
                        // Best effort cleanup of a partially written entry.
                    }
                }
                result.error("DOWNLOAD_SAVE_FAILED", errorMessage(e), null);
                return;
            }
            ContentValues published = new ContentValues();
            published.put(MediaStore.MediaColumns.IS_PENDING, 0);
            resolver.update(uri, published, null, null);
            result.success(APK_DIR + File.separator + displayName);
            return;
        }

        if (checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            pendingDownloadsResult = result;
            pendingDownloadsApkPath = apkPath;
            pendingDownloadsDisplayName = displayName;
            requestPermissions(
                new String[] {Manifest.permission.WRITE_EXTERNAL_STORAGE},
                REQUEST_WRITE_STORAGE
            );
            return;
        }
        writeDownloadsLegacy(apkPath, displayName, result);
    }

    private void writeDownloadsLegacy(
            String apkPath, String displayName, MethodChannel.Result result) {
        File source = new File(apkPath);
        File directory = Environment.getExternalStoragePublicDirectory(APK_DIR);
        if (!directory.exists() && !directory.mkdirs()) {
            result.error(
                "DOWNLOAD_SAVE_FAILED",
                "The Downloads folder is not available.",
                null
            );
            return;
        }
        File target = new File(directory, displayName);
        try {
            copyFile(source, new FileOutputStream(target));
            result.success(target.getAbsolutePath());
        } catch (IOException e) {
            e.printStackTrace();
            result.error("DOWNLOAD_SAVE_FAILED", errorMessage(e), null);
        }
    }

    private static void copyFile(File source, OutputStream output) throws IOException {
        if (output == null) {
            throw new IOException("Could not open the Downloads file for writing.");
        }
        try (InputStream input = new FileInputStream(source);
             OutputStream destination = output) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) != -1) {
                destination.write(buffer, 0, read);
            }
        }
    }

    private static String errorMessage(Exception error) {
        String message = error.getMessage();
        return message == null || message.isEmpty()
            ? "The operation could not be completed."
            : message;
    }
}
