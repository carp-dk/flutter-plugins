part of activity_recognition;

/// The different types of activities which can be detected.
///
/// These types are identical to the ones detected on Android; the smaller set
/// of activities iOS reports is mapped onto them natively.
enum ActivityType {
  IN_VEHICLE,
  ON_BICYCLE,
  ON_FOOT,
  RUNNING,
  STILL,
  TILTING,
  UNKNOWN,
  WALKING,
}

const Map<PlatformActivityType, ActivityType> _activityTypes =
    <PlatformActivityType, ActivityType>{
  PlatformActivityType.inVehicle: ActivityType.IN_VEHICLE,
  PlatformActivityType.onBicycle: ActivityType.ON_BICYCLE,
  PlatformActivityType.onFoot: ActivityType.ON_FOOT,
  PlatformActivityType.running: ActivityType.RUNNING,
  PlatformActivityType.still: ActivityType.STILL,
  PlatformActivityType.tilting: ActivityType.TILTING,
  PlatformActivityType.unknown: ActivityType.UNKNOWN,
  PlatformActivityType.walking: ActivityType.WALKING,
};

/// Represents an activity event detected on the phone.
class ActivityEvent {
  /// The type of activity.
  final ActivityType type;

  /// The confidence of the detection in percent (0-100).
  final int confidence;

  /// The timestamp of the detection, as reported by the platform.
  final DateTime timeStamp;

  /// The type of activity as a String.
  String get typeString => type.name;

  ActivityEvent(this.type, this.confidence, [DateTime? timeStamp])
      : timeStamp = timeStamp ?? DateTime.now();

  factory ActivityEvent.unknown() => ActivityEvent(ActivityType.UNKNOWN, 100);

  factory ActivityEvent._fromPlatform(PlatformActivity activity) =>
      ActivityEvent(
        _activityTypes[activity.type] ?? ActivityType.UNKNOWN,
        activity.confidence,
        DateTime.fromMillisecondsSinceEpoch(activity.timestamp),
      );

  @override
  String toString() => 'Activity - type: $typeString, confidence: $confidence%';
}
