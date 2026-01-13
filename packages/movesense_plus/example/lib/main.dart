// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movesense_plus/movesense_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MovesenseApp());

class MovesenseApp extends StatelessWidget {
  const MovesenseApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: MovesenseHomePage());
}

class MovesenseHomePage extends StatefulWidget {
  const MovesenseHomePage({super.key});

  @override
  State<MovesenseHomePage> createState() => MovesenseHomePageState();
}

class MovesenseHomePageState extends State<MovesenseHomePage> {
  // My device address: 0C:8C:DC:1B:23:BF, serial 233830000816
  // Replace with your Movesense device address.
  final MovesenseDevice device = MovesenseDevice(address: '0C:8C:DC:1B:23:BF');
  bool isSampling = false;
  StreamSubscription<int>? hrSubscription;
  StreamSubscription<MovesenseState>? stateSubscription;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (!mounted) return;

    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movensense HR Monitor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<DeviceConnectionStatus>(
              stream: device.statusEvents,
              builder: (context, snapshot) =>
                  Text('Movesense [${device.address}] - ${device.status.name}'),
            ),
            const Text('Your heart rate is:'),
            StreamBuilder<int>(
              stream: device.hr,
              builder: (context, snapshot) => Text(
                snapshot.hasData ? '${snapshot.data}' : '...',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onButtonPressed(),
        child: (!(device.isConnected))
            ? const Icon(Icons.refresh)
            : (!isSampling)
            ? const Icon(Icons.play_arrow)
            : const Icon(Icons.stop),
      ),
    );
  }

  /// Handle button press to connect to device and start/stop sampling.
  void onButtonPressed() {
    setState(() {
      if (!device.isConnected) {
        // if not connected, connect to the device
        device.connect();
      } else {
        // when connected, first get device info and battery status
        device.getDeviceInfo().then(
          (info) => debugPrint('>> Product name: ${info?.productName}'),
        );

        device.getBatteryStatus().then(
          (battery) => debugPrint('>> Battery level: ${battery.name}'),
        );
        // then start/stop sampling
        if (!isSampling) {
          // Example of subscribing to heart rate data
          hrSubscription = device.hr.listen((hr) {
            debugPrint('>> Heart Rate: $hr');
          });

          // Example of subscribing to tap state changes
          stateSubscription = device
              .getStateEvents(SystemStateComponent.tap)
              .listen((state) {
                debugPrint('>> State: ${state.toString()}');
              });
          isSampling = true;
        } else {
          hrSubscription?.cancel();
          stateSubscription?.cancel();
          isSampling = false;
        }
      }
    });
  }
}
