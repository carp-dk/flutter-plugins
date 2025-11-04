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
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel

/**
 * ActivityRecognitionFlutterPlugin
 */
@SuppressLint("LongLogTag")
class ActivityRecognitionFlutterPlugin : FlutterPlugin, EventChannel.StreamHandler, ActivityAware,
    SharedPreferences.OnSharedPreferenceChangeListener {

    private var channel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var androidActivity: Activity? = null
    private var androidContext: Context? = null

    companion object {
        const val DETECTED_ACTIVITY = "detected_activity"
        const val ACTIVITY_RECOGNITION = "activity_recognition_flutter"
        private const val TAG = "activity_recognition_flutter"
    }

    /**
     * The main function for starting activity tracking.
     * Handling events is done inside [ActivityRecognizedService]
     */
    private fun startActivityTracking() {
        val activity = androidActivity ?: run {
            Log.e(TAG, "Activity is null, cannot start activity tracking")
            return
        }
        val context = androidContext ?: run {
            Log.e(TAG, "Context is null, cannot start activity tracking")
            return
        }

        // Start the service
        val intent = Intent(activity, ActivityRecognizedBroadcastReceiver::class.java)

        Log.d(TAG, "SDK = ${Build.VERSION.SDK_INT}")
        // Activity Recognition requires MUTABLE flag for API 31+
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(activity, 0, intent, flags)

        // Frequency in milliseconds
        val frequency = 5 * 1000L

        ActivityRecognition.getClient(context)
            .requestActivityUpdates(frequency, pendingIntent)
            .addOnSuccessListener {
                Log.d(TAG, "Successfully registered ActivityRecognition listener.")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to register ActivityRecognition listener.", e)
            }
    }

    /**
     * EventChannel.StreamHandler interface below
     */

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = EventChannel(flutterPluginBinding.binaryMessenger, ACTIVITY_RECOGNITION)
        channel?.setStreamHandler(this)
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val args = arguments as? Map<*, *>
        val fg = args?.get("foreground") as? Boolean ?: false

        if (fg) {
            startForegroundService()
        }
        Log.d(TAG, "Foreground mode: $fg")

        eventSink = events
        startActivityTracking()
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setStreamHandler(null)
        channel = null
    }

    override fun onCancel(arguments: Any?) {
        channel?.setStreamHandler(null)
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
        androidActivity = null
        androidContext = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        androidActivity = binding.activity
        androidContext = binding.activity.applicationContext
    }

    override fun onDetachedFromActivity() {
        androidActivity = null
        androidContext = null
    }

    /**
     * Shared preferences changed, i.e. latest activity
     */
    override fun onSharedPreferenceChanged(sharedPreferences: SharedPreferences?, key: String?) {
        if (key == DETECTED_ACTIVITY) {
            val result = sharedPreferences?.getString(DETECTED_ACTIVITY, "error") ?: "error"
            eventSink?.success(result)
        }
    }
}
