pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 8.5.x only supports compileSdk up to API 34 (this project uses
    // compileSdk 35, see android/app/build.gradle.kts), and it predates
    // flutter_local_notifications' requirement of AGP 8.6.0+ for
    // compileSdk 35. 8.13.0 is the newest 8.x release (max API 36.1) and
    // keeps working with the classic `kotlin-android` plugin applied
    // below and in every plugin's own build.gradle — AGP 9.0+ removes
    // that plugin entirely in favor of built-in Kotlin, which would need
    // a separate migration (see Flutter's built-in Kotlin migration
    // guide) that several transitive plugins don't support yet.
    id("com.android.application") version "8.13.0" apply false
    // Kotlin 2.1.20: current stable, matches AGP 8.13/Gradle 8.13, and is
    // the version Google's own docs recommend pairing with AGP ~8.10+.
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
}

include(":app")
