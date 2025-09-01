# CARP Flutter plugins

This repo contains the source code for Flutter first-party plugins developed by developers at the [Copenhagen Research Platform (CARP)](http://www.carp.dk/) at The Technical University of Denmark.
Check the `packages` directory for all plugins.

Flutter plugins enable access to platform-specific APIs using a platform channel. 
For more information about plugins and how to use them, see
[https://flutter.io/platform-plugins/](https://flutter.io/platform-plugins/).

## Plugins
These are the available plugins in this repository.

| Plugin | Description | Android | iOS |    http://pub.dev/    | 
|--------|-------------|:-------:|:---:|:---------:|
| [screen_state](./packages/screen_state) | Track screen state changes | ✔️ | ✔️ | [![pub package](https://img.shields.io/pub/v/screen_state.svg)](https://pub.dartlang.org/packages/screen_state) |
| [light](./packages/light) | Track light sensor readings | ✔️ | ❌ |  [![pub package](https://img.shields.io/pub/v/light.svg)](https://pub.dartlang.org/packages/light) |
| [pedometer](./packages/pedometer) | Track step count |  ✔️ | ✔️ | [![pub package](https://img.shields.io/pub/v/pedometer.svg)](https://pub.dartlang.org/packages/pedometer) |
| [noise_meter](./packages/noise_meter) | Read noise level in Decibel | ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/noise_meter.svg)](https://pub.dartlang.org/packages/noise_meter) |
| [app_usage](./packages/app_usage) | Track usage of all applications on phone. | ✔️ | ❌  | [![pub package](https://img.shields.io/pub/v/app_usage.svg)](https://pub.dartlang.org/packages/app_usage) |
| [weather](./packages/weather) | Get current weather, as well as forecasting using the OpenWeatherMap API. | ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/weather.svg)](https://pub.dartlang.org/packages/weather) |
| [air_quality](./packages/air_quality) | Get the air quality index using the WAQI API. | ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/air_quality.svg)](https://pub.dartlang.org/packages/air_quality) |
| [notifications](./packages/notifications) | Track device notifications. | ✔️ | ❌  | [![pub package](https://img.shields.io/pub/v/notifications.svg)](https://pub.dartlang.org/packages/notifications) |
| [movisens_flutter](./packages/movisens_flutter) | Movisens sensor communication. | ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/movisens_flutter.svg)](https://pub.dartlang.org/packages/movisens_flutter) |
| [esense_flutter](./packages/esense_flutter) | eSense ear sensor plugin. | ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/esense_flutter.svg)](https://pub.dartlang.org/packages/esense_flutter) |
| [health](./packages/health) | Apple HealthKit and Google Fit interface plugin. | ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/health.svg)](https://pub.dartlang.org/packages/health) |
| [activity_recognition](./packages/activity_recognition_flutter) | Activity Recognition | ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/activity_recognition_flutter.svg)](https://pub.dartlang.org/packages/activity_recognition_flutter) |
| [audio_streamer](./packages/audio_streamer) | Stream audio as PCM from mic| ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/audio_streamer.svg)](https://pub.dartlang.org/packages/audio_streamer) |
| [mobility_features](./packages/mobility_features) | Compute daily mobility features from location data | ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/mobility_features.svg)](https://pub.dartlang.org/packages/mobility_features) |
| [carp_background_location](./packages/carp_background_location) | Track location, even when app is in the background | ✔️ | ✔️  | [![pub package](https://img.shields.io/pub/v/carp_background_location.svg)](https://pub.dartlang.org/packages/carp_background_location) |
| [flutter_foreground_service](./packages/flutter_foreground_service) | Foreground service for Android | ✔️ | ❌  | [![pub package](https://img.shields.io/pub/v/flutter_foreground_service.svg)](https://pub.dartlang.org/packages/flutter_foreground_service) |

## Issues

Please check existing issues and file any new issues, bugs, or feature requests in the [flutter-plugin issue list](https://github.com/cph-cachet/flutter-plugins/issues).

## Contributing

As part of the open-source Flutter ecosystem, we would welcome any help in maintaining and enhancing these plugins. 
We (i.e., CACHET) have limited resources for maintaining these plugins and we rely on **your** help in this.
We welcome any contribution -- from small error corrections in the documentation, to bug fixes, to large features enhacements, or even new features in a plugin.
If you wish to contribute to any of the plugins in this repo,
please review our [contribution guide](https://github.com/cph-cachet/flutter-plugins/CONTRIBUTING.md),
and send a [pull request](https://github.com/cph-cachet/flutter-plugins/pulls).


In general, if you wish to contribute a new plugin to the Flutter ecosystem, please
see the documentation for [developing packages](https://flutter.io/developing-packages/) and
[platform channels](https://flutter.io/platform-channels/). You can store
your plugin source code in any GitHub repository (the present repo is only
intended for plugins developed by the core CARP team). Once your plugin
is ready you can [publish](https://flutter.io/developing-packages/#publish)
to the [pub repository](https://pub.dartlang.org/).

