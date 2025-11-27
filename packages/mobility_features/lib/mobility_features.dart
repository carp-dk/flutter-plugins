library;

import 'dart:async';
import 'dart:math';
import 'dart:core';
import 'dart:convert';
import 'dart:io';

import 'package:stats/stats.dart';
import 'package:path_provider/path_provider.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:simple_cluster/simple_cluster.dart';
import 'package:carp_serializable/carp_serializable.dart';

part 'src/mobility_context.dart';
part 'src/domain.dart';
part 'src/util.dart';
part 'src/mobility_functions.dart';
part 'src/serializer.dart';

part 'mobility_features.g.dart';

/// Main entry for configuring and listening for mobility features.
/// Used as a singleton `MobilityFeatures()`.
class MobilityFeatures {
  static final MobilityFeatures _instance = MobilityFeatures._();

  double _stopRadius = 5, _placeRadius = 50;
  Duration _stopDuration = const Duration(seconds: 20);

  final _streamController = StreamController<MobilityContext>.broadcast();
  StreamSubscription<LocationSample>? _subscription;
  MobilitySerializer<LocationSample>? _serializerSamples;
  late MobilitySerializer<Stop> _serializerStops;
  late MobilitySerializer<Move> _serializerMoves;
  List<Stop> _stops = [];
  List<Move> _moves = [];
  List<Place> _places = [];
  List<LocationSample> _cluster = [];
  final List<LocationSample> _buffer = [], _samples = [];
  int _saveEvery = 10;
  bool debug = false;

  void _print(dynamic x) {
    if (debug) {
      print(x);
    }
  }

  // Private constructor
  MobilityFeatures._() {
    FromJsonFactory().registerAll([
      GeoLocation(0, 0),
      LocationSample(GeoLocation(0, 0), DateTime.now()),
      Stop(GeoLocation(0, 0), DateTime.now(), DateTime.now()),
      Place(0, []),
      Move(
        Stop(GeoLocation(0, 0), DateTime.now(), DateTime.now()),
        Stop(GeoLocation(0, 0), DateTime.now(), DateTime.now()),
      ),
    ]);
  }

  /// Singleton instance of MobilityFeatures.
  factory MobilityFeatures() => _instance;

  /// A stream of generated mobility context objects.
  Stream<MobilityContext> get contextStream => _streamController.stream;

  /// Start listening to the [stream] of [LocationSample] updates.
  /// This will start calculating [MobilityContext] instances, which will be
  /// delivered on the [contextStream] stream.
  ///
  /// Use [stopListening] to stop listening to the location stream and hence stop
  /// generating mobility context objects.
  Future<void> startListening(Stream<LocationSample> stream) async {
    await _handleInit();

    if (_subscription != null) {
      await _subscription!.cancel();
    }
    _subscription = stream.listen(_onData);
  }

  Future<void> _handleInit() async {
    _serializerSamples = _serializerSamples =
        MobilitySerializer<LocationSample>();
    _serializerStops = MobilitySerializer<Stop>();
    _serializerMoves = MobilitySerializer<Move>();

    _stops = (await _serializerStops.load() as List<Stop>);
    _moves = (await _serializerMoves.load() as List<Move>);
    _cluster = (await _serializerSamples!.load() as List<LocationSample>);
    _stops = uniqueElements(_stops) as List<Stop>;
    _moves = uniqueElements(_moves) as List<Move>;

    if (_cluster.isNotEmpty) {
      _print('Loaded ${_cluster.length} location samples from disk');
    }
    if (_stops.isNotEmpty) {
      _print('Loaded ${_stops.length} stops from disk');
    }
    if (_moves.isNotEmpty) {
      _print('Loaded ${_moves.length} moves from disk');
    }

    if (_stops.isNotEmpty) {
      /// Only keeps stops and moves from the last known date
      DateTime date = _stops.last.dateTime.midnight;
      _stops = _getElementsForDate(_stops, date) as List<Stop>;
      _moves = _getElementsForDate(_moves, date) as List<Move>;
      _places = _findPlaces(_stops, placeRadius: _placeRadius);

      // Compute features
      MobilityContext context = MobilityContext.fromMobility(
        date,
        _stops,
        _places,
        _moves,
      );
      _streamController.add(context);
    }
  }

