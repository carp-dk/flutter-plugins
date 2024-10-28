package cachet.plugins.health

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import io.objectbox.BoxStore


class StepCounterService : Service(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private lateinit var sensor: Sensor

    private var previousStepCount = 0
    private val maxStepsThreshold = Int.MAX_VALUE / 2

    companion object {
        lateinit var box: BoxStore;
        const val LOG = "StepCounterService"
        const val SENSOR_NAME = Sensor.TYPE_STEP_COUNTER

        fun isRunning(): Boolean {
            return this::box.isInitialized;
        }
    }
    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()

        box = MyObjectBox.builder()
            .androidContext(applicationContext)
            .build();

        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        sensor = sensorManager.getDefaultSensor(SENSOR_NAME)!!
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundService()

        sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)

        return START_STICKY
    }
    private fun startForegroundService() {
        val channelId = "my_foreground_service_channel"
        createNotificationChannel(channelId)

        val notification = Notification.Builder(this, channelId)
            .setContentTitle("Step Detection")
            .setContentText("Built-in step detection is working.")
            .build()

        startForeground(10001, notification)
    }

    private fun createNotificationChannel(channelId: String) {
        val channel = NotificationChannel(
            channelId,
            "Built-in step detection is working.",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }


    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == SENSOR_NAME) {
            val steps = event.values[0].toInt()

            if (previousStepCount == 0) {
                previousStepCount = steps
            }

            if (steps < previousStepCount && previousStepCount > maxStepsThreshold) {
                Log.d(LOG,"Overflow detected. Resetting previousStepCount.")
                previousStepCount = steps  // Reset the previous count to avoid overflow issues
                return
            }

            val newSteps = steps - previousStepCount
            previousStepCount = steps


            val eventHappened = System.currentTimeMillis() + ((event.timestamp- SystemClock.elapsedRealtimeNanos())/1000000L)

            if (newSteps > 0) {
                val step = SensorStep().apply {
                    startTime = eventHappened
                    endTime = System.currentTimeMillis()
                    count = newSteps.toDouble()
                }

                box.boxFor(SensorStep::class.java).put(step)
                Log.d(LOG,"Steps: $newSteps at time: $eventHappened}-${System.currentTimeMillis()}")
            }
        }
    }
    override fun onAccuracyChanged(p0: Sensor?, p1: Int) {
        Log.d(LOG,"onAccuracyChanged")
    }
}