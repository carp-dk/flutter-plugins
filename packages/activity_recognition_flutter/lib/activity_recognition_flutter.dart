library activity_recognition;

import 'dart:async';

import 'src/messages.g.dart';

part 'activity_recognition_domain.dart';

/// Main entry to the activity recognition API. Use as a singleton like
///
///   `ActivityRecognition()`
///
class ActivityRecognition {
  static final ActivityRecognition _instance = ActivityRecognition._();

  ActivityRecognition._();

  /// Get the [ActivityRecognition] singleton.
  factory ActivityRecognition() => _instance;

  final ActivityRecognitionHostApi _hostApi = ActivityRecognitionHostApi();

  Stream<ActivityEvent>? _stream;

  /// Requests continuous [ActivityEvent] updates.
  ///
  /// The stream emits the *most probable* [ActivityEvent] detected by the phone.
  ///
  /// On Android a foreground service is started by default, which allows the
  /// updates to keep arriving while the app runs in the background. Pass
  /// `runForegroundService: false` to opt out. The flag is ignored on iOS,
  /// where updates are delivered in the background regardless.
  ///
  /// The returned stream is a broadcast stream and is built once; later calls
  /// return the same stream and do not re-apply [runForegroundService].
  Stream<ActivityEvent> activityStream({bool runForegroundService = true}) =>
      _stream ??= _createStream(runForegroundService);

  Stream<ActivityEvent> _createStream(bool runForegroundService) {
    // `streamActivities` opens a new event channel on every call, so it is
    // invoked exactly once and the resulting stream reused.
    final Stream<ActivityEvent> events =
        streamActivities().map(ActivityEvent._fromPlatform);

    late final StreamController<ActivityEvent> controller;
    StreamSubscription<ActivityEvent>? subscription;

    controller = StreamController<ActivityEvent>.broadcast(
      onListen: () async {
        // The platform starts tracking as soon as the event channel is listened
        // to, so the configuration has to be applied before subscribing.
        await _hostApi.configure(
          TrackingConfiguration(runForegroundService: runForegroundService),
        );

        // The listener may have cancelled while the configuration was in flight.
        if (!controller.hasListener) return;

        subscription = events.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () async {
        await subscription?.cancel();
        subscription = null;
      },
    );

    return controller.stream;
  }
}