  /// Cancel the [StreamSubscription] and stop listening.
  Future<void> stopListening() async {
    if (_subscription != null) {
      await _subscription!.cancel();
    }
  }

  void _adjustSaveRate() {
    final now = DateTime.now();

    // If night hours, increase saving rate
    if (22 <= now.hour && 8 <= now.hour) {
      _saveEvery = 1;
    }
  }

  /// Call-back method for handling incoming [LocationSample]s
  void _onData(LocationSample sample) {
    _samples.add(sample);
    _adjustSaveRate();

    // If previous samples exist, check if we should compute anything
    if (_cluster.isNotEmpty) {
      // If previous sample was on a different date, reset everything
      if (_cluster.last.dateTime.midnight != sample.dateTime.midnight) {
        _createStopAndResetCluster();
        _clearEverything();
      }
      // If previous sample was today
      else {
        // Compute median location of the collected samples
        GeoLocation centroid = _computeCentroid(_cluster);

        // If the new data point is far away from cluster, make stop
        if (Distance.fromGeoSpatial(centroid, sample) > _stopRadius) {
          _createStopAndResetCluster();
        }
      }
    }
    _addToBuffer(sample);
    _cluster.add(sample);
  }

  void _clearEverything() {
    _print('cleared');
    _serializerStops.clear();
    _serializerMoves.clear();
    _stops.clear();
    _moves.clear();
    _places.clear();
    _cluster.clear();
    _buffer.clear();
  }

  /// Save a sample to the buffer and store samples on disk if buffer overflows
  void _addToBuffer(LocationSample sample) {
    _buffer.add(sample);
    if (_buffer.length >= _saveEvery) {
      _serializerSamples!.append(_buffer);
      _print('Stored buffer to disk');
      _buffer.clear();
    }
  }

  /// Converts the cluster into a stop, i.e. closing the cluster
  void _createStopAndResetCluster() {
    Stop s = Stop.fromLocationSamples(_cluster);

    // If the stop is too short, it is discarded
    // Otherwise compute a context and send it via the stream
    if (s.duration > _stopDuration) {
      _print('----> Stop found: $s');
      Stop? stopPrev = _stops.isNotEmpty ? _stops.last : null;

      _stops.add(s);

      // Find places
      _places = _findPlaces(_stops);

      // Merge stops and recompute places
      _stops = _mergeStops(_stops);
      _places = _findPlaces(_stops);

      // Store to disk
      _serializerStops.clear();
      _serializerStops.append(_stops);

      // Extract date
      DateTime date = _cluster.last.dateTime.midnight;

      if (stopPrev != null) {
        _moves = _findMoves(_stops, _samples);
        _serializerMoves.clear();
        _serializerMoves.append(_moves);
      }

      // Compute features
      MobilityContext context = MobilityContext.fromMobility(
        date,
        _stops,
        _places,
        _moves,
      );
      _streamController.add(context);
    }

    // Reset samples etc
    _cluster.clear();
    _serializerSamples!.clear();
    _buffer.clear();
  }

  /// Configure the stop-duration for the stop algorithm
  set stopDuration(Duration value) {
    _stopDuration = value;
  }

  /// Configure the stop-radius for the stop algorithm
  set stopRadius(double value) {
    _stopRadius = value;
  }

  /// Configure the stop-radius for the place algorithm
  set placeRadius(double value) => _placeRadius = value;

  Future<MobilitySerializer<LocationSample>>
  get _locationSampleSerializer async {
    _serializerSamples ??= MobilitySerializer<LocationSample>();
    return _serializerSamples!;
  }

  Future<void> saveSamples(List<LocationSample> samples) async {
    final serializer = await _locationSampleSerializer;
    serializer.append(samples);
  }

  Future<List<LocationSample>> loadSamples() async {
    final serializer = await _locationSampleSerializer;
    return (await serializer.load() as List<LocationSample>);
  }

  static List<Timestamped> _getElementsForDate(
    List<Timestamped> elements,
    DateTime date,
  ) {
    return elements.where((e) => e.dateTime.midnight == date).toList();
  }

  static List<Timestamped> uniqueElements(List<Timestamped> elements) {
    List<int> seen = [];

    elements.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return elements.where((e) {
      int ms = e.dateTime.millisecondsSinceEpoch;
      if (!seen.contains(ms)) {
        seen.add(ms);
        return true;
      }
      return false;
    }).toList();
  }
}
