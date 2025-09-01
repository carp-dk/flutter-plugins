import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Information on app usage.
class AppUsageInfo {
  late String _packageName, _appName;
  late Duration _usage;
  DateTime _startDate, _endDate, _lastForeground;

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
  static const MethodChannel _methodChannel =
      const MethodChannel("app_usage.methodChannel");

  static final AppUsage _instance = AppUsage._();
  AppUsage._();
  factory AppUsage() => _instance;

  /// Get app usage statistics for the specified interval. Only works on Android.
  /// Returns an empty list if called on iOS.
  Future<List<AppUsageInfo>> getAppUsage(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!Platform.isAndroid) return [];

    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End date must be after start date');
    }

    // Convert dates to ms since epoch
    int end = endDate.millisecondsSinceEpoch;
    int start = startDate.millisecondsSinceEpoch;

    // Set parameters
    Map<String, int> interval = {'start': start, 'end': end};

    // Get result and parse it as a Map of <String, List<double>>
    Map usage = await _methodChannel.invokeMethod('getUsage', interval);

    // Convert to list of AppUsageInfo
    List<AppUsageInfo> result = [];
    for (String key in usage.keys) {
      List<double> temp = List<double>.from(usage[key]);
      if (temp[0] > 0) {
        result.add(AppUsageInfo(
            key,
            temp[0],
            DateTime.fromMillisecondsSinceEpoch(temp[1].round() * 1000),
            DateTime.fromMillisecondsSinceEpoch(temp[2].round() * 1000),
            DateTime.fromMillisecondsSinceEpoch(temp[3].round() * 1000)));
      }
    }

    return result;
  }
}
