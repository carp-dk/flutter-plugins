# Activity Recognition

[![pub package](https://img.shields.io/pub/v/activity_recognition_flutter.svg)](https://pub.dartlang.org/packages/activity_recognition)

Activity recognition plugin for Android and iOS. Only working while App is running (= not terminated by the user or OS).

The communication with the native platforms is defined in [`pigeons/messages.dart`](pigeons/messages.dart)
and generated with [Pigeon](https://pub.dev/packages/pigeon). Regenerate it after
changing that file with:

```sh
dart run pigeon --input pigeons/messages.dart
```

The iOS implementation is a Swift package (`ios/activity_recognition_flutter/`).
CocoaPods is no longer supported, so consuming apps must use Swift Package
Manager. See [iOS](#ios) below.


## Configuration

### Android

The permissions the plugin requires, and the broadcast receiver and 
foreground service it relies on, are declared by the plugin.

You still have to request the `ACTIVITY_RECOGNITION` runtime permission before
listening to the stream -- see [Usage](#usage) below.

#### Known Android quirks

If you update from Android SDK <=28 to >=29 remember to run `flutter clean`. See e.g. [this post](https://stackoverflow.com/questions/55407939/permission-requests-are-not-propagated-when-launching-with-flutter-but-are-when/57072913) on stack overflow.

This package uses the Android Embedding API v2. In order to use this in pre-Flutter 1.12 projects, you need to follow [this guide](https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects).


### iOS 

This plugin ships only as a Swift package, so your app must use Swift Package
Manager. It is enabled by default on Flutter 3.44 and later; if you turned it
off, re-enable it with:

```sh
flutter config --enable-swift-package-manager
```

If your app still has CocoaPods integration, see
[Flutter Swift Package Manager guide](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)
for details.

An iOS app linked on must include usage description keys in its `Info.plist` file for the types of data it needs. Failure to include these keys will cause the app to crash.
To access motion and fitness data specifically, it must include `NSMotionUsageDescription`, like this:

```xml
<key>NSMotionUsageDescription</key>
<string>Detects human activity</string>
```

## Usage

To use this plugin, you need to also use the [permission_handler](https://pub.dev/packages/permission_handler) plugin, or some other way of requesting permission. See the example app. 

> **NOTE:** You should NOT use the permission handler plugin for requesting activity recognition on iOS, since it is not needed and will make your iOS app crash.

## Data types

Each detected activity will have an activity type, which is one of the following:

* IN_VEHICLE
* ON_BICYCLE
* ON_FOOT
* RUNNING
* STILL
* TILTING
* UNKNOWN
* WALKING

As well as a confidence expressed in percentages (i.e. a value from 0-100), and
the timestamp of the detection as reported by the platform.
