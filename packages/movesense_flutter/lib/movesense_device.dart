part of 'movesense_flutter.dart';

/// A class representing a Movesense device.
class MovesenseDevice {
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

  /// A stream of connection status of the device.
  Stream<DeviceConnectionStatus> get statusStream =>
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

  /// The latest device info for the connected Movesense device.
  /// Only available after device is connected.
  /// See https://www.movesense.com/docs/esw/api_reference/#info
  MovesenseDeviceInfo? deviceInfo;

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
      (serial) {
        this.serial = serial;
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
  /// Returns a Future that completes with a Map containing the device info,
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
        deviceInfo = MovesenseDeviceInfo.fromJsonString(info);

        // Try to figure out the type of device based on the "hw" property
        // H3 is "HR+", H4 is "HR2", A1 is "MD"
        deviceType = switch (deviceInfo?.hw.toUpperCase()) {
          'A1' => MovesenseDeviceType.MD,
          'H3' => MovesenseDeviceType.HR_PLUS,
          'H4' => MovesenseDeviceType.HR2,
          _ => MovesenseDeviceType.unknown,
        };
        completer.complete(deviceInfo);
      }),
      // onError
      (error, statusCode) =>
          completer.completeError('$runtimeType - error: $error'),
    );

    return completer.future;

    // var data = MdsAsync.get(Mds.createRequestUri(serial!, "/Info"), "{}")
    //     .then((info) {
    //       debugPrint('$runtimeType - Movesense Device Info:\n$info');
    //       final dataContent = json.decode(info);
    //       deviceInfo = dataContent["Content"] as Map<String, dynamic>;
    //       String hw = (deviceInfo!["hw"] as String).toUpperCase();
    //       debugPrint('$runtimeType - HW: $hw');
    //       // Try to figure out the type of device based on the "hw" property
    //       // H3 is "HR+", H4 is "HR2", A1 is "MD"
    //       deviceType = switch (hw) {
    //         'A1' => MovesenseDeviceType.MD,
    //         'H3' => MovesenseDeviceType.HR_PLUS,
    //         'H4' => MovesenseDeviceType.HR2,
    //         _ => MovesenseDeviceType.unknown,
    //       };
    //       return deviceInfo;
    //     })
    //     .catchError((error) {
    //       Future.error('Error getting Movesense Device Info: $error');
    //     });

    // return data;
  }

  /// A stream of heart rate measurements from the Movesense device.
  /// Only available when the device is connected.
  Stream<int> get heartRate => !isConnected
      ? Stream.empty()
      : MdsAsync.subscribe(Mds.createSubscriptionUri(serial!, "/Meas/HR"), "{}")
            .map((data) => (data["Body"]["average"] as num).toInt())
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

enum DeviceConnectionStatus { disconnected, connecting, connected, error }
