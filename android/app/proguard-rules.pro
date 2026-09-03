# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Oreamnos release rules (minify/shrink enabled in build.gradle.kts release type).
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.android.gms.**
-keep class androidx.lifecycle.** { *; }
-keep class androidx.work.** { *; }
# flutter_secure_storage / encrypted prefs
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**
# image / gallery / share plugins use reflection on platform channels
-keep class androidx.exifinterface.** { *; }
# google_fonts runtime fetching — keep okhttp/dio paths out of obfuscation issues
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
# Keep generated JSON models (json_serializable uses reflection-free codegen,
# but guard against shrinking of646474 generic signatures)
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes *Annotation*
