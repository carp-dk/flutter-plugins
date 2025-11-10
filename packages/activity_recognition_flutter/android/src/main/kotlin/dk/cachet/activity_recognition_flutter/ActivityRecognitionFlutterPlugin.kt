package dk.cachet.activity_recognition_flutter

import android.annotation.SuppressLint
import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityRecognitionClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * ActivityRecognitionFlutterPlugin
 */
@SuppressLint("LongLogTag")
class ActivityRecognitionFlutterPlugin : FlutterPlugin, ActivityRecognitionHostApi, ActivityAware,
    SharedPreferences.OnSharedPreferenceChangeListener {

    private var androidActivity: Activity? = null
    private var androidContext: Context? = null
    private var activityRecognitionClient: ActivityRecognitionClient? = null
    private var flutterApi: ActivityRecognitionFlutterApi? = null
    private var pendingIntent: PendingIntent? = null

    companion object {
        const val DETECTED_ACTIVITY = "detected_activity"
        const val ACTIVITY_RECOGNITION = "activity_recognition_flutter"
        private const val TAG = "activity_recognition_flutter"
    }

    /**
     * Implementation of ActivityRecognitionHostApi
     */
    override fun startActivityUpdates(config: ActivityRecognitionConfig) {
        val activity = androidActivity ?: throw FlutterError(
            "NO_ACTIVITY",
            "Activity is null, cannot start activity tracking",
            null
        )
        val context = androidContext ?: throw FlutterError(
            "NO_CONTEXT",
            "Context is null, cannot start activity tracking",
            null
        )

        Log.d(TAG, "Starting activity updates with foreground: ${config.runForegroundService}")

        // Start foreground service if requested
        if (config.runForegroundService && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService()
        }

        // Start the activity recognition
        startActivityTracking(context, activity)
    }

    override fun stopActivityUpdates() {
        val context = androidContext ?: throw FlutterError(
            "NO_CONTEXT",
            "Context is null, cannot stop activity tracking",
            null
        )

        Log.d(TAG, "Stopping activity updates")

        pendingIntent?.let { intent ->
            activityRecognitionClient?.removeActivityUpdates(intent)
                ?.addOnSuccessListener {
                    Log.d(TAG, "Successfully stopped ActivityRecognition listener.")
                }
                ?.addOnFailureListener { e ->
                    Log.e(TAG, "Failed to stop ActivityRecognition listener.", e)
                }
        }

        // Stop foreground service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            stopForegroundService()
        }
    }

    override fun isActivityRecognitionAvailable(): Boolean {
        return true // Google Play Services Activity Recognition is generally available on Android
    }

    /**
     * The main function for starting activity tracking.
     * Handling events is done inside [ActivityRecognizedService]
     */
    private fun startActivityTracking(context: Context, activity: Activity) {
        // Start the service
        val intent = Intent(activity, ActivityRecognizedBroadcastReceiver::class.java)

        Log.d(TAG, "SDK = ${Build.VERSION.SDK_INT}")
        // Activity Recognition requires MUTABLE flag for API 31+
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        pendingIntent = PendingIntent.getBroadcast(activity, 0, intent, flags)

        // Frequency in milliseconds
        val frequency = 5 * 1000L

        activityRecognitionClient = ActivityRecognition.getClient(context)
        activityRecognitionClient?.requestActivityUpdates(frequency, pendingIntent!!)
            ?.addOnSuccessListener {
                Log.d(TAG, "Successfully registered ActivityRecognition listener.")
            }
            ?.addOnFailureListener { e ->
                Log.e(TAG, "Failed to register ActivityRecognition listener.", e)
            }
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private fun startForegroundService() {
        val activity = androidActivity ?: return
        val context = androidContext ?: return

        val intent = Intent(activity, ForegroundService::class.java).apply {
            action = "start"
            putExtra("title", "MonsensoMonitor")
            putExtra("text", "Monsenso Foreground Service")
            putExtra("icon", android.R.drawable.ic_menu_compass)
            putExtra("importance", 3)
            putExtra("id", 10)
        }

        context.startForegroundService(intent)
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private fun stopForegroundService() {
        val activity = androidActivity ?: return
        val context = androidContext ?: return

        val intent = Intent(activity, ForegroundService::class.java).apply {
            action = "stop"
        }
        context.startForegroundService(intent)
    }

    /**
     * FlutterPlugin interface
     */
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // Set up the HostApi (Flutter calls native)
        ActivityRecognitionHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        
        // Set up the FlutterApi (native calls Flutter)
        flutterApi = ActivityRecognitionFlutterApi(flutterPluginBinding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Clean up
        ActivityRecognitionHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
    }

    /**
     * ActivityAware interface below
     */
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        androidActivity = binding.activity
        androidContext = binding.activity.applicationContext

        val prefs = androidContext?.getSharedPreferences(ACTIVITY_RECOGNITION, Context.MODE_PRIVATE)
        prefs?.registerOnSharedPreferenceChangeListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        val prefs = androidContext?.getSharedPreferences(ACTIVITY_RECOGNITION, Context.MODE_PRIVATE)
        prefs?.unregisterOnSharedPreferenceChangeListener(this)
        androidActivity = null
        androidContext = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        androidActivity = binding.activity
        androidContext = binding.activity.applicationContext
        
        val prefs = androidContext?.getSharedPreferences(ACTIVITY_RECOGNITION, Context.MODE_PRIVATE)
        prefs?.registerOnSharedPreferenceChangeListener(this)
    }

    override fun onDetachedFromActivity() {
        val prefs = androidContext?.getSharedPreferences(ACTIVITY_RECOGNITION, Context.MODE_PRIVATE)
        prefs?.unregisterOnSharedPreferenceChangeListener(this)
        androidActivity = null
        androidContext = null
    }

    /**
     * Shared preferences changed, i.e. latest activity
     * Parse the activity string and send it to Flutter via Pigeon
     */
    override fun onSharedPreferenceChanged(sharedPreferences: SharedPreferences?, key: String?) {
        if (key == DETECTED_ACTIVITY) {
            val result = sharedPreferences?.getString(DETECTED_ACTIVITY, null) ?: return
            
            // Parse the result string "TYPE,confidence"
            val parts = result.split(",")
            if (parts.size < 2) return
            
            val activityType = mapActivityType(parts[0])
            val confidence = parts[1].toLongOrNull() ?: return
            val timestamp = System.currentTimeMillis()
            
            // Create event data
            val eventData = ActivityEventData(
                type = activityType,
                confidence = confidence,
                timestamp = timestamp
            )
            
            // Send to Flutter via Pigeon
            flutterApi?.onActivityUpdate(eventData) { result ->
                result.onFailure { error ->
                    Log.e(TAG, "Error sending activity update to Flutter: $error")
                }
            }
        }
    }

    /**
     * Map activity type string to ActivityTypeData enum
     */
    private fun mapActivityType(typeString: String): ActivityTypeData {
        return when (typeString) {
            "IN_VEHICLE" -> ActivityTypeData.IN_VEHICLE
            "ON_BICYCLE" -> ActivityTypeData.ON_BICYCLE
            "ON_FOOT" -> ActivityTypeData.ON_FOOT
            "RUNNING" -> ActivityTypeData.RUNNING
            "STILL" -> ActivityTypeData.STILL
            "TILTING" -> ActivityTypeData.TILTING
            "WALKING" -> ActivityTypeData.WALKING
            else -> ActivityTypeData.UNKNOWN
        }
    }
}
