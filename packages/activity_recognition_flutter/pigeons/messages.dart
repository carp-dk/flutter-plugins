// Interface definition for the native activity recognition code.
//
// This file is the single source of truth for the Dart <-> native contract.
// It is not shipped with the package; it is consumed by Pigeon to generate
// the typed message plumbing for all three languages:
//
//   lib/src/messages.g.dart
//   ios/activity_recognition_flutter/Sources/activity_recognition_flutter/Messages.g.swift
//   android/src/main/kotlin/dk/carp/activity_recognition_flutter/Messages.g.kt
//
// Regenerate after editing with:
//
//   dart run pigeon --input pigeons/messages.dart

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    swiftOut:
        'ios/activity_recognition_flutter/Sources/activity_recognition_flutter/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut:
        'android/src/main/kotlin/dk/carp/activity_recognition_flutter/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'dk.carp.activity_recognition_flutter'),
    dartPackageName: 'activity_recognition_flutter',
  ),
)
/// The activity types that can be reported by the native platforms.
///
/// Android reports these directly; the smaller set of iOS `CMMotionActivity`
/// flags is mapped onto them natively, so the wire format is identical on
/// both platforms.
enum PlatformActivityType {
  inVehicle,
  onBicycle,
  onFoot,
  running,
  still,
  tilting,
  unknown,
  walking,
}

/// A single activity detection as reported by the platform.
class PlatformActivity {
  PlatformActivity({
    required this.type,
    required this.confidence,
    required this.timestamp,
  });

  /// The detected activity.
  final PlatformActivityType type;

  /// Confidence of the detection, in percent (0-100).
  final int confidence;

  /// When the activity was detected, in milliseconds since the Unix epoch.
  ///
  /// Produced natively so the timestamp reflects the detection itself rather
  /// than the moment the event happened to arrive in Dart.
  final int timestamp;
}

/// Options applied to activity tracking before the event stream is started.
class TrackingConfiguration {
  TrackingConfiguration({required this.runForegroundService});

  /// Whether Android should run a foreground service so that detections keep
  /// arriving while the app is backgrounded.
  ///
  /// Ignored on iOS, where `CMMotionActivityManager` already delivers updates
  /// in the background.
  final bool runForegroundService;
}

/// Control channel. Called before listening to [ActivityStreamApi].
@HostApi()
abstract class ActivityRecognitionHostApi {
  /// Applies [configuration] to the next tracking session.
  void configure(TrackingConfiguration configuration);
}

/// Data channel carrying the detected activities.
@EventChannelApi()
abstract class ActivityStreamApi {
  PlatformActivity streamActivities();
}
