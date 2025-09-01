package cachet.plugins.health

import java.time.Instant
import java.time.temporal.ChronoUnit
import androidx.health.connect.client.records.*
import androidx.health.connect.client.records.metadata.Metadata

/**
 * Converts Health Connect records to Flutter-compatible data structures.
 * Handles the transformation of strongly-typed Health Connect data into generic maps
 * that can be serialized and passed to the Flutter layer.
 */
class HealthDataConverter {
    
    /**
     * Converts a Health Connect record to a list of Flutter-compatible maps.
     * Handles various record types including instant records, interval records, and complex types.
     * 
     * @param record The Health Connect record to convert
     * @param dataType The string identifier for the data type being converted
     * @return List<Map<String, Any?>> List of converted records (some records may split into multiple entries)
     * @throws IllegalArgumentException If the record type is not supported
     */
    fun convertRecord(record: Any, dataType: String): List<Map<String, Any?>> {
        val metadata = (record as Record).metadata
        
        return when (record) {
            // Single-value instant records
            is WeightRecord -> listOf(createInstantRecord(metadata, record.time, record.weight.inKilograms))
            is HeightRecord -> listOf(createInstantRecord(metadata, record.time, record.height.inMeters))
            is BodyFatRecord -> listOf(createInstantRecord(metadata, record.time, record.percentage.value))
            is LeanBodyMassRecord -> listOf(createInstantRecord(metadata, record.time, record.mass.inKilograms))
            is HeartRateVariabilityRmssdRecord -> listOf(createInstantRecord(metadata, record.time, record.heartRateVariabilityMillis))
            is BodyTemperatureRecord -> listOf(createInstantRecord(metadata, record.time, record.temperature.inCelsius))
            is BodyWaterMassRecord -> listOf(createInstantRecord(metadata, record.time, record.mass.inKilograms))
            is OxygenSaturationRecord -> listOf(createInstantRecord(metadata, record.time, record.percentage.value))
            is BloodGlucoseRecord -> listOf(createInstantRecord(metadata, record.time, record.level.inMilligramsPerDeciliter))
            is BasalMetabolicRateRecord -> listOf(createInstantRecord(metadata, record.time, record.basalMetabolicRate.inKilocaloriesPerDay))
            is RestingHeartRateRecord -> listOf(createInstantRecord(metadata, record.time, record.beatsPerMinute))
            is RespiratoryRateRecord -> listOf(createInstantRecord(metadata, record.time, record.rate))
            
            // Interval records
            is StepsRecord -> listOf(createIntervalRecord(metadata, record.startTime, record.endTime, record.count))
            is ActiveCaloriesBurnedRecord -> listOf(createIntervalRecord(metadata, record.startTime, record.endTime, record.energy.inKilocalories))
            is DistanceRecord -> listOf(createIntervalRecord(metadata, record.startTime, record.endTime, record.distance.inMeters))
            is HydrationRecord -> listOf(createIntervalRecord(metadata, record.startTime, record.endTime, record.volume.inLiters))
            is TotalCaloriesBurnedRecord -> listOf(createIntervalRecord(metadata, record.startTime, record.endTime, record.energy.inKilocalories))
            is FloorsClimbedRecord -> listOf(createIntervalRecord(metadata, record.startTime, record.endTime, record.floors))
            
            // Special cases
            is BloodPressureRecord -> listOf(
                createInstantRecord(
                    metadata, 
                    record.time, 
                    if (dataType == BLOOD_PRESSURE_DIASTOLIC) 
                        record.diastolic.inMillimetersOfMercury 
                    else 
                        record.systolic.inMillimetersOfMercury
                )
            )
            
            is HeartRateRecord -> record.samples.map { sample ->
                createInstantRecord(metadata, sample.time, sample.beatsPerMinute)
            }

            is SpeedRecord -> record.samples.map { sample ->
                createInstantRecord(metadata, sample.time, sample.speed.inMetersPerSecond)
            }
            
            is SleepSessionRecord -> listOf(
                createIntervalRecord(
                    metadata,
                    record.startTime,
                    record.endTime,
                    ChronoUnit.MINUTES.between(record.startTime, record.endTime)
                )
            )
            
            is MenstruationFlowRecord -> listOf(
                createInstantRecord(metadata, record.time, record.flow)
            )
            
            is NutritionRecord -> listOf(createNutritionRecord(record, metadata))
            
            else -> throw IllegalArgumentException("Health data type not supported")
        }
    }

    /**
     * Creates a standardized instant record map for point-in-time health measurements.
     * Used for data that represents a single moment measurement (weight, height, etc.).
     * 
     * @param metadata Record metadata containing source and recording information
     * @param time The timestamp when the measurement was taken
     * @param value The measured value
     * @return Map<String, Any?> Standardized instant record structure
     */
    private fun createInstantRecord(
        metadata: Metadata,
        time: Instant,
        value: Any
    ): Map<String, Any?> = createBaseRecord(metadata).apply {
        put("value", value)
        put("date_from", time.toEpochMilli())
        put("date_to", time.toEpochMilli())
    }

    /**
     * Creates a standardized interval record map for time-range health measurements.
     * Used for data that spans a time period (steps, distance, calories burned, etc.).
     * 
     * @param metadata Record metadata containing source and recording information
     * @param startTime Beginning of the measurement period
     * @param endTime End of the measurement period
     * @param value The measured value over the time period
     * @return Map<String, Any?> Standardized interval record structure
     */
    private fun createIntervalRecord(
        metadata: Metadata,
        startTime: Instant,
        endTime: Instant,
        value: Any
    ): Map<String, Any?> = createBaseRecord(metadata).apply {
        put("value", value)
        put("date_from", startTime.toEpochMilli())
        put("date_to", endTime.toEpochMilli())
    }

