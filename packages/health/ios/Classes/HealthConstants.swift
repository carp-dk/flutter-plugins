import HealthKit

/// Constants used across the Health plugin
enum HealthConstants {
    // Recording methods
    enum RecordingMethod: Int {
        case unknown = 0           // RECORDING_METHOD_UNKNOWN (not supported on iOS)
        case active = 1            // RECORDING_METHOD_ACTIVELY_RECORDED (not supported on iOS)
        case automatic = 2         // RECORDING_METHOD_AUTOMATICALLY_RECORDED
        case manual = 3            // RECORDING_METHOD_MANUAL_ENTRY
    }
    
    // Health Data Type Keys
    static let ACTIVE_ENERGY_BURNED = "ACTIVE_ENERGY_BURNED"
    static let ATRIAL_FIBRILLATION_BURDEN = "ATRIAL_FIBRILLATION_BURDEN"
    static let AUDIOGRAM = "AUDIOGRAM"
    static let APPLE_STAND_HOUR = "APPLE_STAND_HOUR"
    static let APPLE_MOVE_TIME = "APPLE_MOVE_TIME"
    static let APPLE_STAND_TIME = "APPLE_STAND_TIME"
    static let BASAL_ENERGY_BURNED = "BASAL_ENERGY_BURNED"
    static let BLOOD_GLUCOSE = "BLOOD_GLUCOSE"
    static let BLOOD_OXYGEN = "BLOOD_OXYGEN"
    static let BLOOD_PRESSURE_DIASTOLIC = "BLOOD_PRESSURE_DIASTOLIC"
    static let BLOOD_PRESSURE_SYSTOLIC = "BLOOD_PRESSURE_SYSTOLIC"
    static let BODY_FAT_PERCENTAGE = "BODY_FAT_PERCENTAGE"
    static let LEAN_BODY_MASS = "LEAN_BODY_MASS"
    static let BODY_MASS_INDEX = "BODY_MASS_INDEX"
    static let BODY_TEMPERATURE = "BODY_TEMPERATURE"
    
    // Nutrition
    static let DIETARY_CARBS_CONSUMED = "DIETARY_CARBS_CONSUMED"
    static let DIETARY_ENERGY_CONSUMED = "DIETARY_ENERGY_CONSUMED"
    static let DIETARY_FATS_CONSUMED = "DIETARY_FATS_CONSUMED"
    static let DIETARY_PROTEIN_CONSUMED = "DIETARY_PROTEIN_CONSUMED"
    static let DIETARY_CAFFEINE = "DIETARY_CAFFEINE"
    static let DIETARY_FIBER = "DIETARY_FIBER"
    static let DIETARY_SUGAR = "DIETARY_SUGAR"
    static let DIETARY_FAT_MONOUNSATURATED = "DIETARY_FAT_MONOUNSATURATED"
    static let DIETARY_FAT_POLYUNSATURATED = "DIETARY_FAT_POLYUNSATURATED"
    static let DIETARY_FAT_SATURATED = "DIETARY_FAT_SATURATED"
    static let DIETARY_CHOLESTEROL = "DIETARY_CHOLESTEROL"
    static let DIETARY_VITAMIN_A = "DIETARY_VITAMIN_A"
    static let DIETARY_THIAMIN = "DIETARY_THIAMIN"
    static let DIETARY_RIBOFLAVIN = "DIETARY_RIBOFLAVIN"
    static let DIETARY_NIACIN = "DIETARY_NIACIN"
    static let DIETARY_PANTOTHENIC_ACID = "DIETARY_PANTOTHENIC_ACID"
    static let DIETARY_VITAMIN_B6 = "DIETARY_VITAMIN_B6"
    static let DIETARY_BIOTIN = "DIETARY_BIOTIN"
    static let DIETARY_VITAMIN_B12 = "DIETARY_VITAMIN_B12"
    static let DIETARY_VITAMIN_C = "DIETARY_VITAMIN_C"
    static let DIETARY_VITAMIN_D = "DIETARY_VITAMIN_D"
    static let DIETARY_VITAMIN_E = "DIETARY_VITAMIN_E"
    static let DIETARY_VITAMIN_K = "DIETARY_VITAMIN_K"
    static let DIETARY_FOLATE = "DIETARY_FOLATE"
    static let DIETARY_CALCIUM = "DIETARY_CALCIUM"
    static let DIETARY_CHLORIDE = "DIETARY_CHLORIDE"
    static let DIETARY_IRON = "DIETARY_IRON"
    static let DIETARY_MAGNESIUM = "DIETARY_MAGNESIUM"
    static let DIETARY_PHOSPHORUS = "DIETARY_PHOSPHORUS"
    static let DIETARY_POTASSIUM = "DIETARY_POTASSIUM"
    static let DIETARY_SODIUM = "DIETARY_SODIUM"
    static let DIETARY_ZINC = "DIETARY_ZINC"
    static let DIETARY_WATER = "WATER"
    static let DIETARY_CHROMIUM = "DIETARY_CHROMIUM"
    static let DIETARY_COPPER = "DIETARY_COPPER"
    static let DIETARY_IODINE = "DIETARY_IODINE"
    static let DIETARY_MANGANESE = "DIETARY_MANGANESE"
    static let DIETARY_MOLYBDENUM = "DIETARY_MOLYBDENUM"
    static let DIETARY_SELENIUM = "DIETARY_SELENIUM"
    
