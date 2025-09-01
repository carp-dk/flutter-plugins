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
