package dk.cachet.activity_recognition_flutter

import android.annotation.TargetApi
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log

class ForegroundService : Service() {

    companion object {
        private const val CHANNEL_ID = "foreground.service.channel"
        private const val CHANNEL_NAME = "Background Services"
        private const val DEFAULT_NOTIFICATION_ID = 197812504
    }

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val title = "Foreground service"
            val text = "Foreground monitoring service"
            val icon = android.R.drawable.ic_menu_compass
            val importance = NotificationManager.IMPORTANCE_LOW
            val id = DEFAULT_NOTIFICATION_ID
            
            startPluginForegroundService(title, text, icon, importance, id)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && intent != null) {
            val title = intent.getStringExtra("title") ?: "Foreground service"
            val text = intent.getStringExtra("text") ?: "Foreground monitoring service"
            val icon = intent.getIntExtra("icon", android.R.drawable.ic_menu_compass)
            val importanceValue = intent.getIntExtra("importance", 1)
            val id = intent.getIntExtra("id", DEFAULT_NOTIFICATION_ID)
            
            val importance = when (importanceValue) {
                2 -> NotificationManager.IMPORTANCE_DEFAULT
                3 -> NotificationManager.IMPORTANCE_HIGH
                else -> NotificationManager.IMPORTANCE_LOW
            }
            
            startPluginForegroundService(title, text, icon, importance, id)
        }
        return START_STICKY
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun startPluginForegroundService(
        title: String,
        text: String,
        icon: Int,
        importance: Int,
        id: Int
    ) {
        val context: Context = applicationContext
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create notification channel if it doesn't exist. Do NOT delete an existing
        // channel while a foreground service is (or may be) active, as this causes a
        // SecurityException on newer Android versions.
        val existingChannel = notificationManager.getNotificationChannel(CHANNEL_ID)
        if (existingChannel == null) {
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = "Enables background processing."
            }
            notificationManager.createNotificationChannel(channel)
        } else {
            if (existingChannel.importance != importance) {
                Log.w(
                    "activity_recognition_flutter",
                    "Notification channel '$CHANNEL_ID' already exists with importance ${existingChannel.importance}; requested $importance. Importance can't be changed once created."
                )
            }
            existingChannel.description = "Enables background processing."
            notificationManager.createNotificationChannel(existingChannel)
        }

        val iconResource = if (icon != 0) icon else android.R.drawable.star_on

        val notification = Notification.Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setSmallIcon(iconResource)
            .build()

        // Put service in foreground and show notification (id of 0 is not allowed)
        val notificationId = if (id != 0) id else DEFAULT_NOTIFICATION_ID
        
        // For Android 14 (API 34) and above, we need to specify the foreground service type
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                notificationId, 
                notification, 
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            startForeground(notificationId, notification)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        throw UnsupportedOperationException("Not yet implemented")
    }
}
