import Flutter
import HealthKit
import UIKit

public class SwiftHealthPlugin: NSObject, FlutterPlugin {

    let healthStore = HKHealthStore()
    var healthDataTypes = [HKSampleType]()
    var healthDataQuantityTypes = [HKQuantityType]()
    var heartRateEventTypes = Set<HKSampleType>()
    var headacheType = Set<HKSampleType>()
    var allDataTypes = Set<HKSampleType>()
    var dataTypesDict: [String: HKSampleType] = [:]
    var dataQuantityTypesDict: [String: HKQuantityType] = [:]
    var unitDict: [String: HKUnit] = [:]
    var workoutActivityTypeMap: [String: HKWorkoutActivityType] = [:]

    // Health Data Type Keys
    let ACTIVE_ENERGY_BURNED = "ACTIVE_ENERGY_BURNED"
    let AUDIOGRAM = "AUDIOGRAM"
    let BASAL_ENERGY_BURNED = "BASAL_ENERGY_BURNED"
    let BLOOD_GLUCOSE = "BLOOD_GLUCOSE"
    let BLOOD_OXYGEN = "BLOOD_OXYGEN"
    let BLOOD_PRESSURE_DIASTOLIC = "BLOOD_PRESSURE_DIASTOLIC"
    let BLOOD_PRESSURE_SYSTOLIC = "BLOOD_PRESSURE_SYSTOLIC"
    let BODY_FAT_PERCENTAGE = "BODY_FAT_PERCENTAGE"
    let BODY_MASS_INDEX = "BODY_MASS_INDEX"
    let BODY_TEMPERATURE = "BODY_TEMPERATURE"
    let DIETARY_CARBS_CONSUMED = "DIETARY_CARBS_CONSUMED"
    let DIETARY_ENERGY_CONSUMED = "DIETARY_ENERGY_CONSUMED"
    let DIETARY_FATS_CONSUMED = "DIETARY_FATS_CONSUMED"
    let DIETARY_PROTEIN_CONSUMED = "DIETARY_PROTEIN_CONSUMED"
    let DIETARY_CAFFEINE = "DIETARY_CAFFEINE"
    let ELECTRODERMAL_ACTIVITY = "ELECTRODERMAL_ACTIVITY"
    let FORCED_EXPIRATORY_VOLUME = "FORCED_EXPIRATORY_VOLUME"
    let HEART_RATE = "HEART_RATE"
    let HEART_RATE_VARIABILITY_SDNN = "HEART_RATE_VARIABILITY_SDNN"
    let HEIGHT = "HEIGHT"
    let HIGH_HEART_RATE_EVENT = "HIGH_HEART_RATE_EVENT"
    let IRREGULAR_HEART_RATE_EVENT = "IRREGULAR_HEART_RATE_EVENT"
    let LOW_HEART_RATE_EVENT = "LOW_HEART_RATE_EVENT"
    let RESTING_HEART_RATE = "RESTING_HEART_RATE"
    let RESPIRATORY_RATE = "RESPIRATORY_RATE"
    let PERIPHERAL_PERFUSION_INDEX = "PERIPHERAL_PERFUSION_INDEX"
    let STEPS = "STEPS"
    let WAIST_CIRCUMFERENCE = "WAIST_CIRCUMFERENCE"
    let WALKING_HEART_RATE = "WALKING_HEART_RATE"
    let WEIGHT = "WEIGHT"
    let DISTANCE_WALKING_RUNNING = "DISTANCE_WALKING_RUNNING"
    let DISTANCE_SWIMMING = "DISTANCE_SWIMMING"
    let DISTANCE_CYCLING = "DISTANCE_CYCLING"
    let FLIGHTS_CLIMBED = "FLIGHTS_CLIMBED"
    let WATER = "WATER"
    let MINDFULNESS = "MINDFULNESS"
    let SLEEP_IN_BED = "SLEEP_IN_BED"
    let SLEEP_ASLEEP = "SLEEP_ASLEEP"
    let SLEEP_ASLEEP_CORE = "SLEEP_ASLEEP_CORE"
    let SLEEP_ASLEEP_DEEP = "SLEEP_ASLEEP_DEEP"
    let SLEEP_ASLEEP_REM = "SLEEP_ASLEEP_REM"
    let SLEEP_AWAKE = "SLEEP_AWAKE"
    let SLEEP_DEEP = "SLEEP_DEEP"
    let SLEEP_REM = "SLEEP_REM"
    let TIME_IN_DAYLIGHT = "TIME_IN_DAYLIGHT"

    let EXERCISE_TIME = "EXERCISE_TIME"
    let WORKOUT = "WORKOUT"
    let HEADACHE_UNSPECIFIED = "HEADACHE_UNSPECIFIED"
    let HEADACHE_NOT_PRESENT = "HEADACHE_NOT_PRESENT"
    let HEADACHE_MILD = "HEADACHE_MILD"
    let HEADACHE_MODERATE = "HEADACHE_MODERATE"
    let HEADACHE_SEVERE = "HEADACHE_SEVERE"
    let ELECTROCARDIOGRAM = "ELECTROCARDIOGRAM"
    let NUTRITION = "NUTRITION"

    // Health Unit types
    // MOLE_UNIT_WITH_MOLAR_MASS, // requires molar mass input - not supported yet
    // MOLE_UNIT_WITH_PREFIX_MOLAR_MASS, // requires molar mass & prefix input - not supported yet
    let GRAM = "GRAM"
    let KILOGRAM = "KILOGRAM"
    let OUNCE = "OUNCE"
    let POUND = "POUND"
    let STONE = "STONE"
    let METER = "METER"
    let INCH = "INCH"
    let FOOT = "FOOT"
    let YARD = "YARD"
    let MILE = "MILE"
    let LITER = "LITER"
    let MILLILITER = "MILLILITER"
    let FLUID_OUNCE_US = "FLUID_OUNCE_US"
    let FLUID_OUNCE_IMPERIAL = "FLUID_OUNCE_IMPERIAL"
    let CUP_US = "CUP_US"
    let CUP_IMPERIAL = "CUP_IMPERIAL"
    let PINT_US = "PINT_US"
    let PINT_IMPERIAL = "PINT_IMPERIAL"
    let PASCAL = "PASCAL"
    let MILLIMETER_OF_MERCURY = "MILLIMETER_OF_MERCURY"
    let INCHES_OF_MERCURY = "INCHES_OF_MERCURY"
    let CENTIMETER_OF_WATER = "CENTIMETER_OF_WATER"
    let ATMOSPHERE = "ATMOSPHERE"
    let DECIBEL_A_WEIGHTED_SOUND_PRESSURE_LEVEL = "DECIBEL_A_WEIGHTED_SOUND_PRESSURE_LEVEL"
    let SECOND = "SECOND"
    let MILLISECOND = "MILLISECOND"
    let MINUTE = "MINUTE"
    let HOUR = "HOUR"
    let DAY = "DAY"
    let JOULE = "JOULE"
    let KILOCALORIE = "KILOCALORIE"
    let LARGE_CALORIE = "LARGE_CALORIE"
    let SMALL_CALORIE = "SMALL_CALORIE"
    let DEGREE_CELSIUS = "DEGREE_CELSIUS"
    let DEGREE_FAHRENHEIT = "DEGREE_FAHRENHEIT"
    let KELVIN = "KELVIN"
    let DECIBEL_HEARING_LEVEL = "DECIBEL_HEARING_LEVEL"
    let HERTZ = "HERTZ"
    let SIEMEN = "SIEMEN"
    let VOLT = "VOLT"
    let INTERNATIONAL_UNIT = "INTERNATIONAL_UNIT"
    let COUNT = "COUNT"
    let PERCENT = "PERCENT"
    let BEATS_PER_MINUTE = "BEATS_PER_MINUTE"
    let RESPIRATIONS_PER_MINUTE = "RESPIRATIONS_PER_MINUTE"
    let MILLIGRAM_PER_DECILITER = "MILLIGRAM_PER_DECILITER"
    let UNKNOWN_UNIT = "UNKNOWN_UNIT"
    let NO_UNIT = "NO_UNIT"

