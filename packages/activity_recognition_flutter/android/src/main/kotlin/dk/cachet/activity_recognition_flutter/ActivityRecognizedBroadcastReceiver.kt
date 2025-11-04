package dk.cachet.activity_recognition_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class ActivityRecognizedBroadcastReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "ActivityRecognizedBroadcastReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context != null && intent != null) {
            Log.d(TAG, "Activity recognition broadcast received")
            ActivityRecognizedService.enqueueWork(context, intent)
        }
    }
}
