part of '../health.dart';

/// An abstract class for health values.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HealthValue extends Serializable {
  HealthValue();

  @override
  Function get fromJsonFunction => _$HealthValueFromJson;
  factory HealthValue.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<HealthValue>(json);
  @override
  Map<String, dynamic> toJson() => _$HealthValueToJson(this);
}

/// A numerical value from Apple HealthKit or Google Health Connect
/// such as integer or double. E.g. 1, 2.9, -3
///
/// Parameters:
/// * [numericValue] - a [num] value for the [HealthDataPoint]
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class NumericHealthValue extends HealthValue {
  /// A [num] value for the [HealthDataPoint].
  num numericValue;

  NumericHealthValue({required this.numericValue});

  /// Create a [NumericHealthValue] based on a health data point from native data format.
  factory NumericHealthValue.fromHealthDataPoint(dynamic dataPoint) =>
      NumericHealthValue(numericValue: dataPoint['value'] as num? ?? 0);

  @override
  String toString() => '$runtimeType - numericValue: $numericValue';

  @override
  Function get fromJsonFunction => _$NumericHealthValueFromJson;
  factory NumericHealthValue.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<NumericHealthValue>(json);
  @override
  Map<String, dynamic> toJson() => _$NumericHealthValueToJson(this);

  @override
  bool operator ==(Object other) =>
      other is NumericHealthValue && numericValue == other.numericValue;

  @override
  int get hashCode => numericValue.hashCode;
}

/// A [HealthValue] object for audiograms
///
/// Parameters:
/// * [frequencies] - array of frequencies of the test
/// * [leftEarSensitivities] threshold in decibel for the left ear
/// * [rightEarSensitivities] threshold in decibel for the left ear
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AudiogramHealthValue extends HealthValue {
  /// Array of frequencies of the test.
  List<num> frequencies;

  /// Threshold in decibel for the left ear.
  List<num> leftEarSensitivities;

  /// Threshold in decibel for the right ear.
  List<num> rightEarSensitivities;

  AudiogramHealthValue({
    required this.frequencies,
    required this.leftEarSensitivities,
    required this.rightEarSensitivities,
  });

  /// Create a [AudiogramHealthValue] based on a health data point from native data format.
  factory AudiogramHealthValue.fromHealthDataPoint(dynamic dataPoint) =>
      AudiogramHealthValue(
          frequencies: List<num>.from(dataPoint['frequencies'] as List),
          leftEarSensitivities:
              List<num>.from(dataPoint['leftEarSensitivities'] as List),
          rightEarSensitivities:
              List<num>.from(dataPoint['rightEarSensitivities'] as List));

  @override
  String toString() => """$runtimeType - frequencies: ${frequencies.toString()},
    left ear sensitivities: ${leftEarSensitivities.toString()},
    right ear sensitivities: ${rightEarSensitivities.toString()}""";

  @override
  Function get fromJsonFunction => _$AudiogramHealthValueFromJson;
  factory AudiogramHealthValue.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AudiogramHealthValue>(json);
  @override
  Map<String, dynamic> toJson() => _$AudiogramHealthValueToJson(this);

  @override
  bool operator ==(Object other) =>
      other is AudiogramHealthValue &&
      listEquals(frequencies, other.frequencies) &&
      listEquals(leftEarSensitivities, other.leftEarSensitivities) &&
      listEquals(rightEarSensitivities, other.rightEarSensitivities);

  @override
  int get hashCode =>
      Object.hash(frequencies, leftEarSensitivities, rightEarSensitivities);
}

