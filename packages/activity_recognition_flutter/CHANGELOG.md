## 6.0.0

- Update AGP
- Updated flutter version
- Updated example app
- Implemented use of Pigeon (see CONTRIBUTING.md)

## 5.0.0

- upgraded Android SDK level
- upgraded flutter version
- upgraded AGP

## 4.2.0

- small refactor and improvement of docs
- using `ActivityRecognition()` when creating a singleton -- standard practice in Dart.

## 4.1.0

- [PR #474](https://github.com/cph-cachet/flutter-plugins/pull/474) - Android 12 intent-flag
- the name of the stream has been changed from `startStream` to `activityStream`
- cleanup in example app

## 4.0.5+1

- [PR #408](https://github.com/cph-cachet/flutter-plugins/pull/408)

## 4.0.4

- improvements to documentation

## 4.0.3

- [PR #358](https://github.com/cph-cachet/flutter-plugins/pull/358)

## 4.0.2

- [PR #302](https://github.com/cph-cachet/flutter-plugins/pull/302)
- [PR #351](https://github.com/cph-cachet/flutter-plugins/pull/351)

## 4.0.1

- Fix of issue #309, i.e. a null pointer that occurs when running the plugin on API 30.
- Replaced the deprecated `IntentService` with a `JobIntentService`.
- [PR #314](https://github.com/cph-cachet/flutter-plugins/pull/314)

## 4.0.0

- Null safety migration
- Updated swift code

## 3.0.1+1

- Update docs.

## 3.0.1

- Fix the null pointer exception described in https://github.com/cph-cachet/flutter-plugins/issues/309

## 3.0.0

- Rewrote the native source code for long-term maintenance sake.
- Changed the API to be easier to follow.

## 2.0.2

- upgrade to `flutter_foreground_service` v. 0.2.1 ([Issue #238](https://github.com/cph-cachet/flutter-plugins/issues/238))
- updated wrong title in example app

## 2.0.1

- upgrade to `flutter_foreground_service` v. 0.2.0 ([Issue #238](https://github.com/cph-cachet/flutter-plugins/issues/238))

## 2.0.0

- Activity recognition now works in the background on Android by means of a foreground service
- Updated domain model

## 1.2.4

- Updated example wrt. permission for Android API 29 and later

## 1.2.3

- Added the ActivityType class
- Updated example app
- Updated docs

## 1.2.2

- Updated Android permissions in docs
- Removed table from README since it was broken on pub.dev

## 1.2.0

- Changed package name to `dk.cachet.activity_recognition_flutter`

## 1.1.0

- Updated documentation with the link to https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects

## 1.0.0

- Initial re-implementation
