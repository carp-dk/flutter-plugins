## 5.0.2

* Relax Dart SDK lower bound from `^3.12.2` to `>=3.12.0` — the patch-level pin was accidental and blocked apps on Flutter 3.44.0/3.44.1.
* Fix Android build in apps using AGP < 9: apply the Kotlin Gradle plugin conditionally instead of pinning AGP 9.0.1/Kotlin 2.3.20 on the buildscript classpath (see the [built-in Kotlin migration guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors)).
* Fix `NoClassDefFoundError: ScreenReceiver` at runtime: `ScreenReceiver.java` lived in the `src/main/kotlin` folder and relied on a `sourceSets` override to be compiled; it is now converted to Kotlin (`ScreenReceiver.kt`).
* Note: 5.0.1 also raised Android `minSdk` 21 → 24 and `compileSdk` 33 → 36 (undocumented in its changelog).

## 5.0.1

* Fix app not running on Flutter 3.44.X
* Fix privacy manifest issue on iOS.
* Update minimum iOS version to 15.0.

## 5.0.0

* Update to kotlin 2.2.2
* Update to gradle 8.12.1
* Enabled SPM support
* Improved example
* Note: some API names have changed

## 4.1.1

* upgrade of Android APK
* adding linter
* removing `ScreenStateException` and instead returning an empty stream on unsupported platforms for more graceful handling

## 4.0.0

* Added support for iOS.
* Restructuring of the interaction between the plugin and native applications.

## 3.0.1

* Reduced minSdk version to 23

## 3.0.0

* `Screen()` implemented as singleton.
* Updates Kotlin plugin and AGP.
* Upgrade of `compileSdkVersion` to 33.
* Upgrade to Dart 3.

## 2.0.0

* Null safety migration

## 1.0.1

* Fixed an issue causing the plugin to crash when the stream was cancelled and then opened again.
  * See <https://github.com/cph-cachet/flutter-plugins/issues/188>

## 1.0.0

* Migrated to new Android Plugin API (Flutter 1.12)

## 0.5.0

* Migrated to AndroidX
