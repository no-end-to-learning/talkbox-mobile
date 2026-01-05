# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Gson (if used by any plugin)
-keepattributes Signature
-keep class com.google.gson.** { *; }

# OkHttp (used by many networking plugins)
-dontwarn okhttp3.**
-dontwarn okio.**

# Video player
-keep class com.google.android.exoplayer2.** { *; }

# Play Core (deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