/// A [HealthValue] object for workouts
///
/// Parameters:
/// * [workoutActivityType] - the type of workout
/// * [totalEnergyBurned] - the total energy burned during the workout
/// * [totalEnergyBurnedUnit] - the unit of the total energy burned
/// * [totalDistance] - the total distance of the workout
/// * [totalDistanceUnit] - the unit of the total distance
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WorkoutHealthValue extends HealthValue {
  /// The type of the workout.
  HealthWorkoutActivityType workoutActivityType;

  /// The total energy burned during the workout.
  /// Might not be available for all workouts.
  int? totalEnergyBurned;

  /// The unit of the total energy burned during the workout.
  /// Might not be available for all workouts.
  HealthDataUnit? totalEnergyBurnedUnit;

  /// The total distance covered during the workout.
  /// Might not be available for all workouts.
  int? totalDistance;

  /// The unit of the total distance covered during the workout.
  /// Might not be available for all workouts.
  HealthDataUnit? totalDistanceUnit;

  /// The total steps covered during the workout.
  /// Might not be available for all workouts.
  int? totalSteps;

  /// The unit of the total steps covered during the workout.
  /// Might not be available for all workouts.
  HealthDataUnit? totalStepsUnit;

  WorkoutHealthValue(
      {required this.workoutActivityType,
      this.totalEnergyBurned,
      this.totalEnergyBurnedUnit,
      this.totalDistance,
      this.totalDistanceUnit,
      this.totalSteps,
      this.totalStepsUnit});

  /// Create a [WorkoutHealthValue] based on a health data point from native data format.
  factory WorkoutHealthValue.fromHealthDataPoint(dynamic dataPoint) =>
      WorkoutHealthValue(
          workoutActivityType: HealthWorkoutActivityType.values.firstWhere(
            (element) => element.name == dataPoint['workoutActivityType'],
            orElse: () => HealthWorkoutActivityType.OTHER,
          ),
          totalEnergyBurned: dataPoint['totalEnergyBurned'] != null
              ? (dataPoint['totalEnergyBurned'] as num).toInt()
              : null,
          totalEnergyBurnedUnit: dataPoint['totalEnergyBurnedUnit'] != null
              ? HealthDataUnit.values.firstWhere((element) =>
                  element.name == dataPoint['totalEnergyBurnedUnit'])
              : null,
          totalDistance: dataPoint['totalDistance'] != null
              ? (dataPoint['totalDistance'] as num).toInt()
              : null,
          totalDistanceUnit: dataPoint['totalDistanceUnit'] != null
              ? HealthDataUnit.values.firstWhere(
                  (element) => element.name == dataPoint['totalDistanceUnit'])
              : null,
          totalSteps: dataPoint['totalSteps'] != null
              ? (dataPoint['totalSteps'] as num).toInt()
              : null,
          totalStepsUnit: dataPoint['totalStepsUnit'] != null
              ? HealthDataUnit.values.firstWhere(
                  (element) => element.name == dataPoint['totalStepsUnit'])
              : null);

  @override
  Function get fromJsonFunction => _$WorkoutHealthValueFromJson;
  factory WorkoutHealthValue.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<WorkoutHealthValue>(json);
  @override
  Map<String, dynamic> toJson() => _$WorkoutHealthValueToJson(this);

  @override
  String toString() =>
      """$runtimeType - workoutActivityType: ${workoutActivityType.name},
           totalEnergyBurned: $totalEnergyBurned,
           totalEnergyBurnedUnit: ${totalEnergyBurnedUnit?.name},
           totalDistance: $totalDistance,
           totalDistanceUnit: ${totalDistanceUnit?.name}
           totalSteps: $totalSteps,
           totalStepsUnit: ${totalStepsUnit?.name}""";

  @override
  bool operator ==(Object other) =>
      other is WorkoutHealthValue &&
      workoutActivityType == other.workoutActivityType &&
      totalEnergyBurned == other.totalEnergyBurned &&
      totalEnergyBurnedUnit == other.totalEnergyBurnedUnit &&
      totalDistance == other.totalDistance &&
      totalDistanceUnit == other.totalDistanceUnit &&
      totalSteps == other.totalSteps &&
      totalStepsUnit == other.totalStepsUnit;

  @override
  int get hashCode => Object.hash(
      workoutActivityType,
      totalEnergyBurned,
      totalEnergyBurnedUnit,
      totalDistance,
      totalDistanceUnit,
      totalSteps,
      totalStepsUnit);
}

