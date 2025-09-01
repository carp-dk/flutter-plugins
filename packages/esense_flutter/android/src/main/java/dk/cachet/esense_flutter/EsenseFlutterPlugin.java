package dk.cachet.esense_flutter;

import androidx.annotation.NonNull;

import android.Manifest;
import io.flutter.plugin.common.*;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.*;
import io.flutter.plugin.common.PluginRegistry;


/** EsenseFlutterPlugin */
public class EsenseFlutterPlugin implements FlutterPlugin {

  // Channel naming
  public static final String ESenseManagerMethodChannelName = "esense.io/esense_manager";
  public static final String ESenseConnectionEventChannelName = "esense.io/esense_connection";
  public static final String ESenseEventEventChannelName = "esense.io/esense_events";
  public static final String ESenseSensorEventChannelName = "esense.io/esense_sensor";

  /// The MethodChannel and EventChannels that will the communication between Flutter and native Android
  private MethodChannel eSenseManagerMethodChannel;
  private EventChannel eSenseConnectionEventChannel;
  private EventChannel eSenseEventChannel;
  private EventChannel eSenseSensorEventChannel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    final ESenseConnectionEventStreamHandler eSenseConnectionEventStreamHandler = new ESenseConnectionEventStreamHandler();
    final ESenseManagerMethodCallHandler eSenseManagerMethodCallHandler = new ESenseManagerMethodCallHandler(flutterPluginBinding.getApplicationContext(), eSenseConnectionEventStreamHandler);

    eSenseManagerMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), ESenseManagerMethodChannelName);
    eSenseManagerMethodChannel.setMethodCallHandler(eSenseManagerMethodCallHandler);

    eSenseConnectionEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), ESenseConnectionEventChannelName);
    eSenseConnectionEventChannel.setStreamHandler(eSenseConnectionEventStreamHandler);

    eSenseEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), ESenseEventEventChannelName);
    eSenseEventChannel.setStreamHandler(new ESenseEventStreamHandler(eSenseManagerMethodCallHandler));

    eSenseSensorEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), ESenseSensorEventChannelName);
    eSenseSensorEventChannel.setStreamHandler(new ESenseSensorEventStreamHandler(eSenseManagerMethodCallHandler));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    eSenseManagerMethodChannel.setMethodCallHandler(null);
    eSenseConnectionEventChannel.setStreamHandler(null);
    eSenseEventChannel.setStreamHandler(null);
    eSenseSensorEventChannel.setStreamHandler(null);
  }
}
