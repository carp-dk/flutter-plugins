<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

A Flutter plugin for accessing the [Movesense](https://www.movesense.com/) family of ECG devices. This is a developer-friendly wrapper of the [mdsflutter](https://pub.dev/packages/mdsflutter) plugin.

## Features

This plugin supports the following features, which is the most commonly used sub-set of the total [Movensene API](https://www.movesense.com/docs/esw/api_reference/):

* scan for Movensense devices (and stop scanning again)
* connect and disconnect to a device
* get device information
* turn on/off the LED on the device
* get a stream of the following data from a device:
  * heartrate
  * ECG
  * IMU
  * temperature
  * state events (movement, battery, connectors, double tap, tap, free fall)

## Getting started

Similar to the [mdsflutter](https://pub.dev/packages/mdsflutter) plugin, the Movesense library needs to be installed in your app.

### iOS

Install the Movesense iOS library using CocoaPods with adding this line to your app's Podfile:

```shell
  pod 'Movesense', :git => 'ssh://git@altssh.bitbucket.org:443/movesense/movesense-mobile-lib.git'
```

Then set up your `ios/Podfile` as follows:

```pod
target 'Runner' do
  use_modular_headers!
  use_frameworks! :linkage => :static

  pod 'Movesense', :git => 'https://bitbucket.org/movesense/movesense-mobile-lib.git'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

This will ensure that the MDS library is linked correctly. If you need to use frameworks that demand dynamic linking, [follow the instructions here](https://bitbucket.org/movesense/movesense-mobile-lib/issues/119/cannot-use-health-and-mdsflutter-depending).

### Android

Download `mdslib-x.x.x-release.aar` from the [movesense-mobile-lib](https://bitbucket.org/movesense/movesense-mobile-lib/src/master/) repository and put it somewhere under 'android' folder of your app. Preferably create a new folder named `android/libs` and put it there.

In the `build.gradle` of your android project, add the following lines (assuming `.aar` file is in `android/libs`):

```graddle
allprojects {
    repositories {
        ...
        flatDir{
            dirs "$rootDir/libs"
        }
    }
}
```

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
