library mobility_app;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:carp_background_location/carp_background_location.dart';
import 'package:mobility_features/mobility_features.dart';

part 'stops_page.dart';
part 'moves_page.dart';
part 'places_page.dart';

void main() => runApp(MyApp());

Widget entry(String key, String value, Icon icon) {
  return Container(
      padding: const EdgeInsets.all(2),
      margin: EdgeInsets.all(3),
      child: ListTile(
        leading: icon,
        title: Text(key),
        trailing: Text(value),
      ));
}

String formatDate(DateTime date) => '${date.year}/${date.month}/${date.day}';

String interval(DateTime a, DateTime b) {
  String pad(int x) => '${x.toString().padLeft(2, '0')}';
  return '${pad(a.hour)}:${pad(a.minute)}:${pad(a.second)} - ${pad(b.hour)}:${pad(b.minute)}:${pad(b.second)}';
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

final stopIcon = Icon(Icons.my_location);
final moveIcon = Icon(Icons.directions_walk);
final placeIcon = Icon(Icons.place);
final featuresIcon = Icon(Icons.assessment);
final homeStayIcon = Icon(Icons.home);
final distanceTraveledIcon = Icon(Icons.card_travel);
final entropyIcon = Icon(Icons.equalizer);
final varianceIcon = Icon(Icons.swap_calls);

enum AppState { NO_FEATURES, CALCULATING_FEATURES, FEATURES_READY }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobility Features Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Mobility Features Example'),
    );
  }
}

