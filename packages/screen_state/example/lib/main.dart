import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screen_state/screen_state.dart';

void main() => runApp(ScreenStateApp());

class ScreenStateApp extends StatefulWidget {
  const ScreenStateApp({super.key});

  @override
  ScreenStateAppState createState() => ScreenStateAppState();
}

class ScreenStateEventEntry {
  ScreenStateEvent event;
  DateTime? time;

  ScreenStateEventEntry(this.event) {
    time = DateTime.now();
  }
}

class ScreenStateAppState extends State<ScreenStateApp> {
  final Screen _screen = Screen();
  StreamSubscription<ScreenStateEvent>? _subscription;
  bool started = false;
  final List<ScreenStateEventEntry> _log = [];

  @override
  void initState() {
    super.initState();
    startListening();
  }

  /// Start listening to screen events
  void startListening() {
    try {
      _subscription = _screen.screenStateStream.listen(onData);
      setState(() => started = true);
    } catch (exception) {
      print(exception);
    }
  }

  void onData(ScreenStateEvent event) {
    setState(() {
      _log.add(ScreenStateEventEntry(event));
    });
  }

  /// Stop listening to screen events
  void stopListening() {
    _subscription?.cancel();
    setState(() => started = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Screen State Example'),
        ),
        body: Center(
            child: ListView.builder(
                itemCount: _log.length,
                reverse: true,
                itemBuilder: (BuildContext context, int idx) {
                  final entry = _log[idx];
                  return ListTile(
                      leading: Text(entry.time.toString().substring(0, 19)),
                      trailing: Text(entry.event.toString().split('.').last));
                })),
        floatingActionButton: FloatingActionButton(
          onPressed: started ? stopListening : startListening,
          tooltip: 'Start/Stop Listening',
          child: started ? Icon(Icons.stop) : Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}
