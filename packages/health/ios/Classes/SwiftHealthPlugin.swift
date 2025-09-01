import Flutter
import HealthKit
import UIKit

/// Main plugin class that coordinates health data operations
public class SwiftHealthPlugin: NSObject, FlutterPlugin {
    
    // Health store and type dictionaries
    let healthStore = HKHealthStore()
    var healthDataTypes = [HKSampleType]()
    var healthDataQuantityTypes = [HKQuantityType]()
    var characteristicsDataTypes = [HKCharacteristicType]()
    var heartRateEventTypes = Set<HKSampleType>()
    var headacheType = Set<HKSampleType>()
    var allDataTypes = Set<HKSampleType>()
    var dataTypesDict: [String: HKSampleType] = [:]
    var dataQuantityTypesDict: [String: HKQuantityType] = [:]
    var unitDict: [String: HKUnit] = [:]
    var workoutActivityTypeMap: [String: HKWorkoutActivityType] = [:]
    var characteristicsTypesDict: [String: HKCharacteristicType] = [:]
    var nutritionList: [String] = []
    
    // Service classes
    private lazy var healthDataReader: HealthDataReader = {
        return HealthDataReader(
            healthStore: healthStore,
            dataTypesDict: dataTypesDict,
            dataQuantityTypesDict: dataQuantityTypesDict,
            unitDict: unitDict,
            workoutActivityTypeMap: workoutActivityTypeMap,
            characteristicsTypesDict: characteristicsTypesDict
        )
    }()
    
    private lazy var healthDataWriter: HealthDataWriter = {
        return HealthDataWriter(
            healthStore: healthStore,
            dataTypesDict: dataTypesDict,
            unitDict: unitDict,
            workoutActivityTypeMap: workoutActivityTypeMap
        )
    }()
    
