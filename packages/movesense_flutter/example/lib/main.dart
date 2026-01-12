// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movesense_flutter/movesense_flutter.dart';
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
  // Replace with your Movesense device address.
  final MovesenseDevice device = MovesenseDevice(address: '0C:8C:DC:1B:23:BF');
  bool isSampling = false;
  StreamSubscription<int>? hrSubscription;

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
              stream: device.statusStream,
              builder: (context, snapshot) =>
                  Text('Movesense [${device.address}] - ${device.status.name}'),
            ),
            const Text('Your heart rate is:'),
            StreamBuilder<int>(
              stream: device.heartRate,
              builder: (context, snapshot) {
                var displayText = '...';
                if (snapshot.hasData) displayText = '${snapshot.data}';
                return Text(
                  displayText,
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
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

  void onButtonPressed() {
    setState(() {
      if (!device.isConnected) {
        device.connect();
      } else {
        if (!isSampling) {
          hrSubscription = device.heartRate.listen((hr) {
            debugPrint('Heart Rate: $hr');
          });
          isSampling = true;
        } else {
          hrSubscription?.cancel();
          isSampling = false;
        }
      }
    });
  }
}
