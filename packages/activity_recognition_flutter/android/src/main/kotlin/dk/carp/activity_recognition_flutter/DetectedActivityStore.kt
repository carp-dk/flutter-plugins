package dk.carp.activity_recognition_flutter

import android.content.Context
import android.content.SharedPreferences

/**
 * Carries detections from [ActivityRecognizedBroadcastReceiver] to
 * [ActivityRecognitionFlutterPlugin].
 *
 * The receiver is started by the system and may run while no Flutter engine is
 * attached, so the two sides cannot hold references to each other. Writing the
 * latest detection to shared preferences lets the plugin observe it whenever it
 * happens to be listening.
 */
internal object DetectedActivityStore {
    private const val PREFERENCES_NAME = "activity_recognition_flutter"

    const val KEY_DETECTED_ACTIVITY = "detected_activity"

    fun preferences(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    fun write(context: Context, activity: PlatformActivity) {
        preferences(context).edit()
            // Clearing first guarantees a change notification even when the same
            // activity is detected twice in a row.
            .clear()
            .putString(KEY_DETECTED_ACTIVITY, encode(activity))
            .apply()
    }

    fun read(preferences: SharedPreferences): PlatformActivity? =
        preferences.getString(KEY_DETECTED_ACTIVITY, null)?.let(::decode)

    private fun encode(activity: PlatformActivity): String =
        "${activity.type.raw},${activity.confidence},${activity.timestamp}"

    private fun decode(value: String): PlatformActivity? {
        val parts = value.split(",")
        if (parts.size != 3) return null

        val type = parts[0].toIntOrNull()?.let(PlatformActivityType::ofRaw) ?: return null
        val confidence = parts[1].toLongOrNull() ?: return null
        val timestamp = parts[2].toLongOrNull() ?: return null

        return PlatformActivity(type = type, confidence = confidence, timestamp = timestamp)
    }
}
