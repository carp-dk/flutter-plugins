import HealthKit
import Flutter

/// Class responsible for writing health data to HealthKit
class HealthDataWriter {
    let healthStore: HKHealthStore
    let dataTypesDict: [String: HKSampleType]
    let unitDict: [String: HKUnit]
    let workoutActivityTypeMap: [String: HKWorkoutActivityType]
    
    /// - Parameters:
    ///   - healthStore: The HealthKit store
    ///   - dataTypesDict: Dictionary of data types
    ///   - unitDict: Dictionary of units
    ///   - workoutActivityTypeMap: Dictionary of workout activity types
    init(healthStore: HKHealthStore, dataTypesDict: [String: HKSampleType], unitDict: [String: HKUnit], workoutActivityTypeMap: [String: HKWorkoutActivityType]) {
        self.healthStore = healthStore
        self.dataTypesDict = dataTypesDict
        self.unitDict = unitDict
        self.workoutActivityTypeMap = workoutActivityTypeMap
    }
    
    /// Writes general health data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func writeData(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let value = (arguments["value"] as? Double),
              let type = (arguments["dataTypeKey"] as? String),
              let unit = (arguments["dataUnitKey"] as? String),
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber),
              let recordingMethod = (arguments["recordingMethod"] as? Int)
        else {
            throw PluginError(message: "Invalid Arguments")
        }
        
        let dateFrom = HealthUtilities.dateFromMilliseconds(startTime.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        let isManualEntry = recordingMethod == HealthConstants.RecordingMethod.manual.rawValue
        let metadata: [String: Any] = [
            HKMetadataKeyWasUserEntered: NSNumber(value: isManualEntry)
        ]
        
        let sample: HKObject
        
        if dataTypesDict[type]!.isKind(of: HKCategoryType.self) {
            sample = HKCategorySample(
                type: dataTypesDict[type] as! HKCategoryType, value: Int(value), start: dateFrom,
                end: dateTo, metadata: metadata)
        } else {
            let quantity = HKQuantity(unit: unitDict[unit]!, doubleValue: value)
            sample = HKQuantitySample(
                type: dataTypesDict[type] as! HKQuantityType, quantity: quantity, start: dateFrom,
                end: dateTo, metadata: metadata)
        }
        
        healthStore.save(
            sample,
            withCompletion: { (success, error) in
                if let err = error {
                    print("Error Saving \(type) Sample: \(err.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result(success)
                }
            })
    }
    
    /// Writes audiogram data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func writeAudiogram(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let frequencies = (arguments["frequencies"] as? [Double]),
              let leftEarSensitivities = (arguments["leftEarSensitivities"] as? [Double]),
              let rightEarSensitivities = (arguments["rightEarSensitivities"] as? [Double]),
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber)
        else {
            throw PluginError(message: "Invalid Arguments")
        }
        
        let dateFrom = HealthUtilities.dateFromMilliseconds(startTime.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        var sensitivityPoints = [HKAudiogramSensitivityPoint]()
        
        for index in 0...frequencies.count - 1 {
            let frequency = HKQuantity(unit: HKUnit.hertz(), doubleValue: frequencies[index])
            let dbUnit = HKUnit.decibelHearingLevel()
            let left = HKQuantity(unit: dbUnit, doubleValue: leftEarSensitivities[index])
            let right = HKQuantity(unit: dbUnit, doubleValue: rightEarSensitivities[index])
            let sensitivityPoint = try HKAudiogramSensitivityPoint(
                frequency: frequency, leftEarSensitivity: left, rightEarSensitivity: right)
            sensitivityPoints.append(sensitivityPoint)
        }
        
        let audiogram: HKAudiogramSample
        let metadataReceived = (arguments["metadata"] as? [String: Any]?)
        
        if (metadataReceived) != nil {
            guard let deviceName = metadataReceived?!["HKDeviceName"] as? String else { return }
            guard let externalUUID = metadataReceived?!["HKExternalUUID"] as? String else { return }
            
            audiogram = HKAudiogramSample(
                sensitivityPoints: sensitivityPoints, start: dateFrom, end: dateTo,
                metadata: [HKMetadataKeyDeviceName: deviceName, HKMetadataKeyExternalUUID: externalUUID])
            
        } else {
            audiogram = HKAudiogramSample(
                sensitivityPoints: sensitivityPoints, start: dateFrom, end: dateTo, metadata: nil)
        }
        
        healthStore.save(
            audiogram,
            withCompletion: { (success, error) in
                if let err = error {
                    print("Error Saving Audiogram. Sample: \(err.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result(success)
                }
            })
    }
    
    /// Writes blood pressure data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func writeBloodPressure(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let systolic = (arguments["systolic"] as? Double),
              let diastolic = (arguments["diastolic"] as? Double),
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber),
              let recordingMethod = (arguments["recordingMethod"] as? Int)
        else {
            throw PluginError(message: "Invalid Arguments")
        }
        let dateFrom = HealthUtilities.dateFromMilliseconds(startTime.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        let isManualEntry = recordingMethod == HealthConstants.RecordingMethod.manual.rawValue
        let metadata = [
            HKMetadataKeyWasUserEntered: NSNumber(value: isManualEntry)
        ]
        
        let systolic_sample = HKQuantitySample(
            type: HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            quantity: HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolic),
            start: dateFrom, end: dateTo, metadata: metadata)
        let diastolic_sample = HKQuantitySample(
            type: HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            quantity: HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: diastolic),
            start: dateFrom, end: dateTo, metadata: metadata)
        let bpCorrelationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
        let bpCorrelation = Set(arrayLiteral: systolic_sample, diastolic_sample)
        let blood_pressure_sample = HKCorrelation(type: bpCorrelationType , start: dateFrom, end: dateTo, objects: bpCorrelation)
        
        healthStore.save(
            [blood_pressure_sample],
            withCompletion: { (success, error) in
                if let err = error {
                    print("Error Saving Blood Pressure Sample: \(err.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result(success)
                }
            })
    }
    
    /// Writes meal nutrition data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func writeMeal(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let name = (arguments["name"] as? String?),
              let startTime = (arguments["start_time"] as? NSNumber),
              let endTime = (arguments["end_time"] as? NSNumber),
              let mealType = (arguments["meal_type"] as? String?),
              let recordingMethod = arguments["recordingMethod"] as? Int
        else {
            throw PluginError(message: "Invalid Arguments")
        }
        
        let dateFrom = HealthUtilities.dateFromMilliseconds(startTime.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        let mealTypeString = mealType ?? "UNKNOWN"
        
        let isManualEntry = recordingMethod == HealthConstants.RecordingMethod.manual.rawValue
        
        var metadata = ["HKFoodMeal": mealTypeString, HKMetadataKeyWasUserEntered: NSNumber(value: isManualEntry)] as [String : Any]
        if (name != nil) {
            metadata[HKMetadataKeyFoodType] = "\(name!)"
        }
        
        var nutrition = Set<HKSample>()
        for (key, identifier) in HealthConstants.NUTRITION_KEYS {
            let value = arguments[key] as? Double
            guard let unwrappedValue = value else { continue }
            let unit = key == "calories" ? HKUnit.kilocalorie() : key == "water" ? HKUnit.literUnit(with: .milli) : HKUnit.gram()
            let nutritionSample = HKQuantitySample(
                type: HKSampleType.quantityType(forIdentifier: identifier)!, quantity: HKQuantity(unit: unit, doubleValue: unwrappedValue), start: dateFrom, end: dateTo, metadata: metadata)
            nutrition.insert(nutritionSample)
        }
        
        if #available(iOS 15.0, *){
            let type = HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!
            let meal = HKCorrelation(type: type, start: dateFrom, end: dateTo, objects: nutrition, metadata: metadata)
            
            healthStore.save(meal, withCompletion: { (success, error) in
                if let err = error {
                    print("Error Saving Meal Sample: \(err.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result(success)
                }
            })
        } else {
            result(false)
        }
    }
    
    /// Writes insulin delivery data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func writeInsulinDelivery(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let units = (arguments["units"] as? Double),
              let reason = (arguments["reason"] as? NSNumber),
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber)
        else {
            throw PluginError(message: "Invalid Arguments")
        }
        let dateFrom = HealthUtilities.dateFromMilliseconds(startTime.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        let type = HKSampleType.quantityType(forIdentifier: .insulinDelivery)!
        let quantity = HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: units)
        let metadata = [HKMetadataKeyInsulinDeliveryReason: reason]
        
        let insulin_sample = HKQuantitySample(type: type, quantity: quantity, start: dateFrom, end: dateTo, metadata: metadata)
        
        healthStore.save(insulin_sample, withCompletion: { (success, error) in
            if let err = error {
                print("Error Saving Insulin Delivery Sample: \(err.localizedDescription)")
            }
            DispatchQueue.main.async {
                result(success)
            }
        })
    }
    
    /// Writes menstruation flow data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func writeMenstruationFlow(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let flow = (arguments["value"] as? Int),
              let endTime = (arguments["endTime"] as? NSNumber),
              let isStartOfCycle = (arguments["isStartOfCycle"] as? NSNumber),
              let recordingMethod = (arguments["recordingMethod"] as? Int)
        else {
            throw PluginError(message: "Invalid Arguments - value, startTime, endTime or isStartOfCycle invalid")
        }
        guard let menstrualFlowType = HKCategoryValueMenstrualFlow(rawValue: flow) else {
            throw PluginError(message: "Invalid Menstrual Flow Type")
        }
        
        let dateTime = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        let isManualEntry = recordingMethod == HealthConstants.RecordingMethod.manual.rawValue
        
        guard let categoryType = HKSampleType.categoryType(forIdentifier: .menstrualFlow) else {
            throw PluginError(message: "Invalid Menstrual Flow Type")
        }
        
        let metadata = [HKMetadataKeyMenstrualCycleStart: isStartOfCycle, HKMetadataKeyWasUserEntered: NSNumber(value: isManualEntry)] as [String : Any]
        
        let sample = HKCategorySample(
            type: categoryType,
            value: menstrualFlowType.rawValue, 
            start: dateTime, 
            end: dateTime,
            metadata: metadata
        )
        
        healthStore.save(
            sample,
            withCompletion: { (success, error) in
                if let err = error {
                    print("Error Saving Menstruation Flow Sample: \(err.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result(success)
                }
            })
    }
    
    /// Writes workout data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func writeWorkoutData(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let activityType = (arguments["activityType"] as? String),
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber),
              let activityTypeValue = workoutActivityTypeMap[activityType]
        else {
            throw PluginError(message: "Invalid Arguments - activityType, startTime or endTime invalid")
        }
        
        var totalEnergyBurned: HKQuantity?
        var totalDistance: HKQuantity? = nil
        
        // Handle optional arguments
        if let teb = (arguments["totalEnergyBurned"] as? Double) {
            totalEnergyBurned = HKQuantity(
                unit: unitDict[(arguments["totalEnergyBurnedUnit"] as! String)]!, doubleValue: teb)
        }
        if let td = (arguments["totalDistance"] as? Double) {
            totalDistance = HKQuantity(
                unit: unitDict[(arguments["totalDistanceUnit"] as! String)]!, doubleValue: td)
        }
        
        let dateFrom = HealthUtilities.dateFromMilliseconds(startTime.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        let workout = HKWorkout(
            activityType: activityTypeValue, 
            start: dateFrom, 
            end: dateTo, 
            duration: dateTo.timeIntervalSince(dateFrom),
            totalEnergyBurned: totalEnergyBurned ?? nil,
            totalDistance: totalDistance ?? nil, 
            metadata: nil
        )
        
        healthStore.save(
            workout,
            withCompletion: { (success, error) in
                if let err = error {
                    print("Error Saving Workout. Sample: \(err.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result(success)
                }
            })
    }
}