    static let NUTRITION_KEYS: [String: HKQuantityTypeIdentifier] = [
        "calories": .dietaryEnergyConsumed,
        "protein": .dietaryProtein,
        "carbs": .dietaryCarbohydrates,
        "fat": .dietaryFatTotal,
        "caffeine": .dietaryCaffeine,
        "vitamin_a": .dietaryVitaminA,
        "b1_thiamine": .dietaryThiamin,
        "b2_riboflavin": .dietaryRiboflavin,
        "b3_niacin" : .dietaryNiacin,
        "b5_pantothenic_acid" : .dietaryPantothenicAcid,
        "b6_pyridoxine" : .dietaryVitaminB6,
        "b7_biotin" : .dietaryBiotin,
        "b9_folate" : .dietaryFolate,
        "b12_cobalamin": .dietaryVitaminB12,
        "vitamin_c": .dietaryVitaminC,
        "vitamin_d": .dietaryVitaminD,
        "vitamin_e": .dietaryVitaminE,
        "vitamin_k": .dietaryVitaminK,
        "calcium": .dietaryCalcium,
        "chloride": .dietaryChloride,
        "cholesterol": .dietaryCholesterol,
        "chromium": .dietaryChromium,
        "copper": .dietaryCopper,
        "fat_unsaturated": .dietaryFatMonounsaturated,
        "fat_monounsaturated": .dietaryFatMonounsaturated,
        "fat_polyunsaturated": .dietaryFatPolyunsaturated,
        "fat_saturated": .dietaryFatSaturated,
        // "fat_trans_monoenoic": .dietaryFatTransMonoenoic,
        "fiber": .dietaryFiber,
        "iodine": .dietaryIodine,
        "iron": .dietaryIron,
        "magnesium": .dietaryMagnesium,
        "manganese": .dietaryManganese,
        "molybdenum": .dietaryMolybdenum,
        "phosphorus": .dietaryPhosphorus,
        "potassium": .dietaryPotassium,
        "selenium": .dietarySelenium,
        "sodium": .dietarySodium,
        "sugar": .dietarySugar,
        "water": .dietaryWater,
        "zinc": .dietaryZinc,
    ]
    
    static let ELECTRODERMAL_ACTIVITY = "ELECTRODERMAL_ACTIVITY"
    static let FORCED_EXPIRATORY_VOLUME = "FORCED_EXPIRATORY_VOLUME"
    static let HEART_RATE = "HEART_RATE"
    static let HEART_RATE_VARIABILITY_SDNN = "HEART_RATE_VARIABILITY_SDNN"
    static let HEIGHT = "HEIGHT"
    static let INSULIN_DELIVERY = "INSULIN_DELIVERY"
    static let HIGH_HEART_RATE_EVENT = "HIGH_HEART_RATE_EVENT"
    static let IRREGULAR_HEART_RATE_EVENT = "IRREGULAR_HEART_RATE_EVENT"
    static let LOW_HEART_RATE_EVENT = "LOW_HEART_RATE_EVENT"
    static let RESTING_HEART_RATE = "RESTING_HEART_RATE"
    static let RESPIRATORY_RATE = "RESPIRATORY_RATE"
    static let PERIPHERAL_PERFUSION_INDEX = "PERIPHERAL_PERFUSION_INDEX"
    static let STEPS = "STEPS"
    static let WAIST_CIRCUMFERENCE = "WAIST_CIRCUMFERENCE"
    static let WALKING_HEART_RATE = "WALKING_HEART_RATE"
    static let WEIGHT = "WEIGHT"
    static let DISTANCE_WALKING_RUNNING = "DISTANCE_WALKING_RUNNING"
    static let DISTANCE_SWIMMING = "DISTANCE_SWIMMING"
    static let DISTANCE_CYCLING = "DISTANCE_CYCLING"
    static let WALKING_SPEED = "WALKING_SPEED"
    static let FLIGHTS_CLIMBED = "FLIGHTS_CLIMBED"
    static let MINDFULNESS = "MINDFULNESS"
    static let SLEEP_ASLEEP = "SLEEP_ASLEEP"
    static let SLEEP_AWAKE = "SLEEP_AWAKE"
    static let SLEEP_DEEP = "SLEEP_DEEP"
    static let SLEEP_IN_BED = "SLEEP_IN_BED"
    static let SLEEP_LIGHT = "SLEEP_LIGHT"
    static let SLEEP_REM = "SLEEP_REM"
    
