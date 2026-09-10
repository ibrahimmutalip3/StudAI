# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Drift / sqlite3
-keep class org.sqlite.** { *; }

# Gson-style reflection used transitively by some plugins
-keepattributes Signature
-keepattributes *Annotation*