    private lazy var healthDataOperations: HealthDataOperations = {
        return HealthDataOperations(
            healthStore: healthStore,
            dataTypesDict: dataTypesDict,
            characteristicsTypesDict: characteristicsTypesDict,
            nutritionList: nutritionList
        )
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_health", binaryMessenger: registrar.messenger())
        let instance = SwiftHealthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        initializeTypes()
        
        switch call.method {
        case "checkIfHealthDataAvailable":
            healthDataOperations.checkIfHealthDataAvailable(call: call, result: result)
            
        case "requestAuthorization":
            do {
                try healthDataOperations.requestAuthorization(call: call, result: result)
            } catch {
                result(FlutterError(code: "REQUEST_AUTH_ERROR",
                                    message: "Error requesting authorization: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "getData":
            healthDataReader.getData(call: call, result: result)
            
        case "getIntervalData":
            healthDataReader.getIntervalData(call: call, result: result)
            
        case "getTotalStepsInInterval":
            healthDataReader.getTotalStepsInInterval(call: call, result: result)
            
        case "writeData":
            do {
                try healthDataWriter.writeData(call: call, result: result)
            } catch {
                result(FlutterError(code: "WRITE_ERROR",
                                    message: "Error writing data: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "writeAudiogram":
            do {
                try healthDataWriter.writeAudiogram(call: call, result: result)
            } catch {
                result(FlutterError(code: "WRITE_ERROR",
                                    message: "Error writing audiogram: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "writeBloodPressure":
            do {
                try healthDataWriter.writeBloodPressure(call: call, result: result)
            } catch {
                result(FlutterError(code: "WRITE_ERROR",
                                    message: "Error writing blood pressure: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "writeMeal":
            do {
                try healthDataWriter.writeMeal(call: call, result: result)
            } catch {
                result(FlutterError(code: "WRITE_ERROR",
                                    message: "Error writing meal: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "writeInsulinDelivery":
            do {
                try healthDataWriter.writeInsulinDelivery(call: call, result: result)
            } catch {
                result(FlutterError(code: "WRITE_ERROR",
                                    message: "Error writing insulin delivery: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "writeWorkoutData":
            do {
                try healthDataWriter.writeWorkoutData(call: call, result: result)
            } catch {
                result(FlutterError(code: "WRITE_ERROR",
                                    message: "Error writing workout: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "writeMenstruationFlow":
            do {
                try healthDataWriter.writeMenstruationFlow(call: call, result: result)
            } catch {
                result(FlutterError(code: "WRITE_ERROR",
                                    message: "Error writing menstruation flow: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "hasPermissions":
            do {
                try healthDataOperations.hasPermissions(call: call, result: result)
            } catch {
                result(FlutterError(code: "PERMISSION_ERROR",
                                    message: "Error checking permissions: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "delete":
            do {
                healthDataOperations.delete(call: call, result: result)
            } catch {
                result(FlutterError(code: "DELETE_ERROR",
                                    message: "Error deleting data: \(error.localizedDescription)",
                                    details: nil))
            }
            
        case "deleteByUUID":
            do {
                try healthDataOperations.deleteByUUID(call: call, result: result)
            } catch {
                result(FlutterError(code: "DELETE_ERROR",
                                    message: "Error deleting data by UUID: \(error.localizedDescription)",
                                    details: nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Initialize all the health data types, unit dictionaries, and other required data structures
    func initializeTypes() {
        // init units
        unitDict[HealthConstants.GRAM] = HKUnit.gram()
        unitDict[HealthConstants.KILOGRAM] = HKUnit.gramUnit(with: .kilo)
        unitDict[HealthConstants.OUNCE] = HKUnit.ounce()
        unitDict[HealthConstants.POUND] = HKUnit.pound()
        unitDict[HealthConstants.STONE] = HKUnit.stone()
        unitDict[HealthConstants.METER] = HKUnit.meter()
        unitDict[HealthConstants.INCH] = HKUnit.inch()
        unitDict[HealthConstants.FOOT] = HKUnit.foot()
        unitDict[HealthConstants.YARD] = HKUnit.yard()
        unitDict[HealthConstants.MILE] = HKUnit.mile()
        unitDict[HealthConstants.LITER] = HKUnit.liter()
        unitDict[HealthConstants.MILLILITER] = HKUnit.literUnit(with: .milli)
        unitDict[HealthConstants.FLUID_OUNCE_US] = HKUnit.fluidOunceUS()
        unitDict[HealthConstants.FLUID_OUNCE_IMPERIAL] = HKUnit.fluidOunceImperial()
        unitDict[HealthConstants.CUP_US] = HKUnit.cupUS()
        unitDict[HealthConstants.CUP_IMPERIAL] = HKUnit.cupImperial()
        unitDict[HealthConstants.PINT_US] = HKUnit.pintUS()
        unitDict[HealthConstants.PINT_IMPERIAL] = HKUnit.pintImperial()
        unitDict[HealthConstants.PASCAL] = HKUnit.pascal()
        unitDict[HealthConstants.MILLIMETER_OF_MERCURY] = HKUnit.millimeterOfMercury()
        unitDict[HealthConstants.CENTIMETER_OF_WATER] = HKUnit.centimeterOfWater()
        unitDict[HealthConstants.ATMOSPHERE] = HKUnit.atmosphere()
        unitDict[HealthConstants.DECIBEL_A_WEIGHTED_SOUND_PRESSURE_LEVEL] = HKUnit.decibelAWeightedSoundPressureLevel()
        unitDict[HealthConstants.SECOND] = HKUnit.second()
        unitDict[HealthConstants.MILLISECOND] = HKUnit.secondUnit(with: .milli)
        unitDict[HealthConstants.MINUTE] = HKUnit.minute()
        unitDict[HealthConstants.HOUR] = HKUnit.hour()
        unitDict[HealthConstants.DAY] = HKUnit.day()
        unitDict[HealthConstants.JOULE] = HKUnit.joule()
        unitDict[HealthConstants.KILOCALORIE] = HKUnit.kilocalorie()
        unitDict[HealthConstants.LARGE_CALORIE] = HKUnit.largeCalorie()
        unitDict[HealthConstants.SMALL_CALORIE] = HKUnit.smallCalorie()
        unitDict[HealthConstants.DEGREE_CELSIUS] = HKUnit.degreeCelsius()
        unitDict[HealthConstants.DEGREE_FAHRENHEIT] = HKUnit.degreeFahrenheit()
        unitDict[HealthConstants.KELVIN] = HKUnit.kelvin()
        unitDict[HealthConstants.DECIBEL_HEARING_LEVEL] = HKUnit.decibelHearingLevel()
        unitDict[HealthConstants.HERTZ] = HKUnit.hertz()
        unitDict[HealthConstants.SIEMEN] = HKUnit.siemen()
        unitDict[HealthConstants.INTERNATIONAL_UNIT] = HKUnit.internationalUnit()
        unitDict[HealthConstants.COUNT] = HKUnit.count()
        unitDict[HealthConstants.PERCENT] = HKUnit.percent()
        unitDict[HealthConstants.BEATS_PER_MINUTE] = HKUnit.init(from: "count/min")
        unitDict[HealthConstants.RESPIRATIONS_PER_MINUTE] = HKUnit.init(from: "count/min")
        unitDict[HealthConstants.MILLIGRAM_PER_DECILITER] = HKUnit.init(from: "mg/dL")
        unitDict[HealthConstants.METER_PER_SECOND] = HKUnit.init(from: "m/s")
        unitDict[HealthConstants.UNKNOWN_UNIT] = HKUnit.init(from: "")
        unitDict[HealthConstants.NO_UNIT] = HKUnit.init(from: "")
        
        // init workout activity types
        initializeWorkoutTypes()
        
        nutritionList = [
            HealthConstants.DIETARY_ENERGY_CONSUMED,
            HealthConstants.DIETARY_CARBS_CONSUMED,
            HealthConstants.DIETARY_PROTEIN_CONSUMED,
            HealthConstants.DIETARY_FATS_CONSUMED,
            HealthConstants.DIETARY_CAFFEINE,
            HealthConstants.DIETARY_FIBER,
            HealthConstants.DIETARY_SUGAR,
            HealthConstants.DIETARY_FAT_MONOUNSATURATED,
            HealthConstants.DIETARY_FAT_POLYUNSATURATED,
            HealthConstants.DIETARY_FAT_SATURATED,
            HealthConstants.DIETARY_CHOLESTEROL,
            HealthConstants.DIETARY_VITAMIN_A,
            HealthConstants.DIETARY_THIAMIN,
            HealthConstants.DIETARY_RIBOFLAVIN,
            HealthConstants.DIETARY_NIACIN,
            HealthConstants.DIETARY_PANTOTHENIC_ACID,
            HealthConstants.DIETARY_VITAMIN_B6,
            HealthConstants.DIETARY_BIOTIN,
            HealthConstants.DIETARY_VITAMIN_B12,
            HealthConstants.DIETARY_VITAMIN_C,
            HealthConstants.DIETARY_VITAMIN_D,
            HealthConstants.DIETARY_VITAMIN_E,
            HealthConstants.DIETARY_VITAMIN_K,
            HealthConstants.DIETARY_FOLATE,
            HealthConstants.DIETARY_CALCIUM,
            HealthConstants.DIETARY_CHLORIDE,
            HealthConstants.DIETARY_IRON,
            HealthConstants.DIETARY_MAGNESIUM,
            HealthConstants.DIETARY_PHOSPHORUS,
            HealthConstants.DIETARY_POTASSIUM,
            HealthConstants.DIETARY_SODIUM,
            HealthConstants.DIETARY_ZINC,
            HealthConstants.DIETARY_WATER,
            HealthConstants.DIETARY_CHROMIUM,
            HealthConstants.DIETARY_COPPER,
            HealthConstants.DIETARY_IODINE,
            HealthConstants.DIETARY_MANGANESE,
            HealthConstants.DIETARY_MOLYBDENUM,
            HealthConstants.DIETARY_SELENIUM,
        ]
        
        // Set up iOS 11 specific types (ordinary health data quantity types)
        if #available(iOS 11.0, *) {
            initializeIOS11Types()
            healthDataQuantityTypes = Array(dataQuantityTypesDict.values)
        }
        
        // Set up heart rate data types specific to the apple watch, requires iOS 12
        if #available(iOS 12.2, *) {
            initializeIOS12Types()
        }
        
        // Set up iOS 13 specific types (ordinary health data types)
        if #available(iOS 13.0, *) {
            initializeIOS13Types()
            healthDataTypes = Array(dataTypesDict.values)
            characteristicsDataTypes = Array(characteristicsTypesDict.values)
        }
        
        if #available(iOS 13.6, *) {
            initializeIOS13_6Types()
        }
        
        if #available(iOS 14.0, *) {
            initializeIOS14Types()
        }
        
        if #available(iOS 16.0, *) {
            initializeIOS16Types()
        }
        
        // Concatenate heart events, headache and health data types (both may be empty)
        allDataTypes = Set(heartRateEventTypes + healthDataTypes)
        allDataTypes = allDataTypes.union(headacheType)
    }
    
    /// Initialize iOS 11 specific data types
    @available(iOS 11.0, *)
    private func initializeIOS11Types() {
        dataTypesDict[HealthConstants.APPLE_STAND_HOUR] = HKSampleType.categoryType(forIdentifier: .appleStandHour)!
        
        dataQuantityTypesDict[HealthConstants.ACTIVE_ENERGY_BURNED] = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        dataQuantityTypesDict[HealthConstants.BASAL_ENERGY_BURNED] = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
        dataQuantityTypesDict[HealthConstants.BLOOD_GLUCOSE] = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        dataQuantityTypesDict[HealthConstants.BLOOD_OXYGEN] = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
        dataQuantityTypesDict[HealthConstants.BLOOD_PRESSURE_DIASTOLIC] = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        dataQuantityTypesDict[HealthConstants.BLOOD_PRESSURE_SYSTOLIC] = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        dataQuantityTypesDict[HealthConstants.BODY_FAT_PERCENTAGE] = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        dataQuantityTypesDict[HealthConstants.LEAN_BODY_MASS] = HKSampleType.quantityType(forIdentifier: .leanBodyMass)!
        dataQuantityTypesDict[HealthConstants.BODY_MASS_INDEX] = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!
        dataQuantityTypesDict[HealthConstants.BODY_TEMPERATURE] = HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
        
        // Initialize nutrition quantity types
        initializeNutritionQuantityTypes()
        
        dataQuantityTypesDict[HealthConstants.ELECTRODERMAL_ACTIVITY] = HKQuantityType.quantityType(forIdentifier: .electrodermalActivity)!
        dataQuantityTypesDict[HealthConstants.FORCED_EXPIRATORY_VOLUME] = HKQuantityType.quantityType(forIdentifier: .forcedExpiratoryVolume1)!
        dataQuantityTypesDict[HealthConstants.HEART_RATE] = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        dataQuantityTypesDict[HealthConstants.HEART_RATE_VARIABILITY_SDNN] = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        dataQuantityTypesDict[HealthConstants.HEIGHT] = HKQuantityType.quantityType(forIdentifier: .height)!
        dataQuantityTypesDict[HealthConstants.RESTING_HEART_RATE] = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        dataQuantityTypesDict[HealthConstants.STEPS] = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        dataQuantityTypesDict[HealthConstants.WAIST_CIRCUMFERENCE] = HKQuantityType.quantityType(forIdentifier: .waistCircumference)!
        dataQuantityTypesDict[HealthConstants.WALKING_HEART_RATE] = HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage)!
        dataQuantityTypesDict[HealthConstants.WEIGHT] = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        dataQuantityTypesDict[HealthConstants.DISTANCE_WALKING_RUNNING] = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        dataQuantityTypesDict[HealthConstants.DISTANCE_SWIMMING] = HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!
        dataQuantityTypesDict[HealthConstants.DISTANCE_CYCLING] = HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
        dataQuantityTypesDict[HealthConstants.FLIGHTS_CLIMBED] = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
    }
    
    /// Initialize nutrition quantity types
    @available(iOS 11.0, *)
    private func initializeNutritionQuantityTypes() {
        dataQuantityTypesDict[HealthConstants.DIETARY_CARBS_CONSUMED] = HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates)!
        dataQuantityTypesDict[HealthConstants.DIETARY_CAFFEINE] = HKSampleType.quantityType(forIdentifier: .dietaryCaffeine)!
        dataQuantityTypesDict[HealthConstants.DIETARY_ENERGY_CONSUMED] = HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        dataQuantityTypesDict[HealthConstants.DIETARY_FATS_CONSUMED] = HKSampleType.quantityType(forIdentifier: .dietaryFatTotal)!
        dataQuantityTypesDict[HealthConstants.DIETARY_PROTEIN_CONSUMED] = HKSampleType.quantityType(forIdentifier: .dietaryProtein)!
        dataQuantityTypesDict[HealthConstants.DIETARY_FIBER] = HKSampleType.quantityType(forIdentifier: .dietaryFiber)!
        dataQuantityTypesDict[HealthConstants.DIETARY_SUGAR] = HKSampleType.quantityType(forIdentifier: .dietarySugar)!
        dataQuantityTypesDict[HealthConstants.DIETARY_FAT_MONOUNSATURATED] = HKSampleType.quantityType(forIdentifier: .dietaryFatMonounsaturated)!
        dataQuantityTypesDict[HealthConstants.DIETARY_FAT_POLYUNSATURATED] = HKSampleType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)!
        dataQuantityTypesDict[HealthConstants.DIETARY_FAT_SATURATED] = HKSampleType.quantityType(forIdentifier: .dietaryFatSaturated)!
        dataQuantityTypesDict[HealthConstants.DIETARY_CHOLESTEROL] = HKSampleType.quantityType(forIdentifier: .dietaryCholesterol)!
        dataQuantityTypesDict[HealthConstants.DIETARY_VITAMIN_A] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminA)!
        dataQuantityTypesDict[HealthConstants.DIETARY_THIAMIN] = HKSampleType.quantityType(forIdentifier: .dietaryThiamin)!
        dataQuantityTypesDict[HealthConstants.DIETARY_RIBOFLAVIN] = HKSampleType.quantityType(forIdentifier: .dietaryRiboflavin)!
        dataQuantityTypesDict[HealthConstants.DIETARY_NIACIN] = HKSampleType.quantityType(forIdentifier: .dietaryNiacin)!
        dataQuantityTypesDict[HealthConstants.DIETARY_PANTOTHENIC_ACID] = HKSampleType.quantityType(forIdentifier: .dietaryPantothenicAcid)!
        dataQuantityTypesDict[HealthConstants.DIETARY_VITAMIN_B6] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminB6)!
        dataQuantityTypesDict[HealthConstants.DIETARY_BIOTIN] = HKSampleType.quantityType(forIdentifier: .dietaryBiotin)!
        dataQuantityTypesDict[HealthConstants.DIETARY_VITAMIN_B12] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminB12)!
        dataQuantityTypesDict[HealthConstants.DIETARY_VITAMIN_C] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminC)!
        dataQuantityTypesDict[HealthConstants.DIETARY_VITAMIN_D] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminD)!
        dataQuantityTypesDict[HealthConstants.DIETARY_VITAMIN_E] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminE)!
        dataQuantityTypesDict[HealthConstants.DIETARY_VITAMIN_K] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminK)!
        dataQuantityTypesDict[HealthConstants.DIETARY_FOLATE] = HKSampleType.quantityType(forIdentifier: .dietaryFolate)!
        dataQuantityTypesDict[HealthConstants.DIETARY_CALCIUM] = HKSampleType.quantityType(forIdentifier: .dietaryCalcium)!
        dataQuantityTypesDict[HealthConstants.DIETARY_CHLORIDE] = HKSampleType.quantityType(forIdentifier: .dietaryChloride)!
        dataQuantityTypesDict[HealthConstants.DIETARY_IRON] = HKSampleType.quantityType(forIdentifier: .dietaryIron)!
        dataQuantityTypesDict[HealthConstants.DIETARY_MAGNESIUM] = HKSampleType.quantityType(forIdentifier: .dietaryMagnesium)!
        dataQuantityTypesDict[HealthConstants.DIETARY_PHOSPHORUS] = HKSampleType.quantityType(forIdentifier: .dietaryPhosphorus)!
        dataQuantityTypesDict[HealthConstants.DIETARY_POTASSIUM] = HKSampleType.quantityType(forIdentifier: .dietaryPotassium)!
        dataQuantityTypesDict[HealthConstants.DIETARY_SODIUM] = HKSampleType.quantityType(forIdentifier: .dietarySodium)!
        dataQuantityTypesDict[HealthConstants.DIETARY_ZINC] = HKSampleType.quantityType(forIdentifier: .dietaryZinc)!
        dataQuantityTypesDict[HealthConstants.DIETARY_WATER] = HKSampleType.quantityType(forIdentifier: .dietaryWater)!
        dataQuantityTypesDict[HealthConstants.DIETARY_CHROMIUM] = HKSampleType.quantityType(forIdentifier: .dietaryChromium)!
        dataQuantityTypesDict[HealthConstants.DIETARY_COPPER] = HKSampleType.quantityType(forIdentifier: .dietaryCopper)!
        dataQuantityTypesDict[HealthConstants.DIETARY_IODINE] = HKSampleType.quantityType(forIdentifier: .dietaryIodine)!
        dataQuantityTypesDict[HealthConstants.DIETARY_MANGANESE] = HKSampleType.quantityType(forIdentifier: .dietaryManganese)!
        dataQuantityTypesDict[HealthConstants.DIETARY_MOLYBDENUM] = HKSampleType.quantityType(forIdentifier: .dietaryMolybdenum)!
        dataQuantityTypesDict[HealthConstants.DIETARY_SELENIUM] = HKSampleType.quantityType(forIdentifier: .dietarySelenium)!
    }
    
    /// Initialize iOS 13 specific data types
    @available(iOS 13.0, *)
    private func initializeIOS13Types() {
        dataTypesDict[HealthConstants.ACTIVE_ENERGY_BURNED] = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
        dataTypesDict[HealthConstants.APPLE_STAND_TIME] = HKSampleType.quantityType(forIdentifier: .appleStandTime)!
        dataTypesDict[HealthConstants.AUDIOGRAM] = HKSampleType.audiogramSampleType()
        dataTypesDict[HealthConstants.BASAL_ENERGY_BURNED] = HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!
        dataTypesDict[HealthConstants.BLOOD_GLUCOSE] = HKSampleType.quantityType(forIdentifier: .bloodGlucose)!
        dataTypesDict[HealthConstants.BLOOD_OXYGEN] = HKSampleType.quantityType(forIdentifier: .oxygenSaturation)!
        dataTypesDict[HealthConstants.RESPIRATORY_RATE] = HKSampleType.quantityType(forIdentifier: .respiratoryRate)!
        dataTypesDict[HealthConstants.PERIPHERAL_PERFUSION_INDEX] = HKSampleType.quantityType(forIdentifier: .peripheralPerfusionIndex)!
        
        dataTypesDict[HealthConstants.BLOOD_PRESSURE_DIASTOLIC] = HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        dataTypesDict[HealthConstants.BLOOD_PRESSURE_SYSTOLIC] = HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic)!
        dataTypesDict[HealthConstants.BODY_FAT_PERCENTAGE] = HKSampleType.quantityType(forIdentifier: .bodyFatPercentage)!
        dataTypesDict[HealthConstants.LEAN_BODY_MASS] = HKSampleType.quantityType(forIdentifier: .leanBodyMass)!
        dataTypesDict[HealthConstants.BODY_MASS_INDEX] = HKSampleType.quantityType(forIdentifier: .bodyMassIndex)!
        dataTypesDict[HealthConstants.BODY_TEMPERATURE] = HKSampleType.quantityType(forIdentifier: .bodyTemperature)!
        
        // Initialize nutrition types
        initializeNutritionTypes()
        
        dataTypesDict[HealthConstants.ELECTRODERMAL_ACTIVITY] = HKSampleType.quantityType(forIdentifier: .electrodermalActivity)!
        dataTypesDict[HealthConstants.FORCED_EXPIRATORY_VOLUME] = HKSampleType.quantityType(forIdentifier: .forcedExpiratoryVolume1)!
        dataTypesDict[HealthConstants.HEART_RATE] = HKSampleType.quantityType(forIdentifier: .heartRate)!
        dataTypesDict[HealthConstants.HEART_RATE_VARIABILITY_SDNN] = HKSampleType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        dataTypesDict[HealthConstants.HEIGHT] = HKSampleType.quantityType(forIdentifier: .height)!
        dataTypesDict[HealthConstants.INSULIN_DELIVERY] = HKSampleType.quantityType(forIdentifier: .insulinDelivery)!
        dataTypesDict[HealthConstants.RESTING_HEART_RATE] = HKSampleType.quantityType(forIdentifier: .restingHeartRate)!
        dataTypesDict[HealthConstants.STEPS] = HKSampleType.quantityType(forIdentifier: .stepCount)!
        dataTypesDict[HealthConstants.WAIST_CIRCUMFERENCE] = HKSampleType.quantityType(forIdentifier: .waistCircumference)!
        dataTypesDict[HealthConstants.WALKING_HEART_RATE] = HKSampleType.quantityType(forIdentifier: .walkingHeartRateAverage)!
        dataTypesDict[HealthConstants.WEIGHT] = HKSampleType.quantityType(forIdentifier: .bodyMass)!
        dataTypesDict[HealthConstants.DISTANCE_WALKING_RUNNING] = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!
        dataTypesDict[HealthConstants.DISTANCE_SWIMMING] = HKSampleType.quantityType(forIdentifier: .distanceSwimming)!
        dataTypesDict[HealthConstants.DISTANCE_CYCLING] = HKSampleType.quantityType(forIdentifier: .distanceCycling)!
        dataTypesDict[HealthConstants.FLIGHTS_CLIMBED] = HKSampleType.quantityType(forIdentifier: .flightsClimbed)!
        dataTypesDict[HealthConstants.MINDFULNESS] = HKSampleType.categoryType(forIdentifier: .mindfulSession)!
        dataTypesDict[HealthConstants.SLEEP_AWAKE] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
        dataTypesDict[HealthConstants.SLEEP_DEEP] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
        dataTypesDict[HealthConstants.SLEEP_IN_BED] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
        dataTypesDict[HealthConstants.SLEEP_LIGHT] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
        dataTypesDict[HealthConstants.SLEEP_REM] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
        dataTypesDict[HealthConstants.SLEEP_ASLEEP] = HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
        dataTypesDict[HealthConstants.MENSTRUATION_FLOW] = HKSampleType.categoryType(forIdentifier: .menstrualFlow)!
        
        dataTypesDict[HealthConstants.EXERCISE_TIME] = HKSampleType.quantityType(forIdentifier: .appleExerciseTime)!
        dataTypesDict[HealthConstants.WORKOUT] = HKSampleType.workoutType()
        dataTypesDict[HealthConstants.NUTRITION] = HKSampleType.correlationType(forIdentifier: .food)!
        
        characteristicsTypesDict[HealthConstants.BIRTH_DATE] = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
        characteristicsTypesDict[HealthConstants.GENDER] = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
        characteristicsTypesDict[HealthConstants.BLOOD_TYPE] = HKObjectType.characteristicType(forIdentifier: .bloodType)!
    }
    
    /// Initialize nutrition types for iOS 13+
    @available(iOS 13.0, *)
    private func initializeNutritionTypes() {
        dataTypesDict[HealthConstants.DIETARY_CARBS_CONSUMED] = HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates)!
        dataTypesDict[HealthConstants.DIETARY_CAFFEINE] = HKSampleType.quantityType(forIdentifier: .dietaryCaffeine)!
        dataTypesDict[HealthConstants.DIETARY_ENERGY_CONSUMED] = HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        dataTypesDict[HealthConstants.DIETARY_FATS_CONSUMED] = HKSampleType.quantityType(forIdentifier: .dietaryFatTotal)!
        dataTypesDict[HealthConstants.DIETARY_PROTEIN_CONSUMED] = HKSampleType.quantityType(forIdentifier: .dietaryProtein)!
        dataTypesDict[HealthConstants.DIETARY_FIBER] = HKSampleType.quantityType(forIdentifier: .dietaryFiber)!
        dataTypesDict[HealthConstants.DIETARY_SUGAR] = HKSampleType.quantityType(forIdentifier: .dietarySugar)!
        dataTypesDict[HealthConstants.DIETARY_FAT_MONOUNSATURATED] = HKSampleType.quantityType(forIdentifier: .dietaryFatMonounsaturated)!
        dataTypesDict[HealthConstants.DIETARY_FAT_POLYUNSATURATED] = HKSampleType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)!
        dataTypesDict[HealthConstants.DIETARY_FAT_SATURATED] = HKSampleType.quantityType(forIdentifier: .dietaryFatSaturated)!
        dataTypesDict[HealthConstants.DIETARY_CHOLESTEROL] = HKSampleType.quantityType(forIdentifier: .dietaryCholesterol)!
        dataTypesDict[HealthConstants.DIETARY_VITAMIN_A] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminA)!
        dataTypesDict[HealthConstants.DIETARY_THIAMIN] = HKSampleType.quantityType(forIdentifier: .dietaryThiamin)!
        dataTypesDict[HealthConstants.DIETARY_RIBOFLAVIN] = HKSampleType.quantityType(forIdentifier: .dietaryRiboflavin)!
        dataTypesDict[HealthConstants.DIETARY_NIACIN] = HKSampleType.quantityType(forIdentifier: .dietaryNiacin)!
        dataTypesDict[HealthConstants.DIETARY_PANTOTHENIC_ACID] = HKSampleType.quantityType(forIdentifier: .dietaryPantothenicAcid)!
        dataTypesDict[HealthConstants.DIETARY_VITAMIN_B6] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminB6)!
        dataTypesDict[HealthConstants.DIETARY_BIOTIN] = HKSampleType.quantityType(forIdentifier: .dietaryBiotin)!
        dataTypesDict[HealthConstants.DIETARY_VITAMIN_B12] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminB12)!
        dataTypesDict[HealthConstants.DIETARY_VITAMIN_C] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminC)!
        dataTypesDict[HealthConstants.DIETARY_VITAMIN_D] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminD)!
        dataTypesDict[HealthConstants.DIETARY_VITAMIN_E] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminE)!
        dataTypesDict[HealthConstants.DIETARY_VITAMIN_K] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminK)!
        dataTypesDict[HealthConstants.DIETARY_FOLATE] = HKSampleType.quantityType(forIdentifier: .dietaryFolate)!
        dataTypesDict[HealthConstants.DIETARY_CALCIUM] = HKSampleType.quantityType(forIdentifier: .dietaryCalcium)!
        dataTypesDict[HealthConstants.DIETARY_CHLORIDE] = HKSampleType.quantityType(forIdentifier: .dietaryChloride)!
        dataTypesDict[HealthConstants.DIETARY_IRON] = HKSampleType.quantityType(forIdentifier: .dietaryIron)!
        dataTypesDict[HealthConstants.DIETARY_MAGNESIUM] = HKSampleType.quantityType(forIdentifier: .dietaryMagnesium)!
        dataTypesDict[HealthConstants.DIETARY_PHOSPHORUS] = HKSampleType.quantityType(forIdentifier: .dietaryPhosphorus)!
        dataTypesDict[HealthConstants.DIETARY_POTASSIUM] = HKSampleType.quantityType(forIdentifier: .dietaryPotassium)!
        dataTypesDict[HealthConstants.DIETARY_SODIUM] = HKSampleType.quantityType(forIdentifier: .dietarySodium)!
        dataTypesDict[HealthConstants.DIETARY_ZINC] = HKSampleType.quantityType(forIdentifier: .dietaryZinc)!
        dataTypesDict[HealthConstants.DIETARY_WATER] = HKSampleType.quantityType(forIdentifier: .dietaryWater)!
        dataTypesDict[HealthConstants.DIETARY_CHROMIUM] = HKSampleType.quantityType(forIdentifier: .dietaryChromium)!
        dataTypesDict[HealthConstants.DIETARY_COPPER] = HKSampleType.quantityType(forIdentifier: .dietaryCopper)!
        dataTypesDict[HealthConstants.DIETARY_IODINE] = HKSampleType.quantityType(forIdentifier: .dietaryIodine)!
        dataTypesDict[HealthConstants.DIETARY_MANGANESE] = HKSampleType.quantityType(forIdentifier: .dietaryManganese)!
        dataTypesDict[HealthConstants.DIETARY_MOLYBDENUM] = HKSampleType.quantityType(forIdentifier: .dietaryMolybdenum)!
        dataTypesDict[HealthConstants.DIETARY_SELENIUM] = HKSampleType.quantityType(forIdentifier: .dietarySelenium)!
    }
    
    /// Initialize iOS 12 specific data types
    @available(iOS 12.2, *)
    private func initializeIOS12Types() {
        dataTypesDict[HealthConstants.HIGH_HEART_RATE_EVENT] = HKSampleType.categoryType(forIdentifier: .highHeartRateEvent)!
        dataTypesDict[HealthConstants.LOW_HEART_RATE_EVENT] = HKSampleType.categoryType(forIdentifier: .lowHeartRateEvent)!
        dataTypesDict[HealthConstants.IRREGULAR_HEART_RATE_EVENT] = HKSampleType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!
        
        heartRateEventTypes = Set([
            HKSampleType.categoryType(forIdentifier: .highHeartRateEvent)!,
            HKSampleType.categoryType(forIdentifier: .lowHeartRateEvent)!,
            HKSampleType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!,
        ])
    }
    
    /// Initialize iOS 13.6 specific data types
    @available(iOS 13.6, *)
    private func initializeIOS13_6Types() {
        dataTypesDict[HealthConstants.HEADACHE_UNSPECIFIED] = HKSampleType.categoryType(forIdentifier: .headache)!
        dataTypesDict[HealthConstants.HEADACHE_NOT_PRESENT] = HKSampleType.categoryType(forIdentifier: .headache)!
        dataTypesDict[HealthConstants.HEADACHE_MILD] = HKSampleType.categoryType(forIdentifier: .headache)!
        dataTypesDict[HealthConstants.HEADACHE_MODERATE] = HKSampleType.categoryType(forIdentifier: .headache)!
        dataTypesDict[HealthConstants.HEADACHE_SEVERE] = HKSampleType.categoryType(forIdentifier: .headache)!
        
        headacheType = Set([
            HKSampleType.categoryType(forIdentifier: .headache)!
        ])
    }
    
    /// Initialize iOS 14 specific data types
    @available(iOS 14.0, *)
    private func initializeIOS14Types() {
        dataTypesDict[HealthConstants.ELECTROCARDIOGRAM] = HKSampleType.electrocardiogramType()
        dataTypesDict[HealthConstants.WALKING_SPEED] = HKSampleType.quantityType(forIdentifier: .walkingSpeed)
        
        unitDict[HealthConstants.VOLT] = HKUnit.volt()
        unitDict[HealthConstants.INCHES_OF_MERCURY] = HKUnit.inchesOfMercury()
        
        workoutActivityTypeMap["CARDIO_DANCE"] = HKWorkoutActivityType.cardioDance
        workoutActivityTypeMap["SOCIAL_DANCE"] = HKWorkoutActivityType.socialDance
        workoutActivityTypeMap["PICKLEBALL"] = HKWorkoutActivityType.pickleball
        workoutActivityTypeMap["COOLDOWN"] = HKWorkoutActivityType.cooldown
        
        if #available(iOS 14.5, *) {
            dataTypesDict[HealthConstants.APPLE_MOVE_TIME] = HKSampleType.quantityType(forIdentifier: .appleMoveTime)!
        }
    }
    
    /// Initialize iOS 16 specific data types
    @available(iOS 16.0, *)
    private func initializeIOS16Types() {
        dataTypesDict[HealthConstants.ATRIAL_FIBRILLATION_BURDEN] = HKQuantityType.quantityType(forIdentifier: .atrialFibrillationBurden)!
        dataTypesDict[HealthConstants.WATER_TEMPERATURE] = HKQuantityType.quantityType(forIdentifier: .waterTemperature)!
        dataTypesDict[HealthConstants.UNDERWATER_DEPTH] = HKQuantityType.quantityType(forIdentifier: .underwaterDepth)!
        dataTypesDict[HealthConstants.UV_INDEX] = HKSampleType.quantityType(forIdentifier: .uvExposure)!
        
        dataQuantityTypesDict[HealthConstants.UV_INDEX] = HKQuantityType.quantityType(forIdentifier: .uvExposure)!
    }
    
    /// Initialize workout activity types
    private func initializeWorkoutTypes() {
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
        workoutActivityTypeMap["PADDLE_SPORTS"] = .paddleSports
        workoutActivityTypeMap["ROWING"] = .rowing
        workoutActivityTypeMap["SAILING"] = .sailing
        workoutActivityTypeMap["SURFING"] = .surfingSports
        workoutActivityTypeMap["SWIMMING"] = .swimming
        workoutActivityTypeMap["SWIMMING_OPEN_WATER"] = .swimming
        workoutActivityTypeMap["SWIMMING_POOL"] = .swimming
        workoutActivityTypeMap["WATER_FITNESS"] = .waterFitness
        workoutActivityTypeMap["WATER_POLO"] = .waterPolo
        workoutActivityTypeMap["WATER_SPORTS"] = .waterSports
        workoutActivityTypeMap["BOXING"] = .boxing
        workoutActivityTypeMap["KICKBOXING"] = .kickboxing
        workoutActivityTypeMap["MARTIAL_ARTS"] = .martialArts
        workoutActivityTypeMap["TAI_CHI"] = .taiChi
        workoutActivityTypeMap["WRESTLING"] = .wrestling
        workoutActivityTypeMap["OTHER"] = .other
        if #available(iOS 17.0, *) {
            workoutActivityTypeMap["UNDERWATER_DIVING"] = .underwaterDiving
        }
    }
}
