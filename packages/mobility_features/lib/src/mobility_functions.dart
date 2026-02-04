part of '../mobility_features.dart';

/// Finds the places by clustering stops with the DBSCAN algorithm
List<Place> _findPlaces(List<Stop> stops, {double placeRadius = 50.0}) {
  List<Place> places = [];

  DBSCAN dbscan = DBSCAN(
      epsilon: placeRadius, minPoints: 1, distanceMeasure: Distance.fromList);

  /// Extract gps coordinates from stops
  List<List<double?>> stopCoordinates = stops
      .map((s) => ([s.geoLocation.latitude, s.geoLocation.longitude]))
      .toList();

  /// Run DBSCAN on stops
  dbscan.run(stopCoordinates as List<List<double>>);

  /// Extract labels for each stop, each label being a cluster
  /// Filter out stops labelled as noise (where label is -1)
  Set<int> clusterLabels = dbscan.label!.where((l) => (l != -1)).toSet();

  for (int label in clusterLabels) {
    /// Get indices of all stops with the current cluster label
    List<int> indices =
        stops.asMap().keys.where((i) => (dbscan.label![i] == label)).toList();

    /// For each index, get the corresponding stop
    List<Stop> stopsForPlace = indices.map((i) => (stops[i])).toList();

    /// Add place to the list
    Place p = Place(label, stopsForPlace);
    places.add(p);

    /// Set placeId field for the stops belonging to this place
    for (var s in stopsForPlace) {
      s.placeId = p.id;
    }
  }
  return places;
}

List<Move> _findMoves(List<Stop> stops, List<LocationSample> samples) {
  Stop? previous;
  List<Move> moves = [];

  for (Stop current in stops) {
    if (previous != null) {
      final path = samples
          .where((s) =>
              previous!.dateTime.leq(s.dateTime) &&
              previous.dateTime.geq(s.dateTime))
          .toList();
      Move m = Move.fromPath(previous, current, path);
      moves.add(m);
    }
    previous = current;
  }
  return moves;
}

GeoLocation _computeCentroid(List<GeoSpatial> data) {
  double lat =
      Stats.fromData(data.map((d) => (d.geoLocation.latitude)).toList()).mean;
  double lon =
      Stats.fromData(data.map((d) => (d.geoLocation.longitude)).toList()).mean;

  return GeoLocation(lat, lon);
}

/// Find the stops in a sequence of gps data points
//List<Stop> _findStops(List<LocationSample> data,
//    {double stopRadius = 25.0,
//    Duration stopDuration = const Duration(minutes: 3)}) {
//  if (data.isEmpty) return [];
//
//  List<Stop> stops = [];
//  int n = data.length;
//
//  /// Go through all the location samples, i.e from index [0...n-1]
//  int start = 0;
//  while (start < n) {
//    int end = start + 1;
//    List<LocationSample> subset = data.sublist(start, end);
//    GeoLocation centroid = _computeCentroid(subset);
//
//    /// Expand cluster until either all samples have been considered,
//    /// or the current sample lies outside the radius.
//    while (
//        end < n && Distance.fromGeospatial(centroid, data[end]) <= stopRadius) {
//      end += 1;
//      subset = data.sublist(start, end);
//      centroid = _computeCentroid(subset);
//    }
//    Stop s = Stop._fromLocationSamples(subset);
//    stops.add(s);
//
//    /// Update the start index, such that we no longer look at
//    /// the previously considered data samples
//    start = end;
//  }
//
//  /// Filter out stops which are shorter than the min. duration
//  stops = stops.where((s) => (s.duration >= stopDuration)).toList();
//
//  return stops;
//}
