package cachet.plugins.health

import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.feature.ExperimentalFeatureAvailabilityApi
import androidx.health.connect.client.HealthConnectFeatures
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.permission.HealthPermission.Companion.PERMISSION_READ_HEALTH_DATA_HISTORY
import androidx.health.connect.client.permission.HealthPermission.Companion.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import java.time.Instant

/**
 * Handles Health Connect operational tasks including permissions, SDK status,
 * and data deletion operations. Manages the administrative aspects of Health Connect integration.
 */
class HealthDataOperations(
    private val healthConnectClient: HealthConnectClient,
    private val scope: CoroutineScope,
    private val healthConnectStatus: Int,
    private val healthConnectAvailable: Boolean
) {
    
    /**
     * Retrieves the current Health Connect SDK availability status.
     * Returns status codes indicating whether Health Connect is available, needs installation, etc.
     * 
     * @param call Method call from Flutter (unused)
     * @param result Flutter result callback to return SDK status integer
     */
    fun getHealthConnectSdkStatus(call: MethodCall, result: Result) {
        result.success(healthConnectStatus)
    }

    /**
     * Checks if the application has been granted the requested health data permissions.
     * Verifies permission status without triggering permission request dialogs.
     * 
     * @param call Method call containing 'types' (data types) and 'permissions' (access levels)
     * @param result Flutter result callback returning boolean permission status
     */
    fun hasPermissions(call: MethodCall, result: Result) {
        val args = call.arguments as HashMap<*, *>
        val types = (args["types"] as? ArrayList<*>)?.filterIsInstance<String>()!!
        val permissions = (args["permissions"] as? ArrayList<*>)?.filterIsInstance<Int>()!!

        val permList = preparePermissionsListInternal(types, permissions)
        if (permList == null) {
            result.success(false)
            return
        }
        
        scope.launch {
            result.success(
                healthConnectClient
                    .permissionController
                    .getGrantedPermissions()
                    .containsAll(permList),
            )
        }
    }

    /**
     * Prepares a list of Health Connect permission strings for authorization requests.
     * Converts Flutter data types and permission levels into Health Connect permission format.
     * 
     * @param call Method call containing 'types' and 'permissions' arrays
     * @return List<String>? List of permission strings, or null if invalid types provided
     */
    fun preparePermissionsList(call: MethodCall): List<String>? {
        val args = call.arguments as HashMap<*, *>
        val types = (args["types"] as? ArrayList<*>)?.filterIsInstance<String>()!!
        val permissions = (args["permissions"] as? ArrayList<*>)?.filterIsInstance<Int>()!!
        
        return preparePermissionsListInternal(types, permissions)
    }

    /**
     * Revokes all previously granted Health Connect permissions for this application.
     * Completely removes app access to Health Connect data.
     * 
     * @param call Method call from Flutter (unused)
     * @param result Flutter result callback returning success status
     */
    fun revokePermissions(call: MethodCall, result: Result) {
        scope.launch {
            Log.i("FLUTTER_HEALTH", "Revoking all Health Connect permissions")
            healthConnectClient.permissionController.revokeAllPermissions()
        }
        result.success(true)
    }

    /**
     * Checks if the health data history feature is available on the current device.
     * History feature allows access to data from before the app was installed.
     * 
     * @param call Method call from Flutter (unused)
     * @param result Flutter result callback returning boolean availability status
     */
    @OptIn(ExperimentalFeatureAvailabilityApi::class)
    fun isHealthDataHistoryAvailable(call: MethodCall, result: Result) {
        scope.launch {
            result.success(
                healthConnectClient
                    .features
                    .getFeatureStatus(HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_HISTORY) ==
                    HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
            )
        }
    }

    /**
     * Checks if the health data history permission has been granted.
     * Verifies if app can access historical health data.
     * 
     * @param call Method call from Flutter (unused)
     * @param result Flutter result callback returning boolean authorization status
     */
    fun isHealthDataHistoryAuthorized(call: MethodCall, result: Result) {
        scope.launch {
            result.success(
                healthConnectClient
                    .permissionController
                    .getGrantedPermissions()
                    .containsAll(listOf(PERMISSION_READ_HEALTH_DATA_HISTORY)),
            )
        }
    }

    /**
     * Checks if background health data reading feature is available on device.
     * Background feature allows data access when app is not in foreground.
     * 
     * @param call Method call from Flutter (unused)
     * @param result Flutter result callback returning boolean availability status
     */
    @OptIn(ExperimentalFeatureAvailabilityApi::class)
    fun isHealthDataInBackgroundAvailable(call: MethodCall, result: Result) {
        scope.launch {
            result.success(
                healthConnectClient
                    .features
                    .getFeatureStatus(HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_IN_BACKGROUND) ==
                    HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
            )
        }
    }

    /**
     * Checks if background health data reading permission has been granted.
     * Verifies if app can access health data in background mode.
     * 
     * @param call Method call from Flutter (unused)
     * @param result Flutter result callback returning boolean authorization status
     */
    fun isHealthDataInBackgroundAuthorized(call: MethodCall, result: Result) {
        scope.launch {
            result.success(
                healthConnectClient
                    .permissionController
                    .getGrantedPermissions()
                    .containsAll(listOf(PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND)),
            )
        }
    }

    /**
     * Deletes all health records of a specified type within a given time range.
     * Performs bulk deletion based on data type and time window.
     * 
     * @param call Method call containing 'dataTypeKey', 'startTime', and 'endTime'
     * @param result Flutter result callback returning boolean success status
     */
    fun deleteData(call: MethodCall, result: Result) {
        val type = call.argument<String>("dataTypeKey")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        
        if (!HealthConstants.mapToType.containsKey(type)) {
            Log.w("FLUTTER_HEALTH::ERROR", "Datatype $type not found in HC")
            result.success(false)
            return
        }
        
        val classType = HealthConstants.mapToType[type]!!

        scope.launch {
            try {
                healthConnectClient.deleteRecords(
                    recordType = classType,
                    timeRangeFilter = TimeRangeFilter.between(startTime, endTime),
                )
                result.success(true)
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "Successfully deleted $type records between $startTime and $endTime"
                )
            } catch (e: Exception) {
                Log.e(
                    "FLUTTER_HEALTH::ERROR",
                    "Error deleting $type records: ${e.message}"
                )
                result.success(false)
            }
        }
    }

    /**
     * Deletes a specific health record by its unique identifier and data type.
     * Allows precise deletion of individual health records.
     * 
     * @param call Method call containing 'dataTypeKey' and 'uuid'
     * @param result Flutter result callback returning boolean success status
     */
    fun deleteByUUID(call: MethodCall, result: Result) {
        val arguments = call.arguments as? HashMap<*, *>
        val dataTypeKey = (arguments?.get("dataTypeKey") as? String)!!
        val uuid = (arguments?.get("uuid") as? String)!!
        
        if (!HealthConstants.mapToType.containsKey(dataTypeKey)) {
            Log.w("FLUTTER_HEALTH::ERROR", "Datatype $dataTypeKey not found in HC")
            result.success(false)
            return
        }
        
        val classType = HealthConstants.mapToType[dataTypeKey]!!
        
        scope.launch {
            try {
                healthConnectClient.deleteRecords(
                    recordType = classType,
                    recordIdsList = listOf(uuid),
                    clientRecordIdsList = emptyList()
                )
                result.success(true)
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "[Health Connect] Record with UUID $uuid was successfully deleted!"
                )
            } catch (e: Exception) {
                Log.e("FLUTTER_HEALTH::ERROR", "Error deleting record with UUID: $uuid")
                Log.e("FLUTTER_HEALTH::ERROR", e.message ?: "unknown error")
                Log.e("FLUTTER_HEALTH::ERROR", e.stackTraceToString())
                result.success(false)
            }
        }
    }

    /**
     * Internal helper method to prepare Health Connect permission strings.
     * Converts data type names and access levels into proper permission format.
     * 
     * @param types List of health data type strings
     * @param permissions List of permission level integers (0=read, 1=read+write)
     * @return List<String>? Formatted permission strings, or null if invalid input
     */
    private fun preparePermissionsListInternal(
        types: List<String>, 
        permissions: List<Int>
    ): List<String>? {
        val permList = mutableListOf<String>()
        
        for ((i, typeKey) in types.withIndex()) {
            if (!HealthConstants.mapToType.containsKey(typeKey)) {
                Log.w(
                    "FLUTTER_HEALTH::ERROR",
                    "Datatype $typeKey not found in HC"
                )
                return null
            }
            
            val access = permissions[i]
            val dataType = HealthConstants.mapToType[typeKey]!!
            
            if (access == 0) {
                // Read permission only
                permList.add(
                    HealthPermission.getReadPermission(dataType),
                )
            } else {
                // Read and write permissions
                permList.addAll(
                    listOf(
                        HealthPermission.getReadPermission(dataType),
                        HealthPermission.getWritePermission(dataType),
                    ),
                )
            }
        }
        
        return permList
    }
}