import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// The type of screen state events coming from Android or iOS.
enum ScreenStateEvent {
  SCREEN_UNLOCKED,
  SCREEN_ON,
  SCREEN_OFF;

  /// Returns the name of the enum value.
  String get name {
    switch (this) {
      case ScreenStateEvent.SCREEN_UNLOCKED:
        return Platform.isAndroid
            ? 'android.intent.action.USER_PRESENT'
            : 'SCREEN_UNLOCKED';
      case ScreenStateEvent.SCREEN_ON:
        return Platform.isAndroid
            ? 'android.intent.action.SCREEN_ON'
            : 'SCREEN_ON';
      case ScreenStateEvent.SCREEN_OFF:
        return Platform.isAndroid
            ? 'android.intent.action.SCREEN_OFF'
            : 'SCREEN_OFF';
      default:
        throw ArgumentError('Unknown ScreenStateEvent: $this');
    }
  }

  /// Returns the enum value from the name.
  static ScreenStateEvent fromName(String name) {
    switch (name) {
      case 'SCREEN_UNLOCKED':
      case 'android.intent.action.USER_PRESENT': // Android only 'USER_PRESENT
        return ScreenStateEvent.SCREEN_UNLOCKED;
      case 'SCREEN_ON':
      case 'android.intent.action.SCREEN_ON': // Android only 'SCREEN_ON'
        return ScreenStateEvent.SCREEN_ON;
      case 'SCREEN_OFF':
      case 'android.intent.action.SCREEN_OFF': // Android only 'SCREEN_OFF'
        return ScreenStateEvent.SCREEN_OFF;
      default:
        throw ArgumentError('Unknown ScreenStateEvent: $name');
    }
  }
}

/// Screen state events as they occur on the phone.
class Screen {
  static Screen? _singleton;
  final EventChannel _eventChannel = const EventChannel('screenStateEvents');
  Stream<ScreenStateEvent>? _screenStateStream;

  /// Constructs a singleton instance of [Screen].
  factory Screen() => _singleton ??= Screen._();

  Screen._();

  /// Stream of [ScreenStateEvent]s as they occurs on the phone.
  /// Returns an empty stream on unsupported platforms.
  Stream<ScreenStateEvent> get screenStateStream =>
      _screenStateStream ??= Platform.isAndroid || Platform.isIOS
          ? _screenStateStream ??= _eventChannel
              .receiveBroadcastStream()
              .map((event) => ScreenStateEvent.fromName(event))
          : Stream<ScreenStateEvent>.empty();
}
