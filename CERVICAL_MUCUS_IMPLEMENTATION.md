# Cervical Mucus Mapping Implementation - Android

## Overview

Implemented complete cervical mucus data handling for Android Health Connect, with proper mapping of both **sensation** (texture) and **appearance** characteristics.

## Changes Made

### 1. New Method: `writeCervicalMucusData()`

**Location:** `HealthDataWriter.kt` (lines 329-382)

A dedicated public method that handles cervical mucus data with both sensation and appearance fields, following the same pattern as `writeBloodPressure()`.

```kotlin
fun writeCervicalMucusData(call: MethodCall, result: Result)
```

**Parameters from Flutter:**

- `sensation: Double` - Sensation value (1=Light/Dry, 2=Medium/Moist, 3=Heavy/Wet, 0=Unknown)
- `appearance: Double` - Appearance value (see mapping below)
- `startTime: Long` - Timestamp in milliseconds
- `recordingMethod: Int` - How data was recorded (0=unknown, 1=manual, 2=auto, 3=active)
- `clientRecordId: String?` - Optional custom record ID
- `clientRecordVersion: Double?` - Optional version for updates
- `deviceType: Int?` - Optional device type information

### 2. New Extension Function: `toCervicalMucusSensation()`

**Location:** `HealthDataWriter.kt` (lines 956-975)

Converts numeric sensation values to Google Health Connect sensation constants.

```kotlin
private fun Double.toCervicalMucusSensation(): Int
```

**Mapping:**
| User Input | Value | Google Constant |
|-----------|-------|-----------------|
| Dry | 1 | `SENSATION_LIGHT` |
| Moist | 2 | `SENSATION_MEDIUM` |
| Wet | 3 | `SENSATION_HEAVY` |
| No value / Invalid | 0 | `SENSATION_UNKNOWN` |

### 3. Updated Extension Function: `toCervicalMucusAppearance()`

**Location:** `HealthDataWriter.kt` (lines 977-999)

Enhanced with comprehensive documentation and validation for all supported appearance types.

```kotlin
private fun Double.toCervicalMucusAppearance(): Int
```

**Mapping:**
| User Input | Value | Google Constant |
|-----------|-------|-----------------|
| None | 0 | `APPEARANCE_UNKNOWN` |
| Sticky | 1 | `APPEARANCE_STICKY` |
| Creamy | 2 | `APPEARANCE_CREAMY` |
| Egg white | 3 | `APPEARANCE_EGG_WHITE` |
| Watery | 4 | `APPEARANCE_WATERY` |
| Unusual | 5 | `APPEARANCE_UNUSUAL` |
| Invalid | - | `APPEARANCE_UNKNOWN` |

### 4. Updated `createRecord()` Method

**Location:** `HealthDataWriter.kt` (lines 852-859)

Changed the generic `CERVICAL_MUCUS_QUALITY` record creation from:

```kotlin
sensation = CervicalMucusRecord.SENSATION_UNKNOWN  // Hardcoded
```

To:

```kotlin
sensation = value.toCervicalMucusSensation()  // Dynamic mapping
```

This allows the generic `writeData()` method to also handle sensation properly.

## Usage Patterns

### Pattern 1: Dedicated Method (Recommended)

For full control with both sensation and appearance:

```kotlin
// From Flutter side
channel.invokeMethod('writeCervicalMucusData', {
  'sensation': 2.0,  // Moist
  'appearance': 1.0,  // Sticky
  'startTime': 1702000000000,
  'recordingMethod': 1,  // Manual entry
});
```

### Pattern 2: Generic writeData() Method

For compatibility, still works through existing `writeData()` method with single value.

## Error Handling

Both methods include:

- **Try-catch blocks** for exception handling
- **Null safety** with Elvis operators (`?:`) defaulting to UNKNOWN values
- **Logging** for success and error cases
- **Boolean result** returned to Flutter indicating success/failure

## Validation

- **Out-of-range values**: Automatically default to `SENSATION_UNKNOWN` or `APPEARANCE_UNKNOWN`
- **Null values**: Handled gracefully with nullable parameters and defaults
- **Invalid sensation values**: Checked against `SENSATION_LIGHT`, `SENSATION_MEDIUM`, `SENSATION_HEAVY`, `SENSATION_UNKNOWN`
- **Invalid appearance values**: Checked against all supported `APPEARANCE_*` constants

## Integration with Existing Code

The implementation integrates seamlessly with:

- **Metadata building**: Uses existing `buildMetadata()` for recording method, device type, and client record tracking
- **Health Connect API**: Direct use of `healthConnectClient.insertRecords()`
- **Error handling pattern**: Consistent with other specialized writers like `writeBloodPressure()` and `writeMeal()`
- **Data reading**: Already supported in `HealthDataConverter.kt` (line 197-198)

## Future-Proofing

The implementation is ready for future enhancements:

- `APPEARANCE_WATERY` support is included in validation
- `APPEARANCE_UNUSUAL` support is included for atypical discharge tracking
- Extension functions can be easily extended for new sensation/appearance values
- Separate sensation and appearance parameters allow for independent updates

## Commit Information

- **Commit Hash:** `59cd6713`
- **Branch:** `add-basal-temperature`
- **Files Modified:** `packages/health/android/src/main/kotlin/cachet/plugins/health/HealthDataWriter.kt`
- **Changes:** 118 insertions, 2 deletions