/// A [HealthValue] object for ECGs
///
/// Parameters:
/// * [voltageValues] - an array of [ElectrocardiogramVoltageValue]s
/// * [averageHeartRate] - the average heart rate during the ECG (in BPM)
/// * [samplingFrequency] - the frequency at which the Apple Watch sampled the voltage.
/// * [classification] - an [ElectrocardiogramClassification]
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ElectrocardiogramHealthValue extends HealthValue {
  /// An array of [ElectrocardiogramVoltageValue]s.
  List<ElectrocardiogramVoltageValue> voltageValues;

  /// The average heart rate during the ECG (in BPM).
  num? averageHeartRate;

  /// The frequency at which the Apple Watch sampled the voltage.
  double? samplingFrequency;

  /// An [ElectrocardiogramClassification].
  ElectrocardiogramClassification? classification;

  ElectrocardiogramHealthValue({
    required this.voltageValues,
    this.averageHeartRate,
    this.samplingFrequency,
    this.classification,
  });

  @override
  Function get fromJsonFunction => _$ElectrocardiogramHealthValueFromJson;
  factory ElectrocardiogramHealthValue.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ElectrocardiogramHealthValue>(json);
  @override
  Map<String, dynamic> toJson() => _$ElectrocardiogramHealthValueToJson(this);

  /// Create a [ElectrocardiogramHealthValue] based on a health data point from native data format.
  factory ElectrocardiogramHealthValue.fromHealthDataPoint(dynamic dataPoint) =>
      ElectrocardiogramHealthValue(
        voltageValues: (dataPoint['voltageValues'] as List)
            .map((voltageValue) =>
                ElectrocardiogramVoltageValue.fromHealthDataPoint(voltageValue))
            .toList(),
        averageHeartRate: dataPoint['averageHeartRate'] as num?,
        samplingFrequency: dataPoint['samplingFrequency'] as double?,
        classification: ElectrocardiogramClassification.values
            .firstWhere((c) => c.value == dataPoint['classification']),
      );

  @override
  bool operator ==(Object other) =>
      other is ElectrocardiogramHealthValue &&
      voltageValues == other.voltageValues &&
      averageHeartRate == other.averageHeartRate &&
      samplingFrequency == other.samplingFrequency &&
      classification == other.classification;

  @override
  int get hashCode => Object.hash(
      voltageValues, averageHeartRate, samplingFrequency, classification);

  @override
  String toString() =>
      '$runtimeType - ${voltageValues.length} values, $averageHeartRate BPM, $samplingFrequency HZ, $classification';
}

/// Single voltage value belonging to a [ElectrocardiogramHealthValue]
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ElectrocardiogramVoltageValue extends HealthValue {
  /// Voltage of the ECG.
  num voltage;

  /// Time since the start of the ECG.
  num timeSinceSampleStart;

  ElectrocardiogramVoltageValue({
    required this.voltage,
    required this.timeSinceSampleStart,
  });

  /// Create a [ElectrocardiogramVoltageValue] based on a health data point from native data format.
  factory ElectrocardiogramVoltageValue.fromHealthDataPoint(
          dynamic dataPoint) =>
      ElectrocardiogramVoltageValue(
          voltage: dataPoint['voltage'] as num,
          timeSinceSampleStart: dataPoint['timeSinceSampleStart'] as num);

  @override
  Function get fromJsonFunction => _$ElectrocardiogramVoltageValueFromJson;
  factory ElectrocardiogramVoltageValue.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ElectrocardiogramVoltageValue>(json);
  @override
  Map<String, dynamic> toJson() => _$ElectrocardiogramVoltageValueToJson(this);

  @override
  bool operator ==(Object other) =>
      other is ElectrocardiogramVoltageValue &&
      voltage == other.voltage &&
      timeSinceSampleStart == other.timeSinceSampleStart;

  @override
  int get hashCode => Object.hash(voltage, timeSinceSampleStart);

  @override
  String toString() => '$runtimeType - voltage: $voltage';
}

