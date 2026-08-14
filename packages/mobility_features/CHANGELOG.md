## 6.2.0

* widen `carp_serializable` constraint to allow 3.x

## 6.1.0

* upgrade of stats package

## 6.0.0

* using carp_serialization for JSON serialization resulting in a new JSON schema for serialization
* upgrade of example app to use new Flutter Android Gradle build setup
* improvements of code structure and documentation

## 5.0.0

* upgrade to Dart 3.2 and Flutter 3.16
* improvements to API docs
* improvements to example apps (permissions - PR [#971](https://github.com/cph-cachet/flutter-plugins/pull/971)).

## 4.0.1

* Fixed formatting
* Lowered minSdk

## 4.0.0

* Updated kotlin and AGP
* Upgraded example app to `carp_background_location` 4.0.0
* Implemented minor fixes

## 3.1.0

* improvement to `MobilityContext` API.
* misc updates to documentation.

## 3.0.0+2

* update to null-safety
* rename of `MobilityFactory` to `MobilityFeatures`and using the standard Dart singleton syntax for `MobilityFeatures()`.
* misc updates to documentation

## 2.0.6+1

* removal of exception
* update to use `carp_background_location`

## 2.0.5

* Documentation
* Added images and changed documentation somewhat

## 2.0.4

* Move Consolidation
* Moves are now recomputed each time a stop is computed
* This means that the number of moves is always one less that the number of stops

## 2.0.3

* Move Calculation
* Fixed a bug when creating moves between two stops belonging to the same place
* To avoid inaccuracy distance as a resulting of noisy readings when inside buildings, this path should be computed as a straight line, rather than from a list of points

## 2.0.2

* Stop merging
* Implemented stop merging to prevent gaps in the data
* This was especially a problem on iOS devices during the night, where location sampling is automatically limited by the OS
* Gaps in the data during the night would cause the home stay feature to be very unreliable

## 2.0.1

* Stream-based API
* Removed Routine Index temporarily

## 2.0.0

* Stream-based API
* The API is now fully streaming-based.

## 1.3.4

* Flushing data
* Fixed an error where location samples were being flushed when they shouldn't

## 1.3.3

* Dependencies
* Updated dependencies

## 1.3.2

* Streaming based API
* Renamed GeoPosition to GeoLocation due to naming conflicts with another package.

## 1.3.0

* Streaming based API
* Refactored API to support streaming
* An example app is now included

## 1.2.0

* Restructuring
* MobilitySerializer is now private.

## 1.1.5

* Major refactoring
* Renamed and refactored classes such as Location and SingleLocationPoint to GeoPosition and LocationSample respectively.

## 1.1.0

* Private classes
* Made a series of classes private such that they cannot be instantiated from outside the package

## 1.0.0

* Formatting
* Fixed a series of formatting issues which caused the package to score lower on pub.dev
* Upgraded the release number to 1.x.x to increase the package score on pub.dev

## 0.1.5

* Private constructor.
* The Mobility Context constructor is now private
* A Mobility Context should always be instantiated via the ContextGenerator class.

## 0.1.0

* First release.
* The first official release with working unit tests
* Includes a minimalistic API which allows the application programmer to generate features with very few lines of code.
