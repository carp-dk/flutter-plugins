import AVFoundation
import Flutter
import UIKit

public class SwiftAudioStreamerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  private var eventSink: FlutterEventSink?
  var engine = AVAudioEngine()
  var audioData: [Float] = []
  var recording = false
  var preferredSampleRate: Int? = nil

  // Register plugin
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SwiftAudioStreamerPlugin()

    // Set flutter communication channel for emitting updates
    let eventChannel = FlutterEventChannel.init(
      name: "audio_streamer.eventChannel", binaryMessenger: registrar.messenger())
    // Set flutter communication channel for receiving method calls
    let methodChannel = FlutterMethodChannel.init(
      name: "audio_streamer.methodChannel", binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: FlutterResult) -> Void in
      if call.method == "getSampleRate" {
        // Return sample rate that is currently being used, may differ from requested
        result(Int(AVAudioSession.sharedInstance().sampleRate))
      }
    }
    eventChannel.setStreamHandler(instance)
    instance.setupNotifications()
  }

  private func setupNotifications() {
    // Get the default notification center instance.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption(notification:)),
      name: AVAudioSession.interruptionNotification,
      object: nil)
  }

  @objc func handleInterruption(notification: Notification) {
    // AVAudioSession posts interruption notifications on an internal thread, so
    // hop onto the platform thread before touching the event sink or the engine.
    onPlatformThread { self.handleInterruptionOnPlatformThread(notification) }
  }

  private func handleInterruptionOnPlatformThread(_ notification: Notification) {
    // If no eventSink to emit events to, do nothing (wait)
    if eventSink == nil {
      return
    }

    guard let userInfo = notification.userInfo,
      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: typeValue)
    else {
      return
    }

    switch type {
    case .began: ()
    case .ended:
      // An interruption ended. Resume playback, if appropriate.

      guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
        return
      }
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
      if options.contains(.shouldResume) {
        startRecording(sampleRate: preferredSampleRate)
      }

    default:
      eventSink?(
        FlutterError(
          code: "100", message: "Recording was interrupted",
          details: "Another process interrupted recording."))
    }
  }

  // Runs [block] on the platform (main) thread.
  //
  // Platform channel messages must be sent on the platform thread, but the
  // audio tap and the interruption notification both fire on other threads.
  // See https://docs.flutter.dev/platform-integration/platform-channels#channels-and-platform-threading
  private func onPlatformThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }

  // Handle stream emitting (Swift => Flutter)
  private func emitValues(values: [Float]) {
    // Emit values event to Flutter. The sink is only read on the platform
    // thread, so a stream cancelled in the meantime simply drops the buffer.
    onPlatformThread { self.eventSink?(values) }
  }

  // Event Channel: On Stream Listen
  public func onListen(
    withArguments arguments: Any?,
    eventSink: @escaping FlutterEventSink
  ) -> FlutterError? {
    self.eventSink = eventSink
    if let args = arguments as? [String: Any] {
      preferredSampleRate = args["sampleRate"] as? Int
      startRecording(sampleRate: preferredSampleRate)
    } else {
      startRecording(sampleRate: nil)
    }
    return nil
  }

  // Event Channel: On Stream Cancelled
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self)
    eventSink = nil
    engine.stop()
    return nil
  }

  func startRecording(sampleRate: Int?) {
    engine = AVAudioEngine()

    do {
      try AVAudioSession.sharedInstance().setCategory(
        AVAudioSession.Category.playAndRecord, options: .mixWithOthers)
      try AVAudioSession.sharedInstance().setActive(true)

      if let sampleRateNotNull = sampleRate {
        // Try to set sample rate
        try AVAudioSession.sharedInstance().setPreferredSampleRate(Double(sampleRateNotNull))
      }

      let input = engine.inputNode
      let bus = 0

      input.installTap(onBus: bus, bufferSize: 22050, format: input.inputFormat(forBus: bus)) {
        buffer, _ -> Void in
        let samples = buffer.floatChannelData?[0]
        // audio callback, samples in samples[0]...samples[buffer.frameLength-1]
        let arr = Array(UnsafeBufferPointer(start: samples, count: Int(buffer.frameLength)))
        self.emitValues(values: arr)
      }

      try engine.start()
    } catch {
      onPlatformThread {
        self.eventSink?(
          FlutterError(
            code: "100", message: "Unable to start audio session",
            details: error.localizedDescription
          ))
      }
    }
  }
}
