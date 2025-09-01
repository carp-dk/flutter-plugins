package cachet.plugins.health

import kotlin.reflect.KClass
import androidx.health.connect.client.records.*
import androidx.health.connect.client.records.MealType

/**
 * Contains all data type mappings, health record classifications, and type conversions
 * used throughout the Health Connect integration.
 */
object HealthConstants {
    // Channel name
    const val CHANNEL_NAME = "flutter_health"

    // Data type constants
    const val ACTIVE_ENERGY_BURNED = "ACTIVE_ENERGY_BURNED"
    const val AGGREGATE_STEP_COUNT = "AGGREGATE_STEP_COUNT"
    const val BASAL_ENERGY_BURNED = "BASAL_ENERGY_BURNED"
    const val BLOOD_GLUCOSE = "BLOOD_GLUCOSE"
    const val BLOOD_OXYGEN = "BLOOD_OXYGEN"
    const val BLOOD_PRESSURE_DIASTOLIC = "BLOOD_PRESSURE_DIASTOLIC"
    const val BLOOD_PRESSURE_SYSTOLIC = "BLOOD_PRESSURE_SYSTOLIC"
    const val BODY_FAT_PERCENTAGE = "BODY_FAT_PERCENTAGE"
    const val LEAN_BODY_MASS = "LEAN_BODY_MASS"
    const val BODY_TEMPERATURE = "BODY_TEMPERATURE"
    const val BODY_WATER_MASS = "BODY_WATER_MASS"
    const val DISTANCE_DELTA = "DISTANCE_DELTA"
    const val FLIGHTS_CLIMBED = "FLIGHTS_CLIMBED"
    const val HEART_RATE = "HEART_RATE"
    const val HEART_RATE_VARIABILITY_RMSSD = "HEART_RATE_VARIABILITY_RMSSD"
    const val HEIGHT = "HEIGHT"
    const val MENSTRUATION_FLOW = "MENSTRUATION_FLOW"
    const val RESPIRATORY_RATE = "RESPIRATORY_RATE"
    const val RESTING_HEART_RATE = "RESTING_HEART_RATE"
    const val STEPS = "STEPS"
    const val WATER = "WATER"
    const val WEIGHT = "WEIGHT"
    const val TOTAL_CALORIES_BURNED = "TOTAL_CALORIES_BURNED"
    const val SPEED = "SPEED"

    // Meal types
    const val BREAKFAST = "BREAKFAST"
    const val DINNER = "DINNER"
    const val LUNCH = "LUNCH"
    const val MEAL_UNKNOWN = "UNKNOWN"
    const val NUTRITION = "NUTRITION"
    const val SNACK = "SNACK"

    // Sleep types
    const val SLEEP_ASLEEP = "SLEEP_ASLEEP"
    const val SLEEP_AWAKE = "SLEEP_AWAKE"
    const val SLEEP_AWAKE_IN_BED = "SLEEP_AWAKE_IN_BED"
    const val SLEEP_DEEP = "SLEEP_DEEP"
    const val SLEEP_IN_BED = "SLEEP_IN_BED"
    const val SLEEP_LIGHT = "SLEEP_LIGHT"
    const val SLEEP_OUT_OF_BED = "SLEEP_OUT_OF_BED"
    const val SLEEP_REM = "SLEEP_REM"
    const val SLEEP_SESSION = "SLEEP_SESSION"
    const val SLEEP_UNKNOWN = "SLEEP_UNKNOWN"

    // Activity type
    const val WORKOUT = "WORKOUT"