String dtoToString(LocationDto dto) =>
    '${dto.latitude}, ${dto.longitude} @ ${DateTime.fromMillisecondsSinceEpoch(dto.time ~/ 1)}';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AppState _state = AppState.NO_FEATURES;

  int _currentIndex = 0;

  // Location Streaming
  late Stream<LocationDto> locationStream;
  late StreamSubscription<LocationDto> locationSubscription;

  // Mobility Features stream
  late StreamSubscription<MobilityContext> mobilitySubscription;
  late MobilityContext _mobilityContext;

  @override
  void initState() {
    super.initState();

    // Set up Mobility Features
    MobilityFeatures().stopDuration = Duration(seconds: 20);
    MobilityFeatures().placeRadius = 50.0;
    MobilityFeatures().stopRadius = 5.0;

    // Setup Location Manager
    LocationManager().distanceFilter = 0;
    LocationManager().interval = 1;
    LocationManager().notificationTitle = 'Mobility Features';
    LocationManager().notificationMsg = 'Your geo-location is being tracked';
    streamInit();
  }

  /// Set up streams:
  /// * Location streaming to MobilityContext
  /// * Subscribe to MobilityContext updates
  Future<void> streamInit() async {
    await requestNotificationPermission();
    await requestManageExternalStoragePermission();

    // ask for location permissions, if not already granted
    if (!await isLocationAlwaysGranted()) {
      await requestLocationPermission();
      await askForLocationAlwaysPermission();
    }

    locationStream = LocationManager().locationStream;

    // subscribe to location stream - in case this is needed in the app
    //locationSubscription.cancel();
    locationSubscription = locationStream.listen(onLocationUpdate);

    // start the location service (specific to carp_background_location)
    await LocationManager().start();

    // map from [LocationDto] to [LocationSample]
    Stream<LocationSample> locationSampleStream = locationStream.map(
        (location) => LocationSample(
            GeoLocation(location.latitude, location.longitude),
            DateTime.now()));

    // provide the [MobilityFeatures] instance with the LocationSample stream
    await MobilityFeatures().startListening(locationSampleStream);

    // start listening to incoming MobilityContext objects
    mobilitySubscription =
        await MobilityFeatures().contextStream.listen(onMobilityContext);
  }

  Future<bool> isLocationAlwaysGranted() async {
    bool granted = false;
    try {
      granted = await Permission.locationAlways.isGranted;
    } catch (e) {
      print(e);
    }
    return granted;
  }

  /// Tries to ask for "location always" permissions from the user.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> askForLocationAlwaysPermission() async {
    bool granted = false;
    try {
      granted = await Permission.locationAlways.isGranted;
    } catch (e) {
      print(e);
    }

    if (!granted) {
      granted =
          await Permission.locationAlways.request() == PermissionStatus.granted;
    }

    return granted;
  }

  Future<void> requestLocationPermission() async {
    final result = await Permission.location.request();

    if (result == PermissionStatus.granted) {
      print('GRANTED'); // ignore: avoid_print
    } else {
      print('NOT GRANTED'); // ignore: avoid_print
    }
  }

  Future<void> requestNotificationPermission() async {
    final result = await Permission.notification.request();

    if (result == PermissionStatus.granted) {
      print('NOTIFICATION GRANTED');
    } else {
      print('NOTIFICATION NOT GRANTED');
    }
  }

  Future<void> requestManageExternalStoragePermission() async {
    final result = await Permission.manageExternalStorage.request();

    if (result == PermissionStatus.granted) {
      print('MANAGE_EXTERNAL_STORAGE GRANTED');
    } else {
      print('MANAGE_EXTERNAL_STORAGE NOT GRANTED');
    }
  }

  /// Called whenever location changes.
  void onLocationUpdate(LocationDto dto) {
    print(dtoToString(dto));
  }

  /// Called whenever mobility context changes.
  void onMobilityContext(MobilityContext context) {
    print('Context received: ${context.toJson()}');
    setState(() {
      _state = AppState.FEATURES_READY;
      _mobilityContext = context;
    });
  }

  @override
  void dispose() {
    mobilitySubscription.cancel();
    locationSubscription.cancel();
    super.dispose();
  }

  Widget get featuresOverview {
    return ListView(
      children: <Widget>[
        entry("Stops", "${_mobilityContext.stops.length}", stopIcon),
        entry("Moves", "${_mobilityContext.moves.length}", moveIcon),
        entry("Significant Places",
            "${_mobilityContext.numberOfSignificantPlaces}", placeIcon),
        entry(
            "Home Stay",
            _mobilityContext.homeStay == null || _mobilityContext.homeStay! < 0
                ? "?"
                : "${(_mobilityContext.homeStay! * 100).toStringAsFixed(1)}%",
            homeStayIcon),
        entry(
            "Distance Traveled",
            "${(_mobilityContext.distanceTraveled! / 1000).toStringAsFixed(2)} km",
            distanceTraveledIcon),
        entry(
            "Normalized Entropy",
            "${_mobilityContext.normalizedEntropy?.toStringAsFixed(2)}",
            entropyIcon),
        entry(
            "Location Variance",
            "${(111.133 * _mobilityContext.locationVariance!).toStringAsFixed(5)} km",
            varianceIcon),
      ],
    );
  }

  List<Widget> get contentNoFeatures {
    return [
      Container(
          margin: EdgeInsets.all(25),
          child: Text(
            'Move around to start generating features',
            style: TextStyle(fontSize: 20),
          ))
    ];
  }

  List<Widget> get contentFeaturesReady {
    return [
      Container(
          margin: EdgeInsets.all(25),
          child: Column(children: [
            Text(
              'Statistics for today,',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              '${formatDate(_mobilityContext.date)}',
              style: TextStyle(fontSize: 20, color: Colors.blue),
            ),
          ])),
      Expanded(child: featuresOverview),
    ];
  }

  Widget get content {
    List<Widget> children;
    if (_state == AppState.FEATURES_READY)
      children = contentFeaturesReady;
    else
      children = contentNoFeatures;
    return Column(children: children);
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget get navBar => BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: featuresIcon, label: 'Features'),
          BottomNavigationBarItem(icon: stopIcon, label: 'Stops'),
          BottomNavigationBarItem(icon: placeIcon, label: 'Places'),
          BottomNavigationBarItem(icon: moveIcon, label: 'Moves')
        ],
      );

  @override
  Widget build(BuildContext context) {
    List<Stop> stops = [];
    List<Move> moves = [];
    List<Place> places = [];

    if (_state == AppState.FEATURES_READY) {
      for (var x in _mobilityContext.stops) print(x);
      for (var x in _mobilityContext.moves) {
        print(x);
        print('${x.stopFrom} --> ${x.stopTo}');
      }
      stops = _mobilityContext.stops;
      moves = _mobilityContext.moves;
      places = _mobilityContext.places;
    }

    List<Widget> pages = [
      content,
      StopsPage(stops),
      PlacesPage(places),
      MovesPage(moves),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(widget.title),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: navBar,
    );
  }
}
