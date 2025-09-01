package dk.cachet.notifications;

import android.app.Notification;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build.VERSION_CODES;
import android.os.Build.VERSION;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;
import androidx.annotation.NonNull;

import androidx.annotation.RequiresApi;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;

/**
 * NotificationsPlugin
 */
public class NotificationsPlugin implements FlutterPlugin, EventChannel.StreamHandler {

  private static final String TAG = "NotificationsPlugin";
  private EventChannel eventChannel;
  private Context context;

  public void requestPermission() {
    /// Sort out permissions for notifications
    if (!permissionGranted()) {
      Intent permissionScreen = new Intent("android.settings" +
          ".ACTION_NOTIFICATION_LISTENER_SETTINGS");
      permissionScreen.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
      context.startActivity(permissionScreen);
    }
  }

  private boolean permissionGranted() {
    String packageName = context.getPackageName();
    String flat = Settings.Secure.getString(context.getContentResolver(),
        "enabled_notification_listeners");
    if (!TextUtils.isEmpty(flat)) {
      String[] names = flat.split(":");
      for (String name : names) {
        ComponentName componentName = ComponentName.unflattenFromString(name);
        boolean nameMatch = TextUtils.equals(packageName, componentName.getPackageName());
        if (nameMatch) {
          return true;
        }
      }
    }
    return false;
  }

  @RequiresApi(api = VERSION_CODES.JELLY_BEAN_MR2)
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    /// Init event channel
    BinaryMessenger binaryMessenger = flutterPluginBinding.getBinaryMessenger();
    eventChannel = new EventChannel(binaryMessenger, "notifications");
    eventChannel.setStreamHandler(this);

    /// Get context
    context = flutterPluginBinding.getApplicationContext();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    eventChannel.setStreamHandler(null);
  }

  @RequiresApi(api = VERSION_CODES.JELLY_BEAN_MR2)
  @Override
  public void onListen(Object arguments, EventSink events) {

    if (permissionGranted()) {

      /// Set up receiver
      IntentFilter intentFilter = new IntentFilter();
      intentFilter.addAction(NotificationListener.NOTIFICATION_INTENT);

      NotificationReceiver receiver = new NotificationReceiver(events);
      if (VERSION.SDK_INT >= VERSION_CODES.TIRAMISU) {
        context.registerReceiver(receiver, intentFilter, Context.RECEIVER_EXPORTED);
      } else {
        context.registerReceiver(receiver, intentFilter);
      }

      /// Set up listener intent
      Intent listenerIntent = new Intent(context, NotificationListener.class);
      context.startService(listenerIntent);
      Log.i(TAG, "Started the notification tracking service.");
    } else {
      requestPermission();
      Log.e(TAG, "Failed to start notification tracking; Permissions were not yet granted.");
    }
  }

  @Override
  public void onCancel(Object arguments) {
    eventChannel.setStreamHandler(null);
  }
}
