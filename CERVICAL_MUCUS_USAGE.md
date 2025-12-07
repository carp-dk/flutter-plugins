# Cervical Mucus Data - Flutter/Dart Usage Guide

## Android Health Connect Integration

### Method Channel Setup

The Android implementation provides a dedicated method channel for cervical mucus data:

```dart
const platform = MethodChannel('flutter_health');
```

### Sensation & Appearance Values

#### Sensation (Texture) Scale

```dart
enum CervicalMucusSensation {
  unknown(0, 'Unknown'),
  light(1, 'Dry'),       // Light sensation
  medium(2, 'Moist'),    // Medium sensation (most fertile)
  heavy(3, 'Wet');       // Heavy sensation (peak fertility)

  final int value;
  final String description;

  const CervicalMucusSensation(this.value, this.description);
}
```

#### Appearance Scale

```dart
enum CervicalMucusAppearance {
  unknown(0, 'None'),
  sticky(1, 'Sticky'),
  creamy(2, 'Creamy'),
  eggWhite(3, 'Egg White'),
  watery(4, 'Watery'),          // For future use
  unusual(5, 'Unusual');         // For atypical discharge

  final int value;
  final String description;

  const CervicalMucusAppearance(this.value, this.description);
}
```

### Writing Cervical Mucus Data

#### Example 1: Simple Entry (Manual Observation)

```dart
Future<bool> writeCervicalMucusData({
  required CervicalMucusSensation sensation,
  required CervicalMucusAppearance appearance,
  required DateTime dateTime,
}) async {
  try {
    final bool result = await platform.invokeMethod<bool>(
      'writeCervicalMucusData',
      {
        'sensation': sensation.value.toDouble(),
        'appearance': appearance.value.toDouble(),
        'startTime': dateTime.millisecondsSinceEpoch,
        'recordingMethod': 1, // Manual entry
      },
    ) ?? false;

    return result;
  } catch (e) {
    print('Error writing cervical mucus data: $e');
    return false;
  }
}
```

#### Example 2: With Device Information

```dart
Future<bool> writeCervicalMucusDataWithDevice({
  required CervicalMucusSensation sensation,
  required CervicalMucusAppearance appearance,
  required DateTime dateTime,
  int recordingMethod = 1, // 1=Manual, 2=Auto, 3=Active
  int? deviceType,
  String? clientRecordId,
  int? clientRecordVersion,
}) async {
  try {
    final bool result = await platform.invokeMethod<bool>(
      'writeCervicalMucusData',
      {
        'sensation': sensation.value.toDouble(),
        'appearance': appearance.value.toDouble(),
        'startTime': dateTime.millisecondsSinceEpoch,
        'recordingMethod': recordingMethod,
        'deviceType': deviceType,
        'clientRecordId': clientRecordId,
        'clientRecordVersion': clientRecordVersion,
      },
    ) ?? false;

    return result;
  } catch (e) {
    print('Error writing cervical mucus data: $e');
    return false;
  }
}
```

### Usage Examples

#### Example 1: Log Peak Fertility Signs

```dart
// User observes egg white consistency and wet sensation
await writeCervicalMucusData(
  sensation: CervicalMucusSensation.heavy,   // Wet
  appearance: CervicalMucusAppearance.eggWhite,
  dateTime: DateTime.now(),
);
```

#### Example 2: Log Dry Day

```dart
// User observes no mucus
await writeCervicalMucusData(
  sensation: CervicalMucusSensation.light,   // Dry
  appearance: CervicalMucusAppearance.unknown,
  dateTime: DateTime.now(),
);
```

#### Example 3: Log Creamy Texture

```dart
// User observes creamy mucus with moist sensation
await writeCervicalMucusData(
  sensation: CervicalMucusSensation.medium,  // Moist
  appearance: CervicalMucusAppearance.creamy,
  dateTime: DateTime.now(),
);
```

### Mapping Reference

#### Sensation Interpretation

| Value | Sensation      | Fertility | Description                                        |
| ----- | -------------- | --------- | -------------------------------------------------- |
| 1     | Light (Dry)    | Low       | No mucus present, dry sensation                    |
| 2     | Medium (Moist) | Higher    | Some mucus, moist feeling, begins fertility window |
| 3     | Heavy (Wet)    | Peak      | Abundant mucus, wet/slippery, peak fertility       |
| 0     | Unknown        | -         | No observation recorded                            |

#### Appearance Interpretation

| Value | Type           | Fertility   | Description                     |
| ----- | -------------- | ----------- | ------------------------------- |
| 0     | Unknown (None) | Low         | No mucus observed               |
| 1     | Sticky         | Low-Medium  | Sticky, doesn't stretch         |
| 2     | Creamy         | Medium      | Creamy texture, some stretch    |
| 3     | Egg White      | Peak        | Stretchy, clear like egg white  |
| 4     | Watery         | Medium-High | Thin, watery consistency        |
| 5     | Unusual        | Consult     | Atypical discharge, seek advice |

### Data Model (Optional)

```dart
class CervicalMucusReading {
  final DateTime dateTime;
  final CervicalMucusSensation sensation;
  final CervicalMucusAppearance appearance;
  final int recordingMethod; // 0=unknown, 1=manual, 2=auto, 3=active

  CervicalMucusReading({
    required this.dateTime,
    required this.sensation,
    required this.appearance,
    this.recordingMethod = 1,
  });

  Future<bool> save() => writeCervicalMucusData(
    sensation: sensation,
    appearance: appearance,
    dateTime: dateTime,
    recordingMethod: recordingMethod,
  );
}
```

### Error Handling Best Practices

```dart
Future<void> saveCervicalMucusWithErrorHandling({
  required CervicalMucusSensation sensation,
  required CervicalMucusAppearance appearance,
  required DateTime dateTime,
}) async {
  try {
    final success = await writeCervicalMucusData(
      sensation: sensation,
      appearance: appearance,
      dateTime: dateTime,
    );

    if (success) {
      // Show success message
      print('Data saved successfully');
    } else {
      // Show error - health data couldn't be written
      print('Failed to save cervical mucus data');
    }
  } on PlatformException catch (e) {
    // Handle platform-specific errors
    print('Platform error: ${e.message}');
  } catch (e) {
    // Handle unexpected errors
    print('Unexpected error: $e');
  }
}
```

### Notes

- **Sensation and Appearance are independent**: You can record one without the other
- **Default to Unknown**: If not provided, values default to `UNKNOWN`
- **Null Safety**: The method uses nullable parameters with safe defaults
- **Recording Method**:
  - 1 = Manual entry (default for user input)
  - 2 = Automatically recorded (from app algorithms)
  - 3 = Actively recorded (from wearable device)
- **Timestamps**: All times should be in milliseconds since epoch
- **Data Persistence**: Data is written to Google Health Connect on Android

### Compatibility

- **Minimum SDK**: Android API 29+
- **Health Connect Integration**: Requires Health Connect app to be installed
- **Permissions**: Requires health data write permissions for `CERVICAL_MUCUS_QUALITY`

### Future Enhancements

The implementation supports:

- ✅ All current sensation types
- ✅ All current appearance types
- ✅ `APPEARANCE_WATERY` (when UI adds support)
- ✅ `APPEARANCE_UNUSUAL` (for abnormal discharge tracking)
- ✅ Device information tracking
- ✅ Client record ID for sync/updates
