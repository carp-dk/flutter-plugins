# Noise Meter

A noise meter plugin for iOS and Android.

## Install

Add `noise_meter` as a dependency in `pubspec.yaml`.
For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).

### Requirements

This plugin builds on [`audio_streamer`](https://pub.dev/packages/audio_streamer) and inherits its
platform requirements: Flutter 3.44 or later, iOS 16.0 or later, and Android `minSdk` 24 or later.

### Android

Add the microphone permission to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

Enable the following in Xcode:

- Capabilities > Background Modes > _Audio, AirPlay and Picture in Picture_
- In the Runner Xcode project edit the _Info.plist_ file. Add an entry for _'Privacy - Microphone Usage Description'_

If your app requests the permission with [`permission_handler`](https://pub.dev/packages/permission_handler)
**and still integrates iOS dependencies with CocoaPods**, edit the `Podfile` to enable the
microphone permission:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      # for more infomation: https://github.com/BaseflowIT/flutter-permission-handler/blob/master/permission_handler/ios/Classes/PermissionHandlerEnums.h
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_MICROPHONE=1',]
    end
  end
end
```

This step is not needed with Swift Package Manager — `permission_handler_apple` enables the
microphone permission automatically when `NSMicrophoneUsageDescription` is present in
`Info.plist`.

## Swift Package Manager

iOS dependencies are resolved with
[Swift Package Manager](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)
on Flutter 3.44 and later; no configuration is needed. CocoaPods remains supported for apps that
have not migrated. The example app is integrated with SPM only and has no `Podfile`.

## Usage

See the example app for how to use the plugin. This app also illustrated how to obtain permission to access the microphone.

Noise sampling happens by listening to the `noise` stream, like this:

```dart
NoiseMeter().noise.listen(
  (NoiseReading noiseReading) {
    print('Noise: ${noiseReading.meanDecibel} dB');
    print('Max amp: ${noiseReading.maxDecibel} dB');
  },
  onError: (Object error) {
    print(error);
  },
  cancelOnError: true,
);
```

## Technical documentation

### Sample rate

The sample rate for both Android and iOS implementations are 44,100.

### Microphone data

The native implementations record PCM data using the microphone of the device, and uses an audio buffer array to store the incoming data. When the buffer is filled, the contents are emitted to the Flutter side. The incoming floating point values are between -1 and 1 which is the PCM values divided by the max amplitude value which is 2^15.

### Conversion to Decibel

Computing the decibel of a PCM value is done as follows:

```python
db = 20 * log10(2**15 * pcmValue)
```
