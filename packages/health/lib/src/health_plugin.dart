part of '../health.dart';

/// Main class for the Plugin. This class works as a singleton and should be accessed
/// via `Health()` factory method. The plugin must be configured using the [configure] method
/// before used.
///
/// Overall, the plugin supports:
///
///  * Handling permissions to access health data using the [hasPermissions],
///    [requestAuthorization], [revokePermissions] methods.
///  * Reading health data using the [getHealthDataFromTypes] method.
///  * Writing health data using the [writeHealthData] method.
///  * Cleaning up duplicate data points via the [removeDuplicates] method.
///
/// In addition, the plugin has a set of specialized methods for reading and writing
/// different types of health data:
///
///  * Reading aggregate health data using the [getHealthIntervalDataFromTypes]
///    and [getHealthAggregateDataFromTypes] methods.
///  * Reading total step counts using the [getTotalStepsInInterval] method.
///  * Writing different types of specialized health data like the [writeWorkoutData],
///    [writeBloodPressure], [writeBloodOxygen], [writeAudiogram], and [writeMeal]
///    methods.
class Health {
  static const MethodChannel _channel = MethodChannel('flutter_health');
  static final _instance = Health._();

  String? _deviceId;
  final _deviceInfo = DeviceInfoPlugin();
  bool _useHealthConnectIfAvailable = false;

  Health._() {
    _registerFromJsonFunctions();
  }

  /// Get the singleton [Health] instance.
  factory Health() => _instance;

  /// The type of platform of this device.
  HealthPlatformType get platformType => Platform.isIOS
      ? HealthPlatformType.appleHealth
      : useHealthConnectIfAvailable
          ? HealthPlatformType.googleHealthConnect
          : HealthPlatformType.googleFit;

  /// The id of this device.
  ///
  /// On Android this is the [ID](https://developer.android.com/reference/android/os/Build#ID) of the BUILD.
  /// On iOS this is the [identifierForVendor](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor) of the UIDevice.
  String get deviceId => _deviceId ?? 'unknown';

  /// Configure the health plugin. Must be called before using the plugin.
  ///
  /// If [useHealthConnectIfAvailable] is true, Google Health Connect on
  /// Android will be used. Has no effect on iOS.
  Future<void> configure({bool useHealthConnectIfAvailable = false}) async {
    _deviceId ??= Platform.isAndroid
        ? (await _deviceInfo.androidInfo).id
        : (await _deviceInfo.iosInfo).identifierForVendor;

    _useHealthConnectIfAvailable = useHealthConnectIfAvailable;
    if (_useHealthConnectIfAvailable) {
      await _channel.invokeMethod('useHealthConnectIfAvailable');
    }
  }

  /// Is this plugin using Health Connect (true) or Google Fit (false)?
  ///
  /// This is set in the [configure] method.
  bool get useHealthConnectIfAvailable => _useHealthConnectIfAvailable;

  /// Check if a given data type is available on the platform
  bool isDataTypeAvailable(HealthDataType dataType) => Platform.isAndroid
      ? dataTypeKeysAndroid.contains(dataType)
      : dataTypeKeysIOS.contains(dataType);

  /// Determines if the health data [types] have been granted with the specified
  /// access rights [permissions].
  ///
  /// Returns:
  ///
  ///  * true - if all of the data types have been granted with the specified access rights.
  ///  * false - if any of the data types has not been granted with the specified access right(s).
  ///  * null - if it can not be determined if the data types have been granted with the specified access right(s).
  ///
  /// Parameters:
  ///
  ///  * [types]  - List of [HealthDataType] whose permissions are to be checked.
  ///  * [permissions] - Optional.
  ///    + If unspecified, this method checks if each HealthDataType in [types] has been granted READ access.
  ///    + If specified, this method checks if each [HealthDataType] in [types] has been granted with the access specified in its
  ///   corresponding entry in this list. The length of this list must be equal to that of [types].
  ///
  /// Caveat:
  ///
  ///  * As Apple HealthKit will not disclose if READ access has been granted for a data type due to privacy concern,
  ///   this method can only return null to represent an undetermined status, if it is called on iOS
  ///   with a READ or READ_WRITE access.
  ///
  ///  * On Android, this function returns true or false, depending on whether the specified access right has been granted.
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (permissions != null && permissions.length != types.length) {
      throw ArgumentError(
          "The lists of types and permissions must be of same length.");
    }

    final mTypes = List<HealthDataType>.from(types, growable: true);
    final mPermissions = permissions == null
        ? List<int>.filled(types.length, HealthDataAccess.READ.index,
            growable: true)
        : permissions.map((permission) => permission.index).toList();

    /// On Android, if BMI is requested, then also ask for weight and height
    if (Platform.isAndroid) _handleBMI(mTypes, mPermissions);

