import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Authorization status for SensorKit ambient-light access on iOS.
enum LightAuthorizationStatus {
  notDetermined,
  authorized,
  denied,
  unavailable,
  unknown,
}

class Light {
  static Light? _instance;
  static const MethodChannel _methodChannel = MethodChannel('light');
  static const EventChannel _eventChannel = EventChannel("light.eventChannel");
  static bool? _debugIsAndroidOverride;
  static bool? _debugIsIOSOverride;
  static MethodChannel? _debugMethodChannelOverride;
  static EventChannel? _debugEventChannelOverride;

  /// Constructs a singleton instance of [Light].
  ///
  /// [Light] is designed to work as a singleton.
  factory Light() => _instance ??= Light._();

  Light._();

  Stream<int>? _lightSensorStream;

  @visibleForTesting
  static set debugIsAndroidOverride(bool? value) {
    _debugIsAndroidOverride = value;
  }

  @visibleForTesting
  static set debugIsIOSOverride(bool? value) {
    _debugIsIOSOverride = value;
  }

  @visibleForTesting
  static set debugMethodChannelOverride(MethodChannel? value) {
    _debugMethodChannelOverride = value;
  }

  @visibleForTesting
  static set debugEventChannelOverride(EventChannel? value) {
    _debugEventChannelOverride = value;
  }

  @visibleForTesting
  static void debugReset() {
    _debugIsAndroidOverride = null;
    _debugIsIOSOverride = null;
    _debugMethodChannelOverride = null;
    _debugEventChannelOverride = null;
    _instance?._lightSensorStream = null;
    _instance = null;
  }

  /// Returns current iOS SensorKit authorization state.
  ///
  /// For non-iOS platforms, this returns [LightAuthorizationStatus.unavailable].
  Future<LightAuthorizationStatus> getAuthorizationStatus() async {
    final bool isIOS = _debugIsIOSOverride ?? Platform.isIOS;
    if (!isIOS) {
      return LightAuthorizationStatus.unavailable;
    }

    final MethodChannel channel = _debugMethodChannelOverride ?? _methodChannel;

    try {
      final String? status =
          await channel.invokeMethod<String>('getAuthorizationStatus');
      return _parseAuthorizationStatus(status);
    } catch (_) {
      return LightAuthorizationStatus.unavailable;
    }
  }

  /// Requests iOS SensorKit authorization for ambient light access.
  ///
  /// For non-iOS platforms, this returns [LightAuthorizationStatus.unavailable].
  Future<LightAuthorizationStatus> requestAuthorization() async {
    final bool isIOS = _debugIsIOSOverride ?? Platform.isIOS;
    if (!isIOS) {
      return LightAuthorizationStatus.unavailable;
    }

    final MethodChannel channel = _debugMethodChannelOverride ?? _methodChannel;

    try {
      final String? status =
          await channel.invokeMethod<String>('requestAuthorization');
      return _parseAuthorizationStatus(status);
    } on PlatformException catch (_) {
      final LightAuthorizationStatus currentStatus =
          await getAuthorizationStatus();
      return currentStatus == LightAuthorizationStatus.unknown
          ? LightAuthorizationStatus.denied
          : currentStatus;
    } catch (_) {
      return LightAuthorizationStatus.unavailable;
    }
  }

  /// The stream of light events.
  ///
  /// Return an empty Stream if this device doesn't support this plugin or if
  /// accessing the light sensor fails.
  Stream<int> get lightSensorStream {
    try {
      final bool isAndroid = _debugIsAndroidOverride ?? Platform.isAndroid;
      final bool isIOS = _debugIsIOSOverride ?? Platform.isIOS;
      final bool isSupportedPlatform = isAndroid || isIOS;
      final EventChannel channel = _debugEventChannelOverride ?? _eventChannel;

      return isSupportedPlatform
          ? _lightSensorStream ??= channel
              .receiveBroadcastStream()
              .map((lux) => int.tryParse(lux.toString()) ?? -1)
          : Stream<int>.empty();
    } catch (_) {
      return Stream<int>.empty();
    }
  }

  LightAuthorizationStatus _parseAuthorizationStatus(String? rawStatus) {
    switch (rawStatus) {
      case 'notDetermined':
        return LightAuthorizationStatus.notDetermined;
      case 'authorized':
        return LightAuthorizationStatus.authorized;
      case 'denied':
        return LightAuthorizationStatus.denied;
      case 'unavailable':
        return LightAuthorizationStatus.unavailable;
      default:
        return LightAuthorizationStatus.unknown;
    }
  }
}