    /**
     * Maps Flutter health data type strings to their corresponding Health Connect Record classes.
     * This mapping enables dynamic type resolution for reading and writing health data.
     * 
     * @return Map<String, KClass<out Record>> Mapping of type strings to Health Connect record classes
     */
    val mapToType: Map<String, KClass<out Record>> = hashMapOf(
        BODY_FAT_PERCENTAGE to BodyFatRecord::class,
        LEAN_BODY_MASS to LeanBodyMassRecord::class,
        HEIGHT to HeightRecord::class,
        WEIGHT to WeightRecord::class,
        STEPS to StepsRecord::class,
        AGGREGATE_STEP_COUNT to StepsRecord::class,
        ACTIVE_ENERGY_BURNED to ActiveCaloriesBurnedRecord::class,
        HEART_RATE to HeartRateRecord::class,
        BODY_TEMPERATURE to BodyTemperatureRecord::class,
        BODY_WATER_MASS to BodyWaterMassRecord::class,
        BLOOD_PRESSURE_SYSTOLIC to BloodPressureRecord::class,
        BLOOD_PRESSURE_DIASTOLIC to BloodPressureRecord::class,
        BLOOD_OXYGEN to OxygenSaturationRecord::class,
        BLOOD_GLUCOSE to BloodGlucoseRecord::class,
        HEART_RATE_VARIABILITY_RMSSD to HeartRateVariabilityRmssdRecord::class,
        DISTANCE_DELTA to DistanceRecord::class,
        WATER to HydrationRecord::class,
        SLEEP_ASLEEP to SleepSessionRecord::class,
        SLEEP_AWAKE to SleepSessionRecord::class,
        SLEEP_AWAKE_IN_BED to SleepSessionRecord::class,
        SLEEP_LIGHT to SleepSessionRecord::class,
        SLEEP_DEEP to SleepSessionRecord::class,
        SLEEP_REM to SleepSessionRecord::class,
        SLEEP_OUT_OF_BED to SleepSessionRecord::class,
        SLEEP_SESSION to SleepSessionRecord::class,
        SLEEP_UNKNOWN to SleepSessionRecord::class,
        WORKOUT to ExerciseSessionRecord::class,
        NUTRITION to NutritionRecord::class,
        RESTING_HEART_RATE to RestingHeartRateRecord::class,
        BASAL_ENERGY_BURNED to BasalMetabolicRateRecord::class,
        FLIGHTS_CLIMBED to FloorsClimbedRecord::class,
        RESPIRATORY_RATE to RespiratoryRateRecord::class,
        TOTAL_CALORIES_BURNED to TotalCaloriesBurnedRecord::class,
        MENSTRUATION_FLOW to MenstruationFlowRecord::class,
        SPEED to SpeedRecord::class,
    )
    
    /**
     * Maps health data types to their corresponding aggregate metric types for batch operations.
     * Used when requesting aggregated data over time periods.
     * 
     * @return Map<String, AggregateMetric> Mapping for aggregate data queries
     */
    val mapToAggregateMetric = hashMapOf(
        HEIGHT to HeightRecord.HEIGHT_AVG,
        WEIGHT to WeightRecord.WEIGHT_AVG,
        STEPS to StepsRecord.COUNT_TOTAL,
        AGGREGATE_STEP_COUNT to StepsRecord.COUNT_TOTAL,
        ACTIVE_ENERGY_BURNED to ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL,
        HEART_RATE to HeartRateRecord.MEASUREMENTS_COUNT,
        DISTANCE_DELTA to DistanceRecord.DISTANCE_TOTAL,
        WATER to HydrationRecord.VOLUME_TOTAL,
        SLEEP_ASLEEP to SleepSessionRecord.SLEEP_DURATION_TOTAL,
        SLEEP_AWAKE to SleepSessionRecord.SLEEP_DURATION_TOTAL,
        SLEEP_IN_BED to SleepSessionRecord.SLEEP_DURATION_TOTAL,
        TOTAL_CALORIES_BURNED to TotalCaloriesBurnedRecord.ENERGY_TOTAL
    )

