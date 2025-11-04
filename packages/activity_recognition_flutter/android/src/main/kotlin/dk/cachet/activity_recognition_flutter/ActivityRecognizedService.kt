package dk.cachet.activity_recognition_flutter

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.JobIntentService
import com.google.android.gms.location.ActivityRecognitionResult
import com.google.android.gms.location.DetectedActivity

class ActivityRecognizedService : JobIntentService() {

    companion object {
        private const val TAG = "ActivityRecognizedService"
        private const val JOB_ID = 1

        fun enqueueWork(context: Context, work: Intent) {
            enqueueWork(context, ActivityRecognizedService::class.java, JOB_ID, work)
        }

        fun getActivityString(type: Int): String = when (type) {
            DetectedActivity.IN_VEHICLE -> "IN_VEHICLE"
            DetectedActivity.ON_BICYCLE -> "ON_BICYCLE"
            DetectedActivity.ON_FOOT -> "ON_FOOT"
            DetectedActivity.RUNNING -> "RUNNING"
            DetectedActivity.STILL -> "STILL"
            DetectedActivity.TILTING -> "TILTING"
            DetectedActivity.WALKING -> "WALKING"
            else -> "UNKNOWN"
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onHandleWork(intent: Intent) {
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val result = ActivityRecognitionResult.extractResult(intent) ?: return
        val activities = result.probableActivities

        // Find the activity with highest confidence
        val mostLikely = activities.maxByOrNull { it.confidence } ?: return

        val type = getActivityString(mostLikely.type)
        val confidence = mostLikely.confidence
        val data = "$type,$confidence"

        Log.d(TAG, "Detected activity: $data")

        // Same preferences as in ActivityRecognitionFlutterPlugin
        val preferences = applicationContext.getSharedPreferences(
            ActivityRecognitionFlutterPlugin.ACTIVITY_RECOGNITION,
            Context.MODE_PRIVATE
        )

        preferences.edit()
            .clear()
            .putString(ActivityRecognitionFlutterPlugin.DETECTED_ACTIVITY, data)
            .apply()
    }
}