    return await _channel.invokeMethod('hasPermissions', {
      "types": mTypes.map((type) => type.name).toList(),
      "permissions": mPermissions,
    });
  }

  /// Revokes permissions of all types.
  ///
  /// Uses `disableFit()` on Google Fit.
  ///
  /// Not implemented on iOS as there is no way to programmatically remove access.
  Future<void> revokePermissions() async {
    try {
      if (Platform.isIOS) {
        throw UnsupportedError(
            'Revoke permissions is not supported on iOS. Please revoke permissions manually in the settings.');
      }
      await _channel.invokeMethod('revokePermissions');
      return;
    } catch (e) {
      debugPrint('$runtimeType - Exception in revokePermissions(): $e');
    }
  }

  /// Returns the current status of Health Connect availability.
  ///
  /// See this for more info:
  /// https://developer.android.com/reference/kotlin/androidx/health/connect/client/HealthConnectClient#getSdkStatus(android.content.Context,kotlin.String)
  ///
  /// Android only.
  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async {
    try {
      if (Platform.isIOS) {
        throw UnsupportedError('Health Connect is not available on iOS.');
      }
      final int status =
          (await _channel.invokeMethod('getHealthConnectSdkStatus'))!;
      return HealthConnectSdkStatus.fromNativeValue(status);
    } catch (e) {
      debugPrint('$runtimeType - Exception in getHealthConnectSdkStatus(): $e');
      return null;
    }
  }

  /// Prompt the user to install the Health Connect app via the installed store
  /// (most likely Play Store).
  ///
  /// Android only.
  Future<void> installHealthConnect() async {
    try {
      if (!Platform.isAndroid) {
        throw UnsupportedError(
            'installHealthConnect is only available on Android');
      }
      await _channel.invokeMethod('installHealthConnect');
    } catch (e) {
      debugPrint('$runtimeType - Exception in installHealthConnect(): $e');
    }
  }

  /// Disconnect from Google fit.
  ///
  /// Not supported on iOS and Google Health Connect, and the method does nothing.
  Future<bool?> disconnect(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (permissions != null && permissions.length != types.length) {
      throw ArgumentError(
          'The length of [types] must be same as that of [permissions].');
    }

    final mTypes = List<HealthDataType>.from(types, growable: true);
    final mPermissions = permissions == null
        ? List<int>.filled(types.length, HealthDataAccess.READ.index,
            growable: true)
        : permissions.map((permission) => permission.index).toList();

    // on Android, if BMI is requested, then also ask for weight and height
    if (Platform.isAndroid) _handleBMI(mTypes, mPermissions);

    List<String> keys = mTypes.map((dataType) => dataType.name).toList();

    return await _channel.invokeMethod(
        'disconnect', {'types': keys, "permissions": mPermissions});
  }

  /// Requests permissions to access health data [types].
  ///
  /// Returns true if successful, false otherwise.
  ///
  /// Parameters:
  ///
  /// * [types] - a list of [HealthDataType] which the permissions are requested for.
  /// * [permissions] - Optional.
  ///   + If unspecified, each [HealthDataType] in [types] is requested for READ [HealthDataAccess].
  ///   + If specified, each [HealthDataAccess] in this list is requested for its corresponding indexed
  ///   entry in [types]. In addition, the length of this list must be equal to that of [types].
  ///
  ///  Caveats:
  ///
  ///  * This method may block if permissions are already granted. Hence, check
  ///    [hasPermissions] before calling this method.
  ///  * As Apple HealthKit will not disclose if READ access has been granted for
  ///    a data type due to privacy concern, this method will return **true if
  ///    the window asking for permission was showed to the user without errors**
  ///    if it is called on iOS with a READ or READ_WRITE access.
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (permissions != null && permissions.length != types.length) {
      throw ArgumentError(
          'The length of [types] must be same as that of [permissions].');
    }

    if (permissions != null) {
      for (int i = 0; i < types.length; i++) {
        final type = types[i];
        final permission = permissions[i];
        if ((type == HealthDataType.ELECTROCARDIOGRAM ||
                type == HealthDataType.HIGH_HEART_RATE_EVENT ||
                type == HealthDataType.LOW_HEART_RATE_EVENT ||
                type == HealthDataType.IRREGULAR_HEART_RATE_EVENT ||
                type == HealthDataType.WALKING_HEART_RATE) &&
            permission != HealthDataAccess.READ) {
          throw ArgumentError(
              'Requesting WRITE permission on ELECTROCARDIOGRAM / HIGH_HEART_RATE_EVENT / LOW_HEART_RATE_EVENT / IRREGULAR_HEART_RATE_EVENT / WALKING_HEART_RATE is not allowed.');
        }
      }
    }

    final mTypes = List<HealthDataType>.from(types, growable: true);
    final mPermissions = permissions == null
        ? List<int>.filled(types.length, HealthDataAccess.READ.index,
            growable: true)
        : permissions.map((permission) => permission.index).toList();

    // on Android, if BMI is requested, then also ask for weight and height
    if (Platform.isAndroid) _handleBMI(mTypes, mPermissions);

    List<String> keys = mTypes.map((e) => e.name).toList();
    final bool? isAuthorized = await _channel.invokeMethod(
        'requestAuthorization', {'types': keys, "permissions": mPermissions});
    return isAuthorized ?? false;
  }

  /// Obtains health and weight if BMI is requested on Android.
  void _handleBMI(List<HealthDataType> mTypes, List<int> mPermissions) {
    final index = mTypes.indexOf(HealthDataType.BODY_MASS_INDEX);

    if (index != -1 && Platform.isAndroid) {
      if (!mTypes.contains(HealthDataType.WEIGHT)) {
        mTypes.add(HealthDataType.WEIGHT);
        mPermissions.add(mPermissions[index]);
      }
      if (!mTypes.contains(HealthDataType.HEIGHT)) {
        mTypes.add(HealthDataType.HEIGHT);
        mPermissions.add(mPermissions[index]);
      }
      mTypes.remove(HealthDataType.BODY_MASS_INDEX);
      mPermissions.removeAt(index);
    }
  }

  /// Calculate the BMI using the last observed height and weight values.
  Future<List<HealthDataPoint>> _computeAndroidBMI(
    DateTime startTime,
    DateTime endTime,
    bool includeManualEntry,
  ) async {
    List<HealthDataPoint> heights = await _prepareQuery(
        startTime, endTime, HealthDataType.HEIGHT, includeManualEntry);

    if (heights.isEmpty) {
      return [];
    }

    List<HealthDataPoint> weights = await _prepareQuery(
        startTime, endTime, HealthDataType.WEIGHT, includeManualEntry);

    double h =
        (heights.last.value as NumericHealthValue).numericValue.toDouble();

    const dataType = HealthDataType.BODY_MASS_INDEX;
    final unit = dataTypeToUnit[dataType]!;

    final bmiHealthPoints = <HealthDataPoint>[];
    for (var i = 0; i < weights.length; i++) {
      final bmiValue =
          (weights[i].value as NumericHealthValue).numericValue.toDouble() /
              (h * h);
      final x = HealthDataPoint(
        value: NumericHealthValue(numericValue: bmiValue),
        type: dataType,
        unit: unit,
        dateFrom: weights[i].dateFrom,
        dateTo: weights[i].dateTo,
        sourcePlatform: platformType,
        sourceDeviceId: _deviceId!,
        sourceId: '',
        sourceName: '',
        isManualEntry: !includeManualEntry,
      );

      bmiHealthPoints.add(x);
    }
    return bmiHealthPoints;
  }

  /// Write health data.
  ///
  /// Returns true if successful, false otherwise.
  ///
  /// Parameters:
  ///  * [value] - the health data's value in double
  ///  * [unit] - **iOS ONLY** the unit the health data is measured in.
  ///  * [type] - the value's HealthDataType
  ///  * [startTime] - the start time when this [value] is measured.
  ///    It must be equal to or earlier than [endTime].
  ///  * [endTime] - the end time when this [value] is measured.
  ///    It must be equal to or later than [startTime].
  ///    Simply set [endTime] equal to [startTime] if the [value] is measured
  ///    only at a specific point in time (default).
  ///
  /// Values for Sleep and Headache are ignored and will be automatically assigned
  /// the default value.
  Future<bool> writeHealthData({
    required double value,
    HealthDataUnit? unit,
    required HealthDataType type,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    if (type == HealthDataType.WORKOUT) {
      throw ArgumentError(
          "Adding workouts should be done using the writeWorkoutData method.");
    }
    endTime ??= startTime;
    if (startTime.isAfter(endTime)) {
      throw ArgumentError("startTime must be equal or earlier than endTime");
    }
    if ({
          HealthDataType.HIGH_HEART_RATE_EVENT,
          HealthDataType.LOW_HEART_RATE_EVENT,
          HealthDataType.IRREGULAR_HEART_RATE_EVENT,
          HealthDataType.ELECTROCARDIOGRAM,
        }.contains(type) &&
        Platform.isIOS) {
      throw ArgumentError(
          "$type - iOS does not support writing this data type in HealthKit");
    }

    // Assign default unit if not specified
    unit ??= dataTypeToUnit[type]!;

    // Align values to type in cases where the type defines the value.
    // E.g. SLEEP_IN_BED should have value 0
    if (type == HealthDataType.SLEEP_ASLEEP ||
        type == HealthDataType.SLEEP_AWAKE ||
        type == HealthDataType.SLEEP_IN_BED ||
        type == HealthDataType.SLEEP_DEEP ||
        type == HealthDataType.SLEEP_REM ||
        type == HealthDataType.SLEEP_ASLEEP_CORE ||
        type == HealthDataType.SLEEP_ASLEEP_DEEP ||
        type == HealthDataType.SLEEP_ASLEEP_REM ||
        type == HealthDataType.HEADACHE_NOT_PRESENT ||
        type == HealthDataType.HEADACHE_MILD ||
        type == HealthDataType.HEADACHE_MODERATE ||
        type == HealthDataType.HEADACHE_SEVERE ||
        type == HealthDataType.HEADACHE_UNSPECIFIED) {
      value = _alignValue(type).toDouble();
    }

    Map<String, dynamic> args = {
      'value': value,
      'dataTypeKey': type.name,
      'dataUnitKey': unit.name,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch
    };
    bool? success = await _channel.invokeMethod('writeData', args);
    return success ?? false;
  }

  /// Deletes all records of the given [type] for a given period of time.
  ///
  /// Returns true if successful, false otherwise.
  ///
  /// Parameters:
  ///  * [type] - the value's HealthDataType.
  ///  * [startTime] - the start time when this [value] is measured.
  ///    Must be equal to or earlier than [endTime].
  ///  * [endTime] - the end time when this [value] is measured.
  ///    Must be equal to or later than [startTime].
  Future<bool> delete({
    required HealthDataType type,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    endTime ??= startTime;
    if (startTime.isAfter(endTime)) {
      throw ArgumentError("startTime must be equal or earlier than endTime");
    }

    Map<String, dynamic> args = {
      'dataTypeKey': type.name,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch
    };
    bool? success = await _channel.invokeMethod('delete', args);
    return success ?? false;
  }

  /// Saves a blood pressure record.
  ///
  /// Returns true if successful, false otherwise.
  ///
  /// Parameters:
  ///  * [systolic] - the systolic part of the blood pressure.
  ///  * [diastolic] - the diastolic part of the blood pressure.
  ///  * [startTime] - the start time when this [value] is measured.
  ///    Must be equal to or earlier than [endTime].
  ///  * [endTime] - the end time when this [value] is measured.
  ///    Must be equal to or later than [startTime].
  ///    Simply set [endTime] equal to [startTime] if the blood pressure is measured
  ///    only at a specific point in time. If omitted, [endTime] is set to [startTime].
  Future<bool> writeBloodPressure({
    required int systolic,
    required int diastolic,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    endTime ??= startTime;
    if (startTime.isAfter(endTime)) {
      throw ArgumentError("startTime must be equal or earlier than endTime");
    }

    Map<String, dynamic> args = {
      'systolic': systolic,
      'diastolic': diastolic,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch
    };
    return await _channel.invokeMethod('writeBloodPressure', args) == true;
  }

  /// Saves blood oxygen saturation record.
  ///
  /// Returns true if successful, false otherwise.
  ///
  /// Parameters:
  ///  * [saturation] - the saturation of the blood oxygen in percentage
  ///  * [flowRate] - optional supplemental oxygen flow rate, only supported on
  ///    Google Fit (default 0.0)
  ///  * [startTime] - the start time when this [saturation] is measured.
  ///    Must be equal to or earlier than [endTime].
  ///  * [endTime] - the end time when this [saturation] is measured.
  ///    Must be equal to or later than [startTime].
  ///    Simply set [endTime] equal to [startTime] if the blood oxygen saturation
  ///    is measured only at a specific point in time (default).
  Future<bool> writeBloodOxygen({
    required double saturation,
    double flowRate = 0.0,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    endTime ??= startTime;
    if (startTime.isAfter(endTime)) {
      throw ArgumentError("startTime must be equal or earlier than endTime");
    }
    bool? success;

    if (Platform.isIOS) {
      success = await writeHealthData(
          value: saturation,
          type: HealthDataType.BLOOD_OXYGEN,
          startTime: startTime,
          endTime: endTime);
    } else if (Platform.isAndroid) {
      Map<String, dynamic> args = {
        'value': saturation,
        'flowRate': flowRate,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'dataTypeKey': HealthDataType.BLOOD_OXYGEN.name,
      };
      success = await _channel.invokeMethod('writeBloodOxygen', args);
    }
    return success ?? false;
  }

  /// Saves meal record into Apple Health or Google Fit / Health Connect.
  ///
  /// Returns true if successful, false otherwise.
  ///
  /// Parameters:
  ///  * [mealType] - the type of meal.
  ///  * [startTime] - the start time when the meal was consumed.
  ///    It must be equal to or earlier than [endTime].
  ///  * [endTime] - the end time when the meal was consumed.
  ///    It must be equal to or later than [startTime].
  ///  * [caloriesConsumed] - total calories consumed with this meal.
  ///  * [carbohydrates] - optional carbohydrates information.
  ///  * [protein] - optional protein information.
  ///  * [fatTotal] - optional total fat information.
  ///  * [name] - optional name information about this meal.
  Future<bool> writeMeal({
    required MealType mealType,
    required DateTime startTime,
    required DateTime endTime,
    double? caloriesConsumed,
    double? carbohydrates,
    double? protein,
    double? fatTotal,
    String? name,
    double? caffeine,
  }) async {
    if (startTime.isAfter(endTime)) {
      throw ArgumentError("startTime must be equal or earlier than endTime");
    }

    Map<String, dynamic> args = {
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'caloriesConsumed': caloriesConsumed,
      'carbohydrates': carbohydrates,
      'protein': protein,
      'fatTotal': fatTotal,
      'name': name,
      'caffeine': caffeine,
      'mealType': mealType.name,
    };
    bool? success = await _channel.invokeMethod('writeMeal', args);
    return success ?? false;
  }

  /// Saves audiogram into Apple Health. Not supported on Android.
  ///
  /// Returns true if successful, false otherwise.
  ///
  /// Parameters:
  ///   * [frequencies] - array of frequencies of the test
  ///   * [leftEarSensitivities] threshold in decibel for the left ear
  ///   * [rightEarSensitivities] threshold in decibel for the left ear
  ///   * [startTime] - the start time when the audiogram is measured.
  ///     It must be equal to or earlier than [endTime].
  ///   * [endTime] - the end time when the audiogram is measured.
  ///     It must be equal to or later than [startTime].
  ///     Simply set [endTime] equal to [startTime] if the audiogram is measured
  ///     only at a specific point in time (default).
  ///   * [metadata] - optional map of keys, both HKMetadataKeyExternalUUID
  ///     and HKMetadataKeyDeviceName are required
  Future<bool> writeAudiogram({
    required List<double> frequencies,
    required List<double> leftEarSensitivities,
    required List<double> rightEarSensitivities,
    required DateTime startTime,
    DateTime? endTime,
    Map<String, dynamic>? metadata,
  }) async {
    if (frequencies.isEmpty ||
        leftEarSensitivities.isEmpty ||
        rightEarSensitivities.isEmpty) {
      throw ArgumentError(
          "frequencies, leftEarSensitivities and rightEarSensitivities can't be empty");
    }
    if (frequencies.length != leftEarSensitivities.length ||
        rightEarSensitivities.length != leftEarSensitivities.length) {
      throw ArgumentError(
          "frequencies, leftEarSensitivities and rightEarSensitivities need to be of the same length");
    }
    endTime ??= startTime;
    if (startTime.isAfter(endTime)) {
      throw ArgumentError("startTime must be equal or earlier than endTime");
    }
    if (Platform.isAndroid) {
      throw UnsupportedError("writeAudiogram is not supported on Android");
    }

    Map<String, dynamic> args = {
      'frequencies': frequencies,
      'leftEarSensitivities': leftEarSensitivities,
      'rightEarSensitivities': rightEarSensitivities,
      'dataTypeKey': HealthDataType.AUDIOGRAM.name,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'metadata': metadata,
    };
    return await _channel.invokeMethod('writeAudiogram', args) == true;
  }

  /// Fetch a list of health data points based on [types].
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
    bool includeManualEntry = true,
  }) async {
    List<HealthDataPoint> dataPoints = [];

    for (var type in types) {
      final result =
          await _prepareQuery(startTime, endTime, type, includeManualEntry);
      dataPoints.addAll(result);
    }

    const int threshold = 100;
    if (dataPoints.length > threshold) {
      return compute(removeDuplicates, dataPoints);
    }

    return removeDuplicates(dataPoints);
  }

  /// Fetch a list of health data points based on [types].
  Future<List<HealthDataPoint>> getHealthIntervalDataFromTypes(
      {required DateTime startDate,
      required DateTime endDate,
      required List<HealthDataType> types,
      required int interval,
      bool includeManualEntry = true}) async {
    List<HealthDataPoint> dataPoints = [];

    for (var type in types) {
      final result = await _prepareIntervalQuery(
          startDate, endDate, type, interval, includeManualEntry);
      dataPoints.addAll(result);
    }

    return removeDuplicates(dataPoints);
  }

  /// Fetch a list of health data points based on [types].
  Future<List<HealthDataPoint>> getHealthAggregateDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startDate,
    required DateTime endDate,
    int activitySegmentDuration = 1,
    bool includeManualEntry = true,
  }) async {
    List<HealthDataPoint> dataPoints = [];

    final result = await _prepareAggregateQuery(
        startDate, endDate, types, activitySegmentDuration, includeManualEntry);
    dataPoints.addAll(result);

    return removeDuplicates(dataPoints);
  }

  /// Prepares an interval query, i.e. checks if the types are available, etc.
  Future<List<HealthDataPoint>> _prepareQuery(
    DateTime startTime,
    DateTime endTime,
    HealthDataType dataType,
    bool includeManualEntry,
  ) async {
    // Ask for device ID only once
    _deviceId ??= Platform.isAndroid
        ? (await _deviceInfo.androidInfo).id
        : (await _deviceInfo.iosInfo).identifierForVendor;

    // If not implemented on platform, throw an exception
    if (!isDataTypeAvailable(dataType)) {
      throw HealthException(
          dataType, 'Not available on platform $platformType');
    }

    // If BodyMassIndex is requested on Android, calculate this manually
    if (dataType == HealthDataType.BODY_MASS_INDEX && Platform.isAndroid) {
      return _computeAndroidBMI(startTime, endTime, includeManualEntry);
    }
    return await _dataQuery(startTime, endTime, dataType, includeManualEntry);
  }

  /// Prepares an interval query, i.e. checks if the types are available, etc.
  Future<List<HealthDataPoint>> _prepareIntervalQuery(
      DateTime startDate,
      DateTime endDate,
      HealthDataType dataType,
      int interval,
      bool includeManualEntry) async {
    // Ask for device ID only once
    _deviceId ??= Platform.isAndroid
        ? (await _deviceInfo.androidInfo).id
        : (await _deviceInfo.iosInfo).identifierForVendor;

    // If not implemented on platform, throw an exception
    if (!isDataTypeAvailable(dataType)) {
      throw HealthException(
          dataType, 'Not available on platform $platformType');
    }

    return await _dataIntervalQuery(
        startDate, endDate, dataType, interval, includeManualEntry);
  }

  /// Prepares an aggregate query, i.e. checks if the types are available, etc.
  Future<List<HealthDataPoint>> _prepareAggregateQuery(
      DateTime startDate,
      DateTime endDate,
      List<HealthDataType> dataTypes,
      int activitySegmentDuration,
      bool includeManualEntry) async {
    // Ask for device ID only once
    _deviceId ??= Platform.isAndroid
        ? (await _deviceInfo.androidInfo).id
        : (await _deviceInfo.iosInfo).identifierForVendor;

    for (var type in dataTypes) {
      // If not implemented on platform, throw an exception
      if (!isDataTypeAvailable(type)) {
        throw HealthException(type, 'Not available on platform $platformType');
      }
    }

    return await _dataAggregateQuery(startDate, endDate, dataTypes,
        activitySegmentDuration, includeManualEntry);
  }

  /// Fetches data points from Android/iOS native code.
  Future<List<HealthDataPoint>> _dataQuery(DateTime startTime, DateTime endTime,
      HealthDataType dataType, bool includeManualEntry) async {
    final args = <String, dynamic>{
      'dataTypeKey': dataType.name,
      'dataUnitKey': dataTypeToUnit[dataType]!.name,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'includeManualEntry': includeManualEntry
    };
    final fetchedDataPoints = await _channel.invokeMethod('getData', args);

    if (fetchedDataPoints != null && fetchedDataPoints is List) {
      final msg = <String, dynamic>{
        "dataType": dataType,
        "dataPoints": fetchedDataPoints,
      };
      const thresHold = 100;
      // If the no. of data points are larger than the threshold,
      // call the compute method to spawn an Isolate to do the parsing in a separate thread.
      if (fetchedDataPoints.length > thresHold) {
        return compute(_parse, msg);
      }
      return _parse(msg);
    } else {
      return <HealthDataPoint>[];
    }
  }

  /// function for fetching statistic health data
  Future<List<HealthDataPoint>> _dataIntervalQuery(
      DateTime startDate,
      DateTime endDate,
      HealthDataType dataType,
      int interval,
      bool includeManualEntry) async {
    final args = <String, dynamic>{
      'dataTypeKey': dataType.name,
      'dataUnitKey': dataTypeToUnit[dataType]!.name,
      'startTime': startDate.millisecondsSinceEpoch,
      'endTime': endDate.millisecondsSinceEpoch,
      'interval': interval,
      'includeManualEntry': includeManualEntry
    };

    final fetchedDataPoints =
        await _channel.invokeMethod('getIntervalData', args);
    if (fetchedDataPoints != null) {
      final msg = <String, dynamic>{
        "dataType": dataType,
        "dataPoints": fetchedDataPoints,
      };
      return _parse(msg);
    }
    return <HealthDataPoint>[];
  }

  Future<bool?> doseStepSensorIsAvailable() async {
    final fetchedDataPoints =
        await _channel.invokeMethod<bool?>('doseStepSensorIsAvailable');

    return fetchedDataPoints;
  }

  Future<bool?> startStepSensorBackgroundService() async {
    final fetchedDataPoints =
        await _channel.invokeMethod<bool?>('startStepSensorBackgroundService');

    return fetchedDataPoints;
  }

  Future<bool?> stopStepSensorBackgroundService() async {
    final fetchedDataPoints =
        await _channel.invokeMethod<bool?>('stopStepSensorBackgroundService');

    return fetchedDataPoints;
  }

  Future<bool?> isStepSensorRunning() async {
    final fetchedDataPoints =
        await _channel.invokeMethod<bool?>('isStepSensorRunning');

    return fetchedDataPoints;
  }

  Future<bool?> clearStepSensorData() async {
    final clearStepSensorData =
        await _channel.invokeMethod<bool?>('clearStepSensorData');

    return clearStepSensorData;
  }

  /// function for fetching statistic health data
  Future<List<HealthDataPoint>> _dataAggregateQuery(
      DateTime startDate,
      DateTime endDate,
      List<HealthDataType> dataTypes,
      int activitySegmentDuration,
      bool includeManualEntry) async {
    final args = <String, dynamic>{
      'dataTypeKeys': dataTypes.map((dataType) => dataType.name).toList(),
      'startTime': startDate.millisecondsSinceEpoch,
      'endTime': endDate.millisecondsSinceEpoch,
      'activitySegmentDuration': activitySegmentDuration,
      'includeManualEntry': includeManualEntry
    };

    final fetchedDataPoints =
        await _channel.invokeMethod('getAggregateData', args);

    if (fetchedDataPoints != null) {
      final msg = <String, dynamic>{
        "dataType": HealthDataType.WORKOUT,
        "dataPoints": fetchedDataPoints,
      };
      return _parse(msg);
    }
    return <HealthDataPoint>[];
  }

  List<HealthDataPoint> _parse(Map<String, dynamic> message) {
    final dataType = message["dataType"] as HealthDataType;
    final dataPoints = message["dataPoints"] as List;

    return dataPoints
        .map<HealthDataPoint>((dataPoint) =>
            HealthDataPoint.fromHealthDataPoint(dataType, dataPoint))
        .toList();
  }

  /// Return a list of [HealthDataPoint] based on [points] with no duplicates.
  List<HealthDataPoint> removeDuplicates(List<HealthDataPoint> points) =>
      LinkedHashSet.of(points).toList();

  /// Get the total number of steps within a specific time period.
  /// Returns null if not successful.
  ///
  /// Is a fix according to https://stackoverflow.com/questions/29414386/step-count-retrieved-through-google-fit-api-does-not-match-step-count-displayed/29415091#29415091
  Future<int?> getTotalStepsInInterval(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final args = <String, dynamic>{
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch
    };
    final stepsCount = await _channel.invokeMethod<int?>(
      'getTotalStepsInInterval',
      args,
    );
    return stepsCount;
  }

  /// Assigns numbers to specific [HealthDataType]s.
  int _alignValue(HealthDataType type) => switch (type) {
        HealthDataType.SLEEP_IN_BED => 0,
        HealthDataType.SLEEP_AWAKE => 2,
        HealthDataType.SLEEP_ASLEEP => 3,
        HealthDataType.SLEEP_DEEP => 4,
        HealthDataType.SLEEP_REM => 5,
        HealthDataType.SLEEP_ASLEEP_CORE => 3,
        HealthDataType.SLEEP_ASLEEP_DEEP => 4,
        HealthDataType.SLEEP_ASLEEP_REM => 5,
        HealthDataType.HEADACHE_UNSPECIFIED => 0,
        HealthDataType.HEADACHE_NOT_PRESENT => 1,
        HealthDataType.HEADACHE_MILD => 2,
        HealthDataType.HEADACHE_MODERATE => 3,
        HealthDataType.HEADACHE_SEVERE => 4,
        _ => throw HealthException(type,
            "HealthDataType was not aligned correctly - please report bug at https://github.com/cph-cachet/flutter-plugins/issues"),
      };

  /// Write workout data to Apple Health or Google Fit or Google Health Connect.
  ///
  /// Returns true if the workout data was successfully added.
  ///
  /// Parameters:
  ///  - [activityType] The type of activity performed.
  ///  - [start] The start time of the workout.
  ///  - [end] The end time of the workout.
  ///  - [totalEnergyBurned] The total energy burned during the workout.
  ///  - [totalEnergyBurnedUnit] The UNIT used to measure [totalEnergyBurned]
  ///    *ONLY FOR IOS* Default value is KILOCALORIE.
  ///  - [totalDistance] The total distance traveled during the workout.
  ///  - [totalDistanceUnit] The UNIT used to measure [totalDistance]
  ///    *ONLY FOR IOS* Default value is METER.
  ///  - [title] The title of the workout.
  ///    *ONLY FOR HEALTH CONNECT* Default value is the [activityType], e.g. "STRENGTH_TRAINING".
  Future<bool> writeWorkoutData({
    required HealthWorkoutActivityType activityType,
    required DateTime start,
    required DateTime end,
    int? totalEnergyBurned,
    HealthDataUnit totalEnergyBurnedUnit = HealthDataUnit.KILOCALORIE,
    int? totalDistance,
    HealthDataUnit totalDistanceUnit = HealthDataUnit.METER,
    String? title,
  }) async {
    // Check that value is on the current Platform
    if (Platform.isIOS && !_isOnIOS(activityType)) {
      throw HealthException(activityType,
          "Workout activity type $activityType is not supported on iOS");
    } else if (Platform.isAndroid && !_isOnAndroid(activityType)) {
      throw HealthException(activityType,
          "Workout activity type $activityType is not supported on Android");
    }
    final args = <String, dynamic>{
      'activityType': activityType.name,
      'startTime': start.millisecondsSinceEpoch,
      'endTime': end.millisecondsSinceEpoch,
      'totalEnergyBurned': totalEnergyBurned,
      'totalEnergyBurnedUnit': totalEnergyBurnedUnit.name,
      'totalDistance': totalDistance,
      'totalDistanceUnit': totalDistanceUnit.name,
      'title': title,
    };
    return await _channel.invokeMethod('writeWorkoutData', args) == true;
  }

  /// Check if the given [HealthWorkoutActivityType] is supported on the iOS platform
  bool _isOnIOS(HealthWorkoutActivityType type) {
    // Returns true if the type is part of the iOS set
    return {
      HealthWorkoutActivityType.ARCHERY,
      HealthWorkoutActivityType.BADMINTON,
      HealthWorkoutActivityType.BASEBALL,
      HealthWorkoutActivityType.BASKETBALL,
      HealthWorkoutActivityType.BIKING,
      HealthWorkoutActivityType.BOXING,
      HealthWorkoutActivityType.CRICKET,
      HealthWorkoutActivityType.CURLING,
      HealthWorkoutActivityType.ELLIPTICAL,
      HealthWorkoutActivityType.FENCING,
      HealthWorkoutActivityType.AMERICAN_FOOTBALL,
      HealthWorkoutActivityType.AUSTRALIAN_FOOTBALL,
      HealthWorkoutActivityType.SOCCER,
      HealthWorkoutActivityType.GOLF,
      HealthWorkoutActivityType.GYMNASTICS,
      HealthWorkoutActivityType.HANDBALL,
      HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING,
      HealthWorkoutActivityType.HIKING,
      HealthWorkoutActivityType.HOCKEY,
      HealthWorkoutActivityType.SKATING,
      HealthWorkoutActivityType.JUMP_ROPE,
      HealthWorkoutActivityType.KICKBOXING,
      HealthWorkoutActivityType.MARTIAL_ARTS,
      HealthWorkoutActivityType.PILATES,
      HealthWorkoutActivityType.RACQUETBALL,
      HealthWorkoutActivityType.ROWING,
      HealthWorkoutActivityType.RUGBY,
      HealthWorkoutActivityType.RUNNING,
      HealthWorkoutActivityType.SAILING,
      HealthWorkoutActivityType.CROSS_COUNTRY_SKIING,
      HealthWorkoutActivityType.DOWNHILL_SKIING,
      HealthWorkoutActivityType.SNOWBOARDING,
      HealthWorkoutActivityType.SOFTBALL,
      HealthWorkoutActivityType.SQUASH,
      HealthWorkoutActivityType.STAIR_CLIMBING,
      HealthWorkoutActivityType.SWIMMING,
      HealthWorkoutActivityType.TABLE_TENNIS,
      HealthWorkoutActivityType.TENNIS,
      HealthWorkoutActivityType.VOLLEYBALL,
      HealthWorkoutActivityType.WALKING,
      HealthWorkoutActivityType.WATER_POLO,
      HealthWorkoutActivityType.YOGA,
      HealthWorkoutActivityType.BOWLING,
      HealthWorkoutActivityType.CROSS_TRAINING,
      HealthWorkoutActivityType.TRACK_AND_FIELD,
      HealthWorkoutActivityType.DISC_SPORTS,
      HealthWorkoutActivityType.LACROSSE,
      HealthWorkoutActivityType.PREPARATION_AND_RECOVERY,
      HealthWorkoutActivityType.FLEXIBILITY,
      HealthWorkoutActivityType.COOLDOWN,
      HealthWorkoutActivityType.WHEELCHAIR_WALK_PACE,
      HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE,
      HealthWorkoutActivityType.HAND_CYCLING,
      HealthWorkoutActivityType.CORE_TRAINING,
      HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING,
      HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
      HealthWorkoutActivityType.MIXED_CARDIO,
      HealthWorkoutActivityType.STAIRS,
      HealthWorkoutActivityType.STEP_TRAINING,
      HealthWorkoutActivityType.FITNESS_GAMING,
      HealthWorkoutActivityType.BARRE,
      HealthWorkoutActivityType.CARDIO_DANCE,
      HealthWorkoutActivityType.SOCIAL_DANCE,
      HealthWorkoutActivityType.MIND_AND_BODY,
      HealthWorkoutActivityType.PICKLEBALL,
      HealthWorkoutActivityType.CLIMBING,
      HealthWorkoutActivityType.EQUESTRIAN_SPORTS,
      HealthWorkoutActivityType.FISHING,
      HealthWorkoutActivityType.HUNTING,
      HealthWorkoutActivityType.PLAY,
      HealthWorkoutActivityType.SNOW_SPORTS,
      HealthWorkoutActivityType.PADDLE_SPORTS,
      HealthWorkoutActivityType.SURFING_SPORTS,
      HealthWorkoutActivityType.WATER_FITNESS,
      HealthWorkoutActivityType.WATER_SPORTS,
      HealthWorkoutActivityType.TAI_CHI,
      HealthWorkoutActivityType.WRESTLING,
      HealthWorkoutActivityType.OTHER,
    }.contains(type);
  }

  /// Check if the given [HealthWorkoutActivityType] is supported on the Android platform
  bool _isOnAndroid(HealthWorkoutActivityType type) {
    // Returns true if the type is part of the Android set
    return {
      // Both
      HealthWorkoutActivityType.ARCHERY,
      HealthWorkoutActivityType.BADMINTON,
      HealthWorkoutActivityType.BASEBALL,
      HealthWorkoutActivityType.BASKETBALL,
      HealthWorkoutActivityType.BIKING,
      HealthWorkoutActivityType.BOXING,
      HealthWorkoutActivityType.CRICKET,
      HealthWorkoutActivityType.CURLING,
      HealthWorkoutActivityType.ELLIPTICAL,
      HealthWorkoutActivityType.FENCING,
      HealthWorkoutActivityType.AMERICAN_FOOTBALL,
      HealthWorkoutActivityType.AUSTRALIAN_FOOTBALL,
      HealthWorkoutActivityType.SOCCER,
      HealthWorkoutActivityType.GOLF,
      HealthWorkoutActivityType.GYMNASTICS,
      HealthWorkoutActivityType.HANDBALL,
      HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING,
      HealthWorkoutActivityType.HIKING,
      HealthWorkoutActivityType.HOCKEY,
      HealthWorkoutActivityType.SKATING,
      HealthWorkoutActivityType.JUMP_ROPE,
      HealthWorkoutActivityType.KICKBOXING,
      HealthWorkoutActivityType.MARTIAL_ARTS,
      HealthWorkoutActivityType.PILATES,
      HealthWorkoutActivityType.RACQUETBALL,
      HealthWorkoutActivityType.ROWING,
      HealthWorkoutActivityType.RUGBY,
      HealthWorkoutActivityType.RUNNING,
      HealthWorkoutActivityType.SAILING,
      HealthWorkoutActivityType.CROSS_COUNTRY_SKIING,
      HealthWorkoutActivityType.DOWNHILL_SKIING,
      HealthWorkoutActivityType.SNOWBOARDING,
      HealthWorkoutActivityType.SOFTBALL,
      HealthWorkoutActivityType.SQUASH,
      HealthWorkoutActivityType.STAIR_CLIMBING,
      HealthWorkoutActivityType.SWIMMING,
      HealthWorkoutActivityType.TABLE_TENNIS,
      HealthWorkoutActivityType.TENNIS,
      HealthWorkoutActivityType.VOLLEYBALL,
      HealthWorkoutActivityType.WALKING,
      HealthWorkoutActivityType.WATER_POLO,
      HealthWorkoutActivityType.YOGA,

      // Android only
      // Once Google Fit is removed, this list needs to be changed
      HealthWorkoutActivityType.AEROBICS,
      HealthWorkoutActivityType.BIATHLON,
      HealthWorkoutActivityType.BIKING_HAND,
      HealthWorkoutActivityType.BIKING_MOUNTAIN,
      HealthWorkoutActivityType.BIKING_ROAD,
      HealthWorkoutActivityType.BIKING_SPINNING,
      HealthWorkoutActivityType.BIKING_STATIONARY,
      HealthWorkoutActivityType.BIKING_UTILITY,
      HealthWorkoutActivityType.CALISTHENICS,
      HealthWorkoutActivityType.CIRCUIT_TRAINING,
      HealthWorkoutActivityType.CROSS_FIT,
      HealthWorkoutActivityType.DANCING,
      HealthWorkoutActivityType.DIVING,
      HealthWorkoutActivityType.ELEVATOR,
      HealthWorkoutActivityType.ERGOMETER,
      HealthWorkoutActivityType.ESCALATOR,
      HealthWorkoutActivityType.FRISBEE_DISC,
      HealthWorkoutActivityType.GARDENING,
      HealthWorkoutActivityType.GUIDED_BREATHING,
      HealthWorkoutActivityType.HORSEBACK_RIDING,
      HealthWorkoutActivityType.HOUSEWORK,
      HealthWorkoutActivityType.INTERVAL_TRAINING,
      HealthWorkoutActivityType.IN_VEHICLE,
      HealthWorkoutActivityType.ICE_SKATING,
      HealthWorkoutActivityType.KAYAKING,
      HealthWorkoutActivityType.KETTLEBELL_TRAINING,
      HealthWorkoutActivityType.KICK_SCOOTER,
      HealthWorkoutActivityType.KITE_SURFING,
      HealthWorkoutActivityType.MEDITATION,
      HealthWorkoutActivityType.MIXED_MARTIAL_ARTS,
      HealthWorkoutActivityType.P90X,
      HealthWorkoutActivityType.PARAGLIDING,
      HealthWorkoutActivityType.POLO,
      HealthWorkoutActivityType.ROCK_CLIMBING,
      HealthWorkoutActivityType.ROWING_MACHINE,
      HealthWorkoutActivityType.RUNNING_JOGGING,
      HealthWorkoutActivityType.RUNNING_SAND,
      HealthWorkoutActivityType.RUNNING_TREADMILL,
      HealthWorkoutActivityType.SCUBA_DIVING,
      HealthWorkoutActivityType.SKATING_CROSS,
      HealthWorkoutActivityType.SKATING_INDOOR,
      HealthWorkoutActivityType.SKATING_INLINE,
      HealthWorkoutActivityType.SKIING,
      HealthWorkoutActivityType.SKIING_BACK_COUNTRY,
      HealthWorkoutActivityType.SKIING_KITE,
      HealthWorkoutActivityType.SKIING_ROLLER,
      HealthWorkoutActivityType.SLEDDING,
      HealthWorkoutActivityType.SNOWMOBILE,
      HealthWorkoutActivityType.SNOWSHOEING,
      HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE,
      HealthWorkoutActivityType.STANDUP_PADDLEBOARDING,
      HealthWorkoutActivityType.STILL,
      HealthWorkoutActivityType.STRENGTH_TRAINING,
      HealthWorkoutActivityType.SURFING,
      HealthWorkoutActivityType.SWIMMING_OPEN_WATER,
      HealthWorkoutActivityType.SWIMMING_POOL,
      HealthWorkoutActivityType.TEAM_SPORTS,
      HealthWorkoutActivityType.TILTING,
      HealthWorkoutActivityType.VOLLEYBALL_BEACH,
      HealthWorkoutActivityType.VOLLEYBALL_INDOOR,
      HealthWorkoutActivityType.WAKEBOARDING,
      HealthWorkoutActivityType.WALKING_FITNESS,
      HealthWorkoutActivityType.WALKING_NORDIC,
      HealthWorkoutActivityType.WALKING_STROLLER,
      HealthWorkoutActivityType.WALKING_TREADMILL,
      HealthWorkoutActivityType.WEIGHTLIFTING,
      HealthWorkoutActivityType.WHEELCHAIR,
      HealthWorkoutActivityType.WINDSURFING,
      HealthWorkoutActivityType.ZUMBA,
      HealthWorkoutActivityType.OTHER,
    }.contains(type);
  }
}
