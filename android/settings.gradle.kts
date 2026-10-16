// Clear deprecated ANDROID_PREFS_ROOT if both ANDROID_USER_HOME and ANDROID_PREFS_ROOT are set in env
try {
    val processEnv = Class.forName("java.lang.ProcessEnvironment")

    val envField = processEnv.getDeclaredField("theEnvironment")
    envField.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val envMap = envField.get(null) as? MutableMap<String, String>
    envMap?.keys?.removeIf { it.equals("ANDROID_PREFS_ROOT", ignoreCase = true) }

    val caseInsensitiveField = processEnv.getDeclaredField("theCaseInsensitiveEnvironment")
    caseInsensitiveField.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val caseInsensitiveMap = caseInsensitiveField.get(null) as? MutableMap<String, String>
    caseInsensitiveMap?.keys?.removeIf { it.equals("ANDROID_PREFS_ROOT", ignoreCase = true) }

    if (envMap != null) {
        val unmodifiableEnvField = processEnv.getDeclaredField("theUnmodifiableEnvironment")
        unmodifiableEnvField.isAccessible = true
        unmodifiableEnvField.set(null, java.util.Collections.unmodifiableMap(envMap))
    }
} catch (_: Throwable) {}

pluginManagement {
    val flutterSdkPath =
        run {
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
    id("com.android.application") version "8.3.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}

include(":app")
