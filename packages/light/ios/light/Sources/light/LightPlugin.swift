import Flutter
import SensorKit

public class LightPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let methodChannelName = "light"
  private static let eventChannelName = "light.eventChannel"

  private var sensorKitStreamHandler: AnyObject?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: registrar.messenger()
    )

    let instance = LightPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAuthorizationStatus":
      if #available(iOS 14.0, *) {
        result(sensorKitHandler().authorizationStatus.rawValue)
      } else {
        result(LightAuthorizationStatus.unavailable.rawValue)
      }
    case "requestAuthorization":
      if #available(iOS 14.0, *) {
        sensorKitHandler().requestAuthorization { status, error in
          if let error {
            result(error)
            return
          }
          result(status.rawValue)
        }
      } else {
        result(LightAuthorizationStatus.unavailable.rawValue)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard #available(iOS 14.0, *) else {
      return FlutterError(
        code: "UNAVAILABLE",
        message: "Ambient light SensorKit support requires iOS 14.0 or later.",
        details: nil
      )
    }

    sensorKitHandler().startStreaming(events: events)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if #available(iOS 14.0, *) {
      sensorKitHandler().stopStreaming()
    }
    return nil
  }

  @available(iOS 14.0, *)
  private func sensorKitHandler() -> SensorKitLightStreamHandler {
    if let existingHandler = sensorKitStreamHandler as? SensorKitLightStreamHandler {
      return existingHandler
    }

    let newHandler = SensorKitLightStreamHandler()
    sensorKitStreamHandler = newHandler
    return newHandler
  }
}

private enum LightAuthorizationStatus: String {
  case notDetermined = "notDetermined"
  case authorized = "authorized"
  case denied = "denied"
  case unavailable = "unavailable"
}

@available(iOS 14.0, *)
private final class SensorKitLightStreamHandler: NSObject, SRSensorReaderDelegate {
  private let sensorUsageDictionaryKey = "NSSensorKitUsageDetail"
  private let sensorUsageAmbientLightKey = "SRSensorUsageAmbientLightSensor"
  private let initialFetchWindowSeconds = 5.0
  private let pollingIntervalSeconds = 2.0

  private let sensorReader = SRSensorReader(sensor: .ambientLightSensor)

  private var eventSink: FlutterEventSink?
  private var pollingTimer: Timer?
  private var lastFetchedTimestamp: SRAbsoluteTime?
  private var isFetching = false

  override init() {
    super.init()
    sensorReader.delegate = self
  }

  var authorizationStatus: LightAuthorizationStatus {
    lightAuthorizationStatus(from: sensorReader.authorizationStatus)
  }

  func requestAuthorization(
    completion: @escaping (_ status: LightAuthorizationStatus, _ error: FlutterError?) -> Void
  ) {
    guard hasAmbientUsageDescription() else {
      completion(
        .notDetermined,
        FlutterError(
          code: "MISSING_USAGE_DESCRIPTION",
          message:
            "Missing NSSensorKitUsageDetail/SRSensorUsageAmbientLightSensor in Info.plist.",
          details: nil
        )
      )
      return
    }

    SRSensorReader.requestAuthorization(sensors: [.ambientLightSensor]) { [weak self] error in
      DispatchQueue.main.async {
        guard let self else {
          completion(
            .unavailable,
            FlutterError(
              code: "DEALLOCATED",
              message: "Light plugin deallocated before authorization completed.",
              details: nil
            )
          )
          return
        }

        let status = self.authorizationStatus
        guard let error else {
          completion(status, nil)
          return
        }

        completion(status, self.flutterError(from: error))
      }
    }
  }

  func startStreaming(events: @escaping FlutterEventSink) {
    eventSink = events

    switch authorizationStatus {
    case .authorized:
      beginRecordingAndPolling()
    case .denied:
      sendError(
        FlutterError(
          code: "PERMISSION_DENIED",
          message: "SensorKit authorization for ambient light is denied.",
          details: nil
        )
      )
    case .notDetermined:
      requestAuthorization { [weak self] status, error in
        guard let self else {
          return
        }

        if let error {
          self.sendError(error)
          return
        }

        guard status == .authorized else {
          self.sendError(
            FlutterError(
              code: "PERMISSION_DENIED",
              message: "SensorKit authorization for ambient light was not granted.",
              details: nil
            )
          )
          return
        }

        self.beginRecordingAndPolling()
      }
    case .unavailable:
      sendError(
        FlutterError(
          code: "UNAVAILABLE",
          message: "SensorKit ambient light support is unavailable on this device.",
          details: nil
        )
      )
    }
  }

