import Flutter
import UIKit

public class ScreenStatePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let screenStateDetector = ScreenStateDetector()
    let channel = FlutterEventChannel(
      name: "screenStateEvents",
      binaryMessenger: registrar.messenger()
    )
    channel.setStreamHandler(screenStateDetector)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}

enum ScreenState: String {
  case on = "SCREEN_ON"
  case off = "SCREEN_OFF"
  case unlock = "SCREEN_UNLOCKED"
}

public class ScreenStateDetector: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var lastState: ScreenState?

  private func handleEvent(screenState: ScreenState) {
    if eventSink == nil {
      return
    }

    eventSink?(screenState.rawValue)
  }

  private func emitCurrentState() {
    let currentState: ScreenState = UIApplication.shared.isProtectedDataAvailable ? .on : .off
    lastState = currentState
    handleEvent(screenState: currentState)
  }

  @objc
  private func handleProtectedDataDidBecomeAvailable() {
    if lastState == .off {
      handleEvent(screenState: .on)
    }

    lastState = .unlock
    handleEvent(screenState: .unlock)
  }

  @objc
  private func handleProtectedDataWillBecomeUnavailable() {
    lastState = .off
    handleEvent(screenState: .off)
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleProtectedDataDidBecomeAvailable),
      name: UIApplication.protectedDataDidBecomeAvailableNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleProtectedDataWillBecomeUnavailable),
      name: UIApplication.protectedDataWillBecomeUnavailableNotification,
      object: nil
    )

    // Provide an immediate state to avoid an empty stream until the first lock event.
    emitCurrentState()

    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self)
    eventSink = nil
    return nil
  }
}
