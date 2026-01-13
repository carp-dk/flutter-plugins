part of 'movesense_flutter.dart';

/// Information about used device and the platform which is running on it.
/// Contains knowledge about the hardware version, serial number, app name or
/// modules state.
///
/// See https://www.movesense.com/docs/esw/api_reference/#info
class MovesenseDeviceInfo {
  final String manufacturerName;
  final String? brandName;
  final String productName;
  final String variant;
  final String design;
  final String hwCompatibilityId;
  final String serial;
  final String pcbaSerial;
  final String sw;
  final String hw;
  final String? additionalVersionInfo;
  final List<MovesenseAddressInfo> addressInfo;
  final String apiLevel;

  const MovesenseDeviceInfo(
    this.manufacturerName,
    this.brandName,
    this.productName,
    this.variant,
    this.design,
    this.hwCompatibilityId,
    this.serial,
    this.pcbaSerial,
    this.sw,
    this.hw,
    this.additionalVersionInfo,
    this.addressInfo,
    this.apiLevel,
  );

  /// Build from the raw JSON string returned by the device.
  factory MovesenseDeviceInfo.fromMovesenseData(String data) {
    final dynamic decoded = json.decode(data);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Device info must be a JSON object');
    }
    final dynamic content = decoded['Content'];
    if (content is! Map<String, dynamic>) {
      throw const FormatException('Device info JSON missing Content object');
    }
    return MovesenseDeviceInfo.fromMap(content);
  }

  /// Build from a JSON map.
  factory MovesenseDeviceInfo.fromMap(Map<String, dynamic> map) {
    final dynamic addresses = map['addressInfo'];
    if (addresses is! List) {
      throw const FormatException('Device info missing addressInfo list');
    }

    return MovesenseDeviceInfo(
      map['manufacturerName'] as String? ?? '',
      map['brandName'] as String?,
      map['productName'] as String? ?? '',
      map['variant'] as String? ?? '',
      map['design'] as String? ?? '',
      map['hwCompatibilityId'] as String? ?? '',
      map['serial'] as String? ?? '',
      map['pcbaSerial'] as String? ?? '',
      map['sw'] as String? ?? '',
      map['hw'] as String? ?? '',
      map['additionalVersionInfo'] as String?,
      addresses
          .map(
            (entry) => MovesenseAddressInfo.fromMap(
              entry is Map<String, dynamic> ? entry : <String, dynamic>{},
            ),
          )
          .toList(growable: false),
      map['apiLevel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'manufacturerName': manufacturerName,
    'brandName': brandName,
    'productName': productName,
    'variant': variant,
    'design': design,
    'hwCompatibilityId': hwCompatibilityId,
    'serial': serial,
    'pcbaSerial': pcbaSerial,
    'sw': sw,
    'hw': hw,
    'additionalVersionInfo': additionalVersionInfo,
    'addressInfo': addressInfo.map((a) => a.toMap()).toList(growable: false),
    'apiLevel': apiLevel,
  };

  /// Serialize to JSON string with the original Content wrapper.
  String toJsonString() => json.encode(<String, dynamic>{'Content': toMap()});
}

/// Address info entry in the Movesense device info.
class MovesenseAddressInfo {
  final String name;
  final String address;

  const MovesenseAddressInfo(this.name, this.address);

  factory MovesenseAddressInfo.fromMap(Map<String, dynamic> map) {
    return MovesenseAddressInfo(
      map['name'] as String? ?? '',
      map['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'address': address,
  };
}

/// Base class for Movesense data samples.
abstract class MovesenseData {
  /// The device's internal timestamp of this data sample.
  /// According to the Movesense documentation, this is in microseconds
  /// since  00:00 1st Jan 1970 UTC.
  /// See https://www.movesense.com/docs/esw/api_reference/#time
  int timestamp;
  MovesenseData(this.timestamp);
}

/// Different states of the Movensense device.
///
/// See https://www.movesense.com/docs/esw/api_reference/#systemstates for an
/// overview.
enum MovesenseDeviceState {
  /// Unknown state.
  unknown,

  /// Device is moving.
  moving,

  /// Device is not moving.
  notMoving,

  /// Device connected to gear (e.g., strap).
  connected,

  /// Device disconnected to gear.
  disconnected,

  /// Device tapped once.
  tap,

  /// Device double tapped.
  doubleTap,

  /// Device is under acceleration.
  acceleration,

  /// Device is in free fall (no gravity).
  freeFall,
}

/// State of a Movesense system component.
class MovesenseState extends MovesenseData {
  /// The state of the component.
  final MovesenseDeviceState state;

  MovesenseState(super.timestamp, this.state);

  /// Get state object from the data returned directly from the device.
  ///
  /// Handles both GET and SUBSCRIBE data formats.
  ///
  /// GET response is in a String format `{"Content": <state_value>}`.
  /// SUBSCRIBE response is in a JSON map format `Body: {Timestamp: 32591214, StateId: 0, NewState: 1}`.
  ///
  /// Note that we do not get the timestamp in the GET response, so we set it to
  /// the current time (in microseconds) on the phone. But note, that this may
  /// be quite different from the device's internal timestamp.
  ///
  /// See https://www.movesense.com/docs/esw/api_reference/#systemstates for details.
  /// Note, however, that the json listed on the official Movesense API is wrong!
  factory MovesenseState.fromMovesenseData(
    SystemStateComponent component,
    dynamic data,
  ) {
    MovesenseDeviceState state = MovesenseDeviceState.unknown;
    num newState = 0;
    num timestamp = DateTime.now().microsecondsSinceEpoch;

    if (data is String) {
      data = json.decode(data);
      newState = data["Content"] as num;
    } else if (data is Map<String, dynamic>) {
      timestamp = data["Body"]["Timestamp"] as num;
      newState = data["Body"]["NewState"] as num;
    }

    switch (component) {
      case SystemStateComponent.movement: // movement
        state = (newState == 0)
            ? MovesenseDeviceState.notMoving
            : MovesenseDeviceState.moving;
        break;
      case SystemStateComponent.connectors: // connectors
        state = (newState == 0)
            ? MovesenseDeviceState.disconnected
            : MovesenseDeviceState.connected;
        break;
      case SystemStateComponent.doubleTap: // double-tap
        if (newState == 1) {
          state = MovesenseDeviceState.doubleTap;
        }
        break;
      case SystemStateComponent.tap: // tap
        if (newState == 1) {
          state = MovesenseDeviceState.tap;
        }
        break;
      case SystemStateComponent.freeFall: // free-fall
        state = (newState == 0)
            ? MovesenseDeviceState.acceleration
            : MovesenseDeviceState.freeFall;
        break;

      default:
    }

    return MovesenseState(timestamp.toInt(), state);
  }

  @override
  String toString() => state.name;
}

/// Electrocardiogram (ECG) reading.
///
/// See https://www.movesense.com/docs/esw/api_reference/#measecg
class MovesenseECG extends MovesenseData {
  /// The ECG samples.
  final List<int> samples;

  MovesenseECG(super.timestamp, this.samples);

  factory MovesenseECG.fromMovesenseData(dynamic data) {
    List<int> samples = (data["Body"]["Samples"] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    num timestamp = data["Body"]["Timestamp"] as num;
    return MovesenseECG(timestamp.toInt(), samples);
  }
}

/// The device's internal temperature. Returned values are in units
/// of Kelvins.
///
/// See https://www.movesense.com/docs/esw/api_reference/#meastemperature
class MovesenseTemperature extends MovesenseData {
  /// The device's internal temperature in units of Kelvins (K).
  final int measurement;

  MovesenseTemperature(super.timestamp, this.measurement);

  factory MovesenseTemperature.fromMovesenseData(dynamic data) {
    num timestamp = data["Body"]["Timestamp"] as num;
    num measurement = data["Body"]["Measurement"] as num;

    return MovesenseTemperature(timestamp.toInt(), measurement.toInt());
  }
}

/// Provides a synchronized access to combined accelerometer, gyroscope and
/// magnetometer data samples for easier processing e.g. for AHRS algorithms.
///
/// See https://www.movesense.com/docs/esw/api_reference/#measimu
class MovesenseIMU extends MovesenseData {
  final List<MovesenseAccelerometerSample> accelerometer;
  final List<MovesenseGyroscopeSample> gyroscope;
  final List<MovesenseMagnetometerSample> magnetometer;

  MovesenseIMU(
    super.timestamp,
    this.accelerometer,
    this.gyroscope,
    this.magnetometer,
  );

  factory MovesenseIMU.fromMovesenseData(dynamic data) {
    num timestamp = data["Body"]["Timestamp"] as num;

    List<MovesenseAccelerometerSample> acc =
        (data["Body"]["ArrayAcc"] as List<dynamic>)
            .map(
              (sample) => MovesenseAccelerometerSample(
                sample['x'] as num,
                sample['y'] as num,
                sample['z'] as num,
              ),
            )
            .toList();

    List<MovesenseGyroscopeSample> gyro =
        (data["Body"]["ArrayAcc"] as List<dynamic>)
            .map(
              (sample) => MovesenseGyroscopeSample(
                sample['x'] as num,
                sample['y'] as num,
                sample['z'] as num,
              ),
            )
            .toList();

    List<MovesenseMagnetometerSample> mag =
        (data["Body"]["ArrayAcc"] as List<dynamic>)
            .map(
              (sample) => MovesenseMagnetometerSample(
                sample['x'] as num,
                sample['y'] as num,
                sample['z'] as num,
              ),
            )
            .toList();

    return MovesenseIMU(timestamp.toInt(), acc, gyro, mag);
  }
}

/// Movesense accelerometer sample.
/// X,Y,Z value in milli-G (including gravity).
class MovesenseAccelerometerSample {
  final num x, y, z;
  MovesenseAccelerometerSample(this.x, this.y, this.z);
}

/// Movesense gyroscope sample.
/// X, Y, Z axis value in deg/sec.
class MovesenseGyroscopeSample {
  final num x, y, z;
  MovesenseGyroscopeSample(this.x, this.y, this.z);
}

/// Movesense magnetometer sample.
/// X, Y, Z axis value in Gauss.
class MovesenseMagnetometerSample {
  final num x, y, z;
  MovesenseMagnetometerSample(this.x, this.y, this.z);
}
