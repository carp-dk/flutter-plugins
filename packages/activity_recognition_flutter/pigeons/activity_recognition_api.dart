// Copyright 2024 Copenhagen Center for Health Technology (CACHET) at the
// Technical University of Denmark (DTU).
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

/// Configuration for the Pigeon code generator
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/activity_recognition_pigeon.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/dk/cachet/activity_recognition_flutter/ActivityRecognitionPigeon.kt',
    kotlinOptions: KotlinOptions(
      package: 'dk.cachet.activity_recognition_flutter',
    ),
    swiftOut: 'ios/activity_recognition_flutter/Sources/activity_recognition_flutter/ActivityRecognitionPigeon.swift',
    swiftOptions: SwiftOptions(),
  ),
)

/// Represents an activity type detected by the device
enum ActivityTypeData {
  inVehicle,
  onBicycle,
  onFoot,
  running,
  still,
  tilting,
  unknown,
  walking,
}

/// Represents an activity event with type, confidence, and timestamp
class ActivityEventData {
  /// The type of activity detected
  final ActivityTypeData type;

  /// The confidence level (0-100) of the detection
  final int confidence;

  /// The timestamp when the activity was detected (milliseconds since epoch)
  final int timestamp;

  ActivityEventData({
    required this.type,
    required this.confidence,
    required this.timestamp,
  });
}

/// Configuration for starting activity recognition
class ActivityRecognitionConfig {
  /// Whether to run a foreground service (Android only)
  final bool runForegroundService;

  ActivityRecognitionConfig({
    required this.runForegroundService,
  });
}

/// Host API - Methods implemented on the native side (Android/iOS) and called from Flutter
@HostApi()
abstract class ActivityRecognitionHostApi {
  /// Starts activity recognition with the given configuration
  /// Returns null on success, throws FlutterError on failure
  void startActivityUpdates(ActivityRecognitionConfig config);

  /// Stops activity recognition
  void stopActivityUpdates();

  /// Checks if activity recognition is available on the device
  bool isActivityRecognitionAvailable();
}

/// Flutter API - Methods implemented in Flutter and called from native code
/// Used to send activity events from native to Flutter
@FlutterApi()
abstract class ActivityRecognitionFlutterApi {
  /// Called when a new activity is detected on the native side
  void onActivityUpdate(ActivityEventData event);
}