    /**
     * Maps integer sleep stage values to their corresponding data type strings.
     * Converts Health Connect sleep stage enumeration to Flutter-friendly string constants.
     * 
     * @return Map<Int, String> Sleep stage integer to type string mapping
     */
    val mapSleepStageToType = hashMapOf(
        0 to SLEEP_UNKNOWN,
        1 to SLEEP_AWAKE,
        2 to SLEEP_ASLEEP,
        3 to SLEEP_OUT_OF_BED,
        4 to SLEEP_LIGHT,
        5 to SLEEP_DEEP,
        6 to SLEEP_REM,
        7 to SLEEP_AWAKE_IN_BED
    )

    /**
     * Maps meal type strings to Health Connect MealType enumeration values.
     * Enables conversion from Flutter meal type strings to Health Connect types.
     * 
     * @return Map<String, MealType> Meal type string to enum mapping
     */
    val mapMealTypeToType = hashMapOf(
        BREAKFAST to MealType.MEAL_TYPE_BREAKFAST,
        LUNCH to MealType.MEAL_TYPE_LUNCH,
        DINNER to MealType.MEAL_TYPE_DINNER,
        SNACK to MealType.MEAL_TYPE_SNACK,
        MEAL_UNKNOWN to MealType.MEAL_TYPE_UNKNOWN,
    )

    /**
     * Maps Health Connect MealType enumeration values back to Flutter string constants.
     * Used for converting Health Connect meal types to Flutter-compatible format.
     * 
     * @return Map<MealType, String> Enum to string mapping for meal types
     */
    val mapTypeToMealType = hashMapOf(
        MealType.MEAL_TYPE_BREAKFAST to BREAKFAST,
        MealType.MEAL_TYPE_LUNCH to LUNCH,
        MealType.MEAL_TYPE_DINNER to DINNER,
        MealType.MEAL_TYPE_SNACK to SNACK,
        MealType.MEAL_TYPE_UNKNOWN to MEAL_UNKNOWN,
    )

