# Empatica Flutter plugin

Flutter plugin for the [Empatica E4](https://e4.empatica.com/e4-wristband) wristband on Android.

## Install (Flutter)

Add `empatica_e4link` as a dependency in `pubspec.yaml` or run `flutter pub add empatica_e4link`
For help on adding as a dependency, view the [pubspec documenation](https://flutter.io/using-packages/).

## Android

The package uses bluetooth to fetch data from the E4 device. Therefore bluetooth usage must be declared. Since bluetooth also allow for locations tracking, location tracking permissions must also be declared.

Add the following entry to your `manifest.xml` file, in the Android project of your application:

```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true"/>
```

Also make sure to obtain permissions in your app to use location and bluetooth. See the example app on how to e.g. use the [`permission_handler`](https://pub.dev/packages/permission_handler) for this. Note that the plugin **does not** handle permissions - this has to be done on an app level.

Set the Android compile and minimum SDK versions to `compileSdkVersion 33`, and `minSdkVersion 28` respectively, inside the `android/app/build.gradle` file.

## iOS

Due to compatibility issues with Empatica's SDK, the iOS implementation is not able to function with new CocoaPods and iPhone architectures.

## Usage

The Empatica E4 Flutter plugin has been designed to resemble the Android Empatica API almost **1:1**. Hence, you should be able to recognize the names of the different classes and class variables. For example, the methods on the `EmpaticaDeviceManager` class is mapped 1:1. See the [Empatica Android documentation](https://developer.empatica.com/empatica-android-sdk-javadoc.zip) on how it all works.

However, one major design change has been done; this Empatica Flutter plugin complies to the Dart/Flutter reactive programming architecture using [Stream](https://api.dart.dev/dart-async/Stream-class.html)s. Hence, you do not get callbacks to an Empatica device (as you do in Java) -- rather, you obtain a Dart stream and listen to this stream (and exploit all the [other very nice stream operations](https://dart.dev/tutorials/language/streams) which are available in Dart). Below, we shall describe how to use the Empatica streams. But first -- let's see how to set up and connect to an Empatica E4 device in the first place.

### Setting up and Connecting to an Empatica Device

All operations on the Empatica device happens via the `Empatica plugin`

At first one must connect to the Empatica backend via an API key given by Empatica using the `authenticateWithAPIKey` method.

```dart
import 'package:empatica_e4link/empatica.dart';

...

// create a device manager that will handle method calls
EmpaticaPlugin deviceManager = EmpaticaPlugin();

await deviceManager
              .authenticateWithAPIKey('your api key goes ');

...

// first listen to status events before trying to connect
deviceManager.statusEventSink?.listen((event) async {
      switch (event.runtimeType) {
        case UpdateStatus:
          //the status of the device manager
          print((event as UpdateStatus).status)
          break;
        case DiscoverDevice:
          await deviceManager.connectDevice((event as DiscoverDevice).device);
          break;
      }
    });

// when status is READY we can start scanning for devices
await deviceManager.startScanning();

```

Everything with the Empatica API happens asynchronously. Hence, the `connectDevice` call merely initiates the connection process. In order to know the status of the device manager, you should listen to status events `statusEventSink`.
This is done via the `statusEventSink` stream.
Note, that if you want to know if your connection to the device is successful, you should initiate listening **before** the connection is initiated, as shown above.

### Listen to physiological data

When the status is `CONNECTED` the device will be sending all data events to `dataEventSink`. To get _ALL_ data one should start listening on this stream before it is connected, e.g. when the status is `CONNECTING`.

```dart
deviceManager.dataEventSink?.listen((event) {
      switch (event.runtimeType) {
        // update each data point with the appropriate data
        case ReceiveBVP:
          event as ReceiveBVP;
          break;
```

The possible data events in the `dataEventSink` are:

- ReceiveBVP
- ReceiveGSR
- ReceiveIBI
- ReceiveTemperature
- ReceiveAcceleration
- ReceiveBatteryLevel
- ReceiveTag
- UpdateOnWristStatus

## Contributing

The Gradle task useAar in `./android` has to be run for the Empatica SDK to be modeled and used in the Android code.
