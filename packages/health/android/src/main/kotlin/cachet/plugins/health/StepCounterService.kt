package cachet.plugins.health

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
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

        const val CHANNEL_ID = "StepCounterServiceChannel"
        const val CHANNEL_NAME = "Step Counter"
        const val NOTIFICATION_ID = 1

        fun initiated(): Boolean {
            return this::box.isInitialized;
        }
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        if (!initiated()) {
            box = MyObjectBox.builder()
                .androidContext(applicationContext)
                .build();
        }

        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        sensor = sensorManager.getDefaultSensor(SENSOR_NAME)!!
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundService()

        sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)

        return START_STICKY
    }

    private fun createNotificationChannel() {
        val notificationChannel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_DEFAULT)
        val notificationManager = applicationContext.getSystemService(NotificationManager::class.java)
        notificationManager.createNotificationChannel(notificationChannel)
    }

    private fun startForegroundService() {
        createNotificationChannel()

        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            NotificationCompat.Builder(this, CHANNEL_ID).build(),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
            } else {
                0
            }
        )
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
                Log.d(LOG, "Overflow detected. Resetting previousStepCount.")
                previousStepCount = steps  // Reset the previous count to avoid overflow issues
                return
            }

            val newSteps = steps - previousStepCount
            previousStepCount = steps


            val eventHappened =
                System.currentTimeMillis() + ((event.timestamp - SystemClock.elapsedRealtimeNanos()) / 1000000L)

            if (newSteps > 0) {
                val step = SensorStep().apply {
                    startTime = eventHappened
                    endTime = System.currentTimeMillis()
                    count = newSteps.toDouble()
                }

                box.boxFor(SensorStep::class.java).put(step)
                Log.d(
                    LOG,
                    "Steps: $newSteps at time: $eventHappened}-${System.currentTimeMillis()}"
                )
            }
        }
    }

    override fun onAccuracyChanged(p0: Sensor?, p1: Int) {
        Log.d(LOG, "onAccuracyChanged")
    }
}