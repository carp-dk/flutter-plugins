library activity_recognition;

import 'dart:async';
import 'package:flutter/services.dart';

part 'activity_recognition_domain.dart';

/// Main entry to activity recognition API. Use as a singleton like
///
///   `ActivityRecognition()`
///
class ActivityRecognition {
  static const EventChannel _eventChannel =
      const EventChannel('activity_recognition_flutter');
  Stream<ActivityEvent>? _stream;
  static ActivityRecognition _instance = ActivityRecognition._();
  ActivityRecognition._();

  /// Get the [ActivityRecognition] singleton.
  factory ActivityRecognition() => _instance;

  /// Requests continuous [ActivityEvent] updates.
  ///
  /// The Stream will output the *most probable* [ActivityEvent].
  /// By default the foreground service is enabled, which allows the
  /// updates to be streamed while the app runs in the background.
  /// The programmer can choose to not enable to foreground service.
  Stream<ActivityEvent> activityStream({bool runForegroundService = true}) {
    _stream ??= _eventChannel
          .receiveBroadcastStream({"foreground": runForegroundService}).map(
              (json) => ActivityEvent.fromString(json));
    return _stream!;
  }
}
