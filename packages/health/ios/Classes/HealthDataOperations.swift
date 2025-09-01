import HealthKit
import Flutter

/// Class for managing health data permissions and deletion operations
class HealthDataOperations {
    let healthStore: HKHealthStore
    let dataTypesDict: [String: HKSampleType]
    let characteristicsTypesDict: [String: HKCharacteristicType]
    let nutritionList: [String]
    
    /// - Parameters:
    ///   - healthStore: The HealthKit store
    ///   - dataTypesDict: Dictionary of data types
    ///   - characteristicsTypesDict: Dictionary of characteristic types
    ///   - nutritionList: List of nutrition data types
    init(healthStore: HKHealthStore, 
         dataTypesDict: [String: HKSampleType],
         characteristicsTypesDict: [String: HKCharacteristicType],
         nutritionList: [String]) {
        self.healthStore = healthStore
        self.dataTypesDict = dataTypesDict
        self.characteristicsTypesDict = characteristicsTypesDict
        self.nutritionList = nutritionList
    }
    
    /// Check if HealthKit is available on the device
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func checkIfHealthDataAvailable(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(HKHealthStore.isHealthDataAvailable())
    }
    
    /// Check if we have required permissions
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func hasPermissions(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let arguments = call.arguments as? NSDictionary
        guard var types = arguments?["types"] as? [String],
              var permissions = arguments?["permissions"] as? [Int],
              types.count == permissions.count
        else {
            throw PluginError(message: "Invalid Arguments!")
        }
        
        if let nutritionIndex = types.firstIndex(of: HealthConstants.NUTRITION) {
            types.remove(at: nutritionIndex)
            let nutritionPermission = permissions[nutritionIndex]
            permissions.remove(at: nutritionIndex)
            
            for nutritionType in nutritionList {
                types.append(nutritionType)
                permissions.append(nutritionPermission)
            }
        }
        
        for (index, type) in types.enumerated() {
            guard let sampleType = dataTypesDict[type] else {
                print("Warning: Health data type '\(type)' not found in dataTypesDict")
                result(false)
                return
            }
            
            let success = hasPermission(type: sampleType, access: permissions[index])
            if success == nil || success == false {
                result(success)
                return
            }
            if let characteristicType = characteristicsTypesDict[type] {
                let characteristicSuccess = hasPermission(type: characteristicType, access: permissions[index])
                if (characteristicSuccess == nil || characteristicSuccess == false) {
                    result(characteristicSuccess)
                    return
                }
            }
        }
        
        result(true)
    }
    
