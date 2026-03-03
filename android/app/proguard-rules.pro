# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Hive — reflection-based adapter lookup must survive shrinking
-keep class com.hivedb.** { *; }
-keep class * extends com.hivedb.hive.HiveObject { *; }
-keepclassmembers class * {
    @com.hivedb.hive.annotations.HiveField *;
    @com.hivedb.hive.annotations.HiveType *;
}

# adhan — uses reflection for calculation parameters
-keep class com.batoulapps.adhan.** { *; }

# Keep all Kotlin metadata
-keepattributes *Annotation*
-keep class kotlin.Metadata { *; }
