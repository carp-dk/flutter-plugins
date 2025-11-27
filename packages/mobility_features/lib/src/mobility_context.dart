part of '../mobility_features.dart';

/// Daily mobility context for a day on [date].
///
/// All [stops] and [moves] are on the same [date].
/// The [places] are all places for which the duration on the given [date]
/// is greater than 0.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MobilityContext {
  List<Place>? _significantPlaces;
  HourMatrix? _hourMatrix;
  Place? _homePlace;
  List<Stop>? _stops;
  List<Place>? _places;
  List<Move>? _moves;

  /// Timestamp at which the features were computed
  DateTime? timestamp;

  /// The date of this context.
  DateTime? date;

  /// Number of stops made today.
  int? numberOfStops;

  /// Number of moves made today.
  int? numberOfMoves;

  /// Number of significant places visited today.
  int? numberOfSignificantPlaces;

  /// Location variance today.
  double? locationVariance;

  /// Location entropy.
  ///
  ///  * High entropy: Time is spent evenly among all places
  ///  * Low  entropy: Time is mainly spent at a few of the places
  double? entropy;

  /// Normalized location entropy. A scalar between 0 and 1.
  double? normalizedEntropy;

  /// Home Stay Percentage today. A scalar between 0 and 1.
  /// Returns null if cannot be calculated based on the available data.
  double? homeStay;

  /// Distance traveled today in meters.
  double? distanceTraveled;

  MobilityContext();

  MobilityContext.fromMobility(
    this.date,
    this._stops,
    this._places,
    this._moves,
  ) {
    timestamp = DateTime.now();

    // compute all features
    _significantPlaces =
        _places!.where((p) => p.duration > const Duration(minutes: 3)).toList();
    _hourMatrix = HourMatrix.fromStops(_stops!, _places!.length);
    numberOfSignificantPlaces = _significantPlaces!.length;
    numberOfStops = _stops?.length;
    numberOfMoves = _moves?.length;
    _homePlace = _findHomePlaceToday();
    homeStay = _calculateHomeStay();
    locationVariance = _calculateLocationVariance();
    entropy = _calculateEntropy();
    normalizedEntropy = _calculateNormalizedEntropy();
    distanceTraveled = _calculateDistanceTraveled();
  }

  /// Stops today.
  List<Stop>? get stops => _stops;

  /// Places today.
  List<Place>? get places => _places;

  /// Moves today.
  List<Move>? get moves => _moves;

  /// The place used as 'home'.
  /// Returns null if home cannot be found from the available data.
  Place? get homePlace => _homePlace;

  /// All significant places, i.e. places with a minimum stay duration.
  List<Place>? get significantPlaces => _significantPlaces;

  double? _calculateHomeStay() {
    if (_stops == null) return null;
    if (_stops!.isEmpty) return null;

    // Latest known sample time
    final latestTime = _stops!.last.departure;

    // Total time elapsed from midnight until the last stop
    int totalTime = latestTime.millisecondsSinceEpoch -
        latestTime.midnight.millisecondsSinceEpoch;

    // Find todays home id, if no home exists today return null
    if (_hourMatrix!.homePlaceId == -1) return null;

    int homeTime = _stops!
        .where((s) => s.placeId == _hourMatrix!.homePlaceId)
        .map((s) => s.duration.inMilliseconds)
        .fold(0, (a, b) => a + b);

    return homeTime.toDouble() / totalTime.toDouble();
  }

  Place? _findHomePlaceToday() => (_hourMatrix!.homePlaceId == -1)
      ? null
      : _places!.where((p) => p.id == _hourMatrix!.homePlaceId).first;

  double? _calculateLocationVariance() {
    // Require at least 2 observations
    if (_stops!.length < 2) return 0.0;

    double latStd = Stats.fromData(_stops!.map((s) => (s.geoLocation.latitude)))
        .sampleValues
        .standardDeviation;

    double lonStd =
        Stats.fromData(_stops!.map((s) => (s.geoLocation.longitude)))
            .sampleValues
            .standardDeviation;
    return log(latStd * latStd + lonStd * lonStd + 1);
  }

  double? _calculateEntropy() {
    // if no places were visited return null
    // else - the Entropy is zero when one outcome is certain to occur
    if (_places!.isEmpty) {
      return null;
    } else if (_places!.length == 1) {
      return 0.0;
    }

    // calculate time spent at different places
    List<Duration> durations =
        _places!.map((p) => p.durationForDate(date)).toList();

    Duration totalTimeSpent = durations.fold(const Duration(), (a, b) => a + b);

    List<double> distribution = durations
        .map((d) => (d.inMilliseconds.toDouble() /
            totalTimeSpent.inMilliseconds.toDouble()))
        .toList();

    return -distribution.map((p) => p * log(p)).reduce((a, b) => (a + b));
  }

  double _calculateNormalizedEntropy() =>
      (_places!.length == 1) ? 0.0 : entropy! / log(_places!.length);

  double _calculateDistanceTraveled() =>
      _moves!.map((m) => (m.distance)).fold(0.0, (a, b) => a + b!);

  factory MobilityContext.fromJson(Map<String, dynamic> json) =>
      _$MobilityContextFromJson(json);
  Map<String, dynamic> toJson() => _$MobilityContextToJson(this);
}

//  /// Routine index (overlap) calculation
//  double _calculateRoutineIndex() {
//    /// We require at least 2 days to compute the routine index
//    if (contexts.isEmpty) return -1.0;
//
//    /// Compute the HourMatrix for each context that is older
//    List<_HourMatrix> matrices = contexts
//        .where((c) => c.date.isBefore(this.date))
//        .map((c) => c._hourMatrix)
//        .toList();
//
//    if (matrices.isEmpty) return -1.0;
//
//    /// Compute the 'average day' from the matrices
//    _HourMatrix routine = _HourMatrix.routineMatrix(matrices);
//
//    /// Compute the overlap between the 'average day' and today
//    return _hourMatrix.computeOverlap(routine);
//  }
