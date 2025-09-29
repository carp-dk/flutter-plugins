package cachet.plugins.health

import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.*
import androidx.health.connect.client.records.metadata.Device
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.units.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import java.time.Instant
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles writing health data to Health Connect. Manages data insertion for various health metrics,
 * specialized records like workouts and nutrition, and proper data type conversion from Flutter to
 * Health Connect format.
 */
class HealthDataWriter(
        private val healthConnectClient: HealthConnectClient,
        private val scope: CoroutineScope
) {

    // Maps incoming recordingMethod int -> Metadata factory method.
    // 0: unknown, 1: manual, 2: auto, 3: active (default unknown for others)
    private fun buildMetadata(
        recordingMethod: Int,
        clientRecordId: String? = null,
        clientRecordVersion: Long? = null,
        deviceType: Int? = null,
    ): Metadata {
        // Device is required for auto/active; optional for manual/unknown
        val deviceForAutoOrActive =
            when (recordingMethod) {
                RECORDING_METHOD_AUTOMATICALLY_RECORDED,
                RECORDING_METHOD_ACTIVELY_RECORDED ->
                    Device(type = deviceType ?: Device.TYPE_UNKNOWN)
                else -> null
            }

                return when (recordingMethod) {
                        RECORDING_METHOD_MANUAL_ENTRY -> {
                                if (clientRecordId != null && clientRecordVersion != null) {
                                        Metadata.manualEntry(
                                                device = null,
                                                clientRecordId = clientRecordId,
                                                clientRecordVersion = clientRecordVersion,
                                        )
                                } else {
                                        Metadata.manualEntry()
                                }
                        }
                        RECORDING_METHOD_AUTOMATICALLY_RECORDED -> {
                                val dev = deviceForAutoOrActive!!
                                if (clientRecordId != null && clientRecordVersion != null) {
                                        Metadata.autoRecorded(
                                                device = dev,
                                                clientRecordId = clientRecordId,
                                                clientRecordVersion = clientRecordVersion,
                                        )
                                } else {
                                        Metadata.autoRecorded(dev)
                                }
                        }
                        RECORDING_METHOD_ACTIVELY_RECORDED -> {
                                val dev = deviceForAutoOrActive!!
                                if (clientRecordId != null && clientRecordVersion != null) {
                                        Metadata.activelyRecorded(
                                                device = dev,
                                                clientRecordId = clientRecordId,
                                                clientRecordVersion = clientRecordVersion,
                                        )
                                } else {
                                        Metadata.activelyRecorded(dev)
                                }
                        }
                        else -> { // unknown
                                if (clientRecordId != null && clientRecordVersion != null) {
                                        Metadata.unknownRecordingMethod(
                                                device = null,
                                                clientRecordId = clientRecordId,
                                                clientRecordVersion = clientRecordVersion,
                                        )
                                } else {
                                        Metadata.unknownRecordingMethod()
                                }
                        }
        }
    }


    /**
     * Writes a single health data record to Health Connect. Supports most basic health metrics with
     * automatic type conversion and validation.
     *
     * @param call Method call containing 'dataTypeKey', 'startTime', 'endTime', 'value',
     * 'recordingMethod'
     * @param result Flutter result callback returning boolean success status
     */
    fun writeData(call: MethodCall, result: Result) {
        val type = call.argument<String>("dataTypeKey")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val value = call.argument<Double>("value")!!
        val clientRecordId: String? = call.argument("clientRecordId")
        val clientRecordVersion: Double? = call.argument<Double>("clientRecordVersion")
        val recordingMethod = call.argument<Int>("recordingMethod")!!
        val deviceType: Int? = call.argument<Int>("deviceType")

        Log.i(
                "FLUTTER_HEALTH",
                "Writing data for $type between $startTime and $endTime, value: $value, recording method: $recordingMethod"
        )

        val metadata: Metadata = buildMetadata(
            recordingMethod = recordingMethod,
            clientRecordId = clientRecordId,
            clientRecordVersion = clientRecordVersion?.toLong(),
            deviceType = deviceType,
        )

        val record = createRecord(type, startTime, endTime, value, metadata)

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
     * Writes a comprehensive workout session with optional distance and calorie data. Creates an
     * ExerciseSessionRecord with associated DistanceRecord and TotalCaloriesBurnedRecord if
     * supplementary data is provided.
     *
     * @param call Method call containing workout details: 'activityType', 'startTime', 'endTime',
     * ```
     *             'totalEnergyBurned', 'totalDistance', 'recordingMethod', 'title'
     * @param result
     * ```
     * Flutter result callback returning boolean success status
     */
    fun writeWorkoutData(call: MethodCall, result: Result) {
        val type = call.argument<String>("activityType")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        val totalEnergyBurned = call.argument<Int>("totalEnergyBurned")
        val totalDistance = call.argument<Int>("totalDistance")
        val recordingMethod = call.argument<Int>("recordingMethod")!!
        val deviceType: Int? = call.argument<Int>("deviceType")
        val workoutMetadata = buildMetadata(recordingMethod = recordingMethod, deviceType = deviceType)

        if (!HealthConstants.workoutTypeMap.containsKey(type)) {
            result.success(false)
            Log.w("FLUTTER_HEALTH::ERROR", "[Health Connect] Workout type not supported")
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
                                metadata = workoutMetadata,
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
                                    metadata = workoutMetadata,
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
                                    metadata = workoutMetadata,
                            ),
                    )
                }

                healthConnectClient.insertRecords(list)
                result.success(true)
                Log.i("FLUTTER_HEALTH::SUCCESS", "[Health Connect] Workout was successfully added!")
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
     * Writes blood pressure measurement with both systolic and diastolic values. Creates a single
     * BloodPressureRecord containing both pressure readings taken at the same time point.
     *
     * @param call Method call containing 'systolic', 'diastolic', 'startTime', 'recordingMethod'
     * @param result Flutter result callback returning boolean success status
     */
    fun writeBloodPressure(call: MethodCall, result: Result) {
        val systolic = call.argument<Double>("systolic")!!
        val diastolic = call.argument<Double>("diastolic")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val recordingMethod = call.argument<Int>("recordingMethod")!!
        val clientRecordId: String? = call.argument<String>("clientRecordId")
        val clientRecordVersion: Double? = call.argument<Double>("clientRecordVersion")
        val deviceType: Int? = call.argument<Int>("deviceType")

        scope.launch {
            try {
                val metadata: Metadata = buildMetadata(
                    recordingMethod = recordingMethod,
                    clientRecordId = clientRecordId,
                    clientRecordVersion = clientRecordVersion?.toLong(),
                    deviceType = deviceType,
                )
                healthConnectClient.insertRecords(
                        listOf(
                                BloodPressureRecord(
                                        time = startTime,
                                        systolic = Pressure.millimetersOfMercury(systolic),
                                        diastolic = Pressure.millimetersOfMercury(diastolic),
                                        zoneOffset = null,
                                        metadata = metadata,
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
     * Writes blood oxygen saturation measurement. Delegates to standard writeData method for
     * OxygenSaturationRecord handling.
     *
     * @param call Method call with blood oxygen data
     * @param result Flutter result callback returning success status
     */
    fun writeBloodOxygen(call: MethodCall, result: Result) {
        writeData(call, result)
    }

    /**
     * Writes menstrual flow data. Delegates to standard writeData method for MenstruationFlowRecord
     * handling.
     *
     * @param call Method call with menstruation flow data
     * @param result Flutter result callback returning success status
     */
    fun writeMenstruationFlow(call: MethodCall, result: Result) {
        writeData(call, result)
    }

    /**
     * Writes comprehensive nutrition/meal data with detailed nutrient breakdown. Creates
     * NutritionRecord with extensive nutrient information including vitamins, minerals,
     * macronutrients, and meal classification.
     *
     * @param call Method call containing nutrition data: calories, macronutrients, vitamins,
     * ```
     *             minerals, meal details, timing information
     * @param result
     * ```
     * Flutter result callback returning boolean success status
     */
    fun writeMeal(call: MethodCall, result: Result) {
        val startTime = Instant.ofEpochMilli(call.argument<Long>("start_time")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("end_time")!!)
        val calories = call.argument<Double>("calories")
        val protein = call.argument<Double>("protein")
        val carbs = call.argument<Double>("carbs")
        val fat = call.argument<Double>("fat")
        val caffeine = call.argument<Double>("caffeine")
        val vitaminA = call.argument<Double>("vitamin_a")
        val b1Thiamine = call.argument<Double>("b1_thiamine")
        val b2Riboflavin = call.argument<Double>("b2_riboflavin")
        val b3Niacin = call.argument<Double>("b3_niacin")
        val b5PantothenicAcid = call.argument<Double>("b5_pantothenic_acid")
        val b6Pyridoxine = call.argument<Double>("b6_pyridoxine")
        val b7Biotin = call.argument<Double>("b7_biotin")
        val b9Folate = call.argument<Double>("b9_folate")
        val b12Cobalamin = call.argument<Double>("b12_cobalamin")
        val vitaminC = call.argument<Double>("vitamin_c")
        val vitaminD = call.argument<Double>("vitamin_d")
        val vitaminE = call.argument<Double>("vitamin_e")
        val vitaminK = call.argument<Double>("vitamin_k")
        val calcium = call.argument<Double>("calcium")
        val chloride = call.argument<Double>("chloride")
        val cholesterol = call.argument<Double>("cholesterol")
        val chromium = call.argument<Double>("chromium")
        val copper = call.argument<Double>("copper")
        val fatUnsaturated = call.argument<Double>("fat_unsaturated")
        val fatMonounsaturated = call.argument<Double>("fat_monounsaturated")
        val fatPolyunsaturated = call.argument<Double>("fat_polyunsaturated")
        val fatSaturated = call.argument<Double>("fat_saturated")
        val fatTransMonoenoic = call.argument<Double>("fat_trans_monoenoic")
        val fiber = call.argument<Double>("fiber")
        val iodine = call.argument<Double>("iodine")
        val iron = call.argument<Double>("iron")
        val magnesium = call.argument<Double>("magnesium")
        val manganese = call.argument<Double>("manganese")
        val molybdenum = call.argument<Double>("molybdenum")
        val phosphorus = call.argument<Double>("phosphorus")
        val potassium = call.argument<Double>("potassium")
        val selenium = call.argument<Double>("selenium")
        val sodium = call.argument<Double>("sodium")
        val sugar = call.argument<Double>("sugar")
        val zinc = call.argument<Double>("zinc")

        val name = call.argument<String>("name")
        val mealType = call.argument<String>("meal_type")!!
        val recordingMethod = call.argument<Int>("recordingMethod") ?: RECORDING_METHOD_MANUAL_ENTRY
        val clientRecordId: String? = call.argument<String>("clientRecordId")
        val clientRecordVersion: Double? = call.argument<Double>("clientRecordVersion")
        val deviceType: Int? = call.argument<Int>("deviceType")

        scope.launch {
            try {
                val metadata: Metadata = buildMetadata(
                    recordingMethod = recordingMethod,
                    clientRecordId = clientRecordId,
                    clientRecordVersion = clientRecordVersion?.toLong(),
                    deviceType = deviceType,
                )
                val list = mutableListOf<Record>()

                list.add(
                        NutritionRecord(
                                name = name,
                                metadata = metadata,
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
                                                ?: MealType.MEAL_TYPE_UNKNOWN
                        ),
                )
                healthConnectClient.insertRecords(list)
                result.success(true)
                Log.i("FLUTTER_HEALTH::SUCCESS", "[Health Connect] Meal was successfully added!")
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
     * Writes speed/velocity data with multiple samples to Health Connect. Creates a SpeedRecord
     * containing time-series speed measurements captured during activities like running, cycling,
     * or walking. Each sample represents the user's instantaneous speed at a specific moment within
     * the recording period.
     *
     * @param call Method call containing startTime, endTime, recordingMethod,
     * ```
     *             samples: List<Map<String, Any>> List of speed measurements, each
     *             containing: time, speed (m/s)
     *
     * @param result
     * ```
     * Flutter result callback returning boolean success status
     */
    fun writeMultipleSpeedData(call: MethodCall, result: Result) {
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val samples = call.argument<List<Map<String, Any>>>("samples")!!
        val recordingMethod = call.argument<Int>("recordingMethod")!!
        val deviceType: Int? = call.argument<Int>("deviceType")

        scope.launch {
            try {
                val speedSamples =
                        samples.map { sample ->
                            SpeedRecord.Sample(
                                    time = Instant.ofEpochMilli(sample["time"] as Long),
                                    speed = Velocity.metersPerSecond(sample["speed"] as Double)
                            )
                        }
                
                val metadata = buildMetadata(recordingMethod, deviceType = deviceType)

                val speedRecord =
                        SpeedRecord(
                                startTime = Instant.ofEpochMilli(startTime),
                                endTime = Instant.ofEpochMilli(endTime),
                                samples = speedSamples,
                                startZoneOffset = null,
                                endZoneOffset = null,
                                metadata = metadata,
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
     * Creates appropriate Health Connect record objects based on data type. Factory method that
     * instantiates the correct record type with proper unit conversion and metadata assignment.
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
            metadata: Metadata
    ): Record? {
        return when (type) {
            BODY_FAT_PERCENTAGE ->
                    BodyFatRecord(
                            time = Instant.ofEpochMilli(startTime),
                            percentage = Percentage(value),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            LEAN_BODY_MASS ->
                    LeanBodyMassRecord(
                            time = Instant.ofEpochMilli(startTime),
                            mass = Mass.kilograms(value),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            HEIGHT ->
                    HeightRecord(
                            time = Instant.ofEpochMilli(startTime),
                            height = Length.meters(value),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            WEIGHT ->
                    WeightRecord(
                            time = Instant.ofEpochMilli(startTime),
                            weight = Mass.kilograms(value),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            STEPS ->
                    StepsRecord(
                            startTime = Instant.ofEpochMilli(startTime),
                            endTime = Instant.ofEpochMilli(endTime),
                            count = value.toLong(),
                            startZoneOffset = null,
                            endZoneOffset = null,
                            metadata = metadata,
                    )
            ACTIVE_ENERGY_BURNED ->
                    ActiveCaloriesBurnedRecord(
                            startTime = Instant.ofEpochMilli(startTime),
                            endTime = Instant.ofEpochMilli(endTime),
                            energy = Energy.kilocalories(value),
                            startZoneOffset = null,
                            endZoneOffset = null,
                            metadata = metadata,
                    )
            HEART_RATE ->
                    HeartRateRecord(
                            startTime = Instant.ofEpochMilli(startTime),
                            endTime = Instant.ofEpochMilli(endTime),
                            samples =
                                    listOf(
                                            HeartRateRecord.Sample(
                                                    time = Instant.ofEpochMilli(startTime),
                                                    beatsPerMinute = value.toLong(),
                                            ),
                                    ),
                            startZoneOffset = null,
                            endZoneOffset = null,
                            metadata = metadata,
                    )
            BODY_TEMPERATURE ->
                    BodyTemperatureRecord(
                            time = Instant.ofEpochMilli(startTime),
                            temperature = Temperature.celsius(value),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            BODY_WATER_MASS ->
                    BodyWaterMassRecord(
                            time = Instant.ofEpochMilli(startTime),
                            mass = Mass.kilograms(value),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            BLOOD_OXYGEN ->
                    OxygenSaturationRecord(
                            time = Instant.ofEpochMilli(startTime),
                            percentage = Percentage(value),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            BLOOD_GLUCOSE ->
                    BloodGlucoseRecord(
                            time = Instant.ofEpochMilli(startTime),
                            level = BloodGlucose.milligramsPerDeciliter(value),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            HEART_RATE_VARIABILITY_RMSSD ->
                    HeartRateVariabilityRmssdRecord(
                            time = Instant.ofEpochMilli(startTime),
                            heartRateVariabilityMillis = value,
                            zoneOffset = null,
                            metadata = metadata,
                    )
            DISTANCE_DELTA ->
                    DistanceRecord(
                            startTime = Instant.ofEpochMilli(startTime),
                            endTime = Instant.ofEpochMilli(endTime),
                            distance = Length.meters(value),
                            startZoneOffset = null,
                            endZoneOffset = null,
                            metadata = metadata,
                    )
            WATER ->
                    HydrationRecord(
                            startTime = Instant.ofEpochMilli(startTime),
                            endTime = Instant.ofEpochMilli(endTime),
                            volume = Volume.liters(value),
                            startZoneOffset = null,
                            endZoneOffset = null,
                            metadata = metadata,
                    )
            SLEEP_ASLEEP ->
                    createSleepRecord(
                            startTime,
                            endTime,
                            SleepSessionRecord.STAGE_TYPE_SLEEPING,
                            metadata
                    )
            SLEEP_LIGHT ->
                    createSleepRecord(
                            startTime,
                            endTime,
                            SleepSessionRecord.STAGE_TYPE_LIGHT,
                            metadata
                    )
            SLEEP_DEEP ->
                    createSleepRecord(
                            startTime,
                            endTime,
                            SleepSessionRecord.STAGE_TYPE_DEEP,
                            metadata
                    )
            SLEEP_REM ->
                    createSleepRecord(
                            startTime,
                            endTime,
                            SleepSessionRecord.STAGE_TYPE_REM,
                            metadata
                    )
            SLEEP_OUT_OF_BED ->
                    createSleepRecord(
                            startTime,
                            endTime,
                            SleepSessionRecord.STAGE_TYPE_OUT_OF_BED,
                            metadata
                    )
            SLEEP_AWAKE ->
                    createSleepRecord(
                            startTime,
                            endTime,
                            SleepSessionRecord.STAGE_TYPE_AWAKE,
                            metadata
                    )
            SLEEP_AWAKE_IN_BED ->
                    createSleepRecord(
                            startTime,
                            endTime,
                            SleepSessionRecord.STAGE_TYPE_AWAKE_IN_BED,
                            metadata
                    )
            SLEEP_UNKNOWN ->
                    createSleepRecord(
                            startTime,
                            endTime,
                            SleepSessionRecord.STAGE_TYPE_UNKNOWN,
                            metadata
                    )
            SLEEP_SESSION ->
                    SleepSessionRecord(
                            startTime = Instant.ofEpochMilli(startTime),
                            endTime = Instant.ofEpochMilli(endTime),
                            startZoneOffset = null,
                            endZoneOffset = null,
                            metadata = metadata,
                    )
            RESTING_HEART_RATE ->
                    RestingHeartRateRecord(
                            time = Instant.ofEpochMilli(startTime),
                            beatsPerMinute = value.toLong(),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            BASAL_ENERGY_BURNED ->
                    BasalMetabolicRateRecord(
                            time = Instant.ofEpochMilli(startTime),
                            basalMetabolicRate = Power.kilocaloriesPerDay(value),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            FLIGHTS_CLIMBED ->
                    FloorsClimbedRecord(
                            startTime = Instant.ofEpochMilli(startTime),
                            endTime = Instant.ofEpochMilli(endTime),
                            floors = value,
                            startZoneOffset = null,
                            endZoneOffset = null,
                            metadata = metadata,
                    )
            RESPIRATORY_RATE ->
                    RespiratoryRateRecord(
                            time = Instant.ofEpochMilli(startTime),
                            rate = value,
                            zoneOffset = null,
                            metadata = metadata,
                    )
            TOTAL_CALORIES_BURNED ->
                    TotalCaloriesBurnedRecord(
                            startTime = Instant.ofEpochMilli(startTime),
                            endTime = Instant.ofEpochMilli(endTime),
                            energy = Energy.kilocalories(value),
                            startZoneOffset = null,
                            endZoneOffset = null,
                            metadata = metadata,
                    )
            MENSTRUATION_FLOW ->
                    MenstruationFlowRecord(
                            time = Instant.ofEpochMilli(startTime),
                            flow = value.toInt(),
                            zoneOffset = null,
                            metadata = metadata,
                    )
            SPEED ->
                    SpeedRecord(
                            startTime = Instant.ofEpochMilli(startTime),
                            endTime = Instant.ofEpochMilli(endTime),
                            samples =
                                    listOf(
                                            SpeedRecord.Sample(
                                                    time = Instant.ofEpochMilli(startTime),
                                                    speed = Velocity.metersPerSecond(value),
                                            )
                                    ),
                            startZoneOffset = null,
                            endZoneOffset = null,
                            metadata = metadata,
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
                Log.e(
                        "FLUTTER_HEALTH::ERROR",
                        "The type $type was not supported by the Health plugin or you must use another API"
                )
                null
            }
        }
    }

    /**
     * Creates sleep session records with stage information. Builds SleepSessionRecord with
     * appropriate sleep stage data and timing.
     *
     * @param startTime Sleep period start time in milliseconds
     * @param endTime Sleep period end time in milliseconds
     * @param stageType Sleep stage type constant
     * @param recordingMethod How sleep data was recorded
     * @return SleepSessionRecord Configured sleep session record
     */
    private fun createSleepRecord(
            startTime: Long,
            endTime: Long,
            stageType: Int,
            metadata: Metadata
    ): SleepSessionRecord {
        return SleepSessionRecord(
                startTime = Instant.ofEpochMilli(startTime),
                endTime = Instant.ofEpochMilli(endTime),
                startZoneOffset = null,
                endZoneOffset = null,
                stages =
                        listOf(
                                SleepSessionRecord.Stage(
                                        Instant.ofEpochMilli(startTime),
                                        Instant.ofEpochMilli(endTime),
                                        stageType
                                )
                        ),
                metadata = metadata,
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

        // Recording method mapping expected from Flutter side
        private const val RECORDING_METHOD_UNKNOWN = 0
        private const val RECORDING_METHOD_MANUAL_ENTRY = 1
        private const val RECORDING_METHOD_AUTOMATICALLY_RECORDED = 2
        private const val RECORDING_METHOD_ACTIVELY_RECORDED = 3

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