    struct PluginError: Error {
        let message: String
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_health", binaryMessenger: registrar.messenger())
        let instance = SwiftHealthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Set up all data types
        initializeTypes()

        /// Handle checkIfHealthDataAvailable
        if call.method.elementsEqual("checkIfHealthDataAvailable") {
            checkIfHealthDataAvailable(call: call, result: result)
        }/// Handle requestAuthorization
        else if call.method.elementsEqual("requestAuthorization") {
            try! requestAuthorization(call: call, result: result)
        }

        /// Handle getData
        else if call.method.elementsEqual("getData") {
            getData(call: call, result: result)
        }

        /// Handle getIntervalData
        else if (call.method.elementsEqual("getIntervalData")){
            getIntervalData(call: call, result: result)
        }

        /// Handle getTotalStepsInInterval
        else if call.method.elementsEqual("getTotalStepsInInterval") {
            getTotalStepsInInterval(call: call, result: result)
        }

        /// Handle writeData
        else if call.method.elementsEqual("writeData") {
            try! writeData(call: call, result: result)
        }

        /// Handle writeAudiogram
        else if call.method.elementsEqual("writeAudiogram") {
            try! writeAudiogram(call: call, result: result)
        }

        /// Handle writeBloodPressure
        else if call.method.elementsEqual("writeBloodPressure") {
            try! writeBloodPressure(call: call, result: result)
        }

        /// Handle writeMeal
        else if (call.method.elementsEqual("writeMeal")){
            try! writeMeal(call: call, result: result)
        }

        /// Handle writeWorkoutData
        else if call.method.elementsEqual("writeWorkoutData") {
            try! writeWorkoutData(call: call, result: result)
        }

        /// Handle hasPermission
        else if call.method.elementsEqual("hasPermissions") {
            try! hasPermissions(call: call, result: result)
        }

        /// Handle delete data
        else if call.method.elementsEqual("delete") {
            try! delete(call: call, result: result)
        }

        /// Disconnect
        else if (call.method.elementsEqual("disconnect")){
            // Do nothing.
            result(true)
        }

    }

    func checkIfHealthDataAvailable(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(HKHealthStore.isHealthDataAvailable())
    }

    func hasPermissions(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let arguments = call.arguments as? NSDictionary
        guard var types = arguments?["types"] as? [String],
              var permissions = arguments?["permissions"] as? [Int],
              types.count == permissions.count
        else {
            throw PluginError(message: "Invalid Arguments!")
        }

        if let nutritionIndex = types.firstIndex(of: NUTRITION) {
            types.remove(at: nutritionIndex)
            let nutritionPermission = permissions[nutritionIndex]
            permissions.remove(at: nutritionIndex)

            types.append(DIETARY_ENERGY_CONSUMED)
            permissions.append(nutritionPermission)
            types.append(DIETARY_CARBS_CONSUMED)
            permissions.append(nutritionPermission)
            types.append(DIETARY_PROTEIN_CONSUMED)
            permissions.append(nutritionPermission)
            types.append(DIETARY_FATS_CONSUMED)
            permissions.append(nutritionPermission)
            types.append(DIETARY_CAFFEINE)
            permissions.append(nutritionPermission)
        }

        for (index, type) in types.enumerated() {
            let sampleType = dataTypeLookUp(key: type)
            let success = hasPermission(type: sampleType, access: permissions[index])
            if success == nil || success == false {
                result(success)
                return
            }
        }

        result(true)
    }

    func hasPermission(type: HKSampleType, access: Int) -> Bool? {

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

    func requestAuthorization(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let types = arguments["types"] as? [String],
              let permissions = arguments["permissions"] as? [Int],
              permissions.count == types.count
        else {
            throw PluginError(message: "Invalid Arguments!")
        }

        var typesToRead = Set<HKSampleType>()
        var typesToWrite = Set<HKSampleType>()
        for (index, key) in types.enumerated() {
            if (key == NUTRITION) {
                let caloriesType = dataTypeLookUp(key: DIETARY_ENERGY_CONSUMED)
                let carbsType = dataTypeLookUp(key: DIETARY_CARBS_CONSUMED)
                let proteinType = dataTypeLookUp(key: DIETARY_PROTEIN_CONSUMED)
                let fatType = dataTypeLookUp(key: DIETARY_FATS_CONSUMED)
                let caffeineType = dataTypeLookUp(key: DIETARY_CAFFEINE)
                typesToWrite.insert(caloriesType);
                typesToWrite.insert(carbsType);
                typesToWrite.insert(proteinType);
                typesToWrite.insert(fatType);
                typesToWrite.insert(caffeineType);
            } else {
                let dataType = dataTypeLookUp(key: key)
                let access = permissions[index]
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
        }

        if #available(iOS 13.0, *) {
            healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) {
                (success, error) in
                DispatchQueue.main.async {
                    result(success)
                }
            }
        } else {
            result(false)  // Handle the error here.
        }
    }

    func writeData(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let value = (arguments["value"] as? Double),
              let type = (arguments["dataTypeKey"] as? String),
              let unit = (arguments["dataUnitKey"] as? String),
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber)
        else {
            throw PluginError(message: "Invalid Arguments")
        }

