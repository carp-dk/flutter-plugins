part of 'activity_recognition_flutter.dart';

/// The different types of activities which can be detected.
/// These types is identical to the types detected on Android
/// and iOS types are mapped to these.
enum ActivityType {
  inVehicle,
  onBicycle,
  onFoot,
  running,
  still,
  tilting,
  unknown,
  walking,
  invalid // Used for parsing errors
}

Map<String, ActivityType> _activityMap = {
  // Android
  'IN_VEHICLE': ActivityType.inVehicle,
  'ON_BICYCLE': ActivityType.onBicycle,
  'ON_FOOT': ActivityType.onFoot,
  'RUNNING': ActivityType.running,
  'STILL': ActivityType.still,
  'TILTING': ActivityType.tilting,
  'UNKNOWN': ActivityType.unknown,
  'WALKING': ActivityType.walking,

  // iOS
  'automotive': ActivityType.inVehicle,
  'cycling': ActivityType.onBicycle,
  'running': ActivityType.running,
  'stationary': ActivityType.still,
  'unknown': ActivityType.unknown,
  'walking': ActivityType.walking,
};

/// Represents an activity event detected on the phone.
class ActivityEvent {
  /// The type of activity.
  ActivityType type;

  /// The confidence of the detection in percentage.
  int confidence;

  /// The timestamp when detected.
  late DateTime timeStamp;

  /// The type of activity as a String.
  String get typeString => type.toString().split('.').last;

  ActivityEvent(this.type, this.confidence) {
    timeStamp = DateTime.now();
  }

  factory ActivityEvent.unknown() => ActivityEvent(ActivityType.unknown, 100);

  /// Create an [ActivityEvent] based on the string format `type,confidence`.
  factory ActivityEvent.fromString(String string) {
    List<String> tokens = string.split(",");
    if (tokens.length < 2) return ActivityEvent.unknown();

    ActivityType type = ActivityType.unknown;
    if (_activityMap.containsKey(tokens.first)) {
      type = _activityMap[tokens.first]!;
    }
    int conf = int.tryParse(tokens.last)!;

    return ActivityEvent(type, conf);
  }

  @override
  String toString() => 'Activity - type: $typeString, confidence: $confidence%';
}