  func stopStreaming() {
    pollingTimer?.invalidate()
    pollingTimer = nil
    isFetching = false
    eventSink = nil
    sensorReader.stopRecording()
  }

  private func beginRecordingAndPolling() {
    sensorReader.startRecording()

    pollingTimer?.invalidate()
    pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingIntervalSeconds, repeats: true) {
      [weak self] _ in
      self?.fetchLatestSamples()
    }
    pollingTimer?.tolerance = pollingIntervalSeconds / 4
    if let pollingTimer {
      RunLoop.main.add(pollingTimer, forMode: .common)
    }

    fetchLatestSamples()
  }

  private func fetchLatestSamples() {
    guard !isFetching else {
      return
    }

    let request = SRFetchRequest()
    request.to = .current()
    request.from =
      lastFetchedTimestamp
      ?? .fromCFAbsoluteTime(_cf: CFAbsoluteTimeGetCurrent() - initialFetchWindowSeconds)

    isFetching = true
    sensorReader.fetch(request)
  }

  private func hasAmbientUsageDescription() -> Bool {
    guard
      let sensorUsageDetails = Bundle.main.object(forInfoDictionaryKey: sensorUsageDictionaryKey)
        as? [String: Any]
    else {
      return false
    }

    guard let usageValue = sensorUsageDetails[sensorUsageAmbientLightKey] as? String else {
      return false
    }

    return !usageValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func sendError(_ error: FlutterError) {
    eventSink?(error)
  }

  private func flutterError(from error: Error) -> FlutterError {
    let nsError = error as NSError
    let details: [String: Any] = [
      "domain": nsError.domain,
      "code": nsError.code,
      "localizedDescription": nsError.localizedDescription,
    ]

    guard nsError.domain == SRErrorDomain else {
      return FlutterError(
        code: "SENSORKIT_ERROR",
        message: nsError.localizedDescription,
        details: details
      )
    }

    switch nsError.code {
    case 0:
      return FlutterError(
        code: "INVALID_ENTITLEMENT",
        message:
          "Missing SensorKit entitlement. Add com.apple.developer.sensorkit.reader.allow with ambient-light-sensor.",
        details: details
      )
    case 1:
      return FlutterError(
        code: "NO_AUTHORIZATION",
        message: "No SensorKit authorization for ambient light.",
        details: details
      )
    case 2:
      return FlutterError(
        code: "DATA_INACCESSIBLE",
        message: "Ambient light data is inaccessible right now.",
        details: details
      )
    case 3:
      return FlutterError(
        code: "INVALID_FETCH_REQUEST",
        message: "SensorKit fetch request is invalid.",
        details: details
      )
    case 4:
      return FlutterError(
        code: "PROMPT_DECLINED",
        message: "SensorKit authorization prompt was declined.",
        details: details
      )
    default:
      return FlutterError(
        code: "SENSORKIT_ERROR",
        message: nsError.localizedDescription,
        details: details
      )
    }
  }

  private func lightAuthorizationStatus(
    from authorizationStatus: SRAuthorizationStatus
  ) -> LightAuthorizationStatus {
    switch authorizationStatus {
    case .authorized:
      return .authorized
    case .denied:
      return .denied
    case .notDetermined:
      return .notDetermined
    @unknown default:
      return .denied
    }
  }

  func sensorReader(_ reader: SRSensorReader, didChange authorizationStatus: SRAuthorizationStatus) {
    guard lightAuthorizationStatus(from: authorizationStatus) == .denied else {
      return
    }

    sendError(
      FlutterError(
        code: "PERMISSION_DENIED",
        message: "SensorKit authorization for ambient light changed to denied.",
        details: nil
      )
    )
  }

  func sensorReader(
    _ reader: SRSensorReader,
    fetching request: SRFetchRequest,
    didFetchResult result: SRFetchResult<AnyObject>
  ) -> Bool {
    defer { lastFetchedTimestamp = result.timestamp }

    guard let sample = result.sample as? SRAmbientLightSample else {
      return true
    }

    let lux = Int(sample.lux.converted(to: .lux).value.rounded())
    eventSink?(lux)
    return true
  }

  func sensorReader(_ reader: SRSensorReader, didCompleteFetch request: SRFetchRequest) {
    isFetching = false
  }

  func sensorReader(
    _ reader: SRSensorReader,
    fetching request: SRFetchRequest,
    failedWithError error: Error
  ) {
    isFetching = false
    sendError(flutterError(from: error))
  }

  @objc(sensorReader:startRecordingFailedWithError:)
  func sensorReader(_ reader: SRSensorReader, startRecordingFailedWithError error: Error) {
    sendError(flutterError(from: error))
  }
}
