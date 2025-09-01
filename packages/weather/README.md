# weather
This package uses the [OpenWeatherMAP API](https://openweathermap.org/) to get the current weather status as well as weather forecasts.

The weather can currently be fetched by providing a geolocation or a city name.

[![pub package](https://img.shields.io/pub/v/weather.svg)](https://pub.dartlang.org/packages/weather)

## Install (Flutter)
Add ```weather``` as a dependency in  `pubspec.yaml`.
For help on adding as a dependency, view the [pubspec documenation](https://flutter.io/using-packages/).

## Permissions
No permissions are needed for this package in isolatation, however for getting the device's geolocation we recommend using the [geolocator](https://pub.dev/packages/geolocator) plugin.

## Usage
First and foremost you need an API key from OpenWeatherMap, which can be acquired for free [here](https://openweathermap.org/price).

Next, an instance of a `WeatherFactory is created using the API key.

```dart
import 'package:weather/weather.dart';

...

WeatherFactory wf = new WeatherFactory("YOUR_API_KEY");
```

Alternatively, you can also specify a language for the weather reports such as Danish

```dart
WeatherFactory wf = new WeatherFactory("YOUR_API_KEY", language: Language.DANISH);
```

For all the supported languages, see the Languages section.

### Current Weather
For specific documentation on the current weather API, see the [OpenWeatherMap weather API docs](https://openweathermap.org/current).

The current weather is queried either through a latitude and longitude or through a city name, i.e.

```dart
double lat = 55.0111;
double lon = 15.0569;
String key = '856822fd8e22db5e1ba48c0e7d69844a';
String cityName = 'Kongens Lyngby';
WeatherFactory wf = WeatherFactory(key);
```

Through geolocation:
```dart
Weather w = await wf.currentWeatherByLocation(lat, lon);
```

Through city name:

```dart
Weather w = await wf.currentWeatherByCityName(cityName);
```

Example output:

```bash
Place Name: Kongens Lyngby [DK] (55.77, 12.5)
Date: 2020-07-13 17:17:34.000
Weather: Clouds, broken clouds
Temp: 17.1 Celsius, Temp (min): 16.7 Celsius, Temp (max): 18.0 Celsius,  Temp (feels like): 13.4 Celsius
Sunrise: 2020-07-13 04:43:53.000, Sunset: 2020-07-13 21:47:15.000
Weather Condition code: 803
```

For a complete list of all the properties of the [Weather](https://pub.dartlang.org/documentation/weather/latest/weather/Weather-class.html) class, check the [documentation](https://pub.dartlang.org/documentation/weather/latest/weather/Weather-class.html)

#### Temperature unit
The [Temperature](https://pub.dartlang.org/documentation/weather/latest/weather/Temperature-class.html) class holds a temperature and can output the temperature in the following units: 
* Celsius
* Fahrenheit
* Kelvin

This can be done as given a `Weather` object `w`
```dart
double celsius = w.temperature.celsius;
double fahrenheit = w.temperature.fahrenheit;
double kelvin = w.temperature.kelvin;
```

### Five-day Weather Forecast
For API documentation on the forecast API, see the [OpenWeatherMap forecast API docs](https://openweathermap.org/forecast5).

The forecast is a 5-day prediction and contains a list of Weather objects with 3 hours between them. 

The forecast can also be fetched via geolocation or city name.

Via geolocation

```dart
List<Weather> forecast = await wf.fiveDayForecastByLocation(lat, lon);
```

Via city name

```dart
List<Weather> forecast = await wf.fiveDayForecastByCityName(cityName);
```

### Exceptions
The following are cases for which an exception will be thrown:

* The provided OpenWeather API key is invalid
* An bad response was given by the API; it may be down.


### Languages
The following languages are supported

* `AFRIKAANS`
* `ALBANIAN`
* `ARABIC`
* `AZERBAIJANI`
* `BULGARIAN`
* `CATALAN`
* `CZECH`
* `DANISH`
* `GERMAN`
* `GREEK`
* `ENGLISH`
* `BASQUE`
* `PERSIAN`
* `FARSI`
* `FINNISH`
* `FRENCH`
* `GALICIAN`
* `HEBREW`
* `HINDI`
* `CROATIAN`
* `HUNGARIAN`
* `INDONESIAN`
* `ITALIAN`
* `JAPANESE`
* `KOREAN`
* `LATVIAN`
* `LITHUANIAN`
* `MACEDONIAN`
* `NORWEGIAN`
* `DUTCH`
* `POLISH`
* `PORTUGUESE`
* `PORTUGUESE_BRAZIL`
* `ROMANIAN`
* `RUSSIAN`
* `SWEDISH`
* `SLOVAK`
* `SLOVENIAN`
* `SPANISH`
* `SERBIAN`
* `THAI`
* `TURKISH`
* `UKRAINIAN`
* `VIETNAMESE`
* `CHINESE_SIMPLIFIED`
* `CHINESE_TRADITIONAL`
* `ZULU`