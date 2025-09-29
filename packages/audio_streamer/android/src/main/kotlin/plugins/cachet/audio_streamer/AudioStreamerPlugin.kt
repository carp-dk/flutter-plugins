package plugins.cachet.audio_streamer

import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import java.util.*

/** AudioStreamerPlugin */
class AudioStreamerPlugin : FlutterPlugin, RequestPermissionsResultListener, EventChannel.StreamHandler, ActivityAware {

    // / Constants
    private val eventChannelName = "audio_streamer.eventChannel"

    // / Method channel for returning the sample rate.
    private val methodChannelName = "audio_streamer.methodChannel"
    private var sampleRate = 44100 // standard value to initialize
    private var bufferSize = 6400 * 2; // / Magical number!
    private val maxAmplitude = 32767 // same as 2^15
    private val logTag = "AudioStreamerPlugin"

    // / Variables (i.e. will change value)
    private var eventSink: EventSink? = null
    @Volatile private var recording = false
    private var recordingThread: Thread? = null


    private var currentActivity: Activity? = null

    private lateinit var audioRecord: AudioRecord;

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val messenger = flutterPluginBinding.binaryMessenger
        val eventChannel = EventChannel(messenger, eventChannelName)
        eventChannel.setStreamHandler(this)
        val methodChannel = MethodChannel(messenger, methodChannelName)
        methodChannel.setMethodCallHandler {
                call, result ->
            if (call.method == "getSampleRate") {
                if (::audioRecord.isInitialized) {
                    result.success(audioRecord.sampleRate)
                } else {
                    result.error("UNAVAILABLE", "AudioRecord not initialized.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        stopRecording()
    }

    override fun onDetachedFromActivity() {
        currentActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        currentActivity = null
    }

    /**
     * Called from Flutter, starts the stream and updates the sample rate using the argument.
     */
    override fun onListen(arguments: Any?, events: EventSink?) {
        this.eventSink = events
        sampleRate = (arguments as Map<*, *>)["sampleRate"] as Int
        if (sampleRate < 4000 || sampleRate > 48000) {
            events!!.error("SampleRateError", "A sample rate of " + sampleRate + "Hz is not supported by Android.", null)
            return
        }
        startRecording()
    }

    /**
     * Called from Flutter, which cancels the stream.
     */
    override fun onCancel(arguments: Any?) {
        stopRecording()
    }

    /**
     * Called by the plugin itself whenever it detects that permissions have not been granted.
     */
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        val requestAudioPermissionCode = 200
        when (requestCode) {
            requestAudioPermissionCode -> if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) return true
        }
        return false
    }

    private fun startRecording() {
        if (recording) {
            Log.w(logTag, "Recording is already in progress")
            return
        }
        recording = true
        recordingThread = Thread { streamMicData() }
        recordingThread?.start()
    }

    private fun stopRecording() {
        if (!recording) {
            Log.w(logTag, "Recording is not in progress")
            return
        }
        recording = false
        try {
            recordingThread?.join()
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
        recordingThread = null
    }


    /**
     * Starts recording and streaming audio data from the mic.
     * Uses a buffer array of size 512. Whenever buffer is full, the content is sent to Flutter.
     * Sets the sample rate as defined by [sampleRate].
     *
     * Source:
     * https://www.newventuresoftware.com/blog/record-play-and-visualize-raw-audio-data-in-android
     */
    private fun streamMicData() {
        Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)

        val audioBuffer = ShortArray(bufferSize / 2)
        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.DEFAULT,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize,
            )

            if (audioRecord.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(logTag, "Audio Record can't initialize!")
                eventSink?.error("MIC_ERROR", "Audio Record can't initialize!", null)
                recording = false
                return
            }

            audioRecord.startRecording()

            while (recording) {
                val readSize = audioRecord.read(audioBuffer, 0, audioBuffer.size)
                if(readSize > 0) {
                    val audioBufferList = ArrayList<Double>()
                    for (i in 0 until readSize) {
                        val normalizedImpulse = audioBuffer[i].toDouble() / maxAmplitude.toDouble()
                        audioBufferList.add(normalizedImpulse)
                    }
                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success(audioBufferList)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(logTag, "Error while recording audio", e)
            eventSink?.error("MIC_ERROR", "Error while recording audio", e.message)
        } finally {
            if (::audioRecord.isInitialized) {
                if (audioRecord.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                    audioRecord.stop()
                }
                audioRecord.release()
            }
            recording = false
        }
    }
}