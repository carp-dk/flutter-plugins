import 'dart:async';

import 'activity_recognition_pigeon.dart';

part 'activity_recognition_domain.dart';

/// Main entry to activity recognition API. Use as a singleton like
///
///   `ActivityRecognition()`
///
class ActivityRecognition implements ActivityRecognitionFlutterApi {
  final ActivityRecognitionHostApi _hostApi = ActivityRecognitionHostApi();
  final StreamController<ActivityEvent> _controller =
      StreamController<ActivityEvent>.broadcast();
  Stream<ActivityEvent>? _stream;
  static final ActivityRecognition _instance = ActivityRecognition._();
  bool _isListening = false;

  ActivityRecognition._() {
    // Set up the Flutter API to receive callbacks from native
    ActivityRecognitionFlutterApi.setUp(this);
  }

  /// Get the [ActivityRecognition] singleton.
  factory ActivityRecognition() => _instance;

  /// Requests continuous [ActivityEvent] updates.
  ///
  /// The Stream will output the *most probable* [ActivityEvent].
  /// By default the foreground service is enabled, which allows the
  /// updates to be streamed while the app runs in the background.
  /// The programmer can choose to not enable to foreground service.
  Stream<ActivityEvent> activityStream({bool runForegroundService = true}) {
    if (!_isListening) {
      _startListening(runForegroundService);
    }
    _stream ??= _controller.stream;
    return _stream!;
  }

  Future<void> _startListening(bool runForegroundService) async {
    try {
      final config = ActivityRecognitionConfig(
        runForegroundService: runForegroundService,
      );
      await _hostApi.startActivityUpdates(config);
      _isListening = true;
    } catch (e) {
      _controller.addError(e);
    }
  }

  /// Stops activity recognition updates
  Future<void> stopActivityUpdates() async {
    try {
      await _hostApi.stopActivityUpdates();
      _isListening = false;
    } catch (e) {
      _controller.addError(e);
    }
  }

  /// Checks if activity recognition is available on this device
  Future<bool> isAvailable() async {
    try {
      return await _hostApi.isActivityRecognitionAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Implementation of ActivityRecognitionFlutterApi
  /// Called by the native side when a new activity is detected
  @override
  void onActivityUpdate(ActivityEventData event) {
    final activityEvent = ActivityEvent(
      _mapActivityType(event.type),
      event.confidence,
    );
    activityEvent.timeStamp =
        DateTime.fromMillisecondsSinceEpoch(event.timestamp);
    _controller.add(activityEvent);
  }

  /// Map Pigeon ActivityTypeData to ActivityType enum
  ActivityType _mapActivityType(ActivityTypeData type) {
    switch (type) {
      case ActivityTypeData.inVehicle:
        return ActivityType.inVehicle;
      case ActivityTypeData.onBicycle:
        return ActivityType.onBicycle;
      case ActivityTypeData.onFoot:
        return ActivityType.onFoot;
      case ActivityTypeData.running:
        return ActivityType.running;
      case ActivityTypeData.still:
        return ActivityType.still;
      case ActivityTypeData.tilting:
        return ActivityType.tilting;
      case ActivityTypeData.walking:
        return ActivityType.walking;
      case ActivityTypeData.unknown:
        return ActivityType.unknown;
    }
  }

  /// Dispose resources
  void dispose() {
    _controller.close();
  }
}