/// A [HealthValue] object from insulin delivery (iOS only)
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class InsulinDeliveryHealthValue extends HealthValue {
  /// The amount of units of insulin taken
  double units;

  /// If it's basal, bolus or unknown reason for insulin dosage
  InsulinDeliveryReason reason;

  InsulinDeliveryHealthValue({
    required this.units,
    required this.reason,
  });

  factory InsulinDeliveryHealthValue.fromHealthDataPoint(dynamic dataPoint) {
    final units = dataPoint['value'] as num;

    final metadata = dataPoint['metadata'] == null
        ? null
        : Map<String, dynamic>.from(dataPoint['metadata'] as Map);
    final reasonIndex =
        metadata == null || !metadata.containsKey('HKInsulinDeliveryReason')
            ? 0
            : metadata['HKInsulinDeliveryReason'] as double;
    final reason = InsulinDeliveryReason.values[reasonIndex.toInt()];

    return InsulinDeliveryHealthValue(units: units.toDouble(), reason: reason);
  }

  @override
  Function get fromJsonFunction => _$InsulinDeliveryHealthValueFromJson;
  factory InsulinDeliveryHealthValue.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<InsulinDeliveryHealthValue>(json);
  @override
  Map<String, dynamic> toJson() => _$InsulinDeliveryHealthValueToJson(this);

  @override
  bool operator ==(Object other) =>
      other is InsulinDeliveryHealthValue &&
      units == other.units &&
      reason == other.reason;

  @override
  int get hashCode => Object.hash(units, reason);

  @override
  String toString() => '$runtimeType - units: $units, reason: $reason';
}

