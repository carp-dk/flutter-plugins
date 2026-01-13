library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mdsflutter/Mds.dart';

part 'movesense_device.dart';
part 'device_info.dart';

class Movesense {
  static final Movesense _instance = Movesense._();
  Movesense._();
  final StreamController<MovesenseDevice> _scanController =
      StreamController<MovesenseDevice>.broadcast();

  /// Returns the singleton instance of [Movesense].
  factory Movesense() => _instance;

  /// A stream of discovered Movesense devices during scanning.
  Stream<MovesenseDevice> get devices =>
      _scanController.stream.asBroadcastStream();

  /// Scan for available Movesense devices.
  /// Found devices are emitted on the [devices] stream.
  /// Call [stopScan] to stop scanning.
  void scan() {
    Mds.startScan(
      (name, address) =>
          _scanController.add(MovesenseDevice(address: address, name: name)),
    );
  }

  /// Stop scanning for Movesense devices.
  void stopScan() => Mds.stopScan();
}
