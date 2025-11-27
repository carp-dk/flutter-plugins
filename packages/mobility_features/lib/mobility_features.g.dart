// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobility_features.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MobilityContext _$MobilityContextFromJson(Map<String, dynamic> json) =>
    MobilityContext()
      ..timestamp = json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String)
      ..date = json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String)
      ..numberOfStops = (json['numberOfStops'] as num?)?.toInt()
      ..numberOfMoves = (json['numberOfMoves'] as num?)?.toInt()
      ..numberOfSignificantPlaces = (json['numberOfSignificantPlaces'] as num?)
          ?.toInt()
      ..locationVariance = (json['locationVariance'] as num?)?.toDouble()
      ..entropy = (json['entropy'] as num?)?.toDouble()
      ..normalizedEntropy = (json['normalizedEntropy'] as num?)?.toDouble()
      ..homeStay = (json['homeStay'] as num?)?.toDouble()
      ..distanceTraveled = (json['distanceTraveled'] as num?)?.toDouble();

Map<String, dynamic> _$MobilityContextToJson(MobilityContext instance) =>
    <String, dynamic>{
      'timestamp': ?instance.timestamp?.toIso8601String(),
      'date': ?instance.date?.toIso8601String(),
      'numberOfStops': ?instance.numberOfStops,
      'numberOfMoves': ?instance.numberOfMoves,
      'numberOfSignificantPlaces': ?instance.numberOfSignificantPlaces,
      'locationVariance': ?instance.locationVariance,
      'entropy': ?instance.entropy,
      'normalizedEntropy': ?instance.normalizedEntropy,
      'homeStay': ?instance.homeStay,
      'distanceTraveled': ?instance.distanceTraveled,
    };

GeoLocation _$GeoLocationFromJson(Map<String, dynamic> json) => GeoLocation(
  (json['latitude'] as num).toDouble(),
  (json['longitude'] as num).toDouble(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$GeoLocationToJson(GeoLocation instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

LocationSample _$LocationSampleFromJson(Map<String, dynamic> json) =>
    LocationSample(
      GeoLocation.fromJson(json['geoLocation'] as Map<String, dynamic>),
      DateTime.parse(json['dateTime'] as String),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$LocationSampleToJson(LocationSample instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'dateTime': instance.dateTime.toIso8601String(),
      'geoLocation': instance.geoLocation.toJson(),
    };

Stop _$StopFromJson(Map<String, dynamic> json) => Stop(
  GeoLocation.fromJson(json['geoLocation'] as Map<String, dynamic>),
  DateTime.parse(json['arrival'] as String),
  DateTime.parse(json['departure'] as String),
  (json['placeId'] as num?)?.toInt() ?? -1,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$StopToJson(Stop instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'geoLocation': instance.geoLocation.toJson(),
  'placeId': instance.placeId,
  'arrival': instance.arrival.toIso8601String(),
  'departure': instance.departure.toIso8601String(),
};

Place _$PlaceFromJson(Map<String, dynamic> json) => Place(
  (json['id'] as num).toInt(),
  (json['stops'] as List<dynamic>)
      .map((e) => Stop.fromJson(e as Map<String, dynamic>))
      .toList(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$PlaceToJson(Place instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'id': instance.id,
  'stops': instance.stops.map((e) => e.toJson()).toList(),
};

Move _$MoveFromJson(Map<String, dynamic> json) => Move(
  Stop.fromJson(json['stopFrom'] as Map<String, dynamic>),
  Stop.fromJson(json['stopTo'] as Map<String, dynamic>),
  (json['distance'] as num?)?.toDouble(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MoveToJson(Move instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'stopFrom': instance.stopFrom.toJson(),
  'stopTo': instance.stopTo.toJson(),
  'distance': ?instance.distance,
};
