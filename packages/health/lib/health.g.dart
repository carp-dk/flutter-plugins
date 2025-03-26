// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthDataPoint _$HealthDataPointFromJson(Map<String, dynamic> json) =>
    HealthDataPoint(
      value: HealthValue.fromJson(json['value'] as Map<String, dynamic>),
      type: $enumDecode(_$HealthDataTypeEnumMap, json['type']),
      unit: $enumDecode(_$HealthDataUnitEnumMap, json['unit']),
      dateFrom: DateTime.parse(json['date_from'] as String),
      dateTo: DateTime.parse(json['date_to'] as String),
      sourcePlatform:
          $enumDecode(_$HealthPlatformTypeEnumMap, json['source_platform']),
      sourceDeviceId: json['source_device_id'] as String,
      sourceId: json['source_id'] as String,
      sourceName: json['source_name'] as String,
      isManualEntry: json['is_manual_entry'] as bool? ?? false,
      workoutSummary: json['workout_summary'] == null
          ? null
          : WorkoutSummary.fromJson(
              json['workout_summary'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HealthDataPointToJson(HealthDataPoint instance) {
  final val = <String, dynamic>{
    'value': instance.value,
    'type': _$HealthDataTypeEnumMap[instance.type]!,
    'unit': _$HealthDataUnitEnumMap[instance.unit]!,
    'date_from': instance.dateFrom.toIso8601String(),
    'date_to': instance.dateTo.toIso8601String(),
    'source_platform': _$HealthPlatformTypeEnumMap[instance.sourcePlatform]!,
    'source_device_id': instance.sourceDeviceId,
    'source_id': instance.sourceId,
    'source_name': instance.sourceName,
    'is_manual_entry': instance.isManualEntry,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('workout_summary', instance.workoutSummary);
  return val;
}

const _$HealthDataTypeEnumMap = {
  HealthDataType.ACTIVE_ENERGY_BURNED: 'ACTIVE_ENERGY_BURNED',
  HealthDataType.AUDIOGRAM: 'AUDIOGRAM',
  HealthDataType.BASAL_ENERGY_BURNED: 'BASAL_ENERGY_BURNED',
  HealthDataType.BLOOD_GLUCOSE: 'BLOOD_GLUCOSE',
  HealthDataType.BLOOD_OXYGEN: 'BLOOD_OXYGEN',
  HealthDataType.BLOOD_PRESSURE_DIASTOLIC: 'BLOOD_PRESSURE_DIASTOLIC',
  HealthDataType.BLOOD_PRESSURE_SYSTOLIC: 'BLOOD_PRESSURE_SYSTOLIC',
  HealthDataType.BODY_FAT_PERCENTAGE: 'BODY_FAT_PERCENTAGE',
  HealthDataType.BODY_MASS_INDEX: 'BODY_MASS_INDEX',
  HealthDataType.BODY_TEMPERATURE: 'BODY_TEMPERATURE',
  HealthDataType.BODY_WATER_MASS: 'BODY_WATER_MASS',
  HealthDataType.DIETARY_CARBS_CONSUMED: 'DIETARY_CARBS_CONSUMED',
  HealthDataType.DIETARY_CAFFEINE: 'DIETARY_CAFFEINE',
  HealthDataType.DIETARY_ENERGY_CONSUMED: 'DIETARY_ENERGY_CONSUMED',
  HealthDataType.DIETARY_FATS_CONSUMED: 'DIETARY_FATS_CONSUMED',
  HealthDataType.DIETARY_PROTEIN_CONSUMED: 'DIETARY_PROTEIN_CONSUMED',
  HealthDataType.FORCED_EXPIRATORY_VOLUME: 'FORCED_EXPIRATORY_VOLUME',
  HealthDataType.HEART_RATE: 'HEART_RATE',
  HealthDataType.HEART_RATE_VARIABILITY_SDNN: 'HEART_RATE_VARIABILITY_SDNN',
  HealthDataType.HEIGHT: 'HEIGHT',
  HealthDataType.RESTING_HEART_RATE: 'RESTING_HEART_RATE',
  HealthDataType.RESPIRATORY_RATE: 'RESPIRATORY_RATE',
  HealthDataType.PERIPHERAL_PERFUSION_INDEX: 'PERIPHERAL_PERFUSION_INDEX',
  HealthDataType.STEPS: 'STEPS',
  HealthDataType.WAIST_CIRCUMFERENCE: 'WAIST_CIRCUMFERENCE',
  HealthDataType.WALKING_HEART_RATE: 'WALKING_HEART_RATE',
  HealthDataType.WEIGHT: 'WEIGHT',
  HealthDataType.DISTANCE_WALKING_RUNNING: 'DISTANCE_WALKING_RUNNING',
  HealthDataType.DISTANCE_SWIMMING: 'DISTANCE_SWIMMING',
  HealthDataType.DISTANCE_CYCLING: 'DISTANCE_CYCLING',
  HealthDataType.FLIGHTS_CLIMBED: 'FLIGHTS_CLIMBED',
  HealthDataType.MOVE_MINUTES: 'MOVE_MINUTES',
  HealthDataType.DISTANCE_DELTA: 'DISTANCE_DELTA',
  HealthDataType.MINDFULNESS: 'MINDFULNESS',
  HealthDataType.WATER: 'WATER',
  HealthDataType.SLEEP_IN_BED: 'SLEEP_IN_BED',
  HealthDataType.SLEEP_ASLEEP: 'SLEEP_ASLEEP',
  HealthDataType.SLEEP_ASLEEP_CORE: 'SLEEP_ASLEEP_CORE',
  HealthDataType.SLEEP_ASLEEP_DEEP: 'SLEEP_ASLEEP_DEEP',
  HealthDataType.SLEEP_ASLEEP_REM: 'SLEEP_ASLEEP_REM',
  HealthDataType.SLEEP_AWAKE: 'SLEEP_AWAKE',
  HealthDataType.SLEEP_LIGHT: 'SLEEP_LIGHT',
  HealthDataType.SLEEP_DEEP: 'SLEEP_DEEP',
  HealthDataType.SLEEP_REM: 'SLEEP_REM',
  HealthDataType.SLEEP_OUT_OF_BED: 'SLEEP_OUT_OF_BED',
  HealthDataType.SLEEP_SESSION: 'SLEEP_SESSION',
  HealthDataType.EXERCISE_TIME: 'EXERCISE_TIME',
  HealthDataType.WORKOUT: 'WORKOUT',
  HealthDataType.HEADACHE_NOT_PRESENT: 'HEADACHE_NOT_PRESENT',
  HealthDataType.HEADACHE_MILD: 'HEADACHE_MILD',
  HealthDataType.HEADACHE_MODERATE: 'HEADACHE_MODERATE',
  HealthDataType.HEADACHE_SEVERE: 'HEADACHE_SEVERE',
  HealthDataType.HEADACHE_UNSPECIFIED: 'HEADACHE_UNSPECIFIED',
  HealthDataType.NUTRITION: 'NUTRITION',
  HealthDataType.HIGH_HEART_RATE_EVENT: 'HIGH_HEART_RATE_EVENT',
  HealthDataType.LOW_HEART_RATE_EVENT: 'LOW_HEART_RATE_EVENT',
  HealthDataType.IRREGULAR_HEART_RATE_EVENT: 'IRREGULAR_HEART_RATE_EVENT',
  HealthDataType.ELECTRODERMAL_ACTIVITY: 'ELECTRODERMAL_ACTIVITY',
  HealthDataType.ELECTROCARDIOGRAM: 'ELECTROCARDIOGRAM',
  HealthDataType.TOTAL_CALORIES_BURNED: 'TOTAL_CALORIES_BURNED',
  HealthDataType.TIME_IN_DAYLIGHT: 'TIME_IN_DAYLIGHT',
};

const _$HealthDataUnitEnumMap = {
  HealthDataUnit.GRAM: 'GRAM',
  HealthDataUnit.KILOGRAM: 'KILOGRAM',
  HealthDataUnit.OUNCE: 'OUNCE',
  HealthDataUnit.POUND: 'POUND',
  HealthDataUnit.STONE: 'STONE',
  HealthDataUnit.METER: 'METER',
  HealthDataUnit.INCH: 'INCH',
  HealthDataUnit.FOOT: 'FOOT',
  HealthDataUnit.YARD: 'YARD',
  HealthDataUnit.MILE: 'MILE',
  HealthDataUnit.LITER: 'LITER',
  HealthDataUnit.MILLILITER: 'MILLILITER',
  HealthDataUnit.FLUID_OUNCE_US: 'FLUID_OUNCE_US',
  HealthDataUnit.FLUID_OUNCE_IMPERIAL: 'FLUID_OUNCE_IMPERIAL',
  HealthDataUnit.CUP_US: 'CUP_US',
  HealthDataUnit.CUP_IMPERIAL: 'CUP_IMPERIAL',
  HealthDataUnit.PINT_US: 'PINT_US',
  HealthDataUnit.PINT_IMPERIAL: 'PINT_IMPERIAL',
  HealthDataUnit.PASCAL: 'PASCAL',
  HealthDataUnit.MILLIMETER_OF_MERCURY: 'MILLIMETER_OF_MERCURY',
  HealthDataUnit.INCHES_OF_MERCURY: 'INCHES_OF_MERCURY',
  HealthDataUnit.CENTIMETER_OF_WATER: 'CENTIMETER_OF_WATER',
  HealthDataUnit.ATMOSPHERE: 'ATMOSPHERE',
  HealthDataUnit.DECIBEL_A_WEIGHTED_SOUND_PRESSURE_LEVEL:
      'DECIBEL_A_WEIGHTED_SOUND_PRESSURE_LEVEL',
  HealthDataUnit.SECOND: 'SECOND',
  HealthDataUnit.MILLISECOND: 'MILLISECOND',
  HealthDataUnit.MINUTE: 'MINUTE',
  HealthDataUnit.HOUR: 'HOUR',
  HealthDataUnit.DAY: 'DAY',
  HealthDataUnit.JOULE: 'JOULE',
  HealthDataUnit.KILOCALORIE: 'KILOCALORIE',
  HealthDataUnit.LARGE_CALORIE: 'LARGE_CALORIE',
  HealthDataUnit.SMALL_CALORIE: 'SMALL_CALORIE',
  HealthDataUnit.DEGREE_CELSIUS: 'DEGREE_CELSIUS',
  HealthDataUnit.DEGREE_FAHRENHEIT: 'DEGREE_FAHRENHEIT',
  HealthDataUnit.KELVIN: 'KELVIN',
  HealthDataUnit.DECIBEL_HEARING_LEVEL: 'DECIBEL_HEARING_LEVEL',
  HealthDataUnit.HERTZ: 'HERTZ',
  HealthDataUnit.SIEMEN: 'SIEMEN',
  HealthDataUnit.VOLT: 'VOLT',
  HealthDataUnit.INTERNATIONAL_UNIT: 'INTERNATIONAL_UNIT',
  HealthDataUnit.COUNT: 'COUNT',
  HealthDataUnit.PERCENT: 'PERCENT',
  HealthDataUnit.BEATS_PER_MINUTE: 'BEATS_PER_MINUTE',
  HealthDataUnit.RESPIRATIONS_PER_MINUTE: 'RESPIRATIONS_PER_MINUTE',
  HealthDataUnit.MILLIGRAM_PER_DECILITER: 'MILLIGRAM_PER_DECILITER',
  HealthDataUnit.UNKNOWN_UNIT: 'UNKNOWN_UNIT',
  HealthDataUnit.NO_UNIT: 'NO_UNIT',
};

const _$HealthPlatformTypeEnumMap = {
  HealthPlatformType.appleHealth: 'appleHealth',
  HealthPlatformType.googleFit: 'googleFit',
  HealthPlatformType.googleHealthConnect: 'googleHealthConnect',
};

HealthValue _$HealthValueFromJson(Map<String, dynamic> json) =>
    HealthValue()..$type = json['__type'] as String?;

Map<String, dynamic> _$HealthValueToJson(HealthValue instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('__type', instance.$type);
  return val;
}

NumericHealthValue _$NumericHealthValueFromJson(Map<String, dynamic> json) =>
    NumericHealthValue(
      numericValue: json['numeric_value'] as num,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$NumericHealthValueToJson(NumericHealthValue instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('__type', instance.$type);
  val['numeric_value'] = instance.numericValue;
  return val;
}

AudiogramHealthValue _$AudiogramHealthValueFromJson(
        Map<String, dynamic> json) =>
    AudiogramHealthValue(
      frequencies:
          (json['frequencies'] as List<dynamic>).map((e) => e as num).toList(),
      leftEarSensitivities: (json['left_ear_sensitivities'] as List<dynamic>)
          .map((e) => e as num)
          .toList(),
      rightEarSensitivities: (json['right_ear_sensitivities'] as List<dynamic>)
          .map((e) => e as num)
          .toList(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$AudiogramHealthValueToJson(
    AudiogramHealthValue instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('__type', instance.$type);
  val['frequencies'] = instance.frequencies;
  val['left_ear_sensitivities'] = instance.leftEarSensitivities;
  val['right_ear_sensitivities'] = instance.rightEarSensitivities;
  return val;
}

WorkoutHealthValue _$WorkoutHealthValueFromJson(Map<String, dynamic> json) =>
    WorkoutHealthValue(
      workoutActivityType: $enumDecode(
          _$HealthWorkoutActivityTypeEnumMap, json['workout_activity_type']),
      totalEnergyBurned: json['total_energy_burned'] as int?,
      totalEnergyBurnedUnit: $enumDecodeNullable(
          _$HealthDataUnitEnumMap, json['total_energy_burned_unit']),
      totalDistance: json['total_distance'] as int?,
      totalDistanceUnit: $enumDecodeNullable(
          _$HealthDataUnitEnumMap, json['total_distance_unit']),
      totalSteps: json['total_steps'] as int?,
      totalStepsUnit: $enumDecodeNullable(
          _$HealthDataUnitEnumMap, json['total_steps_unit']),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$WorkoutHealthValueToJson(WorkoutHealthValue instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('__type', instance.$type);
  val['workout_activity_type'] =
      _$HealthWorkoutActivityTypeEnumMap[instance.workoutActivityType]!;
  writeNotNull('total_energy_burned', instance.totalEnergyBurned);
  writeNotNull('total_energy_burned_unit',
      _$HealthDataUnitEnumMap[instance.totalEnergyBurnedUnit]);
  writeNotNull('total_distance', instance.totalDistance);
  writeNotNull('total_distance_unit',
      _$HealthDataUnitEnumMap[instance.totalDistanceUnit]);
  writeNotNull('total_steps', instance.totalSteps);
  writeNotNull(
      'total_steps_unit', _$HealthDataUnitEnumMap[instance.totalStepsUnit]);
  return val;
}

const _$HealthWorkoutActivityTypeEnumMap = {
  HealthWorkoutActivityType.ARCHERY: 'ARCHERY',
  HealthWorkoutActivityType.BADMINTON: 'BADMINTON',
  HealthWorkoutActivityType.BASEBALL: 'BASEBALL',
  HealthWorkoutActivityType.BASKETBALL: 'BASKETBALL',
  HealthWorkoutActivityType.BIKING: 'BIKING',
  HealthWorkoutActivityType.BOXING: 'BOXING',
  HealthWorkoutActivityType.CRICKET: 'CRICKET',
  HealthWorkoutActivityType.CURLING: 'CURLING',
  HealthWorkoutActivityType.ELLIPTICAL: 'ELLIPTICAL',
  HealthWorkoutActivityType.FENCING: 'FENCING',
  HealthWorkoutActivityType.AMERICAN_FOOTBALL: 'AMERICAN_FOOTBALL',
  HealthWorkoutActivityType.AUSTRALIAN_FOOTBALL: 'AUSTRALIAN_FOOTBALL',
  HealthWorkoutActivityType.SOCCER: 'SOCCER',
  HealthWorkoutActivityType.GOLF: 'GOLF',
  HealthWorkoutActivityType.GYMNASTICS: 'GYMNASTICS',
  HealthWorkoutActivityType.HANDBALL: 'HANDBALL',
  HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING:
      'HIGH_INTENSITY_INTERVAL_TRAINING',
  HealthWorkoutActivityType.HIKING: 'HIKING',
  HealthWorkoutActivityType.HOCKEY: 'HOCKEY',
  HealthWorkoutActivityType.SKATING: 'SKATING',
  HealthWorkoutActivityType.JUMP_ROPE: 'JUMP_ROPE',
  HealthWorkoutActivityType.KICKBOXING: 'KICKBOXING',
  HealthWorkoutActivityType.MARTIAL_ARTS: 'MARTIAL_ARTS',
  HealthWorkoutActivityType.PILATES: 'PILATES',
  HealthWorkoutActivityType.RACQUETBALL: 'RACQUETBALL',
  HealthWorkoutActivityType.ROWING: 'ROWING',
  HealthWorkoutActivityType.RUGBY: 'RUGBY',
  HealthWorkoutActivityType.RUNNING: 'RUNNING',
  HealthWorkoutActivityType.SAILING: 'SAILING',
  HealthWorkoutActivityType.CROSS_COUNTRY_SKIING: 'CROSS_COUNTRY_SKIING',
  HealthWorkoutActivityType.DOWNHILL_SKIING: 'DOWNHILL_SKIING',
  HealthWorkoutActivityType.SNOWBOARDING: 'SNOWBOARDING',
  HealthWorkoutActivityType.SOFTBALL: 'SOFTBALL',
  HealthWorkoutActivityType.SQUASH: 'SQUASH',
  HealthWorkoutActivityType.STAIR_CLIMBING: 'STAIR_CLIMBING',
  HealthWorkoutActivityType.SWIMMING: 'SWIMMING',
  HealthWorkoutActivityType.TABLE_TENNIS: 'TABLE_TENNIS',
  HealthWorkoutActivityType.TENNIS: 'TENNIS',
  HealthWorkoutActivityType.VOLLEYBALL: 'VOLLEYBALL',
  HealthWorkoutActivityType.WALKING: 'WALKING',
  HealthWorkoutActivityType.WATER_POLO: 'WATER_POLO',
  HealthWorkoutActivityType.YOGA: 'YOGA',
  HealthWorkoutActivityType.BOWLING: 'BOWLING',
  HealthWorkoutActivityType.CROSS_TRAINING: 'CROSS_TRAINING',
  HealthWorkoutActivityType.TRACK_AND_FIELD: 'TRACK_AND_FIELD',
  HealthWorkoutActivityType.DISC_SPORTS: 'DISC_SPORTS',
  HealthWorkoutActivityType.LACROSSE: 'LACROSSE',
  HealthWorkoutActivityType.PREPARATION_AND_RECOVERY:
      'PREPARATION_AND_RECOVERY',
  HealthWorkoutActivityType.FLEXIBILITY: 'FLEXIBILITY',
  HealthWorkoutActivityType.COOLDOWN: 'COOLDOWN',
  HealthWorkoutActivityType.WHEELCHAIR_WALK_PACE: 'WHEELCHAIR_WALK_PACE',
  HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE: 'WHEELCHAIR_RUN_PACE',
  HealthWorkoutActivityType.HAND_CYCLING: 'HAND_CYCLING',
  HealthWorkoutActivityType.CORE_TRAINING: 'CORE_TRAINING',
  HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING:
      'FUNCTIONAL_STRENGTH_TRAINING',
  HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING:
      'TRADITIONAL_STRENGTH_TRAINING',
  HealthWorkoutActivityType.MIXED_CARDIO: 'MIXED_CARDIO',
  HealthWorkoutActivityType.STAIRS: 'STAIRS',
  HealthWorkoutActivityType.STEP_TRAINING: 'STEP_TRAINING',
  HealthWorkoutActivityType.FITNESS_GAMING: 'FITNESS_GAMING',
  HealthWorkoutActivityType.BARRE: 'BARRE',
  HealthWorkoutActivityType.CARDIO_DANCE: 'CARDIO_DANCE',
  HealthWorkoutActivityType.SOCIAL_DANCE: 'SOCIAL_DANCE',
  HealthWorkoutActivityType.MIND_AND_BODY: 'MIND_AND_BODY',
  HealthWorkoutActivityType.PICKLEBALL: 'PICKLEBALL',
  HealthWorkoutActivityType.CLIMBING: 'CLIMBING',
  HealthWorkoutActivityType.EQUESTRIAN_SPORTS: 'EQUESTRIAN_SPORTS',
  HealthWorkoutActivityType.FISHING: 'FISHING',
  HealthWorkoutActivityType.HUNTING: 'HUNTING',
  HealthWorkoutActivityType.PLAY: 'PLAY',
  HealthWorkoutActivityType.SNOW_SPORTS: 'SNOW_SPORTS',
  HealthWorkoutActivityType.PADDLE_SPORTS: 'PADDLE_SPORTS',
  HealthWorkoutActivityType.SURFING_SPORTS: 'SURFING_SPORTS',
  HealthWorkoutActivityType.WATER_FITNESS: 'WATER_FITNESS',
  HealthWorkoutActivityType.WATER_SPORTS: 'WATER_SPORTS',
  HealthWorkoutActivityType.TAI_CHI: 'TAI_CHI',
  HealthWorkoutActivityType.WRESTLING: 'WRESTLING',
  HealthWorkoutActivityType.AEROBICS: 'AEROBICS',
  HealthWorkoutActivityType.BIATHLON: 'BIATHLON',
  HealthWorkoutActivityType.BIKING_HAND: 'BIKING_HAND',
  HealthWorkoutActivityType.BIKING_MOUNTAIN: 'BIKING_MOUNTAIN',
  HealthWorkoutActivityType.BIKING_ROAD: 'BIKING_ROAD',
  HealthWorkoutActivityType.BIKING_SPINNING: 'BIKING_SPINNING',
  HealthWorkoutActivityType.BIKING_STATIONARY: 'BIKING_STATIONARY',
  HealthWorkoutActivityType.BIKING_UTILITY: 'BIKING_UTILITY',
  HealthWorkoutActivityType.CALISTHENICS: 'CALISTHENICS',
  HealthWorkoutActivityType.CIRCUIT_TRAINING: 'CIRCUIT_TRAINING',
  HealthWorkoutActivityType.CROSS_FIT: 'CROSS_FIT',
  HealthWorkoutActivityType.DANCING: 'DANCING',
  HealthWorkoutActivityType.DIVING: 'DIVING',
  HealthWorkoutActivityType.ELEVATOR: 'ELEVATOR',
  HealthWorkoutActivityType.ERGOMETER: 'ERGOMETER',
  HealthWorkoutActivityType.ESCALATOR: 'ESCALATOR',
  HealthWorkoutActivityType.FRISBEE_DISC: 'FRISBEE_DISC',
  HealthWorkoutActivityType.GARDENING: 'GARDENING',
  HealthWorkoutActivityType.GUIDED_BREATHING: 'GUIDED_BREATHING',
  HealthWorkoutActivityType.HORSEBACK_RIDING: 'HORSEBACK_RIDING',
  HealthWorkoutActivityType.HOUSEWORK: 'HOUSEWORK',
  HealthWorkoutActivityType.INTERVAL_TRAINING: 'INTERVAL_TRAINING',
  HealthWorkoutActivityType.IN_VEHICLE: 'IN_VEHICLE',
  HealthWorkoutActivityType.ICE_SKATING: 'ICE_SKATING',
  HealthWorkoutActivityType.KAYAKING: 'KAYAKING',
  HealthWorkoutActivityType.KETTLEBELL_TRAINING: 'KETTLEBELL_TRAINING',
  HealthWorkoutActivityType.KICK_SCOOTER: 'KICK_SCOOTER',
  HealthWorkoutActivityType.KITE_SURFING: 'KITE_SURFING',
  HealthWorkoutActivityType.MEDITATION: 'MEDITATION',
  HealthWorkoutActivityType.MIXED_MARTIAL_ARTS: 'MIXED_MARTIAL_ARTS',
  HealthWorkoutActivityType.P90X: 'P90X',
  HealthWorkoutActivityType.PARAGLIDING: 'PARAGLIDING',
  HealthWorkoutActivityType.POLO: 'POLO',
  HealthWorkoutActivityType.ROCK_CLIMBING: 'ROCK_CLIMBING',
  HealthWorkoutActivityType.ROWING_MACHINE: 'ROWING_MACHINE',
  HealthWorkoutActivityType.RUNNING_JOGGING: 'RUNNING_JOGGING',
  HealthWorkoutActivityType.RUNNING_SAND: 'RUNNING_SAND',
  HealthWorkoutActivityType.RUNNING_TREADMILL: 'RUNNING_TREADMILL',
  HealthWorkoutActivityType.SCUBA_DIVING: 'SCUBA_DIVING',
  HealthWorkoutActivityType.SKATING_CROSS: 'SKATING_CROSS',
  HealthWorkoutActivityType.SKATING_INDOOR: 'SKATING_INDOOR',
  HealthWorkoutActivityType.SKATING_INLINE: 'SKATING_INLINE',
  HealthWorkoutActivityType.SKIING: 'SKIING',
  HealthWorkoutActivityType.SKIING_BACK_COUNTRY: 'SKIING_BACK_COUNTRY',
  HealthWorkoutActivityType.SKIING_KITE: 'SKIING_KITE',
  HealthWorkoutActivityType.SKIING_ROLLER: 'SKIING_ROLLER',
  HealthWorkoutActivityType.SLEDDING: 'SLEDDING',
  HealthWorkoutActivityType.SNOWMOBILE: 'SNOWMOBILE',
  HealthWorkoutActivityType.SNOWSHOEING: 'SNOWSHOEING',
  HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE: 'STAIR_CLIMBING_MACHINE',
  HealthWorkoutActivityType.STANDUP_PADDLEBOARDING: 'STANDUP_PADDLEBOARDING',
  HealthWorkoutActivityType.STILL: 'STILL',
  HealthWorkoutActivityType.STRENGTH_TRAINING: 'STRENGTH_TRAINING',
  HealthWorkoutActivityType.SURFING: 'SURFING',
  HealthWorkoutActivityType.SWIMMING_OPEN_WATER: 'SWIMMING_OPEN_WATER',
  HealthWorkoutActivityType.SWIMMING_POOL: 'SWIMMING_POOL',
  HealthWorkoutActivityType.TEAM_SPORTS: 'TEAM_SPORTS',
  HealthWorkoutActivityType.TILTING: 'TILTING',
  HealthWorkoutActivityType.VOLLEYBALL_BEACH: 'VOLLEYBALL_BEACH',
  HealthWorkoutActivityType.VOLLEYBALL_INDOOR: 'VOLLEYBALL_INDOOR',
  HealthWorkoutActivityType.WAKEBOARDING: 'WAKEBOARDING',
  HealthWorkoutActivityType.WALKING_FITNESS: 'WALKING_FITNESS',
  HealthWorkoutActivityType.WALKING_NORDIC: 'WALKING_NORDIC',
  HealthWorkoutActivityType.WALKING_STROLLER: 'WALKING_STROLLER',
  HealthWorkoutActivityType.WALKING_TREADMILL: 'WALKING_TREADMILL',
  HealthWorkoutActivityType.WEIGHTLIFTING: 'WEIGHTLIFTING',
  HealthWorkoutActivityType.WHEELCHAIR: 'WHEELCHAIR',
  HealthWorkoutActivityType.WINDSURFING: 'WINDSURFING',
  HealthWorkoutActivityType.ZUMBA: 'ZUMBA',
  HealthWorkoutActivityType.OTHER: 'OTHER',
};

ElectrocardiogramHealthValue _$ElectrocardiogramHealthValueFromJson(
        Map<String, dynamic> json) =>
    ElectrocardiogramHealthValue(
      voltageValues: (json['voltage_values'] as List<dynamic>)
          .map((e) =>
              ElectrocardiogramVoltageValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageHeartRate: json['average_heart_rate'] as num?,
      samplingFrequency: (json['sampling_frequency'] as num?)?.toDouble(),
      classification: $enumDecodeNullable(
          _$ElectrocardiogramClassificationEnumMap, json['classification']),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$ElectrocardiogramHealthValueToJson(
    ElectrocardiogramHealthValue instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('__type', instance.$type);
  val['voltage_values'] = instance.voltageValues;
  writeNotNull('average_heart_rate', instance.averageHeartRate);
  writeNotNull('sampling_frequency', instance.samplingFrequency);
  writeNotNull('classification',
      _$ElectrocardiogramClassificationEnumMap[instance.classification]);
  return val;
}

const _$ElectrocardiogramClassificationEnumMap = {
  ElectrocardiogramClassification.NOT_SET: 'NOT_SET',
  ElectrocardiogramClassification.SINUS_RHYTHM: 'SINUS_RHYTHM',
  ElectrocardiogramClassification.ATRIAL_FIBRILLATION: 'ATRIAL_FIBRILLATION',
  ElectrocardiogramClassification.INCONCLUSIVE_LOW_HEART_RATE:
      'INCONCLUSIVE_LOW_HEART_RATE',
  ElectrocardiogramClassification.INCONCLUSIVE_HIGH_HEART_RATE:
      'INCONCLUSIVE_HIGH_HEART_RATE',
  ElectrocardiogramClassification.INCONCLUSIVE_POOR_READING:
      'INCONCLUSIVE_POOR_READING',
  ElectrocardiogramClassification.INCONCLUSIVE_OTHER: 'INCONCLUSIVE_OTHER',
  ElectrocardiogramClassification.UNRECOGNIZED: 'UNRECOGNIZED',
};

ElectrocardiogramVoltageValue _$ElectrocardiogramVoltageValueFromJson(
        Map<String, dynamic> json) =>
    ElectrocardiogramVoltageValue(
      voltage: json['voltage'] as num,
      timeSinceSampleStart: json['time_since_sample_start'] as num,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$ElectrocardiogramVoltageValueToJson(
    ElectrocardiogramVoltageValue instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('__type', instance.$type);
  val['voltage'] = instance.voltage;
  val['time_since_sample_start'] = instance.timeSinceSampleStart;
  return val;
}

NutritionHealthValue _$NutritionHealthValueFromJson(
        Map<String, dynamic> json) =>
    NutritionHealthValue(
      mealType: json['meal_type'] as String?,
      protein: (json['protein'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      name: json['name'] as String?,
      carbs: (json['carbs'] as num?)?.toDouble(),
      caffeine: (json['caffeine'] as num?)?.toDouble(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$NutritionHealthValueToJson(
    NutritionHealthValue instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('__type', instance.$type);
  writeNotNull('meal_type', instance.mealType);
  writeNotNull('protein', instance.protein);
  writeNotNull('calories', instance.calories);
  writeNotNull('fat', instance.fat);
  writeNotNull('name', instance.name);
  writeNotNull('carbs', instance.carbs);
  writeNotNull('caffeine', instance.caffeine);
  return val;
}

WorkoutSummary _$WorkoutSummaryFromJson(Map<String, dynamic> json) =>
    WorkoutSummary(
      workoutType: json['workout_type'] as String,
      totalDistance: json['total_distance'] as num,
      totalEnergyBurned: json['total_energy_burned'] as num,
      totalSteps: json['total_steps'] as num,
    );

Map<String, dynamic> _$WorkoutSummaryToJson(WorkoutSummary instance) =>
    <String, dynamic>{
      'workout_type': instance.workoutType,
      'total_distance': instance.totalDistance,
      'total_energy_burned': instance.totalEnergyBurned,
      'total_steps': instance.totalSteps,
    };