/// A [HealthValue] object for nutrition.
///
/// Parameters:
///  * [mealType] - the type of meal
///  * [name] - the name of the food
///  * [b1Thiamine] - the amount of thiamine (B1) in grams
///  * [b2Riboflavin] - the amount of riboflavin (B2) in grams
///  * [b3Niacin] - the amount of niacin (B3) in grams
///  * [b5PantothenicAcid] - the amount of pantothenic acid (B5) in grams
///  * [b6Pyridoxine] - the amount of pyridoxine (B6) in grams
///  * [b7Biotin] - the amount of biotin (B7) in grams
///  * [b9Folate] - the amount of folate (B9) in grams
///  * [b12Cobalamin] - the amount of cobalamin (B12) in grams
///  * [caffeine] - the amount of caffeine in grams
///  * [calcium] - the amount of calcium in grams
///  * [calories] - the amount of calories in kcal
///  * [carbs] - the amount of carbs in grams
///  * [chloride] - the amount of chloride in grams
///  * [cholesterol] - the amount of cholesterol in grams
///  * [choline] - the amount of choline in grams
///  * [chromium] - the amount of chromium in grams
///  * [copper] - the amount of copper in grams
///  * [fat] - the amount of fat in grams
///  * [fatMonounsaturated] - the amount of monounsaturated fat in grams
///  * [fatPolyunsaturated] - the amount of polyunsaturated fat in grams
///  * [fatSaturated] - the amount of saturated fat in grams
///  * [fatTransMonoenoic] - the amount of trans-monoenoic fat in grams
///  * [fatUnsaturated] - the amount of unsaturated fat in grams
///  * [fiber] - the amount of fiber in grams
///  * [iodine] - the amount of iodine in grams
///  * [iron] - the amount of iron in grams
///  * [magnesium] - the amount of magnesium in grams
///  * [manganese] - the amount of manganese in grams
///  * [molybdenum] - the amount of molybdenum in grams
///  * [phosphorus] - the amount of phosphorus in grams
///  * [potassium] - the amount of potassium in grams
///  * [protein] - the amount of protein in grams
///  * [selenium] - the amount of selenium in grams
///  * [sodium] - the amount of sodium in grams
///  * [sugar] - the amount of sugar in grams
///  * [vitaminA] - the amount of vitamin A in grams
///  * [vitaminC] - the amount of vitamin C in grams
///  * [vitaminD] - the amount of vitamin D in grams
///  * [vitaminE] - the amount of vitamin E in grams
///  * [vitaminK] - the amount of vitamin K in grams
///  * [water] - the amount of water in grams
///  * [zinc] - the amount of zinc in grams

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class NutritionHealthValue extends HealthValue {
  /// The name of the food.
  String? name;

  /// The type of meal.
  @JsonKey(name: 'meal_type')
  String? mealType;

  /// The amount of calories in kcal.
  double? calories;

  /// The amount of protein in grams.
  double? protein;

  /// The amount of fat in grams.
  double? fat;

  /// The amount of carbs in grams.
  double? carbs;

  /// The amount of caffeine in grams.
  double? caffeine;

  /// The amount of vitamin A in grams.
  @JsonKey(name: 'vitamin_a')
  double? vitaminA;

  /// The amount of thiamine (B1) in grams.
  @JsonKey(name: 'b1_thiamine')
  double? b1Thiamine;

  /// The amount of riboflavin (B2) in grams.
  @JsonKey(name: 'b2_riboflavin')
  double? b2Riboflavin;

  /// The amount of niacin (B3) in grams.
  @JsonKey(name: 'b3_niacin')
  double? b3Niacin;

  /// The amount of pantothenic acid (B5) in grams.
  @JsonKey(name: 'b5_pantothenic_acid')
  double? b5PantothenicAcid;

  /// The amount of pyridoxine (B6) in grams.
  @JsonKey(name: 'b6_pyridoxine')
  double? b6Pyridoxine;

  /// The amount of biotin (B7) in grams.
  @JsonKey(name: 'b7_biotin')
  double? b7Biotin;

  /// The amount of folate (B9) in grams.
  @JsonKey(name: 'b9_folate')
  double? b9Folate;

  /// The amount of cobalamin (B12) in grams.
  @JsonKey(name: 'b12_cobalamin')
  double? b12Cobalamin;

  /// The amount of vitamin C in grams.
  @JsonKey(name: 'vitamin_c')
  double? vitaminC;

  /// The amount of vitamin D in grams.
  @JsonKey(name: 'vitamin_d')
  double? vitaminD;

  /// The amount of vitamin E in grams.
  @JsonKey(name: 'vitamin_e')
  double? vitaminE;

  /// The amount of vitamin K in grams.
  @JsonKey(name: 'vitamin_k')
  double? vitaminK;

  /// The amount of calcium in grams.
  double? calcium;

  /// The amount of chloride in grams.
  double? chloride;

  /// The amount of cholesterol in grams.
  double? cholesterol;

  /// The amount of choline in grams.
  double? choline;

  /// The amount of chromium in grams.
  double? chromium;

  /// The amount of copper in grams.
  double? copper;

  /// The amount of unsaturated fat in grams.
  @JsonKey(name: 'fat_unsaturated')
  double? fatUnsaturated;

  /// The amount of monounsaturated fat in grams.
  @JsonKey(name: 'fat_monounsaturated')
  double? fatMonounsaturated;

  /// The amount of polyunsaturated fat in grams.
  @JsonKey(name: 'fat_polyunsaturated')
  double? fatPolyunsaturated;

  /// The amount of saturated fat in grams.
  @JsonKey(name: 'fat_saturated')
  double? fatSaturated;

  /// The amount of trans-monoenoic fat in grams.
  @JsonKey(name: 'fat_trans_monoenoic')
  double? fatTransMonoenoic;

  /// The amount of fiber in grams.
  double? fiber;

  /// The amount of iodine in grams.
  double? iodine;

  /// The amount of iron in grams.
  double? iron;

  /// The amount of magnesium in grams.
  double? magnesium;

  /// The amount of manganese in grams.
  double? manganese;

  /// The amount of molybdenum in grams.
  double? molybdenum;

  /// The amount of phosphorus in grams.
  double? phosphorus;

  /// The amount of potassium in grams.
  double? potassium;

  /// The amount of selenium in grams.
  double? selenium;

  /// The amount of sodium in grams.
  double? sodium;

  /// The amount of sugar in grams.
  double? sugar;

  /// The amount of water in grams.
  double? water;

  /// The amount of zinc in grams.
  double? zinc;

  NutritionHealthValue({
    this.name,
    this.mealType,
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
    this.caffeine,
    this.vitaminA,
    this.b1Thiamine,
    this.b2Riboflavin,
    this.b3Niacin,
    this.b5PantothenicAcid,
    this.b6Pyridoxine,
    this.b7Biotin,
    this.b9Folate,
    this.b12Cobalamin,
    this.vitaminC,
    this.vitaminD,
    this.vitaminE,
    this.vitaminK,
    this.calcium,
    this.chloride,
    this.cholesterol,
    this.choline,
    this.chromium,
    this.copper,
    this.fatUnsaturated,
    this.fatMonounsaturated,
    this.fatPolyunsaturated,
    this.fatSaturated,
    this.fatTransMonoenoic,
    this.fiber,
    this.iodine,
    this.iron,
    this.magnesium,
    this.manganese,
    this.molybdenum,
    this.phosphorus,
    this.potassium,
    this.selenium,
    this.sodium,
    this.sugar,
    this.water,
    this.zinc,
  });

  @override
  Function get fromJsonFunction => _$NutritionHealthValueFromJson;
  factory NutritionHealthValue.fromJson(Map<String, dynamic> json) =>
      _$NutritionHealthValueFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$NutritionHealthValueToJson(this);

  /// Create a [NutritionHealthValue] based on a health data point from native data format.
  factory NutritionHealthValue.fromHealthDataPoint(dynamic dataPoint) {
    dataPoint = dataPoint as Map<Object?, Object?>;
    // Convert to Map<String, Object?> and ensure all expected fields are present
    final Map<String, Object?> dataPointMap = {};
    
    // Add all entries from the native data
    dataPoint.forEach((key, value) {
      if (key != null) {
        dataPointMap[key as String] = value;
      }
    });
    
    return _$NutritionHealthValueFromJson(dataPointMap);
  }

  @override
  String toString() => """$runtimeType - protein: ${protein.toString()},
    calories: ${calories.toString()},
    fat: ${fat.toString()},
    name: ${name.toString()},
    carbs: ${carbs.toString()},
    caffeine: ${caffeine.toString()},
    mealType: $mealType,
    vitaminA: ${vitaminA.toString()},
    b1Thiamine: ${b1Thiamine.toString()},
    b2Riboflavin: ${b2Riboflavin.toString()},
    b3Niacin: ${b3Niacin.toString()},
    b5PantothenicAcid: ${b5PantothenicAcid.toString()},
    b6Pyridoxine: ${b6Pyridoxine.toString()},
    b7Biotin: ${b7Biotin.toString()},
    b9Folate: ${b9Folate.toString()},
    b12Cobalamin: ${b12Cobalamin.toString()},
    vitaminC: ${vitaminC.toString()},
    vitaminD: ${vitaminD.toString()},
    vitaminE: ${vitaminE.toString()},
    vitaminK: ${vitaminK.toString()},
    calcium: ${calcium.toString()},
    chloride: ${chloride.toString()},
    cholesterol: ${cholesterol.toString()},
    choline: ${choline.toString()},
    chromium: ${chromium.toString()},
    copper: ${copper.toString()},
    unsaturatedFat: ${fatUnsaturated.toString()},
    fatMonounsaturated: ${fatMonounsaturated.toString()},
    fatPolyunsaturated: ${fatPolyunsaturated.toString()},
    fatSaturated: ${fatSaturated.toString()},
    fatTransMonoenoic: ${fatTransMonoenoic.toString()},
    fiber: ${fiber.toString()},
    iodine: ${iodine.toString()},
    iron: ${iron.toString()},
    magnesium: ${magnesium.toString()},
    manganese: ${manganese.toString()},
    molybdenum: ${molybdenum.toString()},
    phosphorus: ${phosphorus.toString()},
    potassium: ${potassium.toString()},
    selenium: ${selenium.toString()},
    sodium: ${sodium.toString()},
    sugar: ${sugar.toString()},
    water: ${water.toString()},
    zinc: ${zinc.toString()}""";

  @override
  bool operator ==(Object other) =>
      other is NutritionHealthValue &&
      other.name == name &&
      other.mealType == mealType &&
      other.calories == calories &&
      other.protein == protein &&
      other.fat == fat &&
      other.carbs == carbs &&
      other.caffeine == caffeine &&
      other.vitaminA == vitaminA &&
      other.b1Thiamine == b1Thiamine &&
      other.b2Riboflavin == b2Riboflavin &&
      other.b3Niacin == b3Niacin &&
      other.b5PantothenicAcid == b5PantothenicAcid &&
      other.b6Pyridoxine == b6Pyridoxine &&
      other.b7Biotin == b7Biotin &&
      other.b9Folate == b9Folate &&
      other.b12Cobalamin == b12Cobalamin &&
      other.vitaminC == vitaminC &&
      other.vitaminD == vitaminD &&
      other.vitaminE == vitaminE &&
      other.vitaminK == vitaminK &&
      other.calcium == calcium &&
      other.chloride == chloride &&
      other.cholesterol == cholesterol &&
      other.choline == choline &&
      other.chromium == chromium &&
      other.copper == copper &&
      other.fatUnsaturated == fatUnsaturated &&
      other.fatMonounsaturated == fatMonounsaturated &&
      other.fatPolyunsaturated == fatPolyunsaturated &&
      other.fatSaturated == fatSaturated &&
      other.fatTransMonoenoic == fatTransMonoenoic &&
      other.fiber == fiber &&
      other.iodine == iodine &&
      other.iron == iron &&
      other.magnesium == magnesium &&
      other.manganese == manganese &&
      other.molybdenum == molybdenum &&
      other.phosphorus == phosphorus &&
      other.potassium == potassium &&
      other.selenium == selenium &&
      other.sodium == sodium &&
      other.sugar == sugar &&
      other.water == water &&
      other.zinc == zinc;

  @override
  int get hashCode => Object.hashAll([
        protein,
        calories,
        fat,
        name,
        carbs,
        caffeine,
        vitaminA,
        b1Thiamine,
        b2Riboflavin,
        b3Niacin,
        b5PantothenicAcid,
        b6Pyridoxine,
        b7Biotin,
        b9Folate,
        b12Cobalamin,
        vitaminC,
        vitaminD,
        vitaminE,
        vitaminK,
        calcium,
        chloride,
        cholesterol,
        choline,
        chromium,
        copper,
        fatUnsaturated,
        fatMonounsaturated,
        fatPolyunsaturated,
        fatSaturated,
        fatTransMonoenoic,
        fiber,
        iodine,
        iron,
        magnesium,
        manganese,
        molybdenum,
        phosphorus,
        potassium,
        selenium,
        sodium,
        sugar,
        water,
        zinc,
      ]);
}

