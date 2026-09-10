allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Workaround for plugins (e.g. speech_to_text) whose android/build.gradle
// reads `flutter.compileSdkVersion` / `flutter.ndkVersion` directly on the
// Android library extension (`compileSdk = flutter.compileSdkVersion`).
// That `flutter` accessor is normally an extension the Flutter Gradle
// plugin adds onto the *app* module's `android {}` block. With the modern
// plugin-loader setup in settings.gradle.kts it is never added to other
// plugins' own library subprojects, so evaluating them fails with
// "Could not get unknown property 'flutter' for extension 'android'".
// Adding an equivalent extension with the same shape before each
// subproject's `android {}` block is evaluated fixes this without
// touching the plugin's own source.
class FlutterSdkVersions {
    var compileSdkVersion = 35
    var ndkVersion = "27.0.12077973"
    var minSdkVersion = 23
    var targetSdkVersion = 35
}

subprojects {
    if (project.name != "app") {
        plugins.withId("com.android.library") {
            extensions.findByName("android")?.let { android ->
                if ((android as ExtensionAware).extensions.findByName("flutter") == null) {
                    android.extensions.add("flutter", FlutterSdkVersions())
                }
            }
        }
        plugins.withId("com.android.application") {
            extensions.findByName("android")?.let { android ->
                if ((android as ExtensionAware).extensions.findByName("flutter") == null) {
                    android.extensions.add("flutter", FlutterSdkVersions())
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
