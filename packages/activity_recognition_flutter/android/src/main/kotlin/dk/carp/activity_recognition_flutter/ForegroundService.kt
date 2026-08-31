package dk.carp.activity_recognition_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.IBinder

/**
 * Keeps the process alive so that detections keep arriving while the app is in
 * the background.
 *
 * Started by [ActivityRecognitionFlutterPlugin] only when the Dart side asks for
 * it through `runForegroundService`. The notification can be customised through
 * the intent extras below.
 */
class ForegroundService : Service() {

    companion object {
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_ICON = "icon"
        const val EXTRA_ID = "id"

        private const val CHANNEL_ID = "activity_recognition_flutter.foreground"
        private const val DEFAULT_NOTIFICATION_ID = 197812504
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Activity recognition",
                // Low importance keeps the notification silent while still visible,
                // which is what a background monitoring service should be.
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Keeps detecting your activity while the app is in the background."
            },
        )

        val icon = intent?.getIntExtra(EXTRA_ICON, 0) ?: 0
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle(intent?.getStringExtra(EXTRA_TITLE) ?: "Activity recognition")
            .setContentText(intent?.getStringExtra(EXTRA_TEXT) ?: "Detecting your activity.")
            .setSmallIcon(if (icon != 0) icon else android.R.drawable.ic_menu_compass)
            .setOngoing(true)
            .build()

        val notificationId = intent?.getIntExtra(EXTRA_ID, 0) ?: 0
        startForeground(if (notificationId != 0) notificationId else DEFAULT_NOTIFICATION_ID, notification)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