        let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endTime.doubleValue / 1000)

        let sample: HKObject

        if dataTypeLookUp(key: type).isKind(of: HKCategoryType.self) {
            sample = HKCategorySample(
                type: dataTypeLookUp(key: type) as! HKCategoryType, value: Int(value), start: dateFrom,
                end: dateTo)
        } else {
            let quantity = HKQuantity(unit: unitDict[unit]!, doubleValue: value)
            sample = HKQuantitySample(
                type: dataTypeLookUp(key: type) as! HKQuantityType, quantity: quantity, start: dateFrom,
                end: dateTo)
        }

        HKHealthStore().save(
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

        let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endTime.doubleValue / 1000)

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

        HKHealthStore().save(
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

    func writeBloodPressure(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let systolic = (arguments["systolic"] as? Double),
              let diastolic = (arguments["diastolic"] as? Double),
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber)
        else {
            throw PluginError(message: "Invalid Arguments")
        }
        let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endTime.doubleValue / 1000)

        let systolic_sample = HKQuantitySample(
            type: HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            quantity: HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolic),
            start: dateFrom, end: dateTo)
        let diastolic_sample = HKQuantitySample(
            type: HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            quantity: HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: diastolic),
            start: dateFrom, end: dateTo)
        let bpCorrelationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
        let bpCorrelation = Set(arrayLiteral: systolic_sample, diastolic_sample)
        let blood_pressure_sample = HKCorrelation(type: bpCorrelationType , start: dateFrom, end: dateTo, objects: bpCorrelation)

        HKHealthStore().save(
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

    func writeMeal(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber),
              let calories = (arguments["caloriesConsumed"] as? Double?) ?? 0,
              let carbs = (arguments["carbohydrates"] as? Double?) ?? 0,
              let protein = (arguments["protein"] as? Double?) ?? 0,
              let fat = (arguments["fatTotal"] as? Double?) ?? 0,
              let name = (arguments["name"] as? String?),
              let caffeine = (arguments["caffeine"] as? Double?) ?? 0,
              let mealType = (arguments["mealType"] as? String?)
        else {
            throw PluginError(message: "Invalid Arguments")
        }
        let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endTime.doubleValue / 1000)

        var mealTypeString = mealType ?? "UNKNOWN"
        var metadata = ["HKFoodMeal": "\(mealTypeString)"]

        if(name != nil) {
            metadata[HKMetadataKeyFoodType] = "\(name!)"
        }

        var nutrition = Set<HKSample>()

        if(calories > 0) {
            let caloriesSample = HKQuantitySample(type: HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!, quantity: HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories), start: dateFrom, end: dateTo, metadata: metadata)
            nutrition.insert(caloriesSample)
        }

        if(carbs > 0) {
            let carbsSample = HKQuantitySample(type: HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates)!, quantity: HKQuantity(unit: HKUnit.gram(), doubleValue: carbs), start: dateFrom, end: dateTo, metadata: metadata)
            nutrition.insert(carbsSample)
        }

        if(protein > 0) {
            let proteinSample = HKQuantitySample(type: HKSampleType.quantityType(forIdentifier: .dietaryProtein)!, quantity: HKQuantity(unit: HKUnit.gram(), doubleValue: protein), start: dateFrom, end: dateTo, metadata: metadata)
            nutrition.insert(proteinSample)
        }

        if(fat > 0) {
            let fatSample = HKQuantitySample(type: HKSampleType.quantityType(forIdentifier: .dietaryFatTotal)!, quantity: HKQuantity(unit: HKUnit.gram(), doubleValue: fat), start: dateFrom, end: dateTo, metadata: metadata)
            nutrition.insert(fatSample)
        }

        if(caffeine > 0) {
            let caffeineSample = HKQuantitySample(type: HKSampleType.quantityType(forIdentifier: .dietaryCaffeine)!, quantity: HKQuantity(unit: HKUnit.gram(), doubleValue: caffeine), start: dateFrom, end: dateTo, metadata: metadata)
            nutrition.insert(caffeineSample)
        }
        
        if #available(iOS 15.0, *){
            let meal = HKCorrelation.init(type: HKCorrelationType.init(HKCorrelationTypeIdentifier.food), start: dateFrom, end: dateTo, objects: nutrition, metadata: metadata)

            HKHealthStore().save(meal, withCompletion: { (success, error) in
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

    func writeWorkoutData(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let arguments = call.arguments as? NSDictionary,
              let activityType = (arguments["activityType"] as? String),
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber),
              let ac = workoutActivityTypeMap[activityType]
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

        let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endTime.doubleValue / 1000)

        var workout: HKWorkout

        workout = HKWorkout(
            activityType: ac, start: dateFrom, end: dateTo, duration: dateTo.timeIntervalSince(dateFrom),
            totalEnergyBurned: totalEnergyBurned ?? nil,
            totalDistance: totalDistance ?? nil, metadata: nil)

        HKHealthStore().save(
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

    func delete(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let dataTypeKey = (arguments?["dataTypeKey"] as? String)!
        let startTime = (arguments?["startTime"] as? NSNumber) ?? 0
        let endTime = (arguments?["endTime"] as? NSNumber) ?? 0

        let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endTime.doubleValue / 1000)

        let dataType = dataTypeLookUp(key: dataTypeKey)

        let predicate = HKQuery.predicateForSamples(
            withStart: dateFrom, end: dateTo, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let deleteQuery = HKSampleQuery(
            sampleType: dataType, predicate: predicate, limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [self] x, samplesOrNil, error in

            guard let samplesOrNil = samplesOrNil, error == nil else {
                // Handle the error if necessary
                print("Error deleting \(dataType)")
                return
            }

            // Delete the retrieved objects from the HealthKit store
            HKHealthStore().delete(samplesOrNil) { (success, error) in
                if let err = error {
                    print("Error deleting \(dataType) Sample: \(err.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result(success)
                }
            }
        }

        HKHealthStore().execute(deleteQuery)
    }

    func getData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let dataTypeKey = (arguments?["dataTypeKey"] as? String)!
        let dataUnitKey = (arguments?["dataUnitKey"] as? String)
        let startTime = (arguments?["startTime"] as? NSNumber) ?? 0
        let endTime = (arguments?["endTime"] as? NSNumber) ?? 0
        let limit = (arguments?["limit"] as? Int) ?? HKObjectQueryNoLimit
        let includeManualEntry = (arguments?["includeManualEntry"] as? Bool) ?? true

        // Convert dates from milliseconds to Date()
        let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endTime.doubleValue / 1000)

        let dataType = dataTypeLookUp(key: dataTypeKey)
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
        ) {
            [self]
            x, samplesOrNil, error in

            switch samplesOrNil {
            case let (samples as [HKQuantitySample]) as Any:
                let dictionaries = samples.map { sample -> NSDictionary in
                    return [
                        "uuid": "\(sample.uuid)",
                        "value": sample.quantity.doubleValue(for: unit!),
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                        "source_id": sample.sourceRevision.source.bundleIdentifier,
                        "source_name": sample.sourceRevision.source.name,
                        "is_manual_entry": sample.metadata?[HKMetadataKeyWasUserEntered] != nil
                    ]
                }
                DispatchQueue.main.async {
                    result(dictionaries)
                }

            case var (samplesCategory as [HKCategorySample]) as Any:

                if dataTypeKey == self.SLEEP_IN_BED {
                    samplesCategory = samplesCategory.filter { $0.value == 0 }
                }
                if dataTypeKey == self.SLEEP_ASLEEP_CORE {
                    samplesCategory = samplesCategory.filter { $0.value == 3 }
                }
                if dataTypeKey == self.SLEEP_ASLEEP_DEEP {
                    samplesCategory = samplesCategory.filter { $0.value == 4 }
                }
                if dataTypeKey == self.SLEEP_ASLEEP_REM {
                    samplesCategory = samplesCategory.filter { $0.value == 5 }
                }
                if dataTypeKey == self.SLEEP_AWAKE {
                    samplesCategory = samplesCategory.filter { $0.value == 2 }
                }
                if dataTypeKey == self.SLEEP_ASLEEP {
                    samplesCategory = samplesCategory.filter { $0.value == 3  || $0.value == 1 }
                }
                if dataTypeKey == self.SLEEP_DEEP {
                    samplesCategory = samplesCategory.filter { $0.value == 4 }
                }
                if dataTypeKey == self.SLEEP_REM {
                    samplesCategory = samplesCategory.filter { $0.value == 5 }
                }
                if dataTypeKey == self.HEADACHE_UNSPECIFIED {
                    samplesCategory = samplesCategory.filter { $0.value == 0 }
                }
                if dataTypeKey == self.HEADACHE_NOT_PRESENT {
                    samplesCategory = samplesCategory.filter { $0.value == 1 }
                }
                if dataTypeKey == self.HEADACHE_MILD {
                    samplesCategory = samplesCategory.filter { $0.value == 2 }
                }
                if dataTypeKey == self.HEADACHE_MODERATE {
                    samplesCategory = samplesCategory.filter { $0.value == 3 }
                }
                if dataTypeKey == self.HEADACHE_SEVERE {
                    samplesCategory = samplesCategory.filter { $0.value == 4 }
                }
                let categories = samplesCategory.map { sample -> NSDictionary in
                    return [
                        "uuid": "\(sample.uuid)",
                        "value": sample.value,
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                        "source_id": sample.sourceRevision.source.bundleIdentifier,
                        "source_name": sample.sourceRevision.source.name,
                        "is_manual_entry": sample.metadata?[HKMetadataKeyWasUserEntered] != nil
                    ]
                }
                DispatchQueue.main.async {
                    result(categories)
                }

            case let (samplesWorkout as [HKWorkout]) as Any:

                let dictionaries = samplesWorkout.map { sample -> NSDictionary in
                    return [
                        "uuid": "\(sample.uuid)",
                        "workoutActivityType": workoutActivityTypeMap.first(where: {
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
                        "is_manual_entry": sample.metadata?[HKMetadataKeyWasUserEntered] != nil,
                        "workout_type": self.getWorkoutType(type: sample.workoutActivityType),
                        "total_distance": sample.totalDistance != nil ? Int(sample.totalDistance!.doubleValue(for: HKUnit.meter())) : 0,
                        "total_energy_burned": sample.totalEnergyBurned != nil ? Int(sample.totalEnergyBurned!.doubleValue(for: HKUnit.kilocalorie())) : 0
                    ]
                }

                DispatchQueue.main.async {
                    result(dictionaries)
                }

            case let (samplesAudiogram as [HKAudiogramSample]) as Any:
                let dictionaries = samplesAudiogram.map { sample -> NSDictionary in
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

            case let (nutritionSample as [HKCorrelation]) as Any:

                //let samples = nutritionSample[0].objects(for: HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!)
                var calories = 0.0
                var fat = 0.0
                var carbs = 0.0
                var protein = 0.0

                let name = nutritionSample[0].metadata?[HKMetadataKeyFoodType] as! String
                let mealType = nutritionSample[0].metadata?["HKFoodMeal"]
                let samples = nutritionSample[0].objects
                for sample in samples {
                    if let quantitySample = sample as? HKQuantitySample {
                        if (quantitySample.quantityType == HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)){
                            calories = quantitySample.quantity.doubleValue(for: HKUnit.kilocalorie())
                        }
                        if (quantitySample.quantityType == HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)){
                            carbs = quantitySample.quantity.doubleValue(for: HKUnit.gram())
                        }
                        if (quantitySample.quantityType == HKObjectType.quantityType(forIdentifier: .dietaryProtein)){
                            protein = quantitySample.quantity.doubleValue(for: HKUnit.gram())
                        }
                        if (quantitySample.quantityType == HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)){
                            fat = quantitySample.quantity.doubleValue(for: HKUnit.gram())
                        }
                    }
                }


                let dictionaries = nutritionSample.map { sample -> NSDictionary in
                    return [
                        "uuid": "\(sample.uuid)",
                        "calories": calories,
                        "carbs": carbs,
                        "protein": protein,
                        "fat": fat,
                        "name": name,
                        "mealType": mealType,
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                        "source_id": sample.sourceRevision.source.bundleIdentifier,
                        "source_name": sample.sourceRevision.source.name,
                    ]
                }
                DispatchQueue.main.async {
                    result(dictionaries)
                }

            default:
                if #available(iOS 14.0, *), let ecgSamples = samplesOrNil as? [HKElectrocardiogram] {
                    let dictionaries = ecgSamples.map(fetchEcgMeasurements)
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

        HKHealthStore().execute(query)
    }

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
            }
        }
        HKHealthStore().execute(voltageQuery)
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

    func getIntervalData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let dataTypeKey = (arguments?["dataTypeKey"] as? String) ?? "DEFAULT"
        let dataUnitKey = (arguments?["dataUnitKey"] as? String)
        let startDate = (arguments?["startTime"] as? NSNumber) ?? 0
        let endDate = (arguments?["endTime"] as? NSNumber) ?? 0
        let intervalInSecond = (arguments?["interval"] as? Int) ?? 1
        let includeManualEntry = (arguments?["includeManualEntry"] as? Bool) ?? true

        // Set interval in seconds.
        var interval = DateComponents()
        interval.second = intervalInSecond

        // Convert dates from milliseconds to Date()
        let dateFrom = Date(timeIntervalSince1970: startDate.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endDate.doubleValue / 1000)

        let quantityType: HKQuantityType! = dataQuantityTypesDict[dataTypeKey]
        var predicate = HKQuery.predicateForSamples(withStart: dateFrom, end: dateTo, options: [])
        if (!includeManualEntry) {
            let manualPredicate = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
            predicate = NSCompoundPredicate(type: .and, subpredicates: [predicate, manualPredicate])
        }

        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: [.cumulativeSum, .separateBySource], anchorDate: dateFrom, intervalComponents: interval)

        query.initialResultsHandler = {
            [weak self] _, statisticCollectionOrNil, error in
            guard let self = self else {
                // Handle the case where self became nil.
                print("Self is nil")
                DispatchQueue.main.async {
                    result(nil)
                }
                return
            }

            // Error detected.
            if let error = error {
                print("Query error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    result(nil)
                }
                return
            }

            guard let collection = statisticCollectionOrNil as? HKStatisticsCollection else {
                print("Unexpected result from query")
                DispatchQueue.main.async {
                    result(nil)
                }
                return
            }

            var dictionaries = [[String: Any]]()
            collection.enumerateStatistics(from: dateFrom, to: dateTo) {
                [weak self] statisticData, _ in
                guard let self = self else {
                    // Handle the case where self became nil.
                    print("Self is nil during enumeration")
                    return
                }

                do {
                    if let quantity = statisticData.sumQuantity(),
                       let dataUnitKey = dataUnitKey,
                       let unit = self.unitDict[dataUnitKey] {
                        let dict = [
                            "value": quantity.doubleValue(for: unit),
                            "date_from": Int(statisticData.startDate.timeIntervalSince1970 * 1000),
                            "date_to": Int(statisticData.endDate.timeIntervalSince1970 * 1000),
                            "source_id": statisticData.sources?.first?.bundleIdentifier ?? "",
                            "source_name": statisticData.sources?.first?.name ?? ""
                        ]
                        dictionaries.append(dict)
                    }
                } catch {
                    print("Error during collection.enumeration: \(error)")
                }
            }
            DispatchQueue.main.async {
                result(dictionaries)
            }
        }
        HKHealthStore().execute(query)
    }

    func getTotalStepsInInterval(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let startTime = (arguments?["startTime"] as? NSNumber) ?? 0
        let endTime = (arguments?["endTime"] as? NSNumber) ?? 0

        // Convert dates from milliseconds to Date()
        let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endTime.doubleValue / 1000)

        let sampleType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(
            withStart: dateFrom, end: dateTo, options: .strictStartDate)

        let query = HKStatisticsQuery(
            quantityType: sampleType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { query, queryResult, error in

            guard let queryResult = queryResult else {
                let error = error! as NSError
                print("Error getting total steps in interval \(error.localizedDescription)")

                DispatchQueue.main.async {
                    result(nil)
                }
                return
            }

            var steps = 0.0

            if let quantity = queryResult.sumQuantity() {
                let unit = HKUnit.count()
                steps = quantity.doubleValue(for: unit)
            }

            let totalSteps = Int(steps)
            DispatchQueue.main.async {
                result(totalSteps)
            }
        }

        HKHealthStore().execute(query)
    }

    func unitLookUp(key: String) -> HKUnit {
        guard let unit = unitDict[key] else {
            return HKUnit.count()
        }
        return unit
    }

    func dataTypeLookUp(key: String) -> HKSampleType {
        guard let dataType_ = dataTypesDict[key] else {
            return HKSampleType.quantityType(forIdentifier: .bodyMass)!
        }
        return dataType_
    }

    func initializeTypes() {
        // Initialize units
        unitDict[GRAM] = HKUnit.gram()
        unitDict[KILOGRAM] = HKUnit.gramUnit(with: .kilo)
        unitDict[OUNCE] = HKUnit.ounce()
        unitDict[POUND] = HKUnit.pound()
        unitDict[STONE] = HKUnit.stone()
        unitDict[METER] = HKUnit.meter()
        unitDict[INCH] = HKUnit.inch()
        unitDict[FOOT] = HKUnit.foot()
        unitDict[YARD] = HKUnit.yard()
        unitDict[MILE] = HKUnit.mile()
        unitDict[LITER] = HKUnit.liter()
        unitDict[MILLILITER] = HKUnit.literUnit(with: .milli)
        unitDict[FLUID_OUNCE_US] = HKUnit.fluidOunceUS()
        unitDict[FLUID_OUNCE_IMPERIAL] = HKUnit.fluidOunceImperial()
        unitDict[CUP_US] = HKUnit.cupUS()
        unitDict[CUP_IMPERIAL] = HKUnit.cupImperial()
        unitDict[PINT_US] = HKUnit.pintUS()
        unitDict[PINT_IMPERIAL] = HKUnit.pintImperial()
        unitDict[PASCAL] = HKUnit.pascal()
        unitDict[MILLIMETER_OF_MERCURY] = HKUnit.millimeterOfMercury()
        unitDict[CENTIMETER_OF_WATER] = HKUnit.centimeterOfWater()
        unitDict[ATMOSPHERE] = HKUnit.atmosphere()
        unitDict[DECIBEL_A_WEIGHTED_SOUND_PRESSURE_LEVEL] = HKUnit.decibelAWeightedSoundPressureLevel()
        unitDict[SECOND] = HKUnit.second()
        unitDict[MILLISECOND] = HKUnit.secondUnit(with: .milli)
        unitDict[MINUTE] = HKUnit.minute()
        unitDict[HOUR] = HKUnit.hour()
        unitDict[DAY] = HKUnit.day()
        unitDict[JOULE] = HKUnit.joule()
        unitDict[KILOCALORIE] = HKUnit.kilocalorie()
        unitDict[LARGE_CALORIE] = HKUnit.largeCalorie()
        unitDict[SMALL_CALORIE] = HKUnit.smallCalorie()
        unitDict[DEGREE_CELSIUS] = HKUnit.degreeCelsius()
        unitDict[DEGREE_FAHRENHEIT] = HKUnit.degreeFahrenheit()
        unitDict[KELVIN] = HKUnit.kelvin()
        unitDict[DECIBEL_HEARING_LEVEL] = HKUnit.decibelHearingLevel()
        unitDict[HERTZ] = HKUnit.hertz()
        unitDict[SIEMEN] = HKUnit.siemen()
        unitDict[INTERNATIONAL_UNIT] = HKUnit.internationalUnit()
        unitDict[COUNT] = HKUnit.count()
        unitDict[PERCENT] = HKUnit.percent()
        unitDict[BEATS_PER_MINUTE] = HKUnit.init(from: "count/min")
        unitDict[RESPIRATIONS_PER_MINUTE] = HKUnit.init(from: "count/min")
        unitDict[MILLIGRAM_PER_DECILITER] = HKUnit.init(from: "mg/dL")
        unitDict[UNKNOWN_UNIT] = HKUnit.init(from: "")
        unitDict[NO_UNIT] = HKUnit.init(from: "")

        // Initialize workout types
        workoutActivityTypeMap["ARCHERY"] = .archery
        workoutActivityTypeMap["BOWLING"] = .bowling
        workoutActivityTypeMap["FENCING"] = .fencing
        workoutActivityTypeMap["GYMNASTICS"] = .gymnastics
        workoutActivityTypeMap["TRACK_AND_FIELD"] = .trackAndField
        workoutActivityTypeMap["AMERICAN_FOOTBALL"] = .americanFootball
        workoutActivityTypeMap["AUSTRALIAN_FOOTBALL"] = .australianFootball
        workoutActivityTypeMap["BASEBALL"] = .baseball
        workoutActivityTypeMap["BASKETBALL"] = .basketball
        workoutActivityTypeMap["CRICKET"] = .cricket
        workoutActivityTypeMap["DISC_SPORTS"] = .discSports
        workoutActivityTypeMap["HANDBALL"] = .handball
        workoutActivityTypeMap["HOCKEY"] = .hockey
        workoutActivityTypeMap["LACROSSE"] = .lacrosse
        workoutActivityTypeMap["RUGBY"] = .rugby
        workoutActivityTypeMap["SOCCER"] = .soccer
        workoutActivityTypeMap["SOFTBALL"] = .softball
        workoutActivityTypeMap["VOLLEYBALL"] = .volleyball
        workoutActivityTypeMap["PREPARATION_AND_RECOVERY"] = .preparationAndRecovery
        workoutActivityTypeMap["FLEXIBILITY"] = .flexibility
        workoutActivityTypeMap["WALKING"] = .walking
        workoutActivityTypeMap["RUNNING"] = .running
        workoutActivityTypeMap["RUNNING_JOGGING"] = .running  // Supported due to combining with Android naming
        workoutActivityTypeMap["RUNNING_SAND"] = .running  // Supported due to combining with Android naming
        workoutActivityTypeMap["RUNNING_TREADMILL"] = .running  // Supported due to combining with Android naming
        workoutActivityTypeMap["WHEELCHAIR_WALK_PACE"] = .wheelchairWalkPace
        workoutActivityTypeMap["WHEELCHAIR_RUN_PACE"] = .wheelchairRunPace
        workoutActivityTypeMap["BIKING"] = .cycling
        workoutActivityTypeMap["HAND_CYCLING"] = .handCycling
        workoutActivityTypeMap["CORE_TRAINING"] = .coreTraining
        workoutActivityTypeMap["ELLIPTICAL"] = .elliptical
        workoutActivityTypeMap["FUNCTIONAL_STRENGTH_TRAINING"] = .functionalStrengthTraining
        workoutActivityTypeMap["TRADITIONAL_STRENGTH_TRAINING"] = .traditionalStrengthTraining
        workoutActivityTypeMap["CROSS_TRAINING"] = .crossTraining
        workoutActivityTypeMap["MIXED_CARDIO"] = .mixedCardio
        workoutActivityTypeMap["HIGH_INTENSITY_INTERVAL_TRAINING"] = .highIntensityIntervalTraining
        workoutActivityTypeMap["JUMP_ROPE"] = .jumpRope
        workoutActivityTypeMap["STAIR_CLIMBING"] = .stairClimbing
        workoutActivityTypeMap["STAIRS"] = .stairs
        workoutActivityTypeMap["STEP_TRAINING"] = .stepTraining
        workoutActivityTypeMap["FITNESS_GAMING"] = .fitnessGaming
        workoutActivityTypeMap["BARRE"] = .barre
        workoutActivityTypeMap["YOGA"] = .yoga
        workoutActivityTypeMap["MIND_AND_BODY"] = .mindAndBody
        workoutActivityTypeMap["PILATES"] = .pilates
        workoutActivityTypeMap["BADMINTON"] = .badminton
        workoutActivityTypeMap["RACQUETBALL"] = .racquetball
        workoutActivityTypeMap["SQUASH"] = .squash
        workoutActivityTypeMap["TABLE_TENNIS"] = .tableTennis
        workoutActivityTypeMap["TENNIS"] = .tennis
        workoutActivityTypeMap["CLIMBING"] = .climbing
        workoutActivityTypeMap["ROCK_CLIMBING"] = .climbing  // Supported due to combining with Android naming
        workoutActivityTypeMap["EQUESTRIAN_SPORTS"] = .equestrianSports
        workoutActivityTypeMap["FISHING"] = .fishing
        workoutActivityTypeMap["GOLF"] = .golf
        workoutActivityTypeMap["HIKING"] = .hiking
        workoutActivityTypeMap["HUNTING"] = .hunting
        workoutActivityTypeMap["PLAY"] = .play
        workoutActivityTypeMap["CROSS_COUNTRY_SKIING"] = .crossCountrySkiing
        workoutActivityTypeMap["CURLING"] = .curling
        workoutActivityTypeMap["DOWNHILL_SKIING"] = .downhillSkiing
        workoutActivityTypeMap["SNOW_SPORTS"] = .snowSports
        workoutActivityTypeMap["SNOWBOARDING"] = .snowboarding
        workoutActivityTypeMap["SKATING"] = .skatingSports
        workoutActivityTypeMap["SKATING_CROSS,"] = .skatingSports  // Supported due to combining with Android naming
        workoutActivityTypeMap["SKATING_INDOOR,"] = .skatingSports  // Supported due to combining with Android naming
        workoutActivityTypeMap["SKATING_INLINE,"] = .skatingSports  // Supported due to combining with Android naming
        workoutActivityTypeMap["PADDLE_SPORTS"] = .paddleSports
        workoutActivityTypeMap["ROWING"] = .rowing
        workoutActivityTypeMap["SAILING"] = .sailing
        workoutActivityTypeMap["SURFING_SPORTS"] = .surfingSports
        workoutActivityTypeMap["SWIMMING"] = .swimming
        workoutActivityTypeMap["WATER_FITNESS"] = .waterFitness
        workoutActivityTypeMap["WATER_POLO"] = .waterPolo
        workoutActivityTypeMap["WATER_SPORTS"] = .waterSports
        workoutActivityTypeMap["BOXING"] = .boxing
        workoutActivityTypeMap["KICKBOXING"] = .kickboxing
        workoutActivityTypeMap["MARTIAL_ARTS"] = .martialArts
        workoutActivityTypeMap["TAI_CHI"] = .taiChi
        workoutActivityTypeMap["WRESTLING"] = .wrestling
        workoutActivityTypeMap["OTHER"] = .other

        // Set up iOS 13 specific types (ordinary health data types)
        if #available(iOS 13.0, *) {
            dataTypesDict[ACTIVE_ENERGY_BURNED] = HKSampleType.quantityType(
                forIdentifier: .activeEnergyBurned)!
            dataTypesDict[AUDIOGRAM] = HKSampleType.audiogramSampleType()
            dataTypesDict[BASAL_ENERGY_BURNED] = HKSampleType.quantityType(
                forIdentifier: .basalEnergyBurned)!
            dataTypesDict[BLOOD_GLUCOSE] = HKSampleType.quantityType(forIdentifier: .bloodGlucose)!
            dataTypesDict[BLOOD_OXYGEN] = HKSampleType.quantityType(forIdentifier: .oxygenSaturation)!
            dataTypesDict[RESPIRATORY_RATE] = HKSampleType.quantityType(forIdentifier: .respiratoryRate)!
            dataTypesDict[PERIPHERAL_PERFUSION_INDEX] = HKSampleType.quantityType(
                forIdentifier: .peripheralPerfusionIndex)!

            dataTypesDict[BLOOD_PRESSURE_DIASTOLIC] = HKSampleType.quantityType(
                forIdentifier: .bloodPressureDiastolic)!
            dataTypesDict[BLOOD_PRESSURE_SYSTOLIC] = HKSampleType.quantityType(
                forIdentifier: .bloodPressureSystolic)!
            dataTypesDict[BODY_FAT_PERCENTAGE] = HKSampleType.quantityType(
                forIdentifier: .bodyFatPercentage)!
            dataTypesDict[BODY_MASS_INDEX] = HKSampleType.quantityType(forIdentifier: .bodyMassIndex)!
            dataTypesDict[BODY_TEMPERATURE] = HKSampleType.quantityType(forIdentifier: .bodyTemperature)!
            dataTypesDict[DIETARY_CARBS_CONSUMED] = HKSampleType.quantityType(
                forIdentifier: .dietaryCarbohydrates)!
            dataTypesDict[DIETARY_ENERGY_CONSUMED] = HKSampleType.quantityType(
                forIdentifier: .dietaryEnergyConsumed)!
            dataTypesDict[DIETARY_CAFFEINE] = HKSampleType.quantityType(
                forIdentifier: .dietaryCaffeine)!
            dataTypesDict[DIETARY_FATS_CONSUMED] = HKSampleType.quantityType(
                forIdentifier: .dietaryFatTotal)!
            dataTypesDict[DIETARY_PROTEIN_CONSUMED] = HKSampleType.quantityType(
                forIdentifier: .dietaryProtein)!
            dataTypesDict[ELECTRODERMAL_ACTIVITY] = HKSampleType.quantityType(
                forIdentifier: .electrodermalActivity)!
            dataTypesDict[FORCED_EXPIRATORY_VOLUME] = HKSampleType.quantityType(
                forIdentifier: .forcedExpiratoryVolume1)!
            dataTypesDict[HEART_RATE] = HKSampleType.quantityType(forIdentifier: .heartRate)!
            dataTypesDict[HEART_RATE_VARIABILITY_SDNN] = HKSampleType.quantityType(
                forIdentifier: .heartRateVariabilitySDNN)!
            dataTypesDict[HEIGHT] = HKSampleType.quantityType(forIdentifier: .height)!
            dataTypesDict[RESTING_HEART_RATE] = HKSampleType.quantityType(
                forIdentifier: .restingHeartRate)!
            dataTypesDict[STEPS] = HKSampleType.quantityType(forIdentifier: .stepCount)!
            dataTypesDict[WAIST_CIRCUMFERENCE] = HKSampleType.quantityType(
                forIdentifier: .waistCircumference)!
            dataTypesDict[WALKING_HEART_RATE] = HKSampleType.quantityType(
                forIdentifier: .walkingHeartRateAverage)!
            dataTypesDict[WEIGHT] = HKSampleType.quantityType(forIdentifier: .bodyMass)!
            dataTypesDict[DISTANCE_WALKING_RUNNING] = HKSampleType.quantityType(
                forIdentifier: .distanceWalkingRunning)!
            dataTypesDict[DISTANCE_SWIMMING] = HKSampleType.quantityType(forIdentifier: .distanceSwimming)!
            dataTypesDict[DISTANCE_CYCLING] = HKSampleType.quantityType(forIdentifier: .distanceCycling)!
            dataTypesDict[FLIGHTS_CLIMBED] = HKSampleType.quantityType(forIdentifier: .flightsClimbed)!
            dataTypesDict[WATER] = HKSampleType.quantityType(forIdentifier: .dietaryWater)!
            dataTypesDict[MINDFULNESS] = HKSampleType.categoryType(forIdentifier: .mindfulSession)!
            dataTypesDict[SLEEP_IN_BED] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
            dataTypesDict[SLEEP_ASLEEP] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
            dataTypesDict[SLEEP_ASLEEP_CORE] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
            dataTypesDict[SLEEP_ASLEEP_DEEP] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
            dataTypesDict[SLEEP_ASLEEP_REM] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
            dataTypesDict[SLEEP_AWAKE] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
            dataTypesDict[SLEEP_DEEP] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
            dataTypesDict[SLEEP_REM] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!

            dataTypesDict[EXERCISE_TIME] = HKSampleType.quantityType(forIdentifier: .appleExerciseTime)!
            dataTypesDict[WORKOUT] = HKSampleType.workoutType()
            dataTypesDict[NUTRITION] = HKSampleType.correlationType(
                forIdentifier: .food)!

            healthDataTypes = Array(dataTypesDict.values)
        }

        // Set up iOS 11 specific types (ordinary health data quantity types)
        if #available(iOS 11.0, *) {
            dataQuantityTypesDict[ACTIVE_ENERGY_BURNED] = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
            dataQuantityTypesDict[BASAL_ENERGY_BURNED] = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
            dataQuantityTypesDict[BLOOD_GLUCOSE] = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
            dataQuantityTypesDict[BLOOD_OXYGEN] = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
            dataQuantityTypesDict[BLOOD_PRESSURE_DIASTOLIC] = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
            dataQuantityTypesDict[BLOOD_PRESSURE_SYSTOLIC] = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
            dataQuantityTypesDict[BODY_FAT_PERCENTAGE] = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
            dataQuantityTypesDict[BODY_MASS_INDEX] = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!
            dataQuantityTypesDict[BODY_TEMPERATURE] = HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
            dataQuantityTypesDict[DIETARY_CARBS_CONSUMED] = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
            dataQuantityTypesDict[DIETARY_ENERGY_CONSUMED] = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            dataQuantityTypesDict[DIETARY_FATS_CONSUMED] = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
            dataQuantityTypesDict[DIETARY_PROTEIN_CONSUMED] = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            dataQuantityTypesDict[ELECTRODERMAL_ACTIVITY] = HKQuantityType.quantityType(forIdentifier: .electrodermalActivity)!
            dataQuantityTypesDict[FORCED_EXPIRATORY_VOLUME] = HKQuantityType.quantityType(forIdentifier: .forcedExpiratoryVolume1)!
            dataQuantityTypesDict[HEART_RATE] = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            dataQuantityTypesDict[HEART_RATE_VARIABILITY_SDNN] = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            dataQuantityTypesDict[HEIGHT] = HKQuantityType.quantityType(forIdentifier: .height)!
            dataQuantityTypesDict[RESTING_HEART_RATE] = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
            dataQuantityTypesDict[STEPS] = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            dataQuantityTypesDict[WAIST_CIRCUMFERENCE] = HKQuantityType.quantityType(forIdentifier: .waistCircumference)!
            dataQuantityTypesDict[WALKING_HEART_RATE] = HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage)!
            dataQuantityTypesDict[WEIGHT] = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
            dataQuantityTypesDict[DISTANCE_WALKING_RUNNING] = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
            dataQuantityTypesDict[DISTANCE_SWIMMING] = HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!
            dataQuantityTypesDict[DISTANCE_CYCLING] = HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
            dataQuantityTypesDict[FLIGHTS_CLIMBED] = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
            dataQuantityTypesDict[WATER] = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!

            healthDataQuantityTypes = Array(dataQuantityTypesDict.values)
        }

        // Set up heart rate data types specific to the apple watch, requires iOS 12
        if #available(iOS 12.2, *) {
            dataTypesDict[HIGH_HEART_RATE_EVENT] = HKSampleType.categoryType(
                forIdentifier: .highHeartRateEvent)!
            dataTypesDict[LOW_HEART_RATE_EVENT] = HKSampleType.categoryType(
                forIdentifier: .lowHeartRateEvent)!
            dataTypesDict[IRREGULAR_HEART_RATE_EVENT] = HKSampleType.categoryType(
                forIdentifier: .irregularHeartRhythmEvent)!

            heartRateEventTypes = Set([
                HKSampleType.categoryType(forIdentifier: .highHeartRateEvent)!,
                HKSampleType.categoryType(forIdentifier: .lowHeartRateEvent)!,
                HKSampleType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!,
            ])
        }

        if #available(iOS 13.6, *) {
            dataTypesDict[HEADACHE_UNSPECIFIED] = HKSampleType.categoryType(forIdentifier: .headache)!
            dataTypesDict[HEADACHE_NOT_PRESENT] = HKSampleType.categoryType(forIdentifier: .headache)!
            dataTypesDict[HEADACHE_MILD] = HKSampleType.categoryType(forIdentifier: .headache)!
            dataTypesDict[HEADACHE_MODERATE] = HKSampleType.categoryType(forIdentifier: .headache)!
            dataTypesDict[HEADACHE_SEVERE] = HKSampleType.categoryType(forIdentifier: .headache)!

            headacheType = Set([
                HKSampleType.categoryType(forIdentifier: .headache)!
            ])
        }

        if #available(iOS 14.0, *) {
            dataTypesDict[ELECTROCARDIOGRAM] = HKSampleType.electrocardiogramType()

            unitDict[VOLT] = HKUnit.volt()
            unitDict[INCHES_OF_MERCURY] = HKUnit.inchesOfMercury()

            workoutActivityTypeMap["CARDIO_DANCE"] = HKWorkoutActivityType.cardioDance
            workoutActivityTypeMap["SOCIAL_DANCE"] = HKWorkoutActivityType.socialDance
            workoutActivityTypeMap["PICKLEBALL"] = HKWorkoutActivityType.pickleball
            workoutActivityTypeMap["COOLDOWN"] = HKWorkoutActivityType.cooldown
        }
      
        if #available(iOS 17.0, *) {
          dataTypesDict[TIME_IN_DAYLIGHT] = HKObjectType.quantityType(forIdentifier: .timeInDaylight)!
        }

        // Concatenate heart events, headache and health data types (both may be empty)
        allDataTypes = Set(heartRateEventTypes + healthDataTypes)
        allDataTypes = allDataTypes.union(headacheType)
    }

    func getWorkoutType(type: HKWorkoutActivityType) -> String {
        switch type {
        case .americanFootball:
            return "americanFootball"
        case .archery:
            return "archery"
        case .australianFootball:
            return "australianFootball"
        case .badminton:
            return "badminton"
        case .baseball:
            return "baseball"
        case .basketball:
            return "basketball"
        case .bowling:
            return "bowling"
        case .boxing:
            return "boxing"
        case .climbing:
            return "climbing"
        case .cricket:
            return "cricket"
        case .crossTraining:
            return "crossTraining"
        case .curling:
            return "curling"
        case .cycling:
            return "cycling"
        case .dance:
            return "dance"
        case .danceInspiredTraining:
            return "danceInspiredTraining"
        case .elliptical:
            return "elliptical"
        case .equestrianSports:
            return "equestrianSports"
        case .fencing:
            return "fencing"
        case .fishing:
            return "fishing"
        case .functionalStrengthTraining:
            return "functionalStrengthTraining"
        case .golf:
            return "golf"
        case .gymnastics:
            return "gymnastics"
        case .handball:
            return "handball"
        case .hiking:
            return "hiking"
        case .hockey:
            return "hockey"
        case .hunting:
            return "hunting"
        case .lacrosse:
            return "lacrosse"
        case .martialArts:
            return "martialArts"
        case .mindAndBody:
            return "mindAndBody"
        case .mixedMetabolicCardioTraining:
            return "mixedMetabolicCardioTraining"
        case .paddleSports:
            return "paddleSports"
        case .play:
            return "play"
        case .preparationAndRecovery:
            return "preparationAndRecovery"
        case .racquetball:
            return "racquetball"
        case .rowing:
            return "rowing"
        case .rugby:
            return "rugby"
        case .running:
            return "running"
        case .sailing:
            return "sailing"
        case .skatingSports:
            return "skatingSports"
        case .snowSports:
            return "snowSports"
        case .soccer:
            return "soccer"
        case .softball:
            return "softball"
        case .squash:
            return "squash"
        case .stairClimbing:
            return "stairClimbing"
        case .surfingSports:
            return "surfingSports"
        case .swimming:
            return "swimming"
        case .tableTennis:
            return "tableTennis"
        case .tennis:
            return "tennis"
        case .trackAndField:
            return "trackAndField"
        case .traditionalStrengthTraining:
            return "traditionalStrengthTraining"
        case .volleyball:
            return "volleyball"
        case .walking:
            return "walking"
        case .waterFitness:
            return "waterFitness"
        case .waterPolo:
            return "waterPolo"
        case .waterSports:
            return "waterSports"
        case .wrestling:
            return "wrestling"
        case .yoga:
            return "yoga"
        case .barre:
            return "barre"
        case .coreTraining:
            return "coreTraining"
        case .crossCountrySkiing:
            return "crossCountrySkiing"
        case .downhillSkiing:
            return "downhillSkiing"
        case .flexibility:
            return "flexibility"
        case .highIntensityIntervalTraining:
            return "highIntensityIntervalTraining"
        case .jumpRope:
            return "jumpRope"
        case .kickboxing:
            return "kickboxing"
        case .pilates:
            return "pilates"
        case .snowboarding:
            return "snowboarding"
        case .stairs:
            return "stairs"
        case .stepTraining:
            return "stepTraining"
        case .wheelchairWalkPace:
            return "wheelchairWalkPace"
        case .wheelchairRunPace:
            return "wheelchairRunPace"
        case .taiChi:
            return "taiChi"
        case .mixedCardio:
            return "mixedCardio"
        case .handCycling:
            return "handCycling"
        default:
            return "other"
        }
    }
}
