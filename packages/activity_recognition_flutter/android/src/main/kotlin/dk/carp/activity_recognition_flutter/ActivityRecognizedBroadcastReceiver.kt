package dk.carp.activity_recognition_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.ActivityRecognitionResult
import com.google.android.gms.location.DetectedActivity

/**
 * Receives detections from the Activity Recognition API and hands the most
 * probable one to [DetectedActivityStore].
 */
class ActivityRecognizedBroadcastReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityRecognitionResult.hasResult(intent)) return

        val result = ActivityRecognitionResult.extractResult(intent) ?: return
        val mostProbable = result.probableActivities.maxByOrNull { it.confidence } ?: return

        DetectedActivityStore.write(
            context,
            PlatformActivity(
                type = mostProbable.toPlatformActivityType(),
                confidence = mostProbable.confidence.toLong(),
                timestamp = result.time,
            ),
        )
    }
}

private fun DetectedActivity.toPlatformActivityType(): PlatformActivityType = when (type) {
    DetectedActivity.IN_VEHICLE -> PlatformActivityType.IN_VEHICLE
    DetectedActivity.ON_BICYCLE -> PlatformActivityType.ON_BICYCLE
    DetectedActivity.ON_FOOT -> PlatformActivityType.ON_FOOT
    DetectedActivity.RUNNING -> PlatformActivityType.RUNNING
    DetectedActivity.STILL -> PlatformActivityType.STILL
    DetectedActivity.TILTING -> PlatformActivityType.TILTING
    DetectedActivity.WALKING -> PlatformActivityType.WALKING
    else -> PlatformActivityType.UNKNOWN
}
