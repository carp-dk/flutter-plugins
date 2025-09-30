## 4.3.0

* Fix issue where stream function made a new thread each time a recording starts - Fixes [#1242](https://github.com/cph-cachet/flutter-plugins/issues/1242)
* Updated Gradle and Kotlin
* Updated `permission_handler: ^12.0.0`
* Updated `sdk >=3.8.1`

## 4.2.2

* Reverts [#1226](https://github.com/cph-cachet/flutter-plugins/pull/1226)

## 4.2.0

* Gradle files restructure for example app
* Small upgrades to ios example app
* Upgrading gradle version
* Upgrading agp
* Upgrading targetSdkVersion
* Upgrading compileSdkVersion
* Upgrading ndkVersion

## 4.1.1

* enable AGP 8.0

## 4.0.0

* removal of permission_handler dependency - handling permission should take place in the app, not the plugin.
* major refactor of plugin code
* update of example app to handle permissions to access the microphone and other improvements.

## 3.1.0

* upgrade of permission_handler plugins

## 3.0.0

* implementing `AudioStreamer` as a singleton
* updates Kotlin plugin and AGP
* upgrade to Dart 3
* [PR#682](https://github.com/cph-cachet/flutter-plugins/pull/682)
* [PR#721](https://github.com/cph-cachet/flutter-plugins/pull/721)

## 2.3.0

* implemented custom sample rate functionality
* [PR#521](https://github.com/cph-cachet/flutter-plugins/pull/521)
* [PR#522](https://github.com/cph-cachet/flutter-plugins/pull/522)

## 2.2.0+1

* updated example app podfile to correctly include permission for iOS
* updated README to include podfile permission

## 2.2.0

* upgrade of `permission_handler: ^10.0.0`
* Upgraded to Dart 2.17 and Flutter 3.0

## 2.1.0

* upgrade of `permission_handler: ^9.2.0`
* [PR#503](https://github.com/cph-cachet/flutter-plugins/pull/503)
* [PR#504](https://github.com/cph-cachet/flutter-plugins/pull/504)

## 2.0.3

* [PR#371](https://github.com/cph-cachet/flutter-plugins/pull/371)

## 2.0.2

* [PR#364](https://github.com/cph-cachet/flutter-plugins/pull/364)
* upgrade to `permission_handler: ^8.1.0`

## 2.0.0

* Null safety migration

## 1.3.0

* Fixed an issue where using another media player/recorder would cause the plugin to go into an error state on iOS (see <https://github.com/cph-cachet/flutter-plugins/issues/86>)

## 1.2.0

* Fixed an issue where the AVAudioRecorder would crash on iOS (see <https://github.com/cph-cachet/flutter-plugins/issues/91>)

## 1.1.6

* Upgrade to `permission_handler` v. 5.

## 1.1.5

* Added a getter for the sample rate field.

## 1.1.0

* Able to stream audio data on Android as well
* The plugin will now record as soon as the permission dialog ends.

## 1.0.0

* Able to stream audio data on iOS.
