import Flutter
import UIKit
import CoreMotion

/// A Flutter plugin for activity recognition on iOS using CoreMotion
@objc public class ActivityRecognitionFlutterPlugin: NSObject, FlutterPlugin {
    
    /// Registers the plugin with the Flutter engine
    /// - Parameter registrar: The plugin registrar provided by Flutter
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let handler = ActivityStreamHandler()
        let channel = FlutterEventChannel(
            name: "activity_recognition_flutter",
            binaryMessenger: registrar.messenger()
        )
        channel.setStreamHandler(handler)
    }
}

/// Handles the stream of activity recognition events
public class ActivityStreamHandler: NSObject, FlutterStreamHandler {
    
    private let activityManager = CMMotionActivityManager()
    private let operationQueue = OperationQueue()
    
    public override init() {
        super.init()
        // Configure operation queue
        operationQueue.name = "activity_recognition_flutter.queue"
        operationQueue.qualityOfService = .userInitiated
    }
    
    /// Called when Flutter starts listening to the event stream
    /// - Parameters:
    ///   - arguments: Optional arguments from Flutter
    ///   - eventSink: The event sink to send activity updates to
    /// - Returns: FlutterError if there's an error, nil otherwise
    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        // Check if activity recognition is available
        guard CMMotionActivityManager.isActivityAvailable() else {
            return FlutterError(
                code: "UNAVAILABLE",
                message: "Activity recognition is not available on this device",
                details: nil
            )
        }
        
        // Start activity updates
        activityManager.startActivityUpdates(to: operationQueue) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            let activityType = self.extractActivityType(from: activity)
            let confidence = self.extractConfidence(from: activity)
            let data = "\(activityType),\(confidence)"
            
            // Send event to Flutter on the main thread
            DispatchQueue.main.async {
                events(data)
            }
        }
        
        return nil
    }
    
    /// Called when Flutter stops listening to the event stream
    /// - Parameter arguments: Optional arguments from Flutter
    /// - Returns: FlutterError if there's an error, nil otherwise
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        activityManager.stopActivityUpdates()
        return nil
    }
    
    // MARK: - Private Helper Methods
    
    /// Extracts the activity type from a CMMotionActivity
    /// - Parameter activity: The motion activity to extract from
    /// - Returns: A string representation of the activity type
    private func extractActivityType(from activity: CMMotionActivity) -> String {
        // Check activities in order of priority
        if activity.stationary {
            return "STILL"
        } else if activity.walking {
            return "WALKING"
        } else if activity.running {
            return "RUNNING"
        } else if activity.automotive {
            return "IN_VEHICLE"
        } else if activity.cycling {
            return "ON_BICYCLE"
        } else {
            return "UNKNOWN"
        }
    }
    
    /// Extracts the confidence level from a CMMotionActivity
    /// - Parameter activity: The motion activity to extract from
    /// - Returns: An integer representing the confidence level (10, 50, or 100)
    private func extractConfidence(from activity: CMMotionActivity) -> Int {
        switch activity.confidence {
        case .low:
            return 10
        case .medium:
            return 50
        case .high:
            return 100
        @unknown default:
            return -1
        }
    }
}