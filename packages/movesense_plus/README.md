A Flutter plugin for accessing the [Movesense](https://www.movesense.com/) family of ECG devices. This is a developer-friendly wrapper of the [mdsflutter](https://pub.dev/packages/mdsflutter) plugin.

## Features

This plugin supports the following features, which is the most commonly used sub-set of the total [Movesense API](https://www.movesense.com/docs/esw/api_reference/):

* scan for Movesense devices (and stop scanning again)
* connect and disconnect to a device
* get device and state information
* get a stream of the following sensor data from a device:
  * heart rate
  * ECG
  * IMU
  * temperature
  * state events (movement, battery, connectors, double tap, tap, free fall)

## Getting started

Similar to the [mdsflutter](https://pub.dev/packages/mdsflutter) plugin, the Movesense library needs to be installed in your app.

> **NOTE:** This plugin does not handle permission to access Bluetooth. Use the [permission_handler](https://pub.dev/packages/permission_handler) plugin to request access to scan and connect to BLE devices. See the example app.

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

Download `mdslib-x.x.x-release.aar` from the [movesense-mobile-lib](https://bitbucket.org/movesense/movesense-mobile-lib/src/master/) repository and put it somewhere under `android` folder of your app. Preferably create a new folder named `android/libs` and put it there.

In the `build.gradle` of your android project, add the following lines (assuming `.aar` file is in `android/libs`) for Groovy:

```groovy
allprojects {
    repositories {
        ...
        flatDir{
            dirs "$rootDir/libs"
        }
    }
}
```

Or if using Kotlin, use `dirs("$rootDir/libs")`.

## Usage

Import `package:movesense_plus/movesense_plus.dart` and use the singleton `Movesense()` to scan for Movensense device. Once a `MovesenseDevice` is found, start connecting and accessing device info and listen to sensor data streams.

### Scanning for devices

The singleton `Movesense` can be used for scanning devices:

```dart
/// Listen for discovered devices
Movesense().devices.listen((device) {
  debugPrint('Discovered device: ${device.name} [${device.address}]');
});
/// Start scanning.
Movesense().scan();

/// Stop scanning at some later point.
Movesense().stopScan();
```

### Connecting to a device

Scanning return a `MovesenseDevice` which can be used to connect to the device, like:

```dart
if (!device.isConnected) {
  device.connect();
}
```

A `MovesenseDevice` can either be obtained using the scan method above, or can be create if the address of the device is know:

```dart
final MovesenseDevice device = MovesenseDevice(address: '0C:8C:DC:1B:23:BF');

device.connect();
```

Connection status is available in the `status` field and is also emitted in the `statusEvents` stream.

```dart
print(device.status);

device.statusEvents.listen((status) {
  print('Device connection status changed: ${status.name}');
});
```

### Accessing device information, battery status, and system states

The following device information and status is available as getter methods:

* `getDeviceInfo` - get the full [device info](https://www.movesense.com/docs/esw/api_reference/#info) of this Movesense device.
* `getBatteryStatus` - get the [battery level](https://www.movesense.com/docs/esw/api_reference/#systemstates) ("OK" or "LOW") from the device.
* `getState` - get the [system state](https://www.movesense.com/docs/esw/api_reference/#systemstates) from the device (movement, connectors, doubleTap, tap, freeFall).

For example, getting device info and battery level:

```dart
var info = await device.getDeviceInfo();
print('Product name: ${info?.productName}');

var battery = await device.getBatteryStatus();
print('Battery level: ${battery.name}');
```

### Streaming sensor data

The following sensor data is available as streams:

* `hr` - Heart rate as average bpm and R-R interval at 1 Hz.
* `ecg` - Electrocardiography (ECG) as a sample of reading at 125 Hz.
* `imu` - 9-axis Inertial Movement Unit (IMU) at 13 Hz.
* `temperature` - Surface temperature of the device in Kelvin.

For example, you can listen to the heart rate stream like this:

```dart
// Start listening to the stream of heart rate readings
hrSubscription = device.hr.listen((hr) {
  print('Heart Rate: ${hr.average}, R-R Interval: ${hr.rr} ms');
});

// Stop listening.
hrSubscription?.cancel();
```

The example app shows streaming heart rate data, once connected to a device.

### Streaming state change events

You can also listen to a stream of [system state](https://www.movesense.com/docs/esw/api_reference/#systemstates) from the device (movement, connectors, doubleTap, tap, freeFall). For example, listening for 'tap' events like this:

```dart
stateSubscription = device
    .getStateEvents(SystemStateComponent.tap)
    .listen((state) {
      print('State: $state');
    });
```

> **NOTE:** Listening to system state events on a Movensense device comes with some limitations. First of all, you can [only listen to one type of state event at a time](https://github.com/petri-lipponen-movesense/mdsflutter/issues/15). Second, not all Movesense devices seems to support subscription of all types of state events. For example, it seems like only the 'connectors' and 'tap' states are supported on the Movesense MD and HR2 devices.

## Example App

The included example app is very simple. It shows how to connect to a device with a known `address` and once connected, it listens to the heart rate (`hr`) stream and shows average bpm in the app. Use the floating button to (i) connect, (ii) start streaming heart rate data, and (iii) stop streaming again.

## Features and bugs

Please read about existing [issues](https://github.com/carp-dk/flutter-plugins/issues) and file new feature requests and bug reports as issues. We also happily accept contributions as [pull requests](https://github.com/carp-dk/flutter-plugins/pulls).

## License

This software is copyright (c) the [Technical University of Denmark](https://dtu.dk/) (DTU) and is part of the [Copenhagen Research Platform](https://carp.dk/). This software is available 'as-is' under a [MIT license](LICENSE).
