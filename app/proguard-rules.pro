# ProGuard Rules for Eye of Anubis NVR
# proguard-rules.pro

# Keep NanoHTTPD (HTTP Server)
-keep class fi.iki.elonen.** { *; }
-dontwarn fi.iki.elonen.**

# Keep TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**

# Keep OkHttp
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep ExoPlayer / Media3
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Keep Anubis classes (never obfuscate our service classes)
-keep class com.anubis.nvr.service.** { *; }
-keep class com.anubis.nvr.camera.** { *; }
-keep class com.anubis.nvr.storage.** { *; }
-keep class com.anubis.nvr.ai.** { *; }

# Keep JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Compose
-keep class androidx.compose.** { *; }

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static int d(...);
    public static int v(...);
}
