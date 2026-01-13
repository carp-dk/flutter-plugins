part of 'movesense_plus.dart';

/// A class representing a Movesense device.
class MovesenseDevice {
  MovesenseDeviceInfo? _deviceInfo;
  DeviceBatteryLevel _batteryLevel = DeviceBatteryLevel.unknown;

  /// The Movesense device address.
  ///
  /// Address is Bluetooth MAC address for Android devices and UUID for iOS devices.
  String? address;

  /// The Movesense device serial number.
  String? serial;

  /// The Movesense device name.
  String? name;

  /// The type of Movesense device, if known.
  MovesenseDeviceType deviceType;

  /// The current connection status of the device.
  DeviceConnectionStatus get status => _status;
  DeviceConnectionStatus _status = DeviceConnectionStatus.disconnected;
  set status(DeviceConnectionStatus newStatus) {
    if (_status != newStatus) {
      debugPrint("$runtimeType - Setting device '$address' as $newStatus");
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  /// A stream of connection status events of the device.
  Stream<DeviceConnectionStatus> get statusEvents =>
      _statusController.stream.asBroadcastStream();
  final _statusController =
      StreamController<DeviceConnectionStatus>.broadcast();

  MovesenseDevice({
    this.address,
    this.serial,
    this.name,
    this.deviceType = MovesenseDeviceType.unknown,
  });

  /// Returns true if the device has a valid address and can be connected to.
  bool canConnect() => address != null;

  /// Returns true if the device is currently connected.
  bool get isConnected => serial != null;
  // bool get isConnected => status == DeviceConnectionStatus.connected;

  /// The device info for the connected Movesense device.
  /// Only available after device is connected.
  /// See https://www.movesense.com/docs/esw/api_reference/#info
  MovesenseDeviceInfo? get deviceInfo => _deviceInfo;

  /// The battery level of the device, if known.
  /// Battery level is updated every 10 minutes when connected.
  DeviceBatteryLevel? get batteryLevel => _batteryLevel;

  /// Connect to the Movesense device using the [address] specified.
  /// If the address is not set, an exception is thrown.
  Future<void> connect() async {
    if (!canConnect()) {
      throw Exception('Cannot connect to device - address is not set.');
    }

    status = DeviceConnectionStatus.connecting;

    Mds.connect(
      address!,
      // onConnected
      (serial) async {
        this.serial = serial;
        await getDeviceInfo(); // fetch device info upon connection
        await getBatteryStatus(); // fetch battery status upon connection

        status = DeviceConnectionStatus.connected;
      },
      // onDisconnected
      () => status = DeviceConnectionStatus.disconnected,
      // onError
      (error) => status = DeviceConnectionStatus.error,
      // onBleConnected
      // - for now we ignore this callback
      (_) {},
    );
  }

  /// Disconnect from the Movesense device.
  Future<void> disconnect() async {
    if (!isConnected) return;
    Mds.disconnect(address!);
  }

  /// Get the detailed info about this Movesense device.
  /// See https://www.movesense.com/docs/esw/api_reference/#info
  /// Returns [MovesenseDeviceInfo] on success,
  /// or null if the device is not connected.
  Future<MovesenseDeviceInfo?> getDeviceInfo() async {
    // fast out if not connected
    if (!isConnected) return null;

    var completer = Completer<MovesenseDeviceInfo?>();

    Mds.get(
      Mds.createRequestUri(serial!, "/Info"),
      "{}",
      // onSuccess
      ((info, statusCode) {
        _deviceInfo = MovesenseDeviceInfo.fromMovesenseData(info);

        // Try to figure out the type of device based on the "hw" property
        // H3 is "HR+", H4 is "HR2", A1 is "MD"
        deviceType = switch (_deviceInfo?.hw.toUpperCase()) {
          'A1' => MovesenseDeviceType.MD,
          'H3' => MovesenseDeviceType.HR_PLUS,
          'H4' => MovesenseDeviceType.HR2,
          _ => MovesenseDeviceType.unknown,
        };
        completer.complete(_deviceInfo);
      }),
      // onError
      (error, statusCode) =>
          completer.completeError('$runtimeType - error: $error'),
    );

    return completer.future;
  }

  /// Get battery status from the device.
  Future<DeviceBatteryLevel> getBatteryStatus() {
    // fast out if not connected
    if (!isConnected) return Future.value(DeviceBatteryLevel.unknown);

    var completer = Completer<DeviceBatteryLevel>();
    _batteryLevel = DeviceBatteryLevel.unknown;

    Mds.get(
      Mds.createRequestUri(serial!, "/System/States/1"),
      "{}",
      ((data, statusCode) {
        final dataContent = json.decode(data);
        num batteryState = dataContent["Content"] as num;
        // Movesense reports "OK" (0) or "LOW" (1) battery state
        _batteryLevel = batteryState == 0
            ? DeviceBatteryLevel.ok
            : DeviceBatteryLevel.low;
        completer.complete(_batteryLevel);
      }),
      (error, statusCode) {
        _batteryLevel = DeviceBatteryLevel.unknown;
        completer.complete(_batteryLevel);
      },
    );
    return completer.future;
  }

  /// Get the state of the device.
  /// See https://www.movesense.com/docs/esw/api_reference/#systemstates
  ///
  /// Returns [MovesenseState] on success,
  /// or null if the device is not connected.
  Future<MovesenseState?> getState(SystemStateComponent state) {
    // fast out if not connected
    if (!isConnected) return Future.value(null);

    var completer = Completer<MovesenseState?>();

    Mds.get(
      Mds.createRequestUri(serial!, "/System/States/${state.index}"),
      "{}",
      ((data, _) =>
          completer.complete(MovesenseState.fromMovesenseData(state, data))),
      (error, _) => completer.complete(null),
    );
    return completer.future;
  }

  /// A stream of heart rate (HR) measurements from the Movesense device.
  /// Only available when the device is connected.
  Stream<int> get hr => !isConnected
      ? Stream.empty()
      : MdsAsync.subscribe(Mds.createSubscriptionUri(serial!, "/Meas/HR"), "{}")
            .map((data) => (data["Body"]["average"] as num).toInt())
            .asBroadcastStream();

  /// A stream of ECG measurements from the Movesense device collected at 125 Hz.
  /// Only available when the device is connected.
  Stream<MovesenseECG> get ecg => !isConnected
      ? Stream.empty()
      : MdsAsync.subscribe(
              Mds.createSubscriptionUri(serial!, "/Meas/ECG/125"),
              "{}",
            )
            .map((data) => MovesenseECG.fromMovesenseData(data))
            .asBroadcastStream();

  /// A stream of IMU measurements from the Movesense device collected at 13 Hz (lowest).
  /// Only available when the device is connected.
  Stream<MovesenseIMU> get imu => !isConnected
      ? Stream.empty()
      : MdsAsync.subscribe(
              Mds.createSubscriptionUri(serial!, "/Meas/IMU9/13"),
              "{}",
            )
            .map((data) => MovesenseIMU.fromMovesenseData(data))
            .asBroadcastStream();

  /// A stream of temperature measurements from the Movesense device.
  /// Only available when the device is connected.
  Stream<MovesenseTemperature> get temperature => !isConnected
      ? Stream.empty()
      : MdsAsync.subscribe(
              Mds.createSubscriptionUri(serial!, "/Meas/Temp"),
              "{}",
            )
            .map((data) => MovesenseTemperature.fromMovesenseData(data))
            .asBroadcastStream();

  /// Get a stream of state events for a specific [component] from the Movesense device.
  /// The types of state changes available are listed in [SystemStateComponent].
  /// See https://www.movesense.com/docs/esw/api_reference/#systemstates
  ///
  /// **NOTE**, that currently there is a limitation to the Movesense API and you
  /// can only subscribe to a single type of event at a time.
  /// See issue [#15](https://github.com/petri-lipponen-movesense/mdsflutter/issues/15).
  ///
  /// Also note that not all state changes are supported on all types of devices.
  /// For example, it seems like only the 'connectors' and 'tap' states are supported
  /// on the Movesense MD and HR2 devices.
  ///
  /// The returned stream emits [MovesenseState] objects representing
  /// the state change events.
  ///
  /// Only available when the device is connected.
  Stream<MovesenseState> getStateEvents(SystemStateComponent component) =>
      !isConnected
      ? Stream.empty()
      : MdsAsync.subscribe(
              Mds.createSubscriptionUri(
                serial!,
                "/System/States/${component.index}",
              ),
              "{}",
            )
            .map((data) => MovesenseState.fromMovesenseData(component, data))
            .asBroadcastStream();
}

/// Enumeration of supported Movesense devices.
enum MovesenseDeviceType {
  /// Unknown Movesense type
  unknown,

  /// Movesense Medical sensor
  MD,

  /// Movesense ACTIVE HR+
  HR_PLUS,

  /// Movesense ACTIVE HR2 sensor
  HR2,

  /// Movesense FLASH sensor
  FLASH,
}

/// Enumeration of the connection status of the Movesense device.
enum DeviceConnectionStatus { disconnected, connecting, connected, error }

/// Enumeration of the battery level of the Movesense device.
enum DeviceBatteryLevel { low, ok, unknown }

/// Enumeration of the type of system state components available on the Movesense device.
/// See https://www.movesense.com/docs/esw/api_reference/#systemstates
enum SystemStateComponent {
  movement,
  battery,
  connectors,
  doubleTap,
  tap,
  freeFall,
}
