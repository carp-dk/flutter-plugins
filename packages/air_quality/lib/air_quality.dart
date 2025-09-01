/*
 * Copyright 2025 Copenhagen Research Platform (CARP) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
library air_quality;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom Exception for the plugin,
/// Thrown whenever the API responds with an error and body could not be parsed.
class AirQualityAPIException implements Exception {
  String _cause;

  AirQualityAPIException(this._cause);

  String toString() => '${this.runtimeType} - $_cause';
}

enum AirQualityLevel {
  UNKNOWN,
  GOOD,
  MODERATE,
  UNHEALTHY_FOR_SENSITIVE_GROUPS,
  UNHEALTHY,
  VERY_UNHEALTHY,
  HAZARDOUS
}

AirQualityLevel airQualityIndexToLevel(int index) {
  if (index < 0) {
    return AirQualityLevel.UNKNOWN;
  } else if (index <= 50) {
    return AirQualityLevel.GOOD;
  } else if (index <= 100) {
    return AirQualityLevel.MODERATE;
  } else if (index <= 150) {
    return AirQualityLevel.UNHEALTHY_FOR_SENSITIVE_GROUPS;
  } else if (index <= 200) {
    return AirQualityLevel.UNHEALTHY;
  } else if (index <= 300) {
    return AirQualityLevel.VERY_UNHEALTHY;
  } else {
    return AirQualityLevel.HAZARDOUS;
  }
}

/// A class for storing Air Quality JSON Data fetched from the API.
class AirQualityData {
  late int _airQualityIndex;
  late String _source, _place;
  late double _latitude, _longitude;
  late AirQualityLevel _airQualityLevel;

  AirQualityData(Map<String, dynamic> airQualityJson) {
    _airQualityIndex =
        int.tryParse(airQualityJson['data']['aqi'].toString()) ?? -1;
    _place = airQualityJson['data']['city']['name'].toString();
    _source = airQualityJson['data']['attributions'][0]['name'].toString();
    _latitude =
        double.tryParse(airQualityJson['data']['city']['geo'][0].toString()) ??
            -1.0;
    _longitude =
        double.tryParse(airQualityJson['data']['city']['geo'][1].toString()) ??
            -1.0;

    _airQualityLevel = airQualityIndexToLevel(_airQualityIndex);
  }

  int get airQualityIndex => _airQualityIndex;

  String get place => _place;

  String get source => _source;

  double get latitude => _latitude;

  double get longitude => _longitude;

  AirQualityLevel get airQualityLevel => _airQualityLevel;

  String toString() {
    return '''
    Air Quality Level: ${_airQualityLevel.toString().split('.').last}
    AQI: $_airQualityIndex
    Place Name: $_place
    Source: $_source
    Location: ($_latitude, $_longitude)
    ''';
  }
}

/// Plugin for fetching weather data in JSON.
class AirQuality {
  String _token;
  String _endpoint = 'https://api.waqi.info/feed/';

  AirQuality(this._token);

  /// Returns an [AirQualityData] object given a city name or a weather station ID
  Future<AirQualityData> feedFromCity(String city) async =>
      await _airQualityFromUrl(city);

  /// Returns an [AirQualityData] object given a city name or a weather station ID
  Future<AirQualityData> feedFromStationId(String stationId) async =>
      await _airQualityFromUrl('@$stationId');

  /// Returns an [AirQualityData] object given a latitude and longitude.
  Future<AirQualityData> feedFromGeoLocation(double lat, double lon) async =>
      await _airQualityFromUrl('geo:$lat;$lon');

  /// Returns an [AirQualityData] object given using the IP address.
  Future<AirQualityData> feedFromIP() async => await _airQualityFromUrl('here');

  /// Send API request given a URL
  Future<Map<String, dynamic>?> _requestAirQualityFromURL(
      String keyword) async {
    /// Make url using the keyword
    String url = '$_endpoint/$keyword/?token=$_token';

    /// Send HTTP get response with the url
    http.Response response = await http.get(Uri.parse(url));

    /// Perform error checking on response:
    /// Status code 200 means everything went well
    if (response.statusCode == 200) {
      Map<String, dynamic>? jsonBody = json.decode(response.body);
      return jsonBody;
    }
    throw AirQualityAPIException("OpenWeather API Exception: ${response.body}");
  }

  /// Fetch current weather based on geographical coordinates
  /// Result is JSON.
  /// For API documentation, see: https://openweathermap.org/current
  Future<AirQualityData> _airQualityFromUrl(String url) async {
    Map<String, dynamic>? airQualityJson = await _requestAirQualityFromURL(url);
    return AirQualityData(airQualityJson!);
  }
}
