import HealthKit
import Flutter

/// Class responsible for reading health data from HealthKit
class HealthDataReader {
    let healthStore: HKHealthStore
    let dataTypesDict: [String: HKSampleType]
    let dataQuantityTypesDict: [String: HKQuantityType]
    let unitDict: [String: HKUnit]
    let workoutActivityTypeMap: [String: HKWorkoutActivityType]
    let characteristicsTypesDict: [String: HKCharacteristicType]
    
    /// - Parameters:
    ///   - healthStore: The HealthKit store
    ///   - dataTypesDict: Dictionary of data types
    ///   - dataQuantityTypesDict: Dictionary of quantity types
    ///   - unitDict: Dictionary of units
    ///   - workoutActivityTypeMap: Dictionary of workout activity types
    ///   - characteristicsTypesDict: Dictionary of characteristic types
    init(healthStore: HKHealthStore,
         dataTypesDict: [String: HKSampleType],
         dataQuantityTypesDict: [String: HKQuantityType],
         unitDict: [String: HKUnit],
         workoutActivityTypeMap: [String: HKWorkoutActivityType],
         characteristicsTypesDict: [String: HKCharacteristicType]) {
        self.healthStore = healthStore
        self.dataTypesDict = dataTypesDict
        self.dataQuantityTypesDict = dataQuantityTypesDict
        self.unitDict = unitDict
        self.workoutActivityTypeMap = workoutActivityTypeMap
        self.characteristicsTypesDict = characteristicsTypesDict
    }
    
    /// Gets health data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func getData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? NSDictionary,
              let dataTypeKey = arguments["dataTypeKey"] as? String else {
            DispatchQueue.main.async {
                result(FlutterError(code: "ARGUMENT_ERROR",
                                    message: "Missing required dataTypeKey argument",
                                    details: nil))
            }
            return
        }
        
        let dataUnitKey = arguments["dataUnitKey"] as? String
        let startTime = (arguments["startTime"] as? NSNumber) ?? 0
        let endTime = (arguments["endTime"] as? NSNumber) ?? 0
        let limit = (arguments["limit"] as? Int) ?? HKObjectQueryNoLimit
        let recordingMethodsToFilter = (arguments["recordingMethodsToFilter"] as? [Int]) ?? []
        let includeManualEntry = !recordingMethodsToFilter.contains(HealthConstants.RecordingMethod.manual.rawValue)
        
