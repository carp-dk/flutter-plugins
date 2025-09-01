package dk.cachet.light;

import androidx.annotation.NonNull;

import android.annotation.TargetApi;
import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Build;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * LightPlugin
 */
public class LightPlugin implements FlutterPlugin, EventChannel.StreamHandler {
    private SensorEventListener sensorEventListener = null;
    private SensorManager sensorManager = null;
    private Sensor sensor = null;
    private EventChannel eventChannel = null;
    private static final String STEP_COUNT_CHANNEL_NAME =
            "light.eventChannel";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        /// Init sensor manager
        Context context = flutterPluginBinding.getApplicationContext();
        sensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
        sensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT);

        /// Init event channel
        BinaryMessenger binaryMessenger = flutterPluginBinding.getBinaryMessenger();
        eventChannel = new EventChannel(binaryMessenger, STEP_COUNT_CHANNEL_NAME);
        eventChannel.setStreamHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        /// Cancel the handling of stream data
        eventChannel.setStreamHandler(null);
        onCancel(null);
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        /// Set up the event sensor for the light sensor
        sensorEventListener = createSensorEventListener(events);
        sensorManager.registerListener(sensorEventListener, sensor, SensorManager.SENSOR_DELAY_NORMAL);
    }

    @Override
    public void onCancel(Object arguments) {
        /// Finish listening to events
        sensorManager.unregisterListener(sensorEventListener);
    }
    
    SensorEventListener createSensorEventListener(final EventChannel.EventSink events) {
        return new SensorEventListener() {
            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {
                /// Do nothing
            }

            @Override
            public void onSensorChanged(SensorEvent event) {
                /// Extract lux value and send it to Flutter via the event sink
                int lux = (int) event.values[0];
                events.success(lux);
            }
        };
    }
}