enum MenstrualFlow {
  unspecified,
  none,
  light,
  medium,
  heavy,
  spotting;

  static MenstrualFlow fromHealthConnect(int value) {
    switch (value) {
      case 0:
        return MenstrualFlow.unspecified;
      case 1:
        return MenstrualFlow.light;
      case 2:
        return MenstrualFlow.medium;
      case 3:
        return MenstrualFlow.heavy;
      default:
        return MenstrualFlow.unspecified;
    }
  }

  static MenstrualFlow fromHealthKit(int value) {
    switch (value) {
      case 1:
        return MenstrualFlow.unspecified;
      case 2:
        return MenstrualFlow.light;
      case 3:
        return MenstrualFlow.medium;
      case 4:
        return MenstrualFlow.heavy;
      case 5:
        return MenstrualFlow.none;
      default:
        return MenstrualFlow.unspecified;
    }
  }

  static int toHealthConnect(MenstrualFlow value) {
    switch (value) {
      case MenstrualFlow.unspecified:
        return 0;
      case MenstrualFlow.light:
        return 1;
      case MenstrualFlow.medium:
        return 2;
      case MenstrualFlow.heavy:
        return 3;
      default:
        return -1;
    }
  }
}

enum RecordingMethod {
  unknown,
  active,
  automatic,
  manual;