        // convert from milliseconds to Date()
        let dateFrom = HealthUtilities.dateFromMilliseconds(startTime.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        let sourceIdForCharacteristic = "com.apple.Health"
        let sourceNameForCharacteristic = "Health"
        
        // characteristic types checks (like GENDER, BLOOD_TYPE, etc.)
        switch(dataTypeKey) {
        case HealthConstants.BIRTH_DATE:
            let dateOfBirth = getBirthDate()
            result([
                [
                    "value": dateOfBirth?.timeIntervalSince1970,
                    "date_from": Int(dateFrom.timeIntervalSince1970 * 1000),
                    "date_to": Int(dateTo.timeIntervalSince1970 * 1000),
                    "source_id": sourceIdForCharacteristic,
                    "source_name": sourceNameForCharacteristic,
                    "recording_method": HealthConstants.RecordingMethod.manual.rawValue
                ]
            ])
            return
        case HealthConstants.GENDER:
            let gender = getGender()
            result([
                [
                    "value": gender?.rawValue,
                    "date_from": Int(dateFrom.timeIntervalSince1970 * 1000),
                    "date_to": Int(dateTo.timeIntervalSince1970 * 1000),
                    "source_id": sourceIdForCharacteristic,
                    "source_name": sourceNameForCharacteristic,
                    "recording_method": HealthConstants.RecordingMethod.manual.rawValue
                ]
            ])
            return
        case HealthConstants.BLOOD_TYPE:
            let bloodType = getBloodType()
            result([
                [
                    "value": bloodType?.rawValue,
                    "date_from": Int(dateFrom.timeIntervalSince1970 * 1000),
                    "date_to": Int(dateTo.timeIntervalSince1970 * 1000),
                    "source_id": sourceIdForCharacteristic,
                    "source_name": sourceNameForCharacteristic,
                    "recording_method": HealthConstants.RecordingMethod.manual.rawValue
                ]
            ])
            return
        default:
            break
        }
        
        guard let dataType = dataTypesDict[dataTypeKey] else {
            DispatchQueue.main.async {
                result(FlutterError(code: "INVALID_TYPE",
                                    message: "Invalid dataTypeKey: \(dataTypeKey)",
                                    details: nil))
            }
            return
        }
        
        var unit: HKUnit?
        if let dataUnitKey = dataUnitKey {
            unit = unitDict[dataUnitKey]
        }
        
        var predicate = HKQuery.predicateForSamples(
            withStart: dateFrom, end: dateTo, options: .strictStartDate)
        if (!includeManualEntry) {
            let manualPredicate = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
            predicate = NSCompoundPredicate(type: .and, subpredicates: [predicate, manualPredicate])
        }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: dataType, predicate: predicate, limit: limit, sortDescriptors: [sortDescriptor]
        ) { x, samplesOrNil, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "HEALTH_ERROR",
                                        message: "Error getting health data: \(error!.localizedDescription)",
                                        details: nil))
                }
                return
            }
            
            guard let samples = samplesOrNil else {
                DispatchQueue.main.async {
                    result([])
                }
                return
            }
            
            if let quantitySamples = samples as? [HKQuantitySample] {
                let dictionaries = quantitySamples.map { sample -> NSDictionary in
                    return [
                        "uuid": "\(sample.uuid)",
                        "value": sample.quantity.doubleValue(for: unit ?? HKUnit.internationalUnit()),
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                        "source_id": sample.sourceRevision.source.bundleIdentifier,
                        "source_name": sample.sourceRevision.source.name,
                        "recording_method": (sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool == true)
                        ? HealthConstants.RecordingMethod.manual.rawValue
                        : HealthConstants.RecordingMethod.automatic.rawValue,
                        "dataUnitKey": unit?.unitString,
                        "metadata": HealthUtilities.sanitizeMetadata(sample.metadata)
                    ]
                }
                DispatchQueue.main.async {
                    result(dictionaries)
                }
            } else if var categorySamples = samples as? [HKCategorySample] {
                // filter category samples based on dataTypeKey
                switch dataTypeKey {
                case HealthConstants.SLEEP_IN_BED:
                    categorySamples = categorySamples.filter { $0.value == 0 }
                case HealthConstants.SLEEP_ASLEEP:
                    categorySamples = categorySamples.filter { $0.value == 1 }
                case HealthConstants.SLEEP_AWAKE:
                    categorySamples = categorySamples.filter { $0.value == 2 }
                case HealthConstants.SLEEP_LIGHT:
                    categorySamples = categorySamples.filter { $0.value == 3 }
                case HealthConstants.SLEEP_DEEP:
                    categorySamples = categorySamples.filter { $0.value == 4 }
                case HealthConstants.SLEEP_REM:
                    categorySamples = categorySamples.filter { $0.value == 5 }
                case HealthConstants.HEADACHE_UNSPECIFIED:
                    categorySamples = categorySamples.filter { $0.value == 0 }
                case HealthConstants.HEADACHE_NOT_PRESENT:
                    categorySamples = categorySamples.filter { $0.value == 1 }
                case HealthConstants.HEADACHE_MILD:
                    categorySamples = categorySamples.filter { $0.value == 2 }
                case HealthConstants.HEADACHE_MODERATE:
                    categorySamples = categorySamples.filter { $0.value == 3 }
                case HealthConstants.HEADACHE_SEVERE:
                    categorySamples = categorySamples.filter { $0.value == 4 }
                default:
                    break
                }
                
                let categories = categorySamples.map { sample -> NSDictionary in
                    return [
                        "uuid": "\(sample.uuid)",
                        "value": sample.value,
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                        "source_id": sample.sourceRevision.source.bundleIdentifier,
                        "source_name": sample.sourceRevision.source.name,
                        "recording_method": (sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool == true)
                        ? HealthConstants.RecordingMethod.manual.rawValue
                        : HealthConstants.RecordingMethod.automatic.rawValue,
                        "metadata": HealthUtilities.sanitizeMetadata(sample.metadata)
                    ]
                }
                DispatchQueue.main.async {
                    result(categories)
                }
            } else if let workoutSamples = samples as? [HKWorkout] {
                let dictionaries = workoutSamples.map { sample -> NSDictionary in
                    return [
                        "uuid": "\(sample.uuid)",
                        "workoutActivityType": self.workoutActivityTypeMap.first(where: {
                            $0.value == sample.workoutActivityType
                        })?.key,
                        "totalEnergyBurned": sample.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()),
                        "totalEnergyBurnedUnit": "KILOCALORIE",
                        "totalDistance": sample.totalDistance?.doubleValue(for: HKUnit.meter()),
                        "totalDistanceUnit": "METER",
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                        "source_id": sample.sourceRevision.source.bundleIdentifier,
                        "source_name": sample.sourceRevision.source.name,
                        "recording_method": (sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool == true)
                        ? HealthConstants.RecordingMethod.manual.rawValue
                        : HealthConstants.RecordingMethod.automatic.rawValue,
                        "workout_type": HKWorkoutActivityType.toString(sample.workoutActivityType),
                        "total_distance": sample.totalDistance != nil ? Int(sample.totalDistance!.doubleValue(for: HKUnit.meter())) : 0,
                        "total_energy_burned": sample.totalEnergyBurned != nil ? Int(sample.totalEnergyBurned!.doubleValue(for: HKUnit.kilocalorie())) : 0
                    ]
                }
                
                DispatchQueue.main.async {
                    result(dictionaries)
                }
            } else if let audiogramSamples = samples as? [HKAudiogramSample] {
                let dictionaries = audiogramSamples.map { sample -> NSDictionary in
                    var frequencies = [Double]()
                    var leftEarSensitivities = [Double]()
                    var rightEarSensitivities = [Double]()
                    for samplePoint in sample.sensitivityPoints {
                        frequencies.append(samplePoint.frequency.doubleValue(for: HKUnit.hertz()))
                        leftEarSensitivities.append(
                            samplePoint.leftEarSensitivity!.doubleValue(for: HKUnit.decibelHearingLevel()))
                        rightEarSensitivities.append(
                            samplePoint.rightEarSensitivity!.doubleValue(for: HKUnit.decibelHearingLevel()))
                    }
                    return [
                        "uuid": "\(sample.uuid)",
                        "frequencies": frequencies,
                        "leftEarSensitivities": leftEarSensitivities,
                        "rightEarSensitivities": rightEarSensitivities,
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                        "source_id": sample.sourceRevision.source.bundleIdentifier,
                        "source_name": sample.sourceRevision.source.name,
                    ]
                }
                DispatchQueue.main.async {
                    result(dictionaries)
                }
            } else if let nutritionSamples = samples as? [HKCorrelation] {
                var foods: [[String: Any?]] = []
                for food in nutritionSamples {
                    let name = food.metadata?[HKMetadataKeyFoodType] as? String
                    let mealType = food.metadata?["HKFoodMeal"]
                    let samples = food.objects
                    if let sample = samples.first as? HKQuantitySample {
                        var sampleDict = [
                            "uuid": "\(sample.uuid)",
                            "name": name,
                            "meal_type": mealType,
                            "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                            "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                            "source_id": sample.sourceRevision.source.bundleIdentifier,
                            "source_name": sample.sourceRevision.source.name,
                            "recording_method": (sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool == true)
                            ? HealthConstants.RecordingMethod.manual.rawValue
                            : HealthConstants.RecordingMethod.automatic.rawValue
                        ]
                        for sample in samples {
                            if let quantitySample = sample as? HKQuantitySample {
                                for (key, identifier) in HealthConstants.NUTRITION_KEYS {
                                    if (quantitySample.quantityType == HKObjectType.quantityType(forIdentifier: identifier)){
                                        let unit = key == "calories" ? HKUnit.kilocalorie() : key == "water" ? HKUnit.literUnit(with: .milli) : HKUnit.gram()
                                        sampleDict[key] = quantitySample.quantity.doubleValue(for: unit)
                                    }
                                }
                            }
                        }
                        foods.append(sampleDict as! [String : Any?])
                    }
                }
                
                DispatchQueue.main.async {
                    result(foods)
                }
            } else {
                if #available(iOS 14.0, *), let ecgSamples = samples as? [HKElectrocardiogram] {
                    let dictionaries = ecgSamples.map(self.fetchEcgMeasurements)
                    DispatchQueue.main.async {
                        result(dictionaries)
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Error getting ECG - only available on iOS 14.0 and above!")
                        result(nil)
                    }
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Gets interval health data
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func getIntervalData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let dataTypeKey = (arguments?["dataTypeKey"] as? String) ?? "DEFAULT"
        let dataUnitKey = (arguments?["dataUnitKey"] as? String)
        let startDate = (arguments?["startTime"] as? NSNumber) ?? 0
        let endDate = (arguments?["endTime"] as? NSNumber) ?? 0
        let intervalInSecond = (arguments?["interval"] as? Int) ?? 1
        let recordingMethodsToFilter = (arguments?["recordingMethodsToFilter"] as? [Int]) ?? []
        let includeManualEntry = !recordingMethodsToFilter.contains(HealthConstants.RecordingMethod.manual.rawValue)
        
        // interval in seconds
        var interval = DateComponents()
        interval.second = intervalInSecond
        
        let dateFrom = HealthUtilities.dateFromMilliseconds(startDate.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endDate.doubleValue)
        
        guard let quantityType = dataQuantityTypesDict[dataTypeKey] else {
            DispatchQueue.main.async {
                result(FlutterError(code: "INVALID_TYPE",
                                    message: "Invalid dataTypeKey for interval query: \(dataTypeKey)",
                                    details: nil))
            }
            return
        }
        
        var predicate = HKQuery.predicateForSamples(withStart: dateFrom, end: dateTo, options: [])
        if (!includeManualEntry) {
            let manualPredicate = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
            predicate = NSCompoundPredicate(type: .and, subpredicates: [predicate, manualPredicate])
        }
        
        let statisticsOptions = statisticsOption(for: dataTypeKey)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: statisticsOptions,
            anchorDate: dateFrom,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { [weak self] _, statisticCollectionOrNil, error in
            guard let self = self else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "INTERNAL_ERROR",
                                        message: "Internal instance reference lost",
                                        details: nil))
                }
                return
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    result(FlutterError(code: "STATISTICS_ERROR",
                                        message: "Error getting statistics: \(error.localizedDescription)",
                                        details: nil))
                }
                return
            }
            
            guard let collection = statisticCollectionOrNil else {
                DispatchQueue.main.async {
                    result(nil)
                }
                return
            }
            
            var dictionaries = [[String: Any]]()
            collection.enumerateStatistics(from: dateFrom, to: dateTo) { [weak self] statisticData, _ in
                guard let self = self else { return }
                if let dataUnitKey = dataUnitKey, let unit = self.unitDict[dataUnitKey] {
                    var value: Double? = nil
                    switch statisticsOptions {
                    case .cumulativeSum:
                        value = statisticData.sumQuantity()?.doubleValue(for: unit)
                    case .discreteAverage:
                        value = statisticData.averageQuantity()?.doubleValue(for: unit)
                    case .discreteMin:
                        value = statisticData.minimumQuantity()?.doubleValue(for: unit)
                    case .discreteMax:
                        value = statisticData.maximumQuantity()?.doubleValue(for: unit)
                    default:
                        value = statisticData.sumQuantity()?.doubleValue(for: unit)
                    }
                    if let value = value {
                        let dict = [
                            "value": value,
                            "date_from": Int(statisticData.startDate.timeIntervalSince1970 * 1000),
                            "date_to": Int(statisticData.endDate.timeIntervalSince1970 * 1000),
                            "source_id": statisticData.sources?.first?.bundleIdentifier ?? "",
                            "source_name": statisticData.sources?.first?.name ?? ""
                        ]
                        dictionaries.append(dict)
                    }
                }
            }
            DispatchQueue.main.async {
                result(dictionaries)
            }
        }
        healthStore.execute(query)
    }

    /// Helper to select correct HKStatisticsOptions for a given dataTypeKey
    private func statisticsOption(for dataTypeKey: String) -> HKStatisticsOptions {
        guard let quantityType = dataQuantityTypesDict[dataTypeKey] else {
            // Default to cumulativeSum for backward compatibility
            return .cumulativeSum
        }
        switch quantityType.aggregationStyle {
        case .cumulative:
            return .cumulativeSum
        case .discreteArithmetic:
            return .discreteAverage
        case .discrete:
            // Other options are .discreteAverage, .discreteMin, or .discreteMax
            return .discreteAverage
        @unknown default:
            return .cumulativeSum
        }
    }
    
    /// Gets total steps in interval
    /// - Parameters:
    ///   - call: Flutter method call
    ///   - result: Flutter result callback
    func getTotalStepsInInterval(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let startTime = (arguments?["startTime"] as? NSNumber) ?? 0
        let endTime = (arguments?["endTime"] as? NSNumber) ?? 0
        let recordingMethodsToFilter = (arguments?["recordingMethodsToFilter"] as? [Int]) ?? []
        let includeManualEntry = !recordingMethodsToFilter.contains(HealthConstants.RecordingMethod.manual.rawValue)
        
        // Convert dates from milliseconds to Date()
        let dateFrom = HealthUtilities.dateFromMilliseconds(startTime.doubleValue)
        let dateTo = HealthUtilities.dateFromMilliseconds(endTime.doubleValue)
        
        let sampleType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        var predicate = HKQuery.predicateForSamples(
            withStart: dateFrom, end: dateTo, options: .strictStartDate)
        if (!includeManualEntry) {
            let manualPredicate = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
            predicate = NSCompoundPredicate(type: .and, subpredicates: [predicate, manualPredicate])
        }
        
        let query = HKStatisticsCollectionQuery(
            quantityType: sampleType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: dateFrom,
            intervalComponents: DateComponents(day: 1)
        )
        query.initialResultsHandler = { query, results, error in
            guard let results = results else {
                let errorMessage = error?.localizedDescription ?? "Unknown error"
                DispatchQueue.main.async {
                    result(FlutterError(code: "STEPS_ERROR",
                                        message: "Error getting step count: \(errorMessage)",
                                        details: nil))
                }
                return
            }
            
            var totalSteps = 0.0
            results.enumerateStatistics(from: dateFrom, to: dateTo) { statistics, stop in
                if let quantity = statistics.sumQuantity() {
                    let unit = HKUnit.count()
                    totalSteps += quantity.doubleValue(for: unit)
                }
            }
            
            DispatchQueue.main.async {
                result(Int(totalSteps))
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Gets birth date from HealthKit
    /// - Returns: Birth date
    private func getBirthDate() -> Date? {
        var dob: Date?
        do {
            dob = try healthStore.dateOfBirthComponents().date
        } catch {
            dob = nil
            print("Error retrieving date of birth: \(error)")
        }
        return dob
    }
    
    /// Gets gender from HealthKit
    /// - Returns: Biological sex
    private func getGender() -> HKBiologicalSex? {
        var bioSex: HKBiologicalSex?
        do {
            bioSex = try healthStore.biologicalSex().biologicalSex
        } catch {
            bioSex = nil
            print("Error retrieving biologicalSex: \(error)")
        }
        return bioSex
    }
    
    /// Gets blood type from HealthKit
    /// - Returns: Blood type
    private func getBloodType() -> HKBloodType? {
        var bloodType: HKBloodType?
        do {
            bloodType = try healthStore.bloodType().bloodType
        } catch {
            bloodType = nil
            print("Error retrieving blood type: \(error)")
        }
        return bloodType
    }
    
    /// Fetch ECG measurements from an HKElectrocardiogram sample
    /// - Parameter sample: ECG sample
    /// - Returns: Dictionary with ECG data
    @available(iOS 14.0, *)
    private func fetchEcgMeasurements(_ sample: HKElectrocardiogram) -> NSDictionary {
        let semaphore = DispatchSemaphore(value: 0)
        var voltageValues = [NSDictionary]()
        let voltageQuery = HKElectrocardiogramQuery(sample) { query, result in
            switch result {
            case let .measurement(measurement):
                if let voltageQuantity = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                    let voltage = voltageQuantity.doubleValue(for: HKUnit.volt())
                    let timeSinceSampleStart = measurement.timeSinceSampleStart
                    voltageValues.append(["voltage": voltage, "timeSinceSampleStart": timeSinceSampleStart])
                }
            case .done:
                semaphore.signal()
            case let .error(error):
                print(error)
            @unknown default:
                print("Unknown error occurred")
            }
        }
        healthStore.execute(voltageQuery)
        semaphore.wait()
        return [
            "uuid": "\(sample.uuid)",
            "voltageValues": voltageValues,
            "averageHeartRate": sample.averageHeartRate?.doubleValue(
                for: HKUnit.count().unitDivided(by: HKUnit.minute())),
            "samplingFrequency": sample.samplingFrequency?.doubleValue(for: HKUnit.hertz()),
            "classification": sample.classification.rawValue,
            "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
            "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
            "source_id": sample.sourceRevision.source.bundleIdentifier,
            "source_name": sample.sourceRevision.source.name,
        ]
    }
}