    static let EXERCISE_TIME = "EXERCISE_TIME"
    static let WORKOUT = "WORKOUT"
    static let HEADACHE_UNSPECIFIED = "HEADACHE_UNSPECIFIED"
    static let HEADACHE_NOT_PRESENT = "HEADACHE_NOT_PRESENT"
    static let HEADACHE_MILD = "HEADACHE_MILD"
    static let HEADACHE_MODERATE = "HEADACHE_MODERATE"
    static let HEADACHE_SEVERE = "HEADACHE_SEVERE"
    static let ELECTROCARDIOGRAM = "ELECTROCARDIOGRAM"
    static let NUTRITION = "NUTRITION"
    static let BIRTH_DATE = "BIRTH_DATE"
    static let GENDER = "GENDER"
    static let BLOOD_TYPE = "BLOOD_TYPE"
    static let MENSTRUATION_FLOW = "MENSTRUATION_FLOW"
    static let WATER_TEMPERATURE = "WATER_TEMPERATURE"
    static let UNDERWATER_DEPTH = "UNDERWATER_DEPTH"
    static let UV_INDEX = "UV_INDEX"
    
    // Health Unit types
    static let GRAM = "GRAM"
    static let KILOGRAM = "KILOGRAM"
    static let OUNCE = "OUNCE"
    static let POUND = "POUND"
    static let STONE = "STONE"
    static let METER = "METER"
    static let INCH = "INCH"
    static let FOOT = "FOOT"
    static let YARD = "YARD"
    static let MILE = "MILE"
    static let LITER = "LITER"
    static let MILLILITER = "MILLILITER"
    static let FLUID_OUNCE_US = "FLUID_OUNCE_US"
    static let FLUID_OUNCE_IMPERIAL = "FLUID_OUNCE_IMPERIAL"
    static let CUP_US = "CUP_US"
    static let CUP_IMPERIAL = "CUP_IMPERIAL"
    static let PINT_US = "PINT_US"
    static let PINT_IMPERIAL = "PINT_IMPERIAL"
    static let PASCAL = "PASCAL"
    static let MILLIMETER_OF_MERCURY = "MILLIMETER_OF_MERCURY"
    static let INCHES_OF_MERCURY = "INCHES_OF_MERCURY"
    static let CENTIMETER_OF_WATER = "CENTIMETER_OF_WATER"
    static let ATMOSPHERE = "ATMOSPHERE"
    static let DECIBEL_A_WEIGHTED_SOUND_PRESSURE_LEVEL = "DECIBEL_A_WEIGHTED_SOUND_PRESSURE_LEVEL"
    static let SECOND = "SECOND"
    static let MILLISECOND = "MILLISECOND"
    static let MINUTE = "MINUTE"
    static let HOUR = "HOUR"
    static let DAY = "DAY"
    static let JOULE = "JOULE"
    static let KILOCALORIE = "KILOCALORIE"
    static let LARGE_CALORIE = "LARGE_CALORIE"
    static let SMALL_CALORIE = "SMALL_CALORIE"
    static let DEGREE_CELSIUS = "DEGREE_CELSIUS"
    static let DEGREE_FAHRENHEIT = "DEGREE_FAHRENHEIT"
    static let KELVIN = "KELVIN"
    static let DECIBEL_HEARING_LEVEL = "DECIBEL_HEARING_LEVEL"
    static let HERTZ = "HERTZ"
    static let SIEMEN = "SIEMEN"
    static let VOLT = "VOLT"
    static let INTERNATIONAL_UNIT = "INTERNATIONAL_UNIT"
    static let COUNT = "COUNT"
    static let PERCENT = "PERCENT"
    static let BEATS_PER_MINUTE = "BEATS_PER_MINUTE"
    static let RESPIRATIONS_PER_MINUTE = "RESPIRATIONS_PER_MINUTE"
    static let MILLIGRAM_PER_DECILITER = "MILLIGRAM_PER_DECILITER"
    static let METER_PER_SECOND = "METER_PER_SECOND"
    static let UNKNOWN_UNIT = "UNKNOWN_UNIT"
    static let NO_UNIT = "NO_UNIT"
}

/// Error structure used throughout the plugin
struct PluginError: Error {
    let message: String
}