  /// Create a [RecordingMethod] from an integer.
  /// 0: unknown, 1: active, 2: automatic, 3: manual
  /// If the integer is not in the range of 0-3, [RecordingMethod.unknown] is returned.
  /// This is used to align the recording method with the platform.
  static RecordingMethod fromInt(int? recordingMethod) {
    switch (recordingMethod) {
      case 0:
        return RecordingMethod.unknown;
      case 1:
        return RecordingMethod.active;
      case 2:
        return RecordingMethod.automatic;
      case 3:
        return RecordingMethod.manual;
      default:
        return RecordingMethod.unknown;
    }
  }

  /// Convert this [RecordingMethod] to an integer.
  int toInt() {
    switch (this) {
      case RecordingMethod.unknown:
        return 0;
      case RecordingMethod.active:
        return 1;
      case RecordingMethod.automatic:
        return 2;
      case RecordingMethod.manual:
        return 3;
    }
  }
}

/// A [HealthValue] object for menstrual flow.
///
/// Parameters:
/// * [flowValue] - the flow value
/// * [isStartOfCycle] - indicator whether or not this occurrence is the first day of the menstrual cycle (iOS only)
/// * [wasUserEntered] - indicator whether or not the data was entered by the user (iOS only)
/// * [dateTime] - the date and time of the menstrual flow
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MenstruationFlowHealthValue extends HealthValue {
  final MenstrualFlow? flow;
  final bool? isStartOfCycle;
  final bool? wasUserEntered;
  final DateTime dateTime;

  MenstruationFlowHealthValue({
    required this.flow,
    required this.dateTime,
    this.isStartOfCycle,
    this.wasUserEntered,
  });

  @override
  String toString() =>
      "flow: ${flow?.name}, startOfCycle: $isStartOfCycle, wasUserEntered: $wasUserEntered, dateTime: $dateTime";

  factory MenstruationFlowHealthValue.fromHealthDataPoint(dynamic dataPoint) {
    // Parse flow value safely
    final flowValueIndex = dataPoint['value'] as int? ?? 0;
    MenstrualFlow? menstrualFlow;
    if (Platform.isAndroid) {
      menstrualFlow = MenstrualFlow.fromHealthConnect(flowValueIndex);
    } else if (Platform.isIOS) {
      menstrualFlow = MenstrualFlow.fromHealthKit(flowValueIndex);
    }

    return MenstruationFlowHealthValue(
      flow: menstrualFlow,
      isStartOfCycle:
          dataPoint['metadata']?.containsKey('HKMenstrualCycleStart') == true
              ? dataPoint['metadata']['HKMenstrualCycleStart'] == 1.0
              : null,
      wasUserEntered:
          dataPoint['metadata']?.containsKey('HKWasUserEntered') == true
              ? dataPoint['metadata']['HKWasUserEntered'] == 1.0
              : null,
      dateTime:
          DateTime.fromMillisecondsSinceEpoch(dataPoint['date_from'] as int),
    );
  }

  @override
  Function get fromJsonFunction => _$MenstruationFlowHealthValueFromJson;

  factory MenstruationFlowHealthValue.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MenstruationFlowHealthValue>(json);

  @override
  Map<String, dynamic> toJson() => _$MenstruationFlowHealthValueToJson(this);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MenstruationFlowHealthValue &&
            runtimeType == other.runtimeType &&
            flow == other.flow &&
            isStartOfCycle == other.isStartOfCycle &&
            wasUserEntered == other.wasUserEntered &&
            dateTime == other.dateTime;
  }

  @override
  int get hashCode =>
      Object.hash(flow, isStartOfCycle, wasUserEntered, dateTime);
}