    /**
     * Maps workout/exercise type strings to Health Connect ExerciseSessionRecord types.
     * Comprehensive mapping of all supported exercise activities for workout tracking.
     * 
     * @return Map<String, Int> Workout type strings to Health Connect exercise type constants
     */
    val workoutTypeMap = mapOf(
        "AMERICAN_FOOTBALL" to ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AMERICAN,
        "AUSTRALIAN_FOOTBALL" to ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AUSTRALIAN,
        "BADMINTON" to ExerciseSessionRecord.EXERCISE_TYPE_BADMINTON,
        "BASEBALL" to ExerciseSessionRecord.EXERCISE_TYPE_BASEBALL,
        "BASKETBALL" to ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL,
        "BIKING" to ExerciseSessionRecord.EXERCISE_TYPE_BIKING,
        "BOXING" to ExerciseSessionRecord.EXERCISE_TYPE_BOXING,
        "CALISTHENICS" to ExerciseSessionRecord.EXERCISE_TYPE_CALISTHENICS,
        "CARDIO_DANCE" to ExerciseSessionRecord.EXERCISE_TYPE_DANCING,
        "CRICKET" to ExerciseSessionRecord.EXERCISE_TYPE_CRICKET,
        "CROSS_COUNTRY_SKIING" to ExerciseSessionRecord.EXERCISE_TYPE_SKIING,
        "DANCING" to ExerciseSessionRecord.EXERCISE_TYPE_DANCING,
        "DOWNHILL_SKIING" to ExerciseSessionRecord.EXERCISE_TYPE_SKIING,
        "ELLIPTICAL" to ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL,
        "FENCING" to ExerciseSessionRecord.EXERCISE_TYPE_FENCING,
        "FRISBEE_DISC" to ExerciseSessionRecord.EXERCISE_TYPE_FRISBEE_DISC,
        "GOLF" to ExerciseSessionRecord.EXERCISE_TYPE_GOLF,
        "GUIDED_BREATHING" to ExerciseSessionRecord.EXERCISE_TYPE_GUIDED_BREATHING,
        "GYMNASTICS" to ExerciseSessionRecord.EXERCISE_TYPE_GYMNASTICS,
        "HANDBALL" to ExerciseSessionRecord.EXERCISE_TYPE_HANDBALL,
        "HIGH_INTENSITY_INTERVAL_TRAINING" to ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING,
        "HIKING" to ExerciseSessionRecord.EXERCISE_TYPE_HIKING,
        "ICE_SKATING" to ExerciseSessionRecord.EXERCISE_TYPE_ICE_SKATING,
        "MARTIAL_ARTS" to ExerciseSessionRecord.EXERCISE_TYPE_MARTIAL_ARTS,
        "PARAGLIDING" to ExerciseSessionRecord.EXERCISE_TYPE_PARAGLIDING,
        "PILATES" to ExerciseSessionRecord.EXERCISE_TYPE_PILATES,
        "RACQUETBALL" to ExerciseSessionRecord.EXERCISE_TYPE_RACQUETBALL,
        "ROCK_CLIMBING" to ExerciseSessionRecord.EXERCISE_TYPE_ROCK_CLIMBING,
        "ROWING" to ExerciseSessionRecord.EXERCISE_TYPE_ROWING,
        "ROWING_MACHINE" to ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE,
        "RUGBY" to ExerciseSessionRecord.EXERCISE_TYPE_RUGBY,
        "RUNNING_TREADMILL" to ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_TREADMILL,
        "RUNNING" to ExerciseSessionRecord.EXERCISE_TYPE_RUNNING,
        "SAILING" to ExerciseSessionRecord.EXERCISE_TYPE_SAILING,
        "SCUBA_DIVING" to ExerciseSessionRecord.EXERCISE_TYPE_SCUBA_DIVING,
        "SKATING" to ExerciseSessionRecord.EXERCISE_TYPE_SKATING,
        "SKIING" to ExerciseSessionRecord.EXERCISE_TYPE_SKIING,
        "SNOWBOARDING" to ExerciseSessionRecord.EXERCISE_TYPE_SNOWBOARDING,
        "SNOWSHOEING" to ExerciseSessionRecord.EXERCISE_TYPE_SNOWSHOEING,
        "SOCIAL_DANCE" to ExerciseSessionRecord.EXERCISE_TYPE_DANCING,
        "SOFTBALL" to ExerciseSessionRecord.EXERCISE_TYPE_SOFTBALL,
        "SQUASH" to ExerciseSessionRecord.EXERCISE_TYPE_SQUASH,
        "STAIR_CLIMBING_MACHINE" to ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING_MACHINE,
        "STAIR_CLIMBING" to ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING,
        "STRENGTH_TRAINING" to ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING,
        "SURFING" to ExerciseSessionRecord.EXERCISE_TYPE_SURFING,
        "SWIMMING_OPEN_WATER" to ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_OPEN_WATER,
        "SWIMMING_POOL" to ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL,
        "TABLE_TENNIS" to ExerciseSessionRecord.EXERCISE_TYPE_TABLE_TENNIS,
        "TENNIS" to ExerciseSessionRecord.EXERCISE_TYPE_TENNIS,
        "VOLLEYBALL" to ExerciseSessionRecord.EXERCISE_TYPE_VOLLEYBALL,
        "WALKING" to ExerciseSessionRecord.EXERCISE_TYPE_WALKING,
        "WATER_POLO" to ExerciseSessionRecord.EXERCISE_TYPE_WATER_POLO,
        "WEIGHTLIFTING" to ExerciseSessionRecord.EXERCISE_TYPE_WEIGHTLIFTING,
        "WHEELCHAIR" to ExerciseSessionRecord.EXERCISE_TYPE_WHEELCHAIR,
        "WHEELCHAIR_RUN_PACE" to ExerciseSessionRecord.EXERCISE_TYPE_WHEELCHAIR,
        "WHEELCHAIR_WALK_PACE" to ExerciseSessionRecord.EXERCISE_TYPE_WHEELCHAIR,
        "YOGA" to ExerciseSessionRecord.EXERCISE_TYPE_YOGA,
        "OTHER" to ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT,
    )
}