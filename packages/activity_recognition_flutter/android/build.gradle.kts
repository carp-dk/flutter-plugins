group = "dk.carp.activity_recognition_flutter"
version = "1.0"

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

// AGP 9+ has built-in Kotlin support; on older AGP the Kotlin Gradle plugin
// must be applied explicitly. Version is supplied by the consuming app.
// See https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
val agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.substringBefore('.').toInt()
if (agpMajor < 9) {
    apply(plugin = "org.jetbrains.kotlin.android")
}

android {
    namespace = "dk.carp.activity_recognition_flutter"

    // Kept at the lowest currently supported level on purpose: a library forces
    // every app that depends on it to compile against at least this SDK.
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        // API 26 is required by the plugin itself: notification channels and
        // Context.startForegroundService were both added in Android 8.
        minSdk = 26
    }

    lint {
        disable += "InvalidPackage"
    }
}

// Configured reflectively rather than through the `kotlin { }` accessor: the
// Kotlin plugin is applied after this script is compiled (by Flutter, or
// conditionally above), so the type-safe accessor does not exist here.
project.extensions.configure(org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension::class.java) {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-location:21.3.0")
}
