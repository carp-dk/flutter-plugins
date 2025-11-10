import Flutter
import UIKit
import CoreMotion

/// A Flutter plugin for activity recognition on iOS using CoreMotion
@objc public class ActivityRecognitionFlutterPlugin: NSObject, FlutterPlugin, ActivityRecognitionHostApi {
    
    private let activityManager = CMMotionActivityManager()
    private let operationQueue = OperationQueue()
    private var flutterApi: ActivityRecognitionFlutterApi?
    private var isTracking = false
    
    /// Registers the plugin with the Flutter engine
    /// - Parameter registrar: The plugin registrar provided by Flutter
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let instance = ActivityRecognitionFlutterPlugin(messenger: messenger)
        
        // Set up the HostApi (Flutter calls native)
        ActivityRecognitionHostApiSetup.setUp(binaryMessenger: messenger, api: instance)
    }
    
    init(messenger: FlutterBinaryMessenger) {
        super.init()
        
        // Configure operation queue
        operationQueue.name = "activity_recognition_flutter.queue"
        operationQueue.qualityOfService = .userInitiated
        
        // Set up the FlutterApi (native calls Flutter)
        flutterApi = ActivityRecognitionFlutterApi(binaryMessenger: messenger)
    }
    
    // MARK: - ActivityRecognitionHostApi Implementation
    
    /// Starts activity recognition with the given configuration
    /// - Parameter config: Configuration for activity recognition
    /// - Throws: PigeonError if activity recognition is not available
    func startActivityUpdates(config: ActivityRecognitionConfig) throws {
        // Check if activity recognition is available
        guard CMMotionActivityManager.isActivityAvailable() else {
            throw PigeonError(
                code: "UNAVAILABLE",
                message: "Activity recognition is not available on this device",
                details: nil
            )
        }
        
        // Don't start if already tracking
        guard !isTracking else {
            return
        }
        
        // Note: runForegroundService is Android-only and ignored on iOS
        
        // Start activity updates
        activityManager.startActivityUpdates(to: operationQueue) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            let activityType = self.extractActivityType(from: activity)
            let confidence = self.extractConfidence(from: activity)
            let timestamp = Int64(Date().timeIntervalSince1970 * 1000) // milliseconds
            
            let eventData = ActivityEventData(
                type: activityType,
                confidence: confidence,
                timestamp: timestamp
            )
            
            // Send event to Flutter via Pigeon
            self.flutterApi?.onActivityUpdate(event: eventData) { result in
                if case .failure(let error) = result {
                    print("Error sending activity update to Flutter: \(error)")
                }
            }
        }
        
        isTracking = true
    }
    
    /// Stops activity recognition
    /// - Throws: PigeonError if there's an error stopping
    func stopActivityUpdates() throws {
        activityManager.stopActivityUpdates()
        isTracking = false
    }
    
    /// Checks if activity recognition is available on the device
    /// - Returns: true if available, false otherwise
    /// - Throws: Never throws, just returns the availability status
    func isActivityRecognitionAvailable() throws -> Bool {
        return CMMotionActivityManager.isActivityAvailable()
    }
    
    // MARK: - Private Helper Methods
    
    /// Extracts the activity type from a CMMotionActivity
    /// - Parameter activity: The motion activity to extract from
    /// - Returns: The ActivityTypeData enum value
    private func extractActivityType(from activity: CMMotionActivity) -> ActivityTypeData {
        // Check activities in order of priority
        if activity.stationary {
            return .still
        } else if activity.walking {
            return .walking
        } else if activity.running {
            return .running
        } else if activity.automotive {
            return .inVehicle
        } else if activity.cycling {
            return .onBicycle
        } else {
            return .unknown
        }
    }
    
    /// Extracts the confidence level from a CMMotionActivity
    /// - Parameter activity: The motion activity to extract from
    /// - Returns: An integer representing the confidence level (10, 50, or 100)
    private func extractConfidence(from activity: CMMotionActivity) -> Int64 {
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