    /// Check if we have permission for a specific type
    /// - Parameters:
    ///   - type: The object type to check
    ///   - access: Access level (0: read, 1: write, other: read/write)
    /// - Returns: Bool or nil depending on permission status
    private func hasPermission(type: HKObjectType, access: Int) -> Bool? {
        if #available(iOS 13.0, *) {
            let status = healthStore.authorizationStatus(for: type)
            switch access {
            case 0:  // READ
                return nil
            case 1:  // WRITE
                return (status == HKAuthorizationStatus.sharingAuthorized)
            default:  // READ_WRITE
                return nil
            }
        } else {
            return nil
        }
    }
    
    /// Request authorization for health data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func requestAuthorization(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let types = arguments["types"] as? [String],
              let permissions = arguments["permissions"] as? [Int],
              permissions.count == types.count
        else {
            throw PluginError(message: "Invalid Arguments!")
        }
        
        var typesToRead = Set<HKObjectType>()
        var typesToWrite = Set<HKSampleType>()
        
        for (index, key) in types.enumerated() {
            if (key == HealthConstants.NUTRITION) {
                for nutritionType in nutritionList {
                    guard let nutritionData = dataTypesDict[nutritionType] else {
                        print("Warning: Nutrition data type '\(nutritionType)' not found in dataTypesDict")
                        continue
                    }
                    typesToWrite.insert(nutritionData)
                }
            } else {
                let access = permissions[index]
                
                if let dataType = dataTypesDict[key] {
                    switch access {
                    case 0:
                        typesToRead.insert(dataType)
                    case 1:
                        typesToWrite.insert(dataType)
                    default:
                        typesToRead.insert(dataType)
                        typesToWrite.insert(dataType)
                    }
                }
                
                if let characteristicsType = characteristicsTypesDict[key] {
                    switch access {
                    case 0:
                        typesToRead.insert(characteristicsType)
                    case 1:
                        throw PluginError(message: "Cannot request write permission for characteristic type \(characteristicsType)")
                    default:
                        typesToRead.insert(characteristicsType)
                    }
                }
                
                if dataTypesDict[key] == nil && characteristicsTypesDict[key] == nil {
                    print("Warning: Health data type '\(key)' not found in dataTypesDict or characteristicsTypesDict")
                }
                
            }
        }
        
        if #available(iOS 13.0, *) {
            healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) {
                (success, error) in
                DispatchQueue.main.async {
                    result(success)
                }
            }
        } else {
            // TODO: Add proper error handling
            result(false)
        }
    }
    
    /// Delete health data by date range
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func delete(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? NSDictionary,
              let dataTypeKey = arguments["dataTypeKey"] as? String else {
            print("Error: Missing dataTypeKey in arguments")
            result(false)
            return
        }
        
        // Check if it's a characteristic type - these cannot be deleted
        if characteristicsTypesDict[dataTypeKey] != nil {
            print("Info: Cannot delete characteristic type '\(dataTypeKey)' - these are read-only system values")
            result(false)
            return
        }
        
        let startTime = (arguments["startTime"] as? NSNumber) ?? 0
        let endTime = (arguments["endTime"] as? NSNumber) ?? 0
        
        let dateFrom = HealthUtilities.dateFromMilliseconds(startTime.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        guard let dataType = dataTypesDict[dataTypeKey] else {
            print("Warning: Health data type '\(dataTypeKey)' not found in dataTypesDict")
            result(false)
            return
        }
        
        let samplePredicate = HKQuery.predicateForSamples(
            withStart: dateFrom, end: dateTo, options: .strictStartDate)
        let ownerPredicate = HKQuery.predicateForObjects(from: HKSource.default())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let deleteQuery = HKSampleQuery(
            sampleType: dataType,
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [samplePredicate, ownerPredicate]),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] x, samplesOrNil, error in
            guard let self = self else { return }
            
            guard let samplesOrNil = samplesOrNil, error == nil else {
                print("Error querying \(dataType) samples: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    result(false)
                }
                return
            }
            
            // Chcek if there are any samples to delete
            if samplesOrNil.isEmpty {
                print("Info: No \(dataType) samples found in the specified date range.")
                DispatchQueue.main.async {
                    result(true)
                }
                return
            }
            
            // Delete the retrieved objects from the HealthKit store
            self.healthStore.delete(samplesOrNil) { (success, error) in
                if let err = error {
                    print("Error deleting \(dataType) Sample: \(err.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result(success)
                }
            }
        }
        
        healthStore.execute(deleteQuery)
    }
    
    /// Delete health data by UUID
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func deleteByUUID(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let uuidarg = arguments["uuid"] as? String,
              let dataTypeKey = arguments["dataTypeKey"] as? String else {
            throw PluginError(message: "Invalid Arguments - UUID or DataTypeKey invalid")
        }
        
        guard let dataTypeToRemove = dataTypesDict[dataTypeKey] else {
            print("Warning: Health data type '\(dataTypeKey)' not found in dataTypesDict")
            result(false)
            return
        }
        
        guard let uuid = UUID(uuidString: uuidarg) else {
            result(false)
            return
        }
        let predicate = HKQuery.predicateForObjects(with: [uuid])
        
        let query = HKSampleQuery(
            sampleType: dataTypeToRemove,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { [weak self] query, samplesOrNil, error in
            guard let self = self else { return }
            
            guard let samples = samplesOrNil, !samples.isEmpty else {
                DispatchQueue.main.async {
                    result(false)
                }
                return
            }
            
            self.healthStore.delete(samples) { success, error in
                if let error = error {
                    print("Error deleting sample with UUID \(uuid): \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result(success)
                }
            }
        }
        
        healthStore.execute(query)
    }
}
