package cachet.plugins.health

import android.content.Context
import android.os.Handler
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.AggregateGroupByDurationRequest
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import java.time.Duration
import java.time.Instant
import java.time.temporal.ChronoUnit

/**
 * Handles reading and querying health data from Health Connect.
 * Manages data retrieval, filtering, aggregation, and format conversion for Flutter consumption.
 */
class HealthDataReader(
    private val healthConnectClient: HealthConnectClient,
    private val scope: CoroutineScope,
    private val context: Context,
    private val dataConverter: HealthDataConverter
) {
    private val recordingFilter = HealthRecordingFilter()

    /**
     * Retrieves all health data points of a specified type within a given time range.
     * Handles pagination for large datasets and applies recording method filtering.
     * Supports special processing for workout and sleep data.
     * 
     * @param call Method call containing 'dataTypeKey', 'startTime', 'endTime', 'recordingMethodsToFilter'
     * @param result Flutter result callback returning list of health data maps
     */
    fun getData(call: MethodCall, result: Result) {
        val dataType = call.argument<String>("dataTypeKey")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        val healthConnectData = mutableListOf<Map<String, Any?>>()
        val recordingMethodsToFilter = call.argument<List<Int>>("recordingMethodsToFilter")!!

        Log.i(
            "FLUTTER_HEALTH",
            "Getting data for $dataType between $startTime and $endTime, filtering by $recordingMethodsToFilter"
        )

        scope.launch {
            try {
                HealthConstants.mapToType[dataType]?.let { classType ->
                    val records = mutableListOf<Record>()

                    // Set up the initial request to read health records
                    var request = ReadRecordsRequest(
                        recordType = classType,
                        timeRangeFilter = TimeRangeFilter.between(startTime, endTime),
                    )

                    var response = healthConnectClient.readRecords(request)
                    var pageToken = response.pageToken

                    // Add the records from the initial response
                    records.addAll(response.records)

                    // Continue making requests while there is a page token
                    while (!pageToken.isNullOrEmpty()) {
                        request = ReadRecordsRequest(
                            recordType = classType,
                            timeRangeFilter = TimeRangeFilter.between(startTime, endTime),
                            pageToken = pageToken
                        )
                        response = healthConnectClient.readRecords(request)
                        pageToken = response.pageToken
                        records.addAll(response.records)
                    }

                    // Handle special cases
                    when (dataType) {
                        WORKOUT -> handleWorkoutData(records, recordingMethodsToFilter, healthConnectData)
                        SLEEP_SESSION, SLEEP_ASLEEP, SLEEP_AWAKE, SLEEP_AWAKE_IN_BED, 
                        SLEEP_LIGHT, SLEEP_DEEP, SLEEP_REM, SLEEP_OUT_OF_BED, SLEEP_UNKNOWN -> 
                            handleSleepData(records, recordingMethodsToFilter, dataType, healthConnectData)
                        else -> {
                            val filteredRecords = recordingFilter.filterRecordsByRecordingMethods(
                                recordingMethodsToFilter,
                                records
                            )
                            for (rec in filteredRecords) {
                                healthConnectData.addAll(
                                    dataConverter.convertRecord(rec, dataType)
                                )
                            }
                        }
                    }
                }
                Handler(context.mainLooper).run { result.success(healthConnectData) }
            } catch (e: Exception) {
                Log.i(
                    "FLUTTER_HEALTH::ERROR",
                    "Unable to return $dataType due to the following exception:"
                )
                Log.e("FLUTTER_HEALTH::ERROR", Log.getStackTraceString(e))
                result.success(null)
            }
        }
    }

    /**
     * Retrieves aggregated health data grouped by time intervals.
     * Calculates totals, averages, or counts over specified time periods.
     * 
     * @param call Method call containing 'dataTypeKey', 'interval', 'startTime', 'endTime'
     * @param result Flutter result callback returning list of aggregated data maps
     */
    fun getAggregateData(call: MethodCall, result: Result) {
        val dataType = call.argument<String>("dataTypeKey")!!
        val interval = call.argument<Long>("interval")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        val healthConnectData = mutableListOf<Map<String, Any?>>()
        
        scope.launch {
            try {
                HealthConstants.mapToAggregateMetric[dataType]?.let { metricClassType ->
                    val request = AggregateGroupByDurationRequest(
                        metrics = setOf(metricClassType),
                        timeRangeFilter = TimeRangeFilter.between(startTime, endTime),
                        timeRangeSlicer = Duration.ofSeconds(interval)
                    )
                    val response = healthConnectClient.aggregateGroupByDuration(request)

                    for (durationResult in response) {
                        var totalValue = durationResult.result[metricClassType]
                        if (totalValue is Length) {
                            totalValue = totalValue.inMeters
                        } else if (totalValue is Energy) {
                            totalValue = totalValue.inKilocalories
                        }

                        val packageNames = durationResult.result.dataOrigins
                            .joinToString { origin -> origin.packageName }

                        val data = mapOf<String, Any>(
                            "value" to (totalValue ?: 0),
                            "date_from" to durationResult.startTime.toEpochMilli(),
                            "date_to" to durationResult.endTime.toEpochMilli(),
                            "source_name" to packageNames,
                            "source_id" to "",
                            "is_manual_entry" to packageNames.contains("user_input")
                        )
                        healthConnectData.add(data)
                    }
                }
                Handler(context.mainLooper).run { result.success(healthConnectData) }
            } catch (e: Exception) {
                Log.i(
                    "FLUTTER_HEALTH::ERROR",
                    "Unable to return $dataType due to the following exception:"
                )
                Log.e("FLUTTER_HEALTH::ERROR", Log.getStackTraceString(e))
                result.success(null)
            }
        }
    }

    /**
     * Retrieves interval-based health data. Currently delegates to getAggregateData.
     * Maintained for API compatibility and potential future differentiation.
     * 
     * @param call Method call with interval data parameters
     * @param result Flutter result callback returning interval data
     */
    fun getIntervalData(call: MethodCall, result: Result) {
        getAggregateData(call, result)
    }

    /**
     * Gets total step count within a specified time interval with optional filtering.
     * Optimizes between aggregated queries and filtered individual record queries
     * based on whether recording method filtering is required.
     * 
     * @param call Method call containing 'startTime', 'endTime', 'recordingMethodsToFilter'
     * @param result Flutter result callback returning total step count as integer
     */
    fun getTotalStepsInInterval(call: MethodCall, result: Result) {
        val start = call.argument<Long>("startTime")!!
        val end = call.argument<Long>("endTime")!!
        val recordingMethodsToFilter = call.argument<List<Int>>("recordingMethodsToFilter")!!

        if (recordingMethodsToFilter.isEmpty()) {
            getAggregatedStepCount(start, end, result)
        } else {
            getStepCountFiltered(start, end, recordingMethodsToFilter, result)
        }
    }

    // --------- Private Methods ---------

    /**
     * Retrieves aggregated step count using Health Connect's built-in aggregation.
     * Provides optimized step counting when no filtering is required.
     * 
     * @param start Start time in milliseconds
     * @param end End time in milliseconds
     * @param result Flutter result callback returning step count
     */
    private fun getAggregatedStepCount(start: Long, end: Long, result: Result) {
        val startInstant = Instant.ofEpochMilli(start)
        val endInstant = Instant.ofEpochMilli(end)
        
        scope.launch {
            try {
                val response = healthConnectClient.aggregate(
                    AggregateRequest(
                        metrics = setOf(StepsRecord.COUNT_TOTAL),
                        timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant),
                    ),
                )
                val stepsInInterval = response[StepsRecord.COUNT_TOTAL] ?: 0L

                Log.i("FLUTTER_HEALTH::SUCCESS", "returning $stepsInInterval steps")
                result.success(stepsInInterval)
            } catch (e: Exception) {
                Log.e(
                    "FLUTTER_HEALTH::ERROR",
                    "Unable to return steps due to the following exception:"
                )
                Log.e("FLUTTER_HEALTH::ERROR", Log.getStackTraceString(e))
                result.success(null)
            }
        }
    }

    /**
     * Retrieves step count with recording method filtering applied.
     * Manually sums individual step records after applying specified filters.
     * 
     * @param start Start time in milliseconds
     * @param end End time in milliseconds
     * @param recordingMethodsToFilter List of recording methods to exclude
     * @param result Flutter result callback returning filtered step count
     */
    private fun getStepCountFiltered(
        start: Long, 
        end: Long, 
        recordingMethodsToFilter: List<Int>, 
        result: Result
    ) {
        scope.launch {
            try {
                val request = ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(
                        Instant.ofEpochMilli(start),
                        Instant.ofEpochMilli(end)
                    ),
                )
                val response = healthConnectClient.readRecords(request)
                val filteredRecords = recordingFilter.filterRecordsByRecordingMethods(
                    recordingMethodsToFilter,
                    response.records
                )
                val totalSteps = filteredRecords.sumOf { (it as StepsRecord).count.toInt() }
                
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "returning $totalSteps steps (excluding manual entries)"
                )
                result.success(totalSteps)
            } catch (e: Exception) {
                Log.e(
                    "FLUTTER_HEALTH::ERROR",
                    "Unable to return steps due to the following exception:"
                )
                Log.e("FLUTTER_HEALTH::ERROR", Log.getStackTraceString(e))
                result.success(null)
            }
        }
    }

    /**
     * Handles special processing for workout/exercise session data.
     * Enriches workout records with associated distance, energy, and step data
     * by querying related records within the workout time period.
     * 
     * @param records List of ExerciseSessionRecord objects
     * @param recordingMethodsToFilter Recording methods to exclude
     * @param healthConnectData Mutable list to append processed workout data
     */
    private suspend fun handleWorkoutData(
        records: List<Record>,
        recordingMethodsToFilter: List<Int>,
        healthConnectData: MutableList<Map<String, Any?>>
    ) {
        val filteredRecords = recordingFilter.filterRecordsByRecordingMethods(
            recordingMethodsToFilter,
            records
        )

        for (rec in filteredRecords) {
            val record = rec as ExerciseSessionRecord
            
            // Get distance data
            val distanceRequest = healthConnectClient.readRecords(
                ReadRecordsRequest(
                    recordType = DistanceRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(
                        record.startTime,
                        record.endTime,
                    ),
                ),
            )
            var totalDistance = 0.0
            for (distanceRec in distanceRequest.records) {
                totalDistance += distanceRec.distance.inMeters
            }

            // Get energy burned data
            val energyBurnedRequest = healthConnectClient.readRecords(
                ReadRecordsRequest(
                    recordType = TotalCaloriesBurnedRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(
                        record.startTime,
                        record.endTime,
                    ),
                ),
            )
            var totalEnergyBurned = 0.0
            for (energyBurnedRec in energyBurnedRequest.records) {
                totalEnergyBurned += energyBurnedRec.energy.inKilocalories
            }

            // Get steps data
            val stepRequest = healthConnectClient.readRecords(
                ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(
                        record.startTime,
                        record.endTime
                    ),
                ),
            )
            var totalSteps = 0.0
            for (stepRec in stepRequest.records) {
                totalSteps += stepRec.count
            }

            // Add final datapoint
            healthConnectData.add(
                mapOf<String, Any?>(
                    "uuid" to record.metadata.id,
                    "workoutActivityType" to
                            (HealthConstants.workoutTypeMap
                                .filterValues { it == record.exerciseType }
                                .keys
                                .firstOrNull() ?: "OTHER"),
                    "totalDistance" to if (totalDistance == 0.0) null else totalDistance,
                    "totalDistanceUnit" to "METER",
                    "totalEnergyBurned" to if (totalEnergyBurned == 0.0) null else totalEnergyBurned,
                    "totalEnergyBurnedUnit" to "KILOCALORIE",
                    "totalSteps" to if (totalSteps == 0.0) null else totalSteps,
                    "totalStepsUnit" to "COUNT",
                    "unit" to "MINUTES",
                    "date_from" to rec.startTime.toEpochMilli(),
                    "date_to" to rec.endTime.toEpochMilli(),
                    "source_id" to "",
                    "source_name" to record.metadata.dataOrigin.packageName,
                ),
            )
        }
    }

    /**
     * Handles special processing for sleep session and stage data.
     * Processes sleep sessions and individual sleep stages based on requested data type.
     * Converts sleep stage enumerations to meaningful duration and type information.
     * 
     * @param records List of SleepSessionRecord objects
     * @param recordingMethodsToFilter Recording methods to exclude
     * @param dataType Specific sleep data type being requested
     * @param healthConnectData Mutable list to append processed sleep data
     */
    private fun handleSleepData(
        records: List<Record>,
        recordingMethodsToFilter: List<Int>,
        dataType: String,
        healthConnectData: MutableList<Map<String, Any?>>
    ) {
        val filteredRecords = recordingFilter.filterRecordsByRecordingMethods(
            recordingMethodsToFilter,
            records
        )

        for (rec in filteredRecords) {
            if (rec is SleepSessionRecord) {
                if (dataType == SLEEP_SESSION) {
                    healthConnectData.addAll(
                        dataConverter.convertRecord(rec, dataType)
                    )
                } else {
                    for (recStage in rec.stages) {
                        if (dataType == HealthConstants.mapSleepStageToType[recStage.stage]) {
                            healthConnectData.addAll(
                                dataConverter.convertRecordStage(
                                    recStage,
                                    dataType,
                                    rec.metadata
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    companion object {
        // Sleep-related constants
        private const val SLEEP_SESSION = "SLEEP_SESSION"
        private const val SLEEP_ASLEEP = "SLEEP_ASLEEP"
        private const val SLEEP_AWAKE = "SLEEP_AWAKE"
        private const val SLEEP_AWAKE_IN_BED = "SLEEP_AWAKE_IN_BED"
        private const val SLEEP_LIGHT = "SLEEP_LIGHT"
        private const val SLEEP_DEEP = "SLEEP_DEEP"
        private const val SLEEP_REM = "SLEEP_REM"
        private const val SLEEP_OUT_OF_BED = "SLEEP_OUT_OF_BED"
        private const val SLEEP_UNKNOWN = "SLEEP_UNKNOWN"
        private const val WORKOUT = "WORKOUT"
    }
}
