import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Information on app usage.
class AppUsageInfo {
  late String _packageName, _appName;
  late Duration _usage;
  final DateTime _startDate, _endDate, _lastForeground;

  AppUsageInfo(
    String name,
    double usageInSeconds,
    this._startDate,
    this._endDate,
    this._lastForeground,
  ) {
    List<String> tokens = name.split('.');
    _packageName = name;
    _appName = tokens.last;
    _usage = Duration(seconds: usageInSeconds.toInt());
  }

  /// The name of the application
  String get appName => _appName;

  /// The name of the application package
  String get packageName => _packageName;

  /// The amount of time the application has been used
  /// in the specified interval
  Duration get usage => _usage;

  /// The start of the interval
  DateTime get startDate => _startDate;

  /// The end of the interval
  DateTime get endDate => _endDate;

  /// Last time app was in foreground
  DateTime get lastForeground => _lastForeground;

  @override
  String toString() =>
      'App Usage: $packageName - $appName, duration: $usage [$startDate, $endDate]';
}

/// Singleton class to get app usage statistics.
class AppUsage {
  static const MethodChannel _methodChannel = MethodChannel(
    "app_usage.methodChannel",
  );
  static bool? _debugIsAndroidOverride;

  static final AppUsage _instance = AppUsage._();
  AppUsage._();
  factory AppUsage() => _instance;

  @visibleForTesting
  static set debugIsAndroidOverride(bool? value) {
    _debugIsAndroidOverride = value;
  }

  /// Get app usage statistics for the specified interval. Only works on Android.
  /// Returns an empty list if called on iOS.
  Future<List<AppUsageInfo>> getAppUsage(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final bool isAndroid = _debugIsAndroidOverride ?? Platform.isAndroid;
    if (!isAndroid) return [];

    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End date must be after start date');
    }

    // Convert dates to ms since epoch
    int end = endDate.millisecondsSinceEpoch;
    int start = startDate.millisecondsSinceEpoch;

    // Set parameters
    final Map<String, int> interval = <String, int>{'start': start, 'end': end};

    // Get result and parse it as a Map of <String, List<double>>
    final Map<Object?, Object?> usage =
        await _methodChannel.invokeMethod<Map<Object?, Object?>>(
          'getUsage',
          interval,
        ) ??
        <Object?, Object?>{};

    // Convert to list of AppUsageInfo
    final List<AppUsageInfo> result = <AppUsageInfo>[];
    for (final MapEntry<Object?, Object?> entry in usage.entries) {
      final String key = entry.key as String;
      final List<double> temp = List<double>.from(
        entry.value as Iterable<Object?>,
      );
      if (temp[0] > 0) {
        result.add(
          AppUsageInfo(
            key,
            temp[0],
            DateTime.fromMillisecondsSinceEpoch(temp[1].round() * 1000),
            DateTime.fromMillisecondsSinceEpoch(temp[2].round() * 1000),
            DateTime.fromMillisecondsSinceEpoch(temp[3].round() * 1000),
          ),
        );
      }
    }

    return result;
  }
}
