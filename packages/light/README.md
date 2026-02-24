# Light

[![pub package](https://img.shields.io/pub/v/light.svg)](https://pub.dartlang.org/packages/light)

A Flutter plugin for collecting ambient light data on Android and iOS.

Android uses the [Environment Sensors API](https://developer.android.com/develop/sensors-and-location/sensors/sensors_environment).
iOS uses [SensorKit ambient light sensor](https://developer.apple.com/documentation/sensorkit/srsensor/ambientlightsensor).

## Install

Add `light` as a dependency in `pubspec.yaml`.

## iOS requirements

> [!CAUTION]
> Not all devices have SensorKit. Requires iOS 14 or higher. Reading sensory data from iOS requires research entitlements and previous approval from Apple for reading sensory data. Please see the documentations at [Configuring your project for sensor reading](https://developer.apple.com/documentation/sensorkit/configuring-your-project-for-sensor-reading).

SensorKit requires more setup than Android.

1. Enable the SensorKit entitlement and include ambient light in your app entitlements:

```xml
<key>com.apple.developer.sensorkit.reader.allow</key>
<array>
  <string>ambient-light-sensor</string>
</array>
```

SensorKit access is entitlement-gated by Apple. Without approved entitlement provisioning, iOS returns an invalid-entitlement error.

2. Add SensorKit purpose text in `Info.plist`:

```xml
<key>NSSensorKitUsageDetail</key>
<dict>
  <key>SRSensorUsageAmbientLightSensor</key>
  <string>Explain why your app needs ambient light sensor data.</string>
</dict>
```

3. Request authorization before or while starting the stream:

```dart
final LightAuthorizationStatus status =
    await Light().requestAuthorization();
```

On Android, `requestAuthorization()` returns `LightAuthorizationStatus.unavailable` and no runtime permission prompt is required.

If iOS setup is incomplete, the stream emits a `PlatformException` (for example, missing entitlement or usage description).

## Usage

```dart
StreamSubscription<int>? _lightEvents;

Future<void> startListening() async {
  await Light().requestAuthorization(); // no-op on Android
  _lightEvents = Light().lightSensorStream.listen((int luxValue) {
    // Do something with lux.
  });
}

void stopListening() {
  _lightEvents?.cancel();
}
```
