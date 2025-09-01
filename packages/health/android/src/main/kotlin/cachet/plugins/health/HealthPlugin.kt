package cachet.plugins.health

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.annotation.NonNull
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import kotlinx.coroutines.*

/**
 * Main Flutter plugin class for Health Connect integration.
 * Manages plugin lifecycle, method channel communication, permission handling,
 * and coordinates between Flutter and Android Health Connect APIs.
 */
class HealthPlugin(private var channel: MethodChannel? = null) :
    MethodCallHandler, ActivityResultListener, Result, ActivityAware, FlutterPlugin {
    
    private var mResult: Result? = null
    private var handler: Handler? = null
    private var activity: Activity? = null
    private var context: Context? = null
    private var healthConnectRequestPermissionsLauncher: ActivityResultLauncher<Set<String>>? = null
    private lateinit var healthConnectClient: HealthConnectClient
    private lateinit var scope: CoroutineScope
    private var isReplySubmitted = false

    // Helper classes
    private lateinit var dataReader: HealthDataReader
    private lateinit var dataWriter: HealthDataWriter
    private lateinit var dataOperations: HealthDataOperations
    private lateinit var dataConverter: HealthDataConverter

    // Health Connect availability
    private var healthConnectAvailable = false
    private var healthConnectStatus = HealthConnectClient.SDK_UNAVAILABLE

    companion object {
        const val CHANNEL_NAME = "flutter_health"
    }

    /**
     * Initializes the plugin when attached to the Flutter engine.
     * Sets up method channel, checks Health Connect availability, and initializes helper classes.
     * 
     * @param flutterPluginBinding Plugin binding providing access to Flutter engine resources
     */
    override fun onAttachedToEngine(
        @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        handler = Handler(context!!.mainLooper)
        
        checkAvailability()
        if (healthConnectAvailable) {
            healthConnectClient = HealthConnectClient.getOrCreate(
                flutterPluginBinding.applicationContext
            )
            initializeHelpers()
        }
    }

    /**
     * Cleans up resources when plugin is detached from Flutter engine.
     * Cancels coroutines and nullifies references to prevent memory leaks.
     * 
     * @param binding Plugin binding (unused in cleanup)
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = null
        activity = null
        scope.cancel()
    }

    override fun success(p0: Any?) {
        handler?.post { mResult?.success(p0) }
    }

    override fun notImplemented() {
        handler?.post { mResult?.notImplemented() }
    }

    override fun error(
        errorCode: String,
        errorMessage: String?,
        errorDetails: Any?,
    ) {
        handler?.post { mResult?.error(errorCode, errorMessage, errorDetails) }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return false
    }

    /**
     * Handles method calls from Flutter and routes them to appropriate handler classes.
     * Central dispatcher for all Health Connect operations including permissions,
     * data reading, writing, and deletion.
     * 
     * @param call Method call from Flutter containing method name and arguments
     * @param result Result callback to return data or status to Flutter
     */
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            // SDK and Installation
            "installHealthConnect" -> installHealthConnect(call, result)
            "getHealthConnectSdkStatus" -> dataOperations.getHealthConnectSdkStatus(call, result)
            
            // Permissions
            "hasPermissions" -> dataOperations.hasPermissions(call, result)
            "requestAuthorization" -> requestAuthorization(call, result)
            "revokePermissions" -> dataOperations.revokePermissions(call, result)
            
            // History permissions
            "isHealthDataHistoryAvailable" -> dataOperations.isHealthDataHistoryAvailable(call, result)
            "isHealthDataHistoryAuthorized" -> dataOperations.isHealthDataHistoryAuthorized(call, result)
            "requestHealthDataHistoryAuthorization" -> requestHealthDataHistoryAuthorization(call, result)
            
            // Background permissions
            "isHealthDataInBackgroundAvailable" -> dataOperations.isHealthDataInBackgroundAvailable(call, result)
            "isHealthDataInBackgroundAuthorized" -> dataOperations.isHealthDataInBackgroundAuthorized(call, result)
            "requestHealthDataInBackgroundAuthorization" -> requestHealthDataInBackgroundAuthorization(call, result)
            
            // Reading data
            "getData" -> dataReader.getData(call, result)
            "getIntervalData" -> dataReader.getIntervalData(call, result)
            "getAggregateData" -> dataReader.getAggregateData(call, result)
            "getTotalStepsInInterval" -> dataReader.getTotalStepsInInterval(call, result)
            
            // Writing data
            "writeData" -> dataWriter.writeData(call, result)
            "writeWorkoutData" -> dataWriter.writeWorkoutData(call, result)
            "writeBloodPressure" -> dataWriter.writeBloodPressure(call, result)
            "writeBloodOxygen" -> dataWriter.writeBloodOxygen(call, result)
            "writeMenstruationFlow" -> dataWriter.writeMenstruationFlow(call, result)
            "writeMeal" -> dataWriter.writeMeal(call, result)
            // TODO: Add support for multiple speed for iOS as well 
            // "writeMultipleSpeed" -> dataWriter.writeMultipleSpeedData(call, result)
            
            // Deleting data
            "delete" -> dataOperations.deleteData(call, result)
            "deleteByUUID" -> dataOperations.deleteByUUID(call, result)
            
            else -> result.notImplemented()
        }
    }

    /**
     * Called when activity is attached to the plugin.
     * Sets up permission request launcher and activity result handling.
     * 
     * @param binding Activity plugin binding providing activity context
     */
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        if (channel == null) {
            return
        }
        binding.addActivityResultListener(this)
        activity = binding.activity

        val requestPermissionActivityContract =
            PermissionController.createRequestPermissionResultContract()

        healthConnectRequestPermissionsLauncher =
            (activity as ComponentActivity).registerForActivityResult(
                requestPermissionActivityContract
            ) { granted -> onHealthConnectPermissionCallback(granted) }
    }
    
    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    /**
     * Called when activity is detached from plugin.
     * Cleans up activity-specific resources and permission launchers.
     */
    override fun onDetachedFromActivity() {
        if (channel == null) {
            return
        }
        activity = null
        healthConnectRequestPermissionsLauncher = null
    }

    /**
     * Checks Health Connect availability and SDK status on the current device.
     * Determines if Health Connect is installed and accessible.
     */
    private fun checkAvailability() {
        healthConnectStatus = HealthConnectClient.getSdkStatus(context!!)
        healthConnectAvailable = healthConnectStatus == HealthConnectClient.SDK_AVAILABLE
    }

    /**
     * Initializes helper classes for data operations after Health Connect client is ready.
     * Creates instances of reader, writer, operations, and converter classes.
     */
    private fun initializeHelpers() {
        dataConverter = HealthDataConverter()
        dataReader = HealthDataReader(healthConnectClient, scope, context!!, dataConverter)
        dataWriter = HealthDataWriter(healthConnectClient, scope)
        dataOperations = HealthDataOperations(healthConnectClient, scope, healthConnectStatus, healthConnectAvailable)
    }

    /**
     * Launches Health Connect installation flow via Google Play Store.
     * Directs users to install Health Connect when it's not available.
     * 
     * @param call Method call from Flutter (unused)
     * @param result Flutter result callback
     */
    private fun installHealthConnect(call: MethodCall, result: Result) {
        val uriString =
            "market://details?id=com.google.android.apps.healthdata&url=healthconnect%3A%2F%2Fonboarding"
        context!!.startActivity(
            Intent(Intent.ACTION_VIEW).apply {
                setPackage("com.android.vending")
                data = android.net.Uri.parse(uriString)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("overlay", true)
                putExtra("callerId", context!!.packageName)
            }
        )
        result.success(null)
    }

    /**
     * Handles permission request results from Health Connect permission dialog.
     * Called when user responds to permission request, updates Flutter with result.
     * 
     * @param permissionGranted Set of permission strings that were granted
     */
    private fun onHealthConnectPermissionCallback(permissionGranted: Set<String>) {
        if (!isReplySubmitted) {
            if (permissionGranted.isEmpty()) {
                mResult?.success(false)
                Log.i("FLUTTER_HEALTH", "Health Connect permissions were not granted! Make sure to declare the required permissions in the AndroidManifest.xml file.")
            } else {
                mResult?.success(true)
                Log.i("FLUTTER_HEALTH", "${permissionGranted.size} Health Connect permissions were granted!")
                Log.i("FLUTTER_HEALTH", "Permissions granted: $permissionGranted") 
            }
            isReplySubmitted = true
        }
    }

    /**
     * Initiates Health Connect permission request flow.
     * Prepares permission list and launches system permission dialog.
     * 
     * @param call Method call containing permission types and access levels
     * @param result Flutter result callback for permission request outcome
     */
    private fun requestAuthorization(call: MethodCall, result: Result) {
        if (context == null) {
            result.success(false)
            return
        }

        if (healthConnectRequestPermissionsLauncher == null) {
            result.success(false)
            Log.i("FLUTTER_HEALTH", "Permission launcher not found")
            return
        }

        // Store the result to be called in onHealthConnectPermissionCallback
        mResult = result
        isReplySubmitted = false
        
        val permList = dataOperations.preparePermissionsList(call)
        if (permList == null) {
            result.success(false)
            return
        }
        
        healthConnectRequestPermissionsLauncher!!.launch(permList.toSet())
    }

    /**
     * Requests specific permission for accessing health data history.
     * Launches permission dialog for historical data access capability.
     * 
     * @param call Method call from Flutter (unused)
     * @param result Flutter result callback for permission request outcome
     */
    private fun requestHealthDataHistoryAuthorization(call: MethodCall, result: Result) {
        if (context == null || healthConnectRequestPermissionsLauncher == null) {
            result.success(false)
            Log.i("FLUTTER_HEALTH", "Permission launcher not found")
            return
        }

        mResult = result
        isReplySubmitted = false
        healthConnectRequestPermissionsLauncher!!.launch(
            setOf(HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY)
        )
    }

    /**
     * Requests specific permission for background health data access.
     * Launches permission dialog for background data reading capability.
     * 
     * @param call Method call from Flutter (unused)
     * @param result Flutter result callback for permission request outcome
     */
    private fun requestHealthDataInBackgroundAuthorization(call: MethodCall, result: Result) {
        if (context == null || healthConnectRequestPermissionsLauncher == null) {
            result.success(false)
            Log.i("FLUTTER_HEALTH", "Permission launcher not found")
            return
        }

        mResult = result
        isReplySubmitted = false
        healthConnectRequestPermissionsLauncher!!.launch(
            setOf(HealthPermission.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND)
        )
    }
}