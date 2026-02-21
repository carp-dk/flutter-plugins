package com.example.pedometer

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall

/** PedometerPlugin */
class PedometerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var stepDetectionChannel: EventChannel
    private lateinit var stepCountChannel: EventChannel
    private lateinit var methodChannel : MethodChannel;
    private lateinit var sensorManager : SensorManager;

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "isStepDetectionSupported"){
            val stepDetectionSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
            result.success(stepDetectionSensor != null)

        }
        else if (call.method == "isStepCountSupported"){
            val stepCountSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            result.success(stepCountSensor != null)
        }
    }
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPluginBinding) {
        /// Create channels
        stepDetectionChannel = EventChannel(flutterPluginBinding.binaryMessenger, "step_detection")
        stepCountChannel = EventChannel(flutterPluginBinding.binaryMessenger, "step_count")
        /// Create handlers
        val stepDetectionHandler = SensorStreamHandler(flutterPluginBinding, Sensor.TYPE_STEP_DETECTOR)
        val stepCountHandler = SensorStreamHandler(flutterPluginBinding, Sensor.TYPE_STEP_COUNTER)

        /// Set handlers
        stepDetectionChannel.setStreamHandler(stepDetectionHandler)
        stepCountChannel.setStreamHandler(stepCountHandler)

        // setup method channel
        val context = flutterPluginBinding.applicationContext
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.pedometer")
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        stepDetectionChannel.setStreamHandler(null)
        stepCountChannel.setStreamHandler(null)
        methodChannel.setMethodCallHandler(null)
    }

}
