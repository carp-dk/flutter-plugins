package dk.cachet.activity_recognition_flutter;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.JobIntentService;

import com.google.android.gms.location.ActivityRecognitionResult;
import com.google.android.gms.location.DetectedActivity;

import java.util.List;

public class ActivityRecognizedService extends JobIntentService {

    static void enqueueWork(Context context, Intent work) {
        enqueueWork(context, ActivityRecognizedService.class, 1, work);
    }

    @Override
    public int onStartCommand(@Nullable Intent intent, int flags, int startId) {
        return super.onStartCommand(intent, flags, startId);
    }

    // This method is called when service starts instead of onHandleIntent
    protected void onHandleWork(@Nullable Intent intent) {
        onHandleIntent(intent);
    }

    // remove override and make onHandleIntent private.
    private void onHandleIntent(@Nullable Intent intent) {
        ActivityRecognitionResult result = ActivityRecognitionResult.extractResult(intent);
        if (result == null) return;

        List<DetectedActivity> activities = result.getProbableActivities();
        if (activities == null || activities.isEmpty()) return;

        DetectedActivity mostLikely = activities.get(0);

        for (DetectedActivity a : activities) {
            if (a.getConfidence() > mostLikely.getConfidence()) {
                mostLikely = a;
            }
        }

        String type = getActivityString(mostLikely.getType());
        int confidence = mostLikely.getConfidence();

        String data = type + "," + confidence;

        Log.d("onHandleIntent", data);

        // Same preferences as in ActivityRecognitionFlutterPlugin.java
        SharedPreferences preferences =
                getApplicationContext().getSharedPreferences(
                        ActivityRecognitionFlutterPlugin.ACTIVITY_RECOGNITION, MODE_PRIVATE);
        if (preferences == null) return;

        preferences.edit().clear()
                .putString(
                        ActivityRecognitionFlutterPlugin.DETECTED_ACTIVITY,
                        data
                )
                .apply();
    }

    public static String getActivityString(int type) {
        if (type == DetectedActivity.IN_VEHICLE) return "IN_VEHICLE";
        if (type == DetectedActivity.ON_BICYCLE) return "ON_BICYCLE";
        if (type == DetectedActivity.ON_FOOT) return "ON_FOOT";
        if (type == DetectedActivity.RUNNING) return "RUNNING";
        if (type == DetectedActivity.STILL) return "STILL";
        if (type == DetectedActivity.TILTING) return "TILTING";
        if (type == DetectedActivity.WALKING) return "WALKING";

        // Default case
        return "UNKNOWN";
    }
}

