import 'dart:async';

import 'package:flutter/foundation.dart';
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

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_isSupportedPlatform) {
      startListening();
    } else {
      debugPrint('screen_state is only supported on Android and iOS');
    }
  }

  /// Start listening to screen events
  void startListening() {
    try {
      _subscription = _screen.screenStateStream.listen(
        onData,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('screen_state stream error: $error');
        },
        onDone: () {
          debugPrint('screen_state stream closed');
          if (mounted) setState(() => started = false);
        },
      );
      debugPrint('screen_state listening for events');
      setState(() => started = true);
    } catch (exception) {
      debugPrint('screen_state failed to start listening: $exception');
    }
  }

  void onData(ScreenStateEvent event) {
    debugPrint('screen_state event: ${event.name}');
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
          child: _log.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No events yet.\nTry locking and unlocking the device once.\n\n'
                    'If you are running on desktop/web, this plugin is not supported there.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _log.length,
                  reverse: true,
                  itemBuilder: (BuildContext context, int idx) {
                    final entry = _log[idx];
                    return ListTile(
                      leading: Text(entry.time.toString().substring(0, 19)),
                      trailing: Text(entry.event.toString().split('.').last),
                    );
                  },
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: started ? stopListening : startListening,
          tooltip: 'Start/Stop Listening',
          child: started ? Icon(Icons.stop) : Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}
