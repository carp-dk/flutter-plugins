import HealthKit

/// Utilities class containing helper methods for data manipulation
class HealthUtilities {
    
    /// Sanitize metadata to make it Flutter-friendly
    /// - Parameter metadata: The metadata dictionary to sanitize
    /// - Returns: A dictionary with sanitized values
    static func sanitizeMetadata(_ metadata: [String: Any]?) -> [String: Any] {
        guard let metadata = metadata else { return [:] }
        
        var sanitized = [String: Any]()
        
        for (key, value) in metadata {
            switch value {
            case let stringValue as String:
                sanitized[key] = stringValue
            case let numberValue as NSNumber:
                sanitized[key] = numberValue
            case let boolValue as Bool:
                sanitized[key] = boolValue
            case let arrayValue as [Any]:
                sanitized[key] = sanitizeArray(arrayValue)
            case let mapValue as [String: Any]:
                sanitized[key] = sanitizeMetadata(mapValue)
            default:
                continue
            }
        }
        
        return sanitized
    }
    
    /// Sanitize an array to make it Flutter-friendly
    /// - Parameter array: The array to sanitize
    /// - Returns: An array with sanitized values
    static func sanitizeArray(_ array: [Any]) -> [Any] {
        var sanitizedArray: [Any] = []
        
        for value in array {
            switch value {
            case let stringValue as String:
                sanitizedArray.append(stringValue)
            case let numberValue as NSNumber:
                sanitizedArray.append(numberValue)
            case let boolValue as Bool:
                sanitizedArray.append(boolValue)
            case let arrayValue as [Any]:
                sanitizedArray.append(sanitizeArray(arrayValue))
            case let mapValue as [String: Any]:
                sanitizedArray.append(sanitizeMetadata(mapValue))
            default:
                continue
            }
        }
        
        return sanitizedArray
    }
    
    /// Convert milliseconds since epoch to Date
    /// - Parameter milliseconds: Milliseconds since epoch
    /// - Returns: Date object
    static func dateFromMilliseconds(_ milliseconds: Double) -> Date {
        return Date(timeIntervalSince1970: milliseconds / 1000)
    }
}

/// Extension to provide type conversion helpers for HKWorkoutActivityType
extension HKWorkoutActivityType {
    /// Convert HKWorkoutActivityType to string
    /// - Parameter type: The workout activity type
    /// - Returns: String representation of the activity type
    static func toString(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .americanFootball: return "americanFootball"
        case .archery: return "archery"
        case .australianFootball: return "australianFootball"
        case .badminton: return "badminton"
        case .baseball: return "baseball"
        case .basketball: return "basketball"
        case .bowling: return "bowling"
        case .boxing: return "boxing"
        case .climbing: return "climbing"
        case .cricket: return "cricket"
        case .crossTraining: return "crossTraining"
        case .curling: return "curling"
        case .cycling: return "cycling"
        case .dance: return "dance"
        case .danceInspiredTraining: return "danceInspiredTraining"
        case .elliptical: return "elliptical"
        case .equestrianSports: return "equestrianSports"
        case .fencing: return "fencing"
        case .fishing: return "fishing"
        case .functionalStrengthTraining: return "functionalStrengthTraining"
        case .golf: return "golf"
        case .gymnastics: return "gymnastics"
        case .handball: return "handball"
        case .hiking: return "hiking"
        case .hockey: return "hockey"
        case .hunting: return "hunting"
        case .lacrosse: return "lacrosse"
        case .martialArts: return "martialArts"
        case .mindAndBody: return "mindAndBody"
        case .mixedMetabolicCardioTraining: return "mixedMetabolicCardioTraining"
        case .paddleSports: return "paddleSports"
        case .play: return "play"
        case .preparationAndRecovery: return "preparationAndRecovery"
        case .racquetball: return "racquetball"
        case .rowing: return "rowing"
        case .rugby: return "rugby"
        case .running: return "running"
        case .sailing: return "sailing"
        case .skatingSports: return "skatingSports"
        case .snowSports: return "snowSports"
        case .soccer: return "soccer"
        case .softball: return "softball"
        case .squash: return "squash"
        case .stairClimbing: return "stairClimbing"
        case .surfingSports: return "surfingSports"
        case .swimming: return "swimming"
        case .tableTennis: return "tableTennis"
        case .tennis: return "tennis"
        case .trackAndField: return "trackAndField"
        case .traditionalStrengthTraining: return "traditionalStrengthTraining"
        case .volleyball: return "volleyball"
        case .walking: return "walking"
        case .waterFitness: return "waterFitness"
        case .waterPolo: return "waterPolo"
        case .waterSports: return "waterSports"
        case .wrestling: return "wrestling"
        case .yoga: return "yoga"
        case .barre: return "barre"
        case .coreTraining: return "coreTraining"
        case .crossCountrySkiing: return "crossCountrySkiing"
        case .downhillSkiing: return "downhillSkiing"
        case .flexibility: return "flexibility"
        case .highIntensityIntervalTraining: return "highIntensityIntervalTraining"
        case .jumpRope: return "jumpRope"
        case .kickboxing: return "kickboxing"
        case .pilates: return "pilates"
        case .snowboarding: return "snowboarding"
        case .stairs: return "stairs"
        case .stepTraining: return "stepTraining"
        case .wheelchairWalkPace: return "wheelchairWalkPace"
        case .wheelchairRunPace: return "wheelchairRunPace"
        case .taiChi: return "taiChi"
        case .mixedCardio: return "mixedCardio"
        case .handCycling: return "handCycling"
        case .underwaterDiving: return "underwaterDiving"
        default: return "other"
        }
    }
}
