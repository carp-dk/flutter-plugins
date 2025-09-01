package cachet.plugins.health

import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.*
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.units.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import java.time.Instant

/**
 * Handles writing health data to Health Connect.
 * Manages data insertion for various health metrics, specialized records like workouts and nutrition,
 * and proper data type conversion from Flutter to Health Connect format.
 */
class HealthDataWriter(
    private val healthConnectClient: HealthConnectClient,
    private val scope: CoroutineScope
) {
    
    /**
     * Writes a single health data record to Health Connect.
     * Supports most basic health metrics with automatic type conversion and validation.
     * 
     * @param call Method call containing 'dataTypeKey', 'startTime', 'endTime', 'value', 'recordingMethod'
     * @param result Flutter result callback returning boolean success status
     */
    fun writeData(call: MethodCall, result: Result) {
        val type = call.argument<String>("dataTypeKey")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val value = call.argument<Double>("value")!!
        val recordingMethod = call.argument<Int>("recordingMethod")!!

        Log.i(
            "FLUTTER_HEALTH",
            "Writing data for $type between $startTime and $endTime, value: $value, recording method: $recordingMethod"
        )

        val record = createRecord(type, startTime, endTime, value, recordingMethod)
        
        if (record == null) {
            result.success(false)
            return
        }

        scope.launch {
            try {
                healthConnectClient.insertRecords(listOf(record))
                result.success(true)
            } catch (e: Exception) {
                Log.e("FLUTTER_HEALTH::ERROR", "Error writing $type: ${e.message}")
                result.success(false)
            }
        }
    }

    /**
     * Writes a comprehensive workout session with optional distance and calorie data.
     * Creates an ExerciseSessionRecord with associated DistanceRecord and TotalCaloriesBurnedRecord
     * if supplementary data is provided.
     * 
     * @param call Method call containing workout details: 'activityType', 'startTime', 'endTime', 
     *             'totalEnergyBurned', 'totalDistance', 'recordingMethod', 'title'
     * @param result Flutter result callback returning boolean success status
     */
    fun writeWorkoutData(call: MethodCall, result: Result) {
        val type = call.argument<String>("activityType")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        val totalEnergyBurned = call.argument<Int>("totalEnergyBurned")
        val totalDistance = call.argument<Int>("totalDistance")
        val recordingMethod = call.argument<Int>("recordingMethod")!!
        
        if (!HealthConstants.workoutTypeMap.containsKey(type)) {
            result.success(false)
            Log.w(
                "FLUTTER_HEALTH::ERROR",
                "[Health Connect] Workout type not supported"
            )
            return
        }
        
        val workoutType = HealthConstants.workoutTypeMap[type]!!
        val title = call.argument<String>("title") ?: type

        scope.launch {
            try {
                val list = mutableListOf<Record>()
                
                // Add exercise session record
                list.add(
                    ExerciseSessionRecord(
                        startTime = startTime,
                        startZoneOffset = null,
                        endTime = endTime,
                        endZoneOffset = null,
                        exerciseType = workoutType,
                        title = title,
                        metadata = Metadata(
                            recordingMethod = recordingMethod,
                        ),
                    ),
                )
                
                // Add distance record if provided
                if (totalDistance != null) {
                    list.add(
                        DistanceRecord(
                            startTime = startTime,
                            startZoneOffset = null,
                            endTime = endTime,
                            endZoneOffset = null,
                            distance = Length.meters(totalDistance.toDouble()),
                            metadata = Metadata(
                                recordingMethod = recordingMethod,
                            ),
                        ),
                    )
                }
                
                // Add energy burned record if provided
                if (totalEnergyBurned != null) {
                    list.add(
                        TotalCaloriesBurnedRecord(
                            startTime = startTime,
                            startZoneOffset = null,
                            endTime = endTime,
                            endZoneOffset = null,
                            energy = Energy.kilocalories(totalEnergyBurned.toDouble()),
                            metadata = Metadata(
                                recordingMethod = recordingMethod,
                            ),
                        ),
                    )
                }
                
                healthConnectClient.insertRecords(list)
                result.success(true)
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "[Health Connect] Workout was successfully added!"
                )
            } catch (e: Exception) {
                Log.w(
                    "FLUTTER_HEALTH::ERROR",
                    "[Health Connect] There was an error adding the workout",
                )
                Log.w("FLUTTER_HEALTH::ERROR", e.message ?: "unknown error")
                Log.w("FLUTTER_HEALTH::ERROR", e.stackTrace.toString())
                result.success(false)
            }
        }
    }

    /**
     * Writes blood pressure measurement with both systolic and diastolic values.
     * Creates a single BloodPressureRecord containing both pressure readings
     * taken at the same time point.
     * 
     * @param call Method call containing 'systolic', 'diastolic', 'startTime', 'recordingMethod'
     * @param result Flutter result callback returning boolean success status
     */
    fun writeBloodPressure(call: MethodCall, result: Result) {
        val systolic = call.argument<Double>("systolic")!!
        val diastolic = call.argument<Double>("diastolic")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val recordingMethod = call.argument<Int>("recordingMethod")!!

        scope.launch {
            try {
                healthConnectClient.insertRecords(
                    listOf(
                        BloodPressureRecord(
                            time = startTime,
                            systolic = Pressure.millimetersOfMercury(systolic),
                            diastolic = Pressure.millimetersOfMercury(diastolic),
                            zoneOffset = null,
                            metadata = Metadata(
                                recordingMethod = recordingMethod,
                            ),
                        ),
                    ),
                )
                result.success(true)
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "[Health Connect] Blood pressure was successfully added!",
                )
            } catch (e: Exception) {
                Log.w(
                    "FLUTTER_HEALTH::ERROR",
                    "[Health Connect] There was an error adding the blood pressure",
                )
                Log.w("FLUTTER_HEALTH::ERROR", e.message ?: "unknown error")
                Log.w("FLUTTER_HEALTH::ERROR", e.stackTrace.toString())
                result.success(false)
            }
        }
    }

    /**
     * Writes blood oxygen saturation measurement.
     * Delegates to standard writeData method for OxygenSaturationRecord handling.
     * 
     * @param call Method call with blood oxygen data
     * @param result Flutter result callback returning success status
     */
    fun writeBloodOxygen(call: MethodCall, result: Result) {
        writeData(call, result)
    }

    /**
     * Writes menstrual flow data.
     * Delegates to standard writeData method for MenstruationFlowRecord handling.
     * 
     * @param call Method call with menstruation flow data
     * @param result Flutter result callback returning success status
     */
    fun writeMenstruationFlow(call: MethodCall, result: Result) {
        writeData(call, result)
    }

    /**
     * Writes comprehensive nutrition/meal data with detailed nutrient breakdown.
     * Creates NutritionRecord with extensive nutrient information including vitamins,
     * minerals, macronutrients, and meal classification.
     * 
     * @param call Method call containing nutrition data: calories, macronutrients, vitamins, 
     *             minerals, meal details, timing information
     * @param result Flutter result callback returning boolean success status
     */
    fun writeMeal(call: MethodCall, result: Result) {
        val startTime = Instant.ofEpochMilli(call.argument<Long>("start_time")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("end_time")!!)
        val calories = call.argument<Double>("calories")
        val protein = call.argument<Double>("protein") as Double?
        val carbs = call.argument<Double>("carbs") as Double?
        val fat = call.argument<Double>("fat") as Double?
        val caffeine = call.argument<Double>("caffeine") as Double?
        val vitaminA = call.argument<Double>("vitamin_a") as Double?
        val b1Thiamine = call.argument<Double>("b1_thiamine") as Double?
        val b2Riboflavin = call.argument<Double>("b2_riboflavin") as Double?
        val b3Niacin = call.argument<Double>("b3_niacin") as Double?
        val b5PantothenicAcid = call.argument<Double>("b5_pantothenic_acid") as Double?
        val b6Pyridoxine = call.argument<Double>("b6_pyridoxine") as Double?
        val b7Biotin = call.argument<Double>("b7_biotin") as Double?
        val b9Folate = call.argument<Double>("b9_folate") as Double?
        val b12Cobalamin = call.argument<Double>("b12_cobalamin") as Double?
        val vitaminC = call.argument<Double>("vitamin_c") as Double?
        val vitaminD = call.argument<Double>("vitamin_d") as Double?
        val vitaminE = call.argument<Double>("vitamin_e") as Double?
        val vitaminK = call.argument<Double>("vitamin_k") as Double?
        val calcium = call.argument<Double>("calcium") as Double?
        val chloride = call.argument<Double>("chloride") as Double?
        val cholesterol = call.argument<Double>("cholesterol") as Double?
        val chromium = call.argument<Double>("chromium") as Double?
        val copper = call.argument<Double>("copper") as Double?
        val fatUnsaturated = call.argument<Double>("fat_unsaturated") as Double?
        val fatMonounsaturated = call.argument<Double>("fat_monounsaturated") as Double?
        val fatPolyunsaturated = call.argument<Double>("fat_polyunsaturated") as Double?
        val fatSaturated = call.argument<Double>("fat_saturated") as Double?
        val fatTransMonoenoic = call.argument<Double>("fat_trans_monoenoic") as Double?
        val fiber = call.argument<Double>("fiber") as Double?
        val iodine = call.argument<Double>("iodine") as Double?
        val iron = call.argument<Double>("iron") as Double?
        val magnesium = call.argument<Double>("magnesium") as Double?
        val manganese = call.argument<Double>("manganese") as Double?
        val molybdenum = call.argument<Double>("molybdenum") as Double?
        val phosphorus = call.argument<Double>("phosphorus") as Double?
        val potassium = call.argument<Double>("potassium") as Double?
        val selenium = call.argument<Double>("selenium") as Double?
        val sodium = call.argument<Double>("sodium") as Double?
        val sugar = call.argument<Double>("sugar") as Double?
        val zinc = call.argument<Double>("zinc") as Double?

        val name = call.argument<String>("name")
        val mealType = call.argument<String>("meal_type")!!

        scope.launch {
            try {
                val list = mutableListOf<Record>()
                list.add(
                    NutritionRecord(
                        name = name,
                        energy = calories?.kilocalories,
                        totalCarbohydrate = carbs?.grams,
                        protein = protein?.grams,
                        totalFat = fat?.grams,
                        caffeine = caffeine?.grams,
                        vitaminA = vitaminA?.grams,
                        thiamin = b1Thiamine?.grams,
                        riboflavin = b2Riboflavin?.grams,
                        niacin = b3Niacin?.grams,
                        pantothenicAcid = b5PantothenicAcid?.grams,
                        vitaminB6 = b6Pyridoxine?.grams,
                        biotin = b7Biotin?.grams,
                        folate = b9Folate?.grams,
                        vitaminB12 = b12Cobalamin?.grams,
                        vitaminC = vitaminC?.grams,
                        vitaminD = vitaminD?.grams,
                        vitaminE = vitaminE?.grams,
                        vitaminK = vitaminK?.grams,
                        calcium = calcium?.grams,
                        chloride = chloride?.grams,
                        cholesterol = cholesterol?.grams,
                        chromium = chromium?.grams,
                        copper = copper?.grams,
                        unsaturatedFat = fatUnsaturated?.grams,
                        monounsaturatedFat = fatMonounsaturated?.grams,
                        polyunsaturatedFat = fatPolyunsaturated?.grams,
                        saturatedFat = fatSaturated?.grams,
                        transFat = fatTransMonoenoic?.grams,
                        dietaryFiber = fiber?.grams,
                        iodine = iodine?.grams,
                        iron = iron?.grams,
                        magnesium = magnesium?.grams,
                        manganese = manganese?.grams,
                        molybdenum = molybdenum?.grams,
                        phosphorus = phosphorus?.grams,
                        potassium = potassium?.grams,
                        selenium = selenium?.grams,
                        sodium = sodium?.grams,
                        sugar = sugar?.grams,
                        zinc = zinc?.grams,
                        startTime = startTime,
                        startZoneOffset = null,
                        endTime = endTime,
                        endZoneOffset = null,
                        mealType = HealthConstants.mapMealTypeToType[mealType] 
                            ?: MealType.MEAL_TYPE_UNKNOWN,
                    ),
                )
                healthConnectClient.insertRecords(list)
                result.success(true)
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "[Health Connect] Meal was successfully added!"
                )
            } catch (e: Exception) {
                Log.w(
                    "FLUTTER_HEALTH::ERROR",
                    "[Health Connect] There was an error adding the meal",
                )
                Log.w("FLUTTER_HEALTH::ERROR", e.message ?: "unknown error")
                Log.w("FLUTTER_HEALTH::ERROR", e.stackTrace.toString())
                result.success(false)
            }
        }
    }

    /**
     * Writes speed/velocity data with multiple samples to Health Connect.
     * Creates a SpeedRecord containing time-series speed measurements captured during
     * activities like running, cycling, or walking. Each sample represents the user's
     * instantaneous speed at a specific moment within the recording period.
     *
     * @param call Method call containing startTime, endTime, recordingMethod,
     *             samples: List<Map<String, Any>> List of speed measurements, each
     *             containing: time, speed (m/s)
     *
     * @param result Flutter result callback returning boolean success status
     */
    fun writeMultipleSpeedData(call: MethodCall, result: Result) {
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val samples = call.argument<List<Map<String, Any>>>("samples")!!
        val recordingMethod = call.argument<Int>("recordingMethod")!!

        scope.launch {
            try {
                val speedSamples = samples.map { sample ->
                    SpeedRecord.Sample(
                        time = Instant.ofEpochMilli(sample["time"] as Long),
                        speed = Velocity.metersPerSecond(sample["speed"] as Double)
                    )
                }

                val speedRecord = SpeedRecord(
                    startTime = Instant.ofEpochMilli(startTime),
                    endTime = Instant.ofEpochMilli(endTime),
                    samples = speedSamples,
                    startZoneOffset = null,
                    endZoneOffset = null,
                    metadata = Metadata(recordingMethod = recordingMethod),
                )

                healthConnectClient.insertRecords(listOf(speedRecord))
                result.success(true)
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "Successfully wrote ${speedSamples.size} speed samples"
                )
            } catch (e: Exception) {
                Log.e("FLUTTER_HEALTH::ERROR", "Error writing speed data: ${e.message}")
                result.success(false)
            }
        }
    }

        // ---------- Private Methods ----------

    /**
     * Creates appropriate Health Connect record objects based on data type.
     * Factory method that instantiates the correct record type with proper unit conversion
     * and metadata assignment.
     * 
     * @param type Health data type string identifier
     * @param startTime Record start time in milliseconds
     * @param endTime Record end time in milliseconds
     * @param value Measured value to record
     * @param recordingMethod How the data was recorded (manual, automatic, etc.)
     * @return Record? Properly configured Health Connect record, or null if type unsupported
     */
    private fun createRecord(
        type: String, 
        startTime: Long, 
        endTime: Long, 
        value: Double, 
        recordingMethod: Int
    ): Record? {
        return when (type) {
            BODY_FAT_PERCENTAGE -> BodyFatRecord(
                time = Instant.ofEpochMilli(startTime),
                percentage = Percentage(value),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            LEAN_BODY_MASS -> LeanBodyMassRecord(
                time = Instant.ofEpochMilli(startTime),
                mass = Mass.kilograms(value),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            HEIGHT -> HeightRecord(
                time = Instant.ofEpochMilli(startTime),
                height = Length.meters(value),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            WEIGHT -> WeightRecord(
                time = Instant.ofEpochMilli(startTime),
                weight = Mass.kilograms(value),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            STEPS -> StepsRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                count = value.toLong(),
                startZoneOffset = null,
                endZoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            ACTIVE_ENERGY_BURNED -> ActiveCaloriesBurnedRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                energy = Energy.kilocalories(value),
                startZoneOffset = null,
                endZoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            HEART_RATE -> HeartRateRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                samples = listOf(
                    HeartRateRecord.Sample(
                        time = Instant.ofEpochMilli(startTime),
                        beatsPerMinute = value.toLong(),
                    ),
                ),
                startZoneOffset = null,
                endZoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            BODY_TEMPERATURE -> BodyTemperatureRecord(
                time = Instant.ofEpochMilli(startTime),
                temperature = Temperature.celsius(value),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            BODY_WATER_MASS -> BodyWaterMassRecord(
                time = Instant.ofEpochMilli(startTime),
                mass = Mass.kilograms(value),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            BLOOD_OXYGEN -> OxygenSaturationRecord(
                time = Instant.ofEpochMilli(startTime),
                percentage = Percentage(value),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            BLOOD_GLUCOSE -> BloodGlucoseRecord(
                time = Instant.ofEpochMilli(startTime),
                level = BloodGlucose.milligramsPerDeciliter(value),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            HEART_RATE_VARIABILITY_RMSSD -> HeartRateVariabilityRmssdRecord(
                time = Instant.ofEpochMilli(startTime),
                heartRateVariabilityMillis = value,
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            DISTANCE_DELTA -> DistanceRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                distance = Length.meters(value),
                startZoneOffset = null,
                endZoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            WATER -> HydrationRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                volume = Volume.liters(value),
                startZoneOffset = null,
                endZoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            SLEEP_ASLEEP -> createSleepRecord(startTime, endTime, SleepSessionRecord.STAGE_TYPE_SLEEPING, recordingMethod)
            SLEEP_LIGHT -> createSleepRecord(startTime, endTime, SleepSessionRecord.STAGE_TYPE_LIGHT, recordingMethod)
            SLEEP_DEEP -> createSleepRecord(startTime, endTime, SleepSessionRecord.STAGE_TYPE_DEEP, recordingMethod)
            SLEEP_REM -> createSleepRecord(startTime, endTime, SleepSessionRecord.STAGE_TYPE_REM, recordingMethod)
            SLEEP_OUT_OF_BED -> createSleepRecord(startTime, endTime, SleepSessionRecord.STAGE_TYPE_OUT_OF_BED, recordingMethod)
            SLEEP_AWAKE -> createSleepRecord(startTime, endTime, SleepSessionRecord.STAGE_TYPE_AWAKE, recordingMethod)
            SLEEP_AWAKE_IN_BED -> createSleepRecord(startTime, endTime, SleepSessionRecord.STAGE_TYPE_AWAKE_IN_BED, recordingMethod)
            SLEEP_UNKNOWN -> createSleepRecord(startTime, endTime, SleepSessionRecord.STAGE_TYPE_UNKNOWN, recordingMethod)
            
            SLEEP_SESSION -> SleepSessionRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                startZoneOffset = null,
                endZoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            RESTING_HEART_RATE -> RestingHeartRateRecord(
                time = Instant.ofEpochMilli(startTime),
                beatsPerMinute = value.toLong(),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            BASAL_ENERGY_BURNED -> BasalMetabolicRateRecord(
                time = Instant.ofEpochMilli(startTime),
                basalMetabolicRate = Power.kilocaloriesPerDay(value),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            FLIGHTS_CLIMBED -> FloorsClimbedRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                floors = value,
                startZoneOffset = null,
                endZoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            RESPIRATORY_RATE -> RespiratoryRateRecord(
                time = Instant.ofEpochMilli(startTime),
                rate = value,
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            TOTAL_CALORIES_BURNED -> TotalCaloriesBurnedRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                energy = Energy.kilocalories(value),
                startZoneOffset = null,
                endZoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            MENSTRUATION_FLOW -> MenstruationFlowRecord(
                time = Instant.ofEpochMilli(startTime),
                flow = value.toInt(),
                zoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )

            SPEED -> SpeedRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                samples = listOf(
                    SpeedRecord.Sample(
                        time = Instant.ofEpochMilli(startTime),
                        speed = Velocity.metersPerSecond(value),
                    )
                ),
                startZoneOffset = null,
                endZoneOffset = null,
                metadata = Metadata(recordingMethod = recordingMethod),
            )
            
            BLOOD_PRESSURE_SYSTOLIC -> {
                Log.e("FLUTTER_HEALTH::ERROR", "You must use the [writeBloodPressure] API")
                null
            }
            
            BLOOD_PRESSURE_DIASTOLIC -> {
                Log.e("FLUTTER_HEALTH::ERROR", "You must use the [writeBloodPressure] API")
                null
            }
            
            WORKOUT -> {
                Log.e("FLUTTER_HEALTH::ERROR", "You must use the [writeWorkoutData] API")
                null
            }
            
            NUTRITION -> {
                Log.e("FLUTTER_HEALTH::ERROR", "You must use the [writeMeal] API")
                null
            }
            
            else -> {
                Log.e("FLUTTER_HEALTH::ERROR", "The type $type was not supported by the Health plugin or you must use another API")
                null
            }
        }
    }

    /**
     * Creates sleep session records with stage information.
     * Builds SleepSessionRecord with appropriate sleep stage data and timing.
     * 
     * @param startTime Sleep period start time in milliseconds
     * @param endTime Sleep period end time in milliseconds
     * @param stageType Sleep stage type constant
     * @param recordingMethod How sleep data was recorded
     * @return SleepSessionRecord Configured sleep session record
     */
    private fun createSleepRecord(startTime: Long, endTime: Long, stageType: Int, recordingMethod: Int): SleepSessionRecord {
        return SleepSessionRecord(
            startTime = Instant.ofEpochMilli(startTime),
            endTime = Instant.ofEpochMilli(endTime),
            startZoneOffset = null,
            endZoneOffset = null,
            stages = listOf(
                SleepSessionRecord.Stage(
                    Instant.ofEpochMilli(startTime),
                    Instant.ofEpochMilli(endTime),
                    stageType
                )
            ),
            metadata = Metadata(recordingMethod = recordingMethod),
        )
    }

    companion object {
        // Health data type constants
        private const val BODY_FAT_PERCENTAGE = "BODY_FAT_PERCENTAGE"
        private const val LEAN_BODY_MASS = "LEAN_BODY_MASS"
        private const val HEIGHT = "HEIGHT"
        private const val WEIGHT = "WEIGHT"
        private const val STEPS = "STEPS"
        private const val ACTIVE_ENERGY_BURNED = "ACTIVE_ENERGY_BURNED"
        private const val HEART_RATE = "HEART_RATE"
        private const val BODY_TEMPERATURE = "BODY_TEMPERATURE"
        private const val BODY_WATER_MASS = "BODY_WATER_MASS"
        private const val BLOOD_OXYGEN = "BLOOD_OXYGEN"
        private const val BLOOD_GLUCOSE = "BLOOD_GLUCOSE"
        private const val HEART_RATE_VARIABILITY_RMSSD = "HEART_RATE_VARIABILITY_RMSSD"
        private const val DISTANCE_DELTA = "DISTANCE_DELTA"
        private const val WATER = "WATER"
        private const val RESTING_HEART_RATE = "RESTING_HEART_RATE"
        private const val BASAL_ENERGY_BURNED = "BASAL_ENERGY_BURNED"
        private const val FLIGHTS_CLIMBED = "FLIGHTS_CLIMBED"
        private const val RESPIRATORY_RATE = "RESPIRATORY_RATE"
        private const val TOTAL_CALORIES_BURNED = "TOTAL_CALORIES_BURNED"
        private const val MENSTRUATION_FLOW = "MENSTRUATION_FLOW"
        private const val BLOOD_PRESSURE_SYSTOLIC = "BLOOD_PRESSURE_SYSTOLIC"
        private const val BLOOD_PRESSURE_DIASTOLIC = "BLOOD_PRESSURE_DIASTOLIC"
        private const val WORKOUT = "WORKOUT"
        private const val NUTRITION = "NUTRITION"
        private const val SPEED = "SPEED"
        
        // Sleep types
        private const val SLEEP_ASLEEP = "SLEEP_ASLEEP"
        private const val SLEEP_LIGHT = "SLEEP_LIGHT"
        private const val SLEEP_DEEP = "SLEEP_DEEP"
        private const val SLEEP_REM = "SLEEP_REM"
        private const val SLEEP_OUT_OF_BED = "SLEEP_OUT_OF_BED"
        private const val SLEEP_AWAKE = "SLEEP_AWAKE"
        private const val SLEEP_AWAKE_IN_BED = "SLEEP_AWAKE_IN_BED"
        private const val SLEEP_UNKNOWN = "SLEEP_UNKNOWN"
        private const val SLEEP_SESSION = "SLEEP_SESSION"
    }
}