    /**
     * Creates the base record structure with common fields shared by all health records.
     * Includes metadata like UUID, source information, and recording method.
     * 
     * @param metadata Record metadata from Health Connect
     * @return MutableMap<String, Any?> Base record structure with common fields
     */
    private fun createBaseRecord(metadata: Metadata): MutableMap<String, Any?> = mutableMapOf(
        "uuid" to metadata.id,
        "source_id" to "",
        "source_name" to metadata.dataOrigin.packageName,
        "recording_method" to metadata.recordingMethod
    )

    /**
     * Creates a specialized nutrition record with comprehensive nutrient information.
     * Handles the complex nutrition data structure with multiple nutrient fields,
     * meal type classification, and optional food name.
     * 
     * @param record The NutritionRecord from Health Connect
     * @param metadata Record metadata
     * @return Map<String, Any?> Comprehensive nutrition record with all nutrient fields
     */
    private fun createNutritionRecord(
        record: NutritionRecord,
        metadata: Metadata
    ): Map<String, Any?> = createIntervalRecord(
        metadata,
        record.startTime,
        record.endTime,
        0 // Placeholder value since nutrition doesn't have a single value
    ).toMutableMap().apply {
        remove("value") // Remove the placeholder
        
        // Add all nutrition-specific fields
        putAll(mapOf(
            "calories" to record.energy?.inKilocalories,
            "protein" to record.protein?.inGrams,
            "carbs" to record.totalCarbohydrate?.inGrams,
            "fat" to record.totalFat?.inGrams,
            "caffeine" to record.caffeine?.inGrams,
            "vitamin_a" to record.vitaminA?.inGrams,
            "b1_thiamine" to record.thiamin?.inGrams,
            "b2_riboflavin" to record.riboflavin?.inGrams,
            "b3_niacin" to record.niacin?.inGrams,
            "b5_pantothenic_acid" to record.pantothenicAcid?.inGrams,
            "b6_pyridoxine" to record.vitaminB6?.inGrams,
            "b7_biotin" to record.biotin?.inGrams,
            "b9_folate" to record.folate?.inGrams,
            "b12_cobalamin" to record.vitaminB12?.inGrams,
            "vitamin_c" to record.vitaminC?.inGrams,
            "vitamin_d" to record.vitaminD?.inGrams,
            "vitamin_e" to record.vitaminE?.inGrams,
            "vitamin_k" to record.vitaminK?.inGrams,
            "calcium" to record.calcium?.inGrams,
            "chloride" to record.chloride?.inGrams,
            "cholesterol" to record.cholesterol?.inGrams,
            "choline" to null, // Not supported by Health Connect
            "chromium" to record.chromium?.inGrams,
            "copper" to record.copper?.inGrams,
            "fat_unsaturated" to record.unsaturatedFat?.inGrams,
            "fat_monounsaturated" to record.monounsaturatedFat?.inGrams,
            "fat_polyunsaturated" to record.polyunsaturatedFat?.inGrams,
            "fat_saturated" to record.saturatedFat?.inGrams,
            "fat_trans_monoenoic" to record.transFat?.inGrams,
            "fiber" to record.dietaryFiber?.inGrams,
            "iodine" to record.iodine?.inGrams,
            "iron" to record.iron?.inGrams,
            "magnesium" to record.magnesium?.inGrams,
            "manganese" to record.manganese?.inGrams,
            "molybdenum" to record.molybdenum?.inGrams,
            "phosphorus" to record.phosphorus?.inGrams,
            "potassium" to record.potassium?.inGrams,
            "selenium" to record.selenium?.inGrams,
            "sodium" to record.sodium?.inGrams,
            "sugar" to record.sugar?.inGrams,
            "water" to null, // Not supported by Health Connect
            "zinc" to record.zinc?.inGrams,
            "name" to (record.name ?: ""),
            "meal_type" to (HealthConstants.mapTypeToMealType[record.mealType] ?: MEAL_UNKNOWN)
        ))
    }

    /**
     * Converts a sleep stage to a Flutter-compatible map structure.
     * Transforms individual sleep stage data including duration and stage type
     * into a standardized format for Flutter consumption.
     * 
     * @param stage The sleep stage record from Health Connect
     * @param dataType The specific sleep data type being requested
     * @param metadata Parent sleep session metadata
     * @return List<Map<String, Any>> Sleep stage data in Flutter format
     */
    fun convertRecordStage(
        stage: SleepSessionRecord.Stage,
        dataType: String,
        metadata: Metadata
    ): List<Map<String, Any>> {
        return listOf(
            mapOf(
                "uuid" to metadata.id,
                "stage" to stage.stage,
                "value" to ChronoUnit.MINUTES.between(stage.startTime, stage.endTime),
                "date_from" to stage.startTime.toEpochMilli(),
                "date_to" to stage.endTime.toEpochMilli(),
                "source_id" to "",
                "source_name" to metadata.dataOrigin.packageName,
            )
        )
    }
    
    companion object {
        private const val BLOOD_PRESSURE_DIASTOLIC = "BLOOD_PRESSURE_DIASTOLIC"
        private const val MEAL_UNKNOWN = "UNKNOWN"
    }
}
