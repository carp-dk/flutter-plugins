## 4.1.1

- upgrading kotlin version
- upgrading agp version

## 4.1.0

- upgrading gradle version
- upgrading agp version
- upgrading kotlin version
- changing gradle file structure
- untracking files on git

## 4.0.2

- Updates Kotlin plugin and AGP.
- Upgrade of `compileSdkVersion` to 33.
- Upgrade to Dart 3.
- Small updates to example app (asking for permissions)

## 3.0.0

- Migrated to null safety

## 2.1.0

- Removed automatic error handling such as when the sensor is not available. This allows the plugin user to see when errors occur.

## 2.0.2

- Getters for streams are no longer async

## 2.0.1+2

- Downgraded `minSdkVersion` to 18 on Android
- It was set to 26 by mistake in a previous release

## 2.0.1+1

- Fixed image link

## 2.0.1

- Added error handling for when sensors are unavailable

## 2.0.0

- Re-implemented the plugin for both Android and iOS
- This should solve many build problems which persisted on Android
- Added Pedestrian Status events and the ability to stream these
- Added a class for the already-existing step count event

## 1.2.5

- Android 10 and above requires the Activity Recognition permission, this has been added to the docs.

## 1.2.0

- The plugin now returns the steps taken since last boot up.

## 1.1.0

- The Pedometer stream now returns the value since the plugin was started on both platforms.
- Previously this was only the case on iOS, and Android returned the steps taken since last phone boot-up.
