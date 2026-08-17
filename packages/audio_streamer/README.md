# Audio Streamer

Streaming of Pulse-code modulation (PCM) audio from Android and iOS with a customizable sampling rate.

## Permissions

Using this plugin needs permission to access the microphone. Requesting this permission is **NOT** part of the plugin, but should be handled by the app. However, for the app to be able to access the microphone, the app need to have the following permission on Android and iOS.

On **Android** add the audio recording permission to `AndroidManifest.xml`.

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

On **iOS** enable the following using XCode:

- Capabilities > Background Modes > _Audio, AirPlay and Picture in Picture_
- In the Runner Xcode project edit the `Info.plist` file. Add an entry for _'Privacy - Microphone Usage Description'_

If editing the `Info.plist` file manually, the entries needed are:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>YOUR DESCRIPTION</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

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

This plugin supports both [Swift Package Manager](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)
and CocoaPods on iOS. SPM is used automatically on Flutter 3.44 and later; no configuration is
needed. The example app is integrated with SPM only and has no `Podfile`.

## Using the plugin

The plugin works as a singleton and provide a simple `audioStream` to listen to.

```dart
AudioStreamer().audioStream.listen(
  (List<double> buffer) {
    print('Max amp: ${buffer.reduce(max)}');
    print('Min amp: ${buffer.reduce(min)}');
  },
  onError: (Object error) {
    print(error);
  },
  cancelOnError: true,
);
```

The sampling rate can be set and read using the `samplingRate` and `actualSampleRate` properties.

```dart
// Set the sampling rate. Must be done BEFORE listening to the audioStream.
AudioStreamer().sampleRate = 22100;

// Get the real sampling rate - may be different from the requested sampling rate.
int sampleRate = await AudioStreamer().actualSampleRate;
```

## Example

See the file `example/lib/main.dart` for an example app using the plugin.
This app also illustrates how to ask for permission to access the microphone.
Note that on iOS the sample rate will not necessarily change, as there is only the option to set a preferred one.
