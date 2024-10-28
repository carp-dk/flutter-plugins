package cachet.plugins.health

import android.Manifest
import android.app.Activity
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.*
import androidx.health.connect.client.records.MealType.MEAL_TYPE_BREAKFAST
import androidx.health.connect.client.records.MealType.MEAL_TYPE_DINNER
import androidx.health.connect.client.records.MealType.MEAL_TYPE_LUNCH
import androidx.health.connect.client.records.MealType.MEAL_TYPE_SNACK
import androidx.health.connect.client.records.MealType.MEAL_TYPE_UNKNOWN
import androidx.health.connect.client.request.AggregateGroupByDurationRequest
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.*
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.fitness.Fitness
import com.google.android.gms.fitness.FitnessActivities
import com.google.android.gms.fitness.FitnessOptions
import com.google.android.gms.fitness.data.*
import com.google.android.gms.fitness.request.DataDeleteRequest
import com.google.android.gms.fitness.request.DataReadRequest
import com.google.android.gms.fitness.request.SessionInsertRequest
import com.google.android.gms.fitness.request.SessionReadRequest
import com.google.android.gms.fitness.result.DataReadResponse
import com.google.android.gms.fitness.result.SessionReadResponse
import com.google.android.gms.tasks.OnFailureListener
import com.google.android.gms.tasks.OnSuccessListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.time.*
import java.time.temporal.ChronoUnit
import java.util.*
import java.util.concurrent.*
import kotlinx.coroutines.*

const val GOOGLE_FIT_PERMISSIONS_REQUEST_CODE = 1111
const val HEALTH_CONNECT_RESULT_CODE = 16969
const val CHANNEL_NAME = "flutter_health"
const val MMOLL_2_MGDL = 18.0 // 1 mmoll= 18 mgdl

// The minimum android level that can use Health Connect
const val MIN_SUPPORTED_SDK = Build.VERSION_CODES.O_MR1

class HealthPlugin(private var channel: MethodChannel? = null) :
    MethodCallHandler, ActivityResultListener, Result, ActivityAware, FlutterPlugin {
    private var mResult: Result? = null
    private var handler: Handler? = null
    private var activity: Activity? = null
    private var context: Context? = null
    private var threadPoolExecutor: ExecutorService? = null
    private var useHealthConnectIfAvailable: Boolean = false
    private var healthConnectRequestPermissionsLauncher: ActivityResultLauncher<Set<String>>? =
        null
    private var activityRecognitionPermissionLauncher: ActivityResultLauncher<Array<String>>? =
        null
    private lateinit var healthConnectClient: HealthConnectClient
    private lateinit var scope: CoroutineScope

    private var BODY_FAT_PERCENTAGE = "BODY_FAT_PERCENTAGE"
    private var HEIGHT = "HEIGHT"
    private var WEIGHT = "WEIGHT"
    private var STEPS = "STEPS"
    private var AGGREGATE_STEP_COUNT = "AGGREGATE_STEP_COUNT"
    private var ACTIVE_ENERGY_BURNED = "ACTIVE_ENERGY_BURNED"
    private var HEART_RATE = "HEART_RATE"
    private var BODY_TEMPERATURE = "BODY_TEMPERATURE"
    private var BODY_WATER_MASS = "BODY_WATER_MASS"
    private var BLOOD_PRESSURE_SYSTOLIC = "BLOOD_PRESSURE_SYSTOLIC"
    private var BLOOD_PRESSURE_DIASTOLIC = "BLOOD_PRESSURE_DIASTOLIC"
    private var BLOOD_OXYGEN = "BLOOD_OXYGEN"
    private var BLOOD_GLUCOSE = "BLOOD_GLUCOSE"
    private var MOVE_MINUTES = "MOVE_MINUTES"
    private var DISTANCE_DELTA = "DISTANCE_DELTA"
    private var WATER = "WATER"
    private var RESTING_HEART_RATE = "RESTING_HEART_RATE"
    private var BASAL_ENERGY_BURNED = "BASAL_ENERGY_BURNED"
    private var FLIGHTS_CLIMBED = "FLIGHTS_CLIMBED"
    private var RESPIRATORY_RATE = "RESPIRATORY_RATE"

    // TODO support unknown?
    private var SLEEP_ASLEEP = "SLEEP_ASLEEP"
    private var SLEEP_AWAKE = "SLEEP_AWAKE"
    private var SLEEP_IN_BED = "SLEEP_IN_BED"
    private var SLEEP_SESSION = "SLEEP_SESSION"
    private var SLEEP_LIGHT = "SLEEP_LIGHT"
    private var SLEEP_DEEP = "SLEEP_DEEP"
    private var SLEEP_REM = "SLEEP_REM"
    private var SLEEP_OUT_OF_BED = "SLEEP_OUT_OF_BED"
    private var WORKOUT = "WORKOUT"
    private var NUTRITION = "NUTRITION"
    private var BREAKFAST = "BREAKFAST"
    private var LUNCH = "LUNCH"
    private var DINNER = "DINNER"
    private var SNACK = "SNACK"
    private var MEAL_UNKNOWN = "UNKNOWN"

    private var TOTAL_CALORIES_BURNED = "TOTAL_CALORIES_BURNED"

    val workoutTypeMap =
        mapOf(
            "AEROBICS" to FitnessActivities.AEROBICS,
            "AMERICAN_FOOTBALL" to FitnessActivities.FOOTBALL_AMERICAN,
            "ARCHERY" to FitnessActivities.ARCHERY,
            "AUSTRALIAN_FOOTBALL" to
                    FitnessActivities.FOOTBALL_AUSTRALIAN,
            "BADMINTON" to FitnessActivities.BADMINTON,
            "BASEBALL" to FitnessActivities.BASEBALL,
            "BASKETBALL" to FitnessActivities.BASKETBALL,
            "BIATHLON" to FitnessActivities.BIATHLON,
            "BIKING" to FitnessActivities.BIKING,
            "BIKING_HAND" to FitnessActivities.BIKING_HAND,
            "BIKING_MOUNTAIN" to FitnessActivities.BIKING_MOUNTAIN,
            "BIKING_ROAD" to FitnessActivities.BIKING_ROAD,
            "BIKING_SPINNING" to FitnessActivities.BIKING_SPINNING,
            "BIKING_STATIONARY" to FitnessActivities.BIKING_STATIONARY,
            "BIKING_UTILITY" to FitnessActivities.BIKING_UTILITY,
            "BOXING" to FitnessActivities.BOXING,
            "CALISTHENICS" to FitnessActivities.CALISTHENICS,
            "CIRCUIT_TRAINING" to FitnessActivities.CIRCUIT_TRAINING,
            "CRICKET" to FitnessActivities.CRICKET,
            "CROSS_COUNTRY_SKIING" to
                    FitnessActivities.SKIING_CROSS_COUNTRY,
            "CROSS_FIT" to FitnessActivities.CROSSFIT,
            "CURLING" to FitnessActivities.CURLING,
            "DANCING" to FitnessActivities.DANCING,
            "DIVING" to FitnessActivities.DIVING,
            "DOWNHILL_SKIING" to FitnessActivities.SKIING_DOWNHILL,
            "ELEVATOR" to FitnessActivities.ELEVATOR,
            "ELLIPTICAL" to FitnessActivities.ELLIPTICAL,
            "ERGOMETER" to FitnessActivities.ERGOMETER,
            "ESCALATOR" to FitnessActivities.ESCALATOR,
            "FENCING" to FitnessActivities.FENCING,
            "FRISBEE_DISC" to FitnessActivities.FRISBEE_DISC,
            "GARDENING" to FitnessActivities.GARDENING,
            "GOLF" to FitnessActivities.GOLF,
            "GUIDED_BREATHING" to FitnessActivities.GUIDED_BREATHING,
            "GYMNASTICS" to FitnessActivities.GYMNASTICS,
            "HANDBALL" to FitnessActivities.HANDBALL,
            "HIGH_INTENSITY_INTERVAL_TRAINING" to
                    FitnessActivities
                        .HIGH_INTENSITY_INTERVAL_TRAINING,
            "HIKING" to FitnessActivities.HIKING,
            "HOCKEY" to FitnessActivities.HOCKEY,
            "HORSEBACK_RIDING" to FitnessActivities.HORSEBACK_RIDING,
            "HOUSEWORK" to FitnessActivities.HOUSEWORK,
            "IN_VEHICLE" to FitnessActivities.IN_VEHICLE,
            "ICE_SKATING" to FitnessActivities.ICE_SKATING,
            "INTERVAL_TRAINING" to FitnessActivities.INTERVAL_TRAINING,
            "JUMP_ROPE" to FitnessActivities.JUMP_ROPE,
            "KAYAKING" to FitnessActivities.KAYAKING,
            "KETTLEBELL_TRAINING" to
                    FitnessActivities.KETTLEBELL_TRAINING,
            "KICK_SCOOTER" to FitnessActivities.KICK_SCOOTER,
            "KICKBOXING" to FitnessActivities.KICKBOXING,
            "KITE_SURFING" to FitnessActivities.KITESURFING,
            "MARTIAL_ARTS" to FitnessActivities.MARTIAL_ARTS,
            "MEDITATION" to FitnessActivities.MEDITATION,
            "MIXED_MARTIAL_ARTS" to
                    FitnessActivities.MIXED_MARTIAL_ARTS,
            "P90X" to FitnessActivities.P90X,
            "PARAGLIDING" to FitnessActivities.PARAGLIDING,
            "PILATES" to FitnessActivities.PILATES,
            "POLO" to FitnessActivities.POLO,
            "RACQUETBALL" to FitnessActivities.RACQUETBALL,
            "ROCK_CLIMBING" to FitnessActivities.ROCK_CLIMBING,
            "ROWING" to FitnessActivities.ROWING,
            "ROWING_MACHINE" to FitnessActivities.ROWING_MACHINE,
            "RUGBY" to FitnessActivities.RUGBY,
            "RUNNING_JOGGING" to FitnessActivities.RUNNING_JOGGING,
            "RUNNING_SAND" to FitnessActivities.RUNNING_SAND,
            "RUNNING_TREADMILL" to FitnessActivities.RUNNING_TREADMILL,
            "RUNNING" to FitnessActivities.RUNNING,
            "SAILING" to FitnessActivities.SAILING,
            "SCUBA_DIVING" to FitnessActivities.SCUBA_DIVING,
            "SKATING_CROSS" to FitnessActivities.SKATING_CROSS,
            "SKATING_INDOOR" to FitnessActivities.SKATING_INDOOR,
            "SKATING_INLINE" to FitnessActivities.SKATING_INLINE,
            "SKATING" to FitnessActivities.SKATING,
            "SKIING" to FitnessActivities.SKIING,
            "SKIING_BACK_COUNTRY" to
                    FitnessActivities.SKIING_BACK_COUNTRY,
            "SKIING_KITE" to FitnessActivities.SKIING_KITE,
            "SKIING_ROLLER" to FitnessActivities.SKIING_ROLLER,
            "SLEDDING" to FitnessActivities.SLEDDING,
            "SNOWBOARDING" to FitnessActivities.SNOWBOARDING,
            "SNOWMOBILE" to FitnessActivities.SNOWMOBILE,
            "SNOWSHOEING" to FitnessActivities.SNOWSHOEING,
            "SOCCER" to FitnessActivities.FOOTBALL_SOCCER,
            "SOFTBALL" to FitnessActivities.SOFTBALL,
            "SQUASH" to FitnessActivities.SQUASH,
            "STAIR_CLIMBING_MACHINE" to
                    FitnessActivities.STAIR_CLIMBING_MACHINE,
            "STAIR_CLIMBING" to FitnessActivities.STAIR_CLIMBING,
            "STANDUP_PADDLEBOARDING" to
                    FitnessActivities.STANDUP_PADDLEBOARDING,
            "STILL" to FitnessActivities.STILL,
            "STRENGTH_TRAINING" to FitnessActivities.STRENGTH_TRAINING,
            "SURFING" to FitnessActivities.SURFING,
            "SWIMMING_OPEN_WATER" to
                    FitnessActivities.SWIMMING_OPEN_WATER,
            "SWIMMING_POOL" to FitnessActivities.SWIMMING_POOL,
            "SWIMMING" to FitnessActivities.SWIMMING,
            "TABLE_TENNIS" to FitnessActivities.TABLE_TENNIS,
            "TEAM_SPORTS" to FitnessActivities.TEAM_SPORTS,
            "TENNIS" to FitnessActivities.TENNIS,
            "TILTING" to FitnessActivities.TILTING,
            "VOLLEYBALL_BEACH" to FitnessActivities.VOLLEYBALL_BEACH,
            "VOLLEYBALL_INDOOR" to FitnessActivities.VOLLEYBALL_INDOOR,
            "VOLLEYBALL" to FitnessActivities.VOLLEYBALL,
            "WAKEBOARDING" to FitnessActivities.WAKEBOARDING,
            "WALKING_FITNESS" to FitnessActivities.WALKING_FITNESS,
            "WALKING_PACED" to FitnessActivities.WALKING_PACED,
            "WALKING_NORDIC" to FitnessActivities.WALKING_NORDIC,
            "WALKING_STROLLER" to FitnessActivities.WALKING_STROLLER,
            "WALKING_TREADMILL" to FitnessActivities.WALKING_TREADMILL,
            "WALKING" to FitnessActivities.WALKING,
            "WATER_POLO" to FitnessActivities.WATER_POLO,
            "WEIGHTLIFTING" to FitnessActivities.WEIGHTLIFTING,
            "WHEELCHAIR" to FitnessActivities.WHEELCHAIR,
            "WINDSURFING" to FitnessActivities.WINDSURFING,
            "YOGA" to FitnessActivities.YOGA,
            "ZUMBA" to FitnessActivities.ZUMBA,
            "OTHER" to FitnessActivities.OTHER,
        )

    // TODO: Update with new workout types when Health Connect becomes the standard.
    val workoutTypeMapHealthConnect =
        mapOf(
            // "AEROBICS" to
            // ExerciseSessionRecord.EXERCISE_TYPE_AEROBICS,
            "AMERICAN_FOOTBALL" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_FOOTBALL_AMERICAN,
            // "ARCHERY" to ExerciseSessionRecord.EXERCISE_TYPE_ARCHERY,
            "AUSTRALIAN_FOOTBALL" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_FOOTBALL_AUSTRALIAN,
            "BADMINTON" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_BADMINTON,
            "BASEBALL" to ExerciseSessionRecord.EXERCISE_TYPE_BASEBALL,
            "BASKETBALL" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_BASKETBALL,
            // "BIATHLON" to
            // ExerciseSessionRecord.EXERCISE_TYPE_BIATHLON,
            "BIKING" to ExerciseSessionRecord.EXERCISE_TYPE_BIKING,
            // "BIKING_HAND" to
            // ExerciseSessionRecord.EXERCISE_TYPE_BIKING_HAND,
            // "BIKING_MOUNTAIN" to
            // ExerciseSessionRecord.EXERCISE_TYPE_BIKING_MOUNTAIN,
            // "BIKING_ROAD" to
            // ExerciseSessionRecord.EXERCISE_TYPE_BIKING_ROAD,
            // "BIKING_SPINNING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_BIKING_SPINNING,
            // "BIKING_STATIONARY" to
            // ExerciseSessionRecord.EXERCISE_TYPE_BIKING_STATIONARY,
            // "BIKING_UTILITY" to
            // ExerciseSessionRecord.EXERCISE_TYPE_BIKING_UTILITY,
            "BOXING" to ExerciseSessionRecord.EXERCISE_TYPE_BOXING,
            "CALISTHENICS" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_CALISTHENICS,
            // "CIRCUIT_TRAINING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_CIRCUIT_TRAINING,
            "CRICKET" to ExerciseSessionRecord.EXERCISE_TYPE_CRICKET,
            // "CROSS_COUNTRY_SKIING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SKIING_CROSS_COUNTRY,
            // "CROSS_FIT" to
            // ExerciseSessionRecord.EXERCISE_TYPE_CROSSFIT,
            // "CURLING" to ExerciseSessionRecord.EXERCISE_TYPE_CURLING,
            "DANCING" to ExerciseSessionRecord.EXERCISE_TYPE_DANCING,
            // "DIVING" to ExerciseSessionRecord.EXERCISE_TYPE_DIVING,
            // "DOWNHILL_SKIING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SKIING_DOWNHILL,
            // "ELEVATOR" to
            // ExerciseSessionRecord.EXERCISE_TYPE_ELEVATOR,
            "ELLIPTICAL" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_ELLIPTICAL,
            // "ERGOMETER" to
            // ExerciseSessionRecord.EXERCISE_TYPE_ERGOMETER,
            // "ESCALATOR" to
            // ExerciseSessionRecord.EXERCISE_TYPE_ESCALATOR,
            "FENCING" to ExerciseSessionRecord.EXERCISE_TYPE_FENCING,
            "FRISBEE_DISC" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_FRISBEE_DISC,
            // "GARDENING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_GARDENING,
            "GOLF" to ExerciseSessionRecord.EXERCISE_TYPE_GOLF,
            "GUIDED_BREATHING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_GUIDED_BREATHING,
            "GYMNASTICS" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_GYMNASTICS,
            "HANDBALL" to ExerciseSessionRecord.EXERCISE_TYPE_HANDBALL,
            "HIGH_INTENSITY_INTERVAL_TRAINING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING,
            "HIKING" to ExerciseSessionRecord.EXERCISE_TYPE_HIKING,
            // "HOCKEY" to ExerciseSessionRecord.EXERCISE_TYPE_HOCKEY,
            // "HORSEBACK_RIDING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_HORSEBACK_RIDING,
            // "HOUSEWORK" to
            // ExerciseSessionRecord.EXERCISE_TYPE_HOUSEWORK,
            // "IN_VEHICLE" to
            // ExerciseSessionRecord.EXERCISE_TYPE_IN_VEHICLE,
            "ICE_SKATING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_ICE_SKATING,
            // "INTERVAL_TRAINING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_INTERVAL_TRAINING,
            // "JUMP_ROPE" to
            // ExerciseSessionRecord.EXERCISE_TYPE_JUMP_ROPE,
            // "KAYAKING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_KAYAKING,
            // "KETTLEBELL_TRAINING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_KETTLEBELL_TRAINING,
            // "KICK_SCOOTER" to
            // ExerciseSessionRecord.EXERCISE_TYPE_KICK_SCOOTER,
            // "KICKBOXING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_KICKBOXING,
            // "KITE_SURFING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_KITESURFING,
            "MARTIAL_ARTS" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_MARTIAL_ARTS,
            // "MEDITATION" to
            // ExerciseSessionRecord.EXERCISE_TYPE_MEDITATION,
            // "MIXED_MARTIAL_ARTS" to
            // ExerciseSessionRecord.EXERCISE_TYPE_MIXED_MARTIAL_ARTS,
            // "P90X" to ExerciseSessionRecord.EXERCISE_TYPE_P90X,
            "PARAGLIDING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_PARAGLIDING,
            "PILATES" to ExerciseSessionRecord.EXERCISE_TYPE_PILATES,
            // "POLO" to ExerciseSessionRecord.EXERCISE_TYPE_POLO,
            "RACQUETBALL" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_RACQUETBALL,
            "ROCK_CLIMBING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_ROCK_CLIMBING,
            "ROWING" to ExerciseSessionRecord.EXERCISE_TYPE_ROWING,
            "ROWING_MACHINE" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_ROWING_MACHINE,
            "RUGBY" to ExerciseSessionRecord.EXERCISE_TYPE_RUGBY,
            // "RUNNING_JOGGING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_JOGGING,
            // "RUNNING_SAND" to
            // ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_SAND,
            "RUNNING_TREADMILL" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_RUNNING_TREADMILL,
            "RUNNING" to ExerciseSessionRecord.EXERCISE_TYPE_RUNNING,
            "SAILING" to ExerciseSessionRecord.EXERCISE_TYPE_SAILING,
            "SCUBA_DIVING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_SCUBA_DIVING,
            // "SKATING_CROSS" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SKATING_CROSS,
            // "SKATING_INDOOR" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SKATING_INDOOR,
            // "SKATING_INLINE" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SKATING_INLINE,
            "SKATING" to ExerciseSessionRecord.EXERCISE_TYPE_SKATING,
            "SKIING" to ExerciseSessionRecord.EXERCISE_TYPE_SKIING,
            // "SKIING_BACK_COUNTRY" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SKIING_BACK_COUNTRY,
            // "SKIING_KITE" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SKIING_KITE,
            // "SKIING_ROLLER" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SKIING_ROLLER,
            // "SLEDDING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SLEDDING,
            "SNOWBOARDING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_SNOWBOARDING,
            // "SNOWMOBILE" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SNOWMOBILE,
            "SNOWSHOEING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_SNOWSHOEING,
            // "SOCCER" to
            // ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_SOCCER,
            "SOFTBALL" to ExerciseSessionRecord.EXERCISE_TYPE_SOFTBALL,
            "SQUASH" to ExerciseSessionRecord.EXERCISE_TYPE_SQUASH,
            "STAIR_CLIMBING_MACHINE" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_STAIR_CLIMBING_MACHINE,
            "STAIR_CLIMBING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_STAIR_CLIMBING,
            // "STANDUP_PADDLEBOARDING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_STANDUP_PADDLEBOARDING,
            // "STILL" to ExerciseSessionRecord.EXERCISE_TYPE_STILL,
            "STRENGTH_TRAINING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_STRENGTH_TRAINING,
            "SURFING" to ExerciseSessionRecord.EXERCISE_TYPE_SURFING,
            "SWIMMING_OPEN_WATER" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_SWIMMING_OPEN_WATER,
            "SWIMMING_POOL" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_SWIMMING_POOL,
            // "SWIMMING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING,
            "TABLE_TENNIS" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_TABLE_TENNIS,
            // "TEAM_SPORTS" to
            // ExerciseSessionRecord.EXERCISE_TYPE_TEAM_SPORTS,
            "TENNIS" to ExerciseSessionRecord.EXERCISE_TYPE_TENNIS,
            // "TILTING" to ExerciseSessionRecord.EXERCISE_TYPE_TILTING,
            // "VOLLEYBALL_BEACH" to
            // ExerciseSessionRecord.EXERCISE_TYPE_VOLLEYBALL_BEACH,
            // "VOLLEYBALL_INDOOR" to
            // ExerciseSessionRecord.EXERCISE_TYPE_VOLLEYBALL_INDOOR,
            "VOLLEYBALL" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_VOLLEYBALL,
            // "WAKEBOARDING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_WAKEBOARDING,
            // "WALKING_FITNESS" to
            // ExerciseSessionRecord.EXERCISE_TYPE_WALKING_FITNESS,
            // "WALKING_PACED" to
            // ExerciseSessionRecord.EXERCISE_TYPE_WALKING_PACED,
            // "WALKING_NORDIC" to
            // ExerciseSessionRecord.EXERCISE_TYPE_WALKING_NORDIC,
            // "WALKING_STROLLER" to
            // ExerciseSessionRecord.EXERCISE_TYPE_WALKING_STROLLER,
            // "WALKING_TREADMILL" to
            // ExerciseSessionRecord.EXERCISE_TYPE_WALKING_TREADMILL,
            "WALKING" to ExerciseSessionRecord.EXERCISE_TYPE_WALKING,
            "WATER_POLO" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_WATER_POLO,
            "WEIGHTLIFTING" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_WEIGHTLIFTING,
            "WHEELCHAIR" to
                    ExerciseSessionRecord
                        .EXERCISE_TYPE_WHEELCHAIR,
            // "WINDSURFING" to
            // ExerciseSessionRecord.EXERCISE_TYPE_WINDSURFING,
            "YOGA" to ExerciseSessionRecord.EXERCISE_TYPE_YOGA,
            // "ZUMBA" to ExerciseSessionRecord.EXERCISE_TYPE_ZUMBA,
            // "OTHER" to ExerciseSessionRecord.EXERCISE_TYPE_OTHER,
        )

    override fun onAttachedToEngine(
        @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        threadPoolExecutor = Executors.newFixedThreadPool(4)
        checkAvailability()
        if (healthConnectAvailable) {
            healthConnectClient =
                HealthConnectClient.getOrCreate(
                    flutterPluginBinding.applicationContext
                )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = null
        activity = null
        threadPoolExecutor!!.shutdown()
        threadPoolExecutor = null
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the
    // old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be
    // called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        @Suppress("unused")
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
            val plugin = HealthPlugin(channel)
            registrar.addActivityResultListener(plugin)
            channel.setMethodCallHandler(plugin)
        }

        const val PERMISSIONS_REQUEST_ACTIVITY_RECOGNITION = 10
    }

    override fun success(p0: Any?) {
        handler?.post { mResult?.success(p0) }
    }

    override fun notImplemented() {
        handler?.post { mResult?.notImplemented() }
    }

    override fun error(
        errorCode: String,
        errorMessage: String?,
        errorDetails: Any?,
    ) {
        handler?.post { mResult?.error(errorCode, errorMessage, errorDetails) }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == GOOGLE_FIT_PERMISSIONS_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                Log.i("FLUTTER_HEALTH", "Access Granted!")
                mResult?.success(true)
            } else if (resultCode == Activity.RESULT_CANCELED) {
                Log.i("FLUTTER_HEALTH", "Access Denied!")
                mResult?.success(false)
            }
        }
        return false
    }

    private fun onHealthConnectPermissionCallback(permissionGranted: Set<String>) {
        if (permissionGranted.isEmpty()) {
            mResult?.success(false)
            Log.i("FLUTTER_HEALTH", "Access Denied (to Health Connect)!")
        } else {
            mResult?.success(true)
            Log.i("FLUTTER_HEALTH", "Access Granted (to Health Connect)!")
        }
    }

    private fun keyToHealthDataType(type: String): DataType {
        return when (type) {
            BODY_FAT_PERCENTAGE -> DataType.TYPE_BODY_FAT_PERCENTAGE
            HEIGHT -> DataType.TYPE_HEIGHT
            WEIGHT -> DataType.TYPE_WEIGHT
            STEPS -> DataType.TYPE_STEP_COUNT_DELTA
            AGGREGATE_STEP_COUNT -> DataType.AGGREGATE_STEP_COUNT_DELTA
            ACTIVE_ENERGY_BURNED -> DataType.TYPE_CALORIES_EXPENDED
            HEART_RATE -> DataType.TYPE_HEART_RATE_BPM
            BODY_TEMPERATURE -> HealthDataTypes.TYPE_BODY_TEMPERATURE
            BLOOD_PRESSURE_SYSTOLIC -> HealthDataTypes.TYPE_BLOOD_PRESSURE
            BLOOD_PRESSURE_DIASTOLIC -> HealthDataTypes.TYPE_BLOOD_PRESSURE
            BLOOD_OXYGEN -> HealthDataTypes.TYPE_OXYGEN_SATURATION
            BLOOD_GLUCOSE -> HealthDataTypes.TYPE_BLOOD_GLUCOSE
            MOVE_MINUTES -> DataType.TYPE_MOVE_MINUTES
            DISTANCE_DELTA -> DataType.TYPE_DISTANCE_DELTA
            WATER -> DataType.TYPE_HYDRATION
            SLEEP_ASLEEP -> DataType.TYPE_SLEEP_SEGMENT
            SLEEP_AWAKE -> DataType.TYPE_SLEEP_SEGMENT
            SLEEP_IN_BED -> DataType.TYPE_SLEEP_SEGMENT
            SLEEP_LIGHT -> DataType.TYPE_SLEEP_SEGMENT
            SLEEP_REM -> DataType.TYPE_SLEEP_SEGMENT
            SLEEP_DEEP -> DataType.TYPE_SLEEP_SEGMENT
            WORKOUT -> DataType.TYPE_ACTIVITY_SEGMENT
            NUTRITION -> DataType.TYPE_NUTRITION
            else -> throw IllegalArgumentException("Unsupported dataType: $type")
        }
    }

    private fun getField(type: String): Field {
        return when (type) {
            BODY_FAT_PERCENTAGE -> Field.FIELD_PERCENTAGE
            HEIGHT -> Field.FIELD_HEIGHT
            WEIGHT -> Field.FIELD_WEIGHT
            STEPS -> Field.FIELD_STEPS
            ACTIVE_ENERGY_BURNED -> Field.FIELD_CALORIES
            HEART_RATE -> Field.FIELD_BPM
            BODY_TEMPERATURE -> HealthFields.FIELD_BODY_TEMPERATURE
            BLOOD_PRESSURE_SYSTOLIC -> HealthFields.FIELD_BLOOD_PRESSURE_SYSTOLIC
            BLOOD_PRESSURE_DIASTOLIC -> HealthFields.FIELD_BLOOD_PRESSURE_DIASTOLIC
            BLOOD_OXYGEN -> HealthFields.FIELD_OXYGEN_SATURATION
            BLOOD_GLUCOSE -> HealthFields.FIELD_BLOOD_GLUCOSE_LEVEL
            MOVE_MINUTES -> Field.FIELD_DURATION
            DISTANCE_DELTA -> Field.FIELD_DISTANCE
            WATER -> Field.FIELD_VOLUME
            SLEEP_ASLEEP -> Field.FIELD_SLEEP_SEGMENT_TYPE
            SLEEP_AWAKE -> Field.FIELD_SLEEP_SEGMENT_TYPE
            SLEEP_IN_BED -> Field.FIELD_SLEEP_SEGMENT_TYPE
            SLEEP_LIGHT -> Field.FIELD_SLEEP_SEGMENT_TYPE
            SLEEP_REM -> Field.FIELD_SLEEP_SEGMENT_TYPE
            SLEEP_DEEP -> Field.FIELD_SLEEP_SEGMENT_TYPE
            WORKOUT -> Field.FIELD_ACTIVITY
            NUTRITION -> Field.FIELD_NUTRIENTS
            else -> throw IllegalArgumentException("Unsupported dataType: $type")
        }
    }

    private fun isIntField(dataSource: DataSource, unit: Field): Boolean {
        val dataPoint = DataPoint.builder(dataSource).build()
        val value = dataPoint.getValue(unit)
        return value.format == Field.FORMAT_INT32
    }

    // / Extracts the (numeric) value from a Health Data Point
    private fun getHealthDataValue(dataPoint: DataPoint, field: Field): Any {
        val value = dataPoint.getValue(field)
        // Conversion is needed because glucose is stored as mmoll in Google Fit;
        // while mgdl is used for glucose in this plugin.
        val isGlucose = field == HealthFields.FIELD_BLOOD_GLUCOSE_LEVEL
        return when (value.format) {
            Field.FORMAT_FLOAT ->
                if (!isGlucose) value.asFloat()
                else value.asFloat() * MMOLL_2_MGDL

            Field.FORMAT_INT32 -> value.asInt()
            Field.FORMAT_STRING -> value.asString()
            else -> Log.e("Unsupported format:", value.format.toString())
        }
    }

    /** Delete records of the given type in the time range */
    private fun delete(call: MethodCall, result: Result) {
        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            deleteHCData(call, result)
            return
        }
        if (context == null) {
            result.success(false)
            return
        }

        val type = call.argument<String>("dataTypeKey")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!

        // Look up data type and unit for the type key
        val dataType = keyToHealthDataType(type)
        val field = getField(type)

        val typesBuilder = FitnessOptions.builder()
        typesBuilder.addDataType(dataType, FitnessOptions.ACCESS_WRITE)

        val dataSource =
            DataDeleteRequest.Builder()
                .setTimeInterval(
                    startTime,
                    endTime,
                    TimeUnit.MILLISECONDS
                )
                .addDataType(dataType)
                .deleteAllSessions()
                .build()

        val fitnessOptions = typesBuilder.build()

        try {
            val googleSignInAccount =
                GoogleSignIn.getAccountForExtension(
                    context!!.applicationContext,
                    fitnessOptions
                )
            Fitness.getHistoryClient(context!!.applicationContext, googleSignInAccount)
                .deleteData(dataSource)
                .addOnSuccessListener {
                    Log.i(
                        "FLUTTER_HEALTH::SUCCESS",
                        "Dataset deleted successfully!"
                    )
                    result.success(true)
                }
                .addOnFailureListener(
                    errHandler(
                        result,
                        "There was an error deleting the dataset"
                    )
                )
        } catch (e3: Exception) {
            result.success(false)
        }
    }

    /** Save a Blood Pressure measurement with systolic and diastolic values */
    private fun writeBloodPressure(call: MethodCall, result: Result) {
        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            writeBloodPressureHC(call, result)
            return
        }
        if (context == null) {
            result.success(false)
            return
        }

        val dataType = HealthDataTypes.TYPE_BLOOD_PRESSURE
        val systolic = call.argument<Float>("systolic")!!
        val diastolic = call.argument<Float>("diastolic")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!

        val typesBuilder = FitnessOptions.builder()
        typesBuilder.addDataType(dataType, FitnessOptions.ACCESS_WRITE)

        val dataSource =
            DataSource.Builder()
                .setDataType(dataType)
                .setType(DataSource.TYPE_RAW)
                .setDevice(
                    Device.getLocalDevice(
                        context!!.applicationContext
                    )
                )
                .setAppPackageName(context!!.applicationContext)
                .build()

        val builder =
            DataPoint.builder(dataSource)
                .setTimeInterval(
                    startTime,
                    endTime,
                    TimeUnit.MILLISECONDS
                )
                .setField(
                    HealthFields.FIELD_BLOOD_PRESSURE_SYSTOLIC,
                    systolic
                )
                .setField(
                    HealthFields.FIELD_BLOOD_PRESSURE_DIASTOLIC,
                    diastolic
                )
                .build()

        val dataPoint = builder
        val dataSet = DataSet.builder(dataSource).add(dataPoint).build()

        val fitnessOptions = typesBuilder.build()
        try {
            val googleSignInAccount =
                GoogleSignIn.getAccountForExtension(
                    context!!.applicationContext,
                    fitnessOptions
                )
            Fitness.getHistoryClient(context!!.applicationContext, googleSignInAccount)
                .insertData(dataSet)
                .addOnSuccessListener {
                    Log.i(
                        "FLUTTER_HEALTH::SUCCESS",
                        "Blood Pressure added successfully!"
                    )
                    result.success(true)
                }
                .addOnFailureListener(
                    errHandler(
                        result,
                        "There was an error adding the blood pressure data!",
                    ),
                )
        } catch (e3: Exception) {
            result.success(false)
        }
    }

    private fun writeMealHC(call: MethodCall, result: Result) {
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        val calories = call.argument<Double>("caloriesConsumed")
        val carbs = call.argument<Double>("carbohydrates") as Double?
        val protein = call.argument<Double>("protein") as Double?
        val fat = call.argument<Double>("fatTotal") as Double?
        val caffeine = call.argument<Double>("caffeine") as Double?
        val name = call.argument<String>("name")
        val mealType = call.argument<String>("mealType")!!

        scope.launch {
            try {
                val list = mutableListOf<Record>()
                list.add(
                    NutritionRecord(
                        name = name,
                        energy = calories?.kilocalories,
                        totalCarbohydrate = carbs?.grams,
                        protein = protein?.grams,
                        totalFat = fat?.grams,
                        caffeine = caffeine?.grams,
                        startTime = startTime,
                        startZoneOffset = null,
                        endTime = endTime,
                        endZoneOffset = null,
                        mealType =
                        MapMealTypeToTypeHC[
                            mealType]
                            ?: MEAL_TYPE_UNKNOWN,
                    ),
                )
                healthConnectClient.insertRecords(
                    list,
                )
                result.success(true)
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "[Health Connect] Meal was successfully added!"
                )
            } catch (e: Exception) {
                Log.w(
                    "FLUTTER_HEALTH::ERROR",
                    "[Health Connect] There was an error adding the meal",
                )
                Log.w("FLUTTER_HEALTH::ERROR", e.message ?: "unknown error")
                Log.w("FLUTTER_HEALTH::ERROR", e.stackTrace.toString())
                result.success(false)
            }
        }
    }

    /** Save a Nutrition measurement with calories, carbs, protein, fat, name and mealType */
    private fun writeMeal(call: MethodCall, result: Result) {
        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            writeMealHC(call, result)
            return
        }

        if (context == null) {
            result.success(false)
            return
        }

        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val calories = call.argument<Double>("caloriesConsumed")
        val carbs = call.argument<Double>("carbohydrates") as Double?
        val protein = call.argument<Double>("protein") as Double?
        val fat = call.argument<Double>("fatTotal") as Double?
        val name = call.argument<String>("name")
        val mealType = call.argument<String>("mealType")!!

        val dataType = DataType.TYPE_NUTRITION

        val typesBuilder = FitnessOptions.builder()
        typesBuilder.addDataType(dataType, FitnessOptions.ACCESS_WRITE)

        val dataSource =
            DataSource.Builder()
                .setDataType(dataType)
                .setType(DataSource.TYPE_RAW)
                .setDevice(
                    Device.getLocalDevice(
                        context!!.applicationContext
                    )
                )
                .setAppPackageName(context!!.applicationContext)
                .build()

        val nutrients = mutableMapOf(Field.NUTRIENT_CALORIES to calories?.toFloat())

        if (carbs != null) {
            nutrients[Field.NUTRIENT_TOTAL_CARBS] = carbs.toFloat()
        }

        if (protein != null) {
            nutrients[Field.NUTRIENT_PROTEIN] = protein.toFloat()
        }

        if (fat != null) {
            nutrients[Field.NUTRIENT_TOTAL_FAT] = fat.toFloat()
        }

        val dataBuilder =
            DataPoint.builder(dataSource)
                .setTimeInterval(
                    startTime,
                    endTime,
                    TimeUnit.MILLISECONDS
                )
                .setField(Field.FIELD_NUTRIENTS, nutrients)

        if (name != null) {
            dataBuilder.setField(Field.FIELD_FOOD_ITEM, name as String)
        }

        dataBuilder.setField(
            Field.FIELD_MEAL_TYPE,
            MapMealTypeToType[mealType] ?: Field.MEAL_TYPE_UNKNOWN
        )

        val dataPoint = dataBuilder.build()

        val dataSet = DataSet.builder(dataSource).add(dataPoint).build()

        val fitnessOptions = typesBuilder.build()
        try {
            val googleSignInAccount =
                GoogleSignIn.getAccountForExtension(
                    context!!.applicationContext,
                    fitnessOptions
                )
            Fitness.getHistoryClient(context!!.applicationContext, googleSignInAccount)
                .insertData(dataSet)
                .addOnSuccessListener {
                    Log.i(
                        "FLUTTER_HEALTH::SUCCESS",
                        "Meal added successfully!"
                    )
                    result.success(true)
                }
                .addOnFailureListener(
                    errHandler(
                        result,
                        "There was an error adding the meal data!"
                    )
                )
        } catch (e3: Exception) {
            result.success(false)
        }
    }

    /** Save a data type in Google Fit */
    private fun writeData(call: MethodCall, result: Result) {
        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            writeHCData(call, result)
            return
        }
        if (context == null) {
            result.success(false)
            return
        }

        val type = call.argument<String>("dataTypeKey")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val value = call.argument<Float>("value")!!

        // Look up data type and unit for the type key
        val dataType = keyToHealthDataType(type)
        val field = getField(type)

        val typesBuilder = FitnessOptions.builder()
        typesBuilder.addDataType(dataType, FitnessOptions.ACCESS_WRITE)

        val dataSource =
            DataSource.Builder()
                .setDataType(dataType)
                .setType(DataSource.TYPE_RAW)
                .setDevice(
                    Device.getLocalDevice(
                        context!!.applicationContext
                    )
                )
                .setAppPackageName(context!!.applicationContext)
                .build()

        val builder =
            if (startTime == endTime) {
                DataPoint.builder(dataSource)
                    .setTimestamp(
                        startTime,
                        TimeUnit.MILLISECONDS
                    )
            } else {
                DataPoint.builder(dataSource)
                    .setTimeInterval(
                        startTime,
                        endTime,
                        TimeUnit.MILLISECONDS
                    )
            }

        // Conversion is needed because glucose is stored as mmoll in Google Fit;
        // while mgdl is used for glucose in this plugin.
        val isGlucose = field == HealthFields.FIELD_BLOOD_GLUCOSE_LEVEL
        val dataPoint =
            if (!isIntField(dataSource, field)) {
                builder.setField(
                    field,
                    (if (!isGlucose) value
                    else
                        (value /
                                MMOLL_2_MGDL)
                            .toFloat())
                )
                    .build()
            } else {
                builder.setField(field, value.toInt()).build()
            }

        val dataSet = DataSet.builder(dataSource).add(dataPoint).build()

        if (dataType == DataType.TYPE_SLEEP_SEGMENT) {
            typesBuilder.accessSleepSessions(FitnessOptions.ACCESS_READ)
        }
        val fitnessOptions = typesBuilder.build()
        try {
            val googleSignInAccount =
                GoogleSignIn.getAccountForExtension(
                    context!!.applicationContext,
                    fitnessOptions
                )
            Fitness.getHistoryClient(context!!.applicationContext, googleSignInAccount)
                .insertData(dataSet)
                .addOnSuccessListener {
                    Log.i(
                        "FLUTTER_HEALTH::SUCCESS",
                        "Dataset added successfully!"
                    )
                    result.success(true)
                }
                .addOnFailureListener(
                    errHandler(
                        result,
                        "There was an error adding the dataset"
                    )
                )
        } catch (e3: Exception) {
            result.success(false)
        }
    }

    /**
     * Save the blood oxygen saturation, in Google Fit with the supplemental flow rate, in
     * HealthConnect without
     */
    private fun writeBloodOxygen(call: MethodCall, result: Result) {
        // Health Connect does not support supplemental flow rate, thus it is ignored
        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            writeHCData(call, result)
            return
        }

        if (context == null) {
            result.success(false)
            return
        }

        val dataType = HealthDataTypes.TYPE_OXYGEN_SATURATION
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val saturation = call.argument<Float>("value")!!
        val flowRate = call.argument<Float>("flowRate")!!

        val typesBuilder = FitnessOptions.builder()
        typesBuilder.addDataType(dataType, FitnessOptions.ACCESS_WRITE)

        val dataSource =
            DataSource.Builder()
                .setDataType(dataType)
                .setType(DataSource.TYPE_RAW)
                .setDevice(
                    Device.getLocalDevice(
                        context!!.applicationContext
                    )
                )
                .setAppPackageName(context!!.applicationContext)
                .build()

        val builder =
            if (startTime == endTime) {
                DataPoint.builder(dataSource)
                    .setTimestamp(
                        startTime,
                        TimeUnit.MILLISECONDS
                    )
            } else {
                DataPoint.builder(dataSource)
                    .setTimeInterval(
                        startTime,
                        endTime,
                        TimeUnit.MILLISECONDS
                    )
            }

        builder.setField(HealthFields.FIELD_SUPPLEMENTAL_OXYGEN_FLOW_RATE, flowRate)
        builder.setField(HealthFields.FIELD_OXYGEN_SATURATION, saturation)

        val dataPoint = builder.build()
        val dataSet = DataSet.builder(dataSource).add(dataPoint).build()

        val fitnessOptions = typesBuilder.build()
        try {
            val googleSignInAccount =
                GoogleSignIn.getAccountForExtension(
                    context!!.applicationContext,
                    fitnessOptions
                )
            Fitness.getHistoryClient(context!!.applicationContext, googleSignInAccount)
                .insertData(dataSet)
                .addOnSuccessListener {
                    Log.i(
                        "FLUTTER_HEALTH::SUCCESS",
                        "Blood Oxygen added successfully!"
                    )
                    result.success(true)
                }
                .addOnFailureListener(
                    errHandler(
                        result,
                        "There was an error adding the blood oxygen data!",
                    ),
                )
        } catch (e3: Exception) {
            result.success(false)
        }
    }

    /** Save a Workout session with options for distance and calories expended */
    private fun writeWorkoutData(call: MethodCall, result: Result) {
        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            writeWorkoutHCData(call, result)
            return
        }
        if (context == null) {
            result.success(false)
            return
        }

        val type = call.argument<String>("activityType")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val totalEnergyBurned = call.argument<Int>("totalEnergyBurned")
        val totalDistance = call.argument<Int>("totalDistance")

        val activityType = getActivityType(type)
        // Create the Activity Segment DataSource
        val activitySegmentDataSource =
            DataSource.Builder()
                .setAppPackageName(context!!.packageName)
                .setDataType(DataType.TYPE_ACTIVITY_SEGMENT)
                .setStreamName("FLUTTER_HEALTH - Activity")
                .setType(DataSource.TYPE_RAW)
                .build()
        // Create the Activity Segment
        val activityDataPoint =
            DataPoint.builder(activitySegmentDataSource)
                .setTimeInterval(
                    startTime,
                    endTime,
                    TimeUnit.MILLISECONDS
                )
                .setActivityField(
                    Field.FIELD_ACTIVITY,
                    activityType
                )
                .build()
        // Add DataPoint to DataSet
        val activitySegments =
            DataSet.builder(activitySegmentDataSource)
                .add(activityDataPoint)
                .build()

        // If distance is provided
        var distanceDataSet: DataSet? = null
        if (totalDistance != null) {
            // Create a data source
            val distanceDataSource =
                DataSource.Builder()
                    .setAppPackageName(context!!.packageName)
                    .setDataType(DataType.TYPE_DISTANCE_DELTA)
                    .setStreamName("FLUTTER_HEALTH - Distance")
                    .setType(DataSource.TYPE_RAW)
                    .build()

            val distanceDataPoint =
                DataPoint.builder(distanceDataSource)
                    .setTimeInterval(
                        startTime,
                        endTime,
                        TimeUnit.MILLISECONDS
                    )
                    .setField(
                        Field.FIELD_DISTANCE,
                        totalDistance.toFloat()
                    )
                    .build()
            // Create a data set
            distanceDataSet =
                DataSet.builder(distanceDataSource)
                    .add(distanceDataPoint)
                    .build()
        }
        // If energyBurned is provided
        var energyDataSet: DataSet? = null
        if (totalEnergyBurned != null) {
            // Create a data source
            val energyDataSource =
                DataSource.Builder()
                    .setAppPackageName(context!!.packageName)
                    .setDataType(
                        DataType.TYPE_CALORIES_EXPENDED
                    )
                    .setStreamName("FLUTTER_HEALTH - Calories")
                    .setType(DataSource.TYPE_RAW)
                    .build()

            val energyDataPoint =
                DataPoint.builder(energyDataSource)
                    .setTimeInterval(
                        startTime,
                        endTime,
                        TimeUnit.MILLISECONDS
                    )
                    .setField(
                        Field.FIELD_CALORIES,
                        totalEnergyBurned.toFloat()
                    )
                    .build()
            // Create a data set
            energyDataSet =
                DataSet.builder(energyDataSource)
                    .add(energyDataPoint)
                    .build()
        }

        // Finish session setup
        val session =
            Session.Builder()
                .setName(
                    activityType
                ) // TODO: Make a sensible name / allow user to set
                // name
                .setDescription("")
                .setIdentifier(UUID.randomUUID().toString())
                .setActivity(activityType)
                .setStartTime(startTime, TimeUnit.MILLISECONDS)
                .setEndTime(endTime, TimeUnit.MILLISECONDS)
                .build()
        // Build a session and add the values provided
        val sessionInsertRequestBuilder =
            SessionInsertRequest.Builder()
                .setSession(session)
                .addDataSet(activitySegments)
        if (totalDistance != null) {
            sessionInsertRequestBuilder.addDataSet(distanceDataSet!!)
        }
        if (totalEnergyBurned != null) {
            sessionInsertRequestBuilder.addDataSet(energyDataSet!!)
        }
        val insertRequest = sessionInsertRequestBuilder.build()

        val fitnessOptionsBuilder =
            FitnessOptions.builder()
                .addDataType(
                    DataType.TYPE_ACTIVITY_SEGMENT,
                    FitnessOptions.ACCESS_WRITE
                )
        if (totalDistance != null) {
            fitnessOptionsBuilder.addDataType(
                DataType.TYPE_DISTANCE_DELTA,
                FitnessOptions.ACCESS_WRITE,
            )
        }
        if (totalEnergyBurned != null) {
            fitnessOptionsBuilder.addDataType(
                DataType.TYPE_CALORIES_EXPENDED,
                FitnessOptions.ACCESS_WRITE,
            )
        }
        val fitnessOptions = fitnessOptionsBuilder.build()

        try {
            val googleSignInAccount =
                GoogleSignIn.getAccountForExtension(
                    context!!.applicationContext,
                    fitnessOptions
                )
            Fitness.getSessionsClient(
                context!!.applicationContext,
                googleSignInAccount,
            )
                .insertSession(insertRequest)
                .addOnSuccessListener {
                    Log.i(
                        "FLUTTER_HEALTH::SUCCESS",
                        "Workout was successfully added!"
                    )
                    result.success(true)
                }
                .addOnFailureListener(
                    errHandler(
                        result,
                        "There was an error adding the workout"
                    )
                )
        } catch (e: Exception) {
            result.success(false)
        }
    }

    /** Get all datapoints of the DataType within the given time range */
    private fun getData(call: MethodCall, result: Result) {

        if (StepCounterService.isRunning()) {
            getSensorData(call, result)
            return
        }

        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            getHCData(call, result)
            return
        }

        if (context == null) {
            result.success(null)
            return
        }

        val type = call.argument<String>("dataTypeKey")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val includeManualEntry = call.argument<Boolean>("includeManualEntry")!!
        // Look up data type and unit for the type key
        val dataType = keyToHealthDataType(type)
        val field = getField(type)
        val typesBuilder = FitnessOptions.builder()
        typesBuilder.addDataType(dataType)

        // Add special cases for accessing workouts or sleep data.
        if (dataType == DataType.TYPE_SLEEP_SEGMENT) {
            typesBuilder.accessSleepSessions(FitnessOptions.ACCESS_READ)
        } else if (dataType == DataType.TYPE_ACTIVITY_SEGMENT) {
            typesBuilder.accessActivitySessions(FitnessOptions.ACCESS_READ)
                .addDataType(
                    DataType.TYPE_CALORIES_EXPENDED,
                    FitnessOptions.ACCESS_READ
                )
                .addDataType(
                    DataType.TYPE_DISTANCE_DELTA,
                    FitnessOptions.ACCESS_READ
                )
        }
        val fitnessOptions = typesBuilder.build()
        val googleSignInAccount =
            GoogleSignIn.getAccountForExtension(
                context!!.applicationContext,
                fitnessOptions
            )
        // Handle data types
        when (dataType) {
            DataType.TYPE_SLEEP_SEGMENT -> {
                // request to the sessions for sleep data
                val request =
                    SessionReadRequest.Builder()
                        .setTimeInterval(
                            startTime,
                            endTime,
                            TimeUnit.MILLISECONDS
                        )
                        .enableServerQueries()
                        .readSessionsFromAllApps()
                        .includeSleepSessions()
                        .build()
                Fitness.getSessionsClient(
                    context!!.applicationContext,
                    googleSignInAccount
                )
                    .readSession(request)
                    .addOnSuccessListener(
                        threadPoolExecutor!!,
                        sleepDataHandler(type, result)
                    )
                    .addOnFailureListener(
                        errHandler(
                            result,
                            "There was an error getting the sleeping data!",
                        ),
                    )
            }

            DataType.TYPE_ACTIVITY_SEGMENT -> {
                val readRequest: SessionReadRequest
                val readRequestBuilder =
                    SessionReadRequest.Builder()
                        .setTimeInterval(
                            startTime,
                            endTime,
                            TimeUnit.MILLISECONDS
                        )
                        .enableServerQueries()
                        .readSessionsFromAllApps()
                        .includeActivitySessions()
                        .read(dataType)
                        .read(
                            DataType.TYPE_CALORIES_EXPENDED
                        )

                // If fine location is enabled, read distance data
                if (ContextCompat.checkSelfPermission(
                        context!!.applicationContext,
                        android.Manifest.permission
                            .ACCESS_FINE_LOCATION,
                    ) == PackageManager.PERMISSION_GRANTED
                ) {
                    readRequestBuilder.read(DataType.TYPE_DISTANCE_DELTA)
                }
                readRequest = readRequestBuilder.build()
                Fitness.getSessionsClient(
                    context!!.applicationContext,
                    googleSignInAccount
                )
                    .readSession(readRequest)
                    .addOnSuccessListener(
                        threadPoolExecutor!!,
                        workoutDataHandler(type, result)
                    )
                    .addOnFailureListener(
                        errHandler(
                            result,
                            "There was an error getting the workout data!",
                        ),
                    )
            }

            else -> {
                Fitness.getHistoryClient(
                    context!!.applicationContext,
                    googleSignInAccount
                )
                    .readData(
                        DataReadRequest.Builder()
                            .read(dataType)
                            .setTimeRange(
                                startTime,
                                endTime,
                                TimeUnit.MILLISECONDS
                            )
                            .build(),
                    )
                    .addOnSuccessListener(
                        threadPoolExecutor!!,
                        dataHandler(
                            dataType,
                            field,
                            includeManualEntry,
                            result
                        ),
                    )
                    .addOnFailureListener(
                        errHandler(
                            result,
                            "There was an error getting the data!",
                        ),
                    )
            }
        }
    }

    private fun getSensorData(call: MethodCall, result: Result) {
        val dataType = call.argument<String>("dataTypeKey")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)

        val healthConnectData = mutableListOf<Map<String, Any?>>()

        if(dataType == STEPS && StepCounterService.isRunning()) {
            val items = StepCounterService.box.boxFor(SensorStep::class.java).query(SensorStep_.startTime.between(startTime.toEpochMilli(),endTime.toEpochMilli())).build().find()
            healthConnectData.addAll(items.map {
                mapOf<String, Any>(
                    "value" to
                            it.count,
                    "date_from" to
                            it.startTime!!
                    ,
                    "date_to" to
                            it.endTime!!,
                    "source_id" to "",
                    "source_name" to
                            "sensor_step",
                )
            })
        }

        Handler(context!!.mainLooper).run { result.success(healthConnectData) }
    }

    private fun getIntervalData(call: MethodCall, result: Result) {
        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            getAggregateHCData(call, result)
            return
        }

        if (context == null) {
            result.success(null)
            return
        }

        val type = call.argument<String>("dataTypeKey")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val interval = call.argument<Int>("interval")!!
        val includeManualEntry = call.argument<Boolean>("includeManualEntry")!!

        // Look up data type and unit for the type key
        val dataType = keyToHealthDataType(type)
        val field = getField(type)
        val typesBuilder = FitnessOptions.builder()
        typesBuilder.addDataType(dataType)
        if (dataType == DataType.TYPE_SLEEP_SEGMENT) {
            typesBuilder.accessSleepSessions(FitnessOptions.ACCESS_READ)
        }
        val fitnessOptions = typesBuilder.build()
        val googleSignInAccount =
            GoogleSignIn.getAccountForExtension(
                context!!.applicationContext,
                fitnessOptions
            )

        Fitness.getHistoryClient(context!!.applicationContext, googleSignInAccount)
            .readData(
                DataReadRequest.Builder()
                    .aggregate(dataType)
                    .bucketByTime(
                        interval,
                        TimeUnit.SECONDS
                    )
                    .setTimeRange(
                        startTime,
                        endTime,
                        TimeUnit.MILLISECONDS
                    )
                    .build()
            )
            .addOnSuccessListener(
                threadPoolExecutor!!,
                intervalDataHandler(
                    dataType,
                    field,
                    includeManualEntry,
                    result
                )
            )
            .addOnFailureListener(
                errHandler(
                    result,
                    "There was an error getting the interval data!"
                )
            )
    }

    private fun getAggregateData(call: MethodCall, result: Result) {
        if (context == null) {
            result.success(null)
            return
        }

        val types = call.argument<List<String>>("dataTypeKeys")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val activitySegmentDuration = call.argument<Int>("activitySegmentDuration")!!
        val includeManualEntry = call.argument<Boolean>("includeManualEntry")!!

        val typesBuilder = FitnessOptions.builder()
        for (type in types) {
            val dataType = keyToHealthDataType(type)
            typesBuilder.addDataType(dataType)
        }
        val fitnessOptions = typesBuilder.build()
        val googleSignInAccount =
            GoogleSignIn.getAccountForExtension(
                context!!.applicationContext,
                fitnessOptions
            )

        val readWorkoutsRequest =
            DataReadRequest.Builder()
                .bucketByActivitySegment(
                    activitySegmentDuration,
                    TimeUnit.SECONDS
                )
                .setTimeRange(
                    startTime,
                    endTime,
                    TimeUnit.MILLISECONDS
                )

        for (type in types) {
            val dataType = keyToHealthDataType(type)
            readWorkoutsRequest.aggregate(dataType)
        }

        Fitness.getHistoryClient(context!!.applicationContext, googleSignInAccount)
            .readData(readWorkoutsRequest.build())
            .addOnSuccessListener(
                threadPoolExecutor!!,
                aggregateDataHandler(includeManualEntry, result)
            )
            .addOnFailureListener(
                errHandler(
                    result,
                    "There was an error getting the aggregate data!"
                )
            )
    }

    private fun dataHandler(
        dataType: DataType,
        field: Field,
        includeManualEntry: Boolean,
        result: Result
    ) = OnSuccessListener { response: DataReadResponse ->
        // / Fetch all data points for the specified DataType
        val dataSet = response.getDataSet(dataType)
        /// For each data point, extract the contents and send them to Flutter, along with
        // date and unit.
        var dataPoints = dataSet.dataPoints
        if (!includeManualEntry) {
            dataPoints =
                dataPoints.filterIndexed { _, dataPoint ->
                    !dataPoint.originalDataSource.streamName.contains(
                        "user_input"
                    )
                }
        }
        // For each data point, extract the contents and send them to Flutter, along with
        // date and unit.
        val healthData =
            dataPoints.mapIndexed { _, dataPoint ->
                return@mapIndexed hashMapOf(
                    "value" to
                            getHealthDataValue(
                                dataPoint,
                                field
                            ),
                    "date_from" to
                            dataPoint.getStartTime(
                                TimeUnit.MILLISECONDS
                            ),
                    "date_to" to
                            dataPoint.getEndTime(
                                TimeUnit.MILLISECONDS
                            ),
                    "source_name" to
                            (dataPoint.originalDataSource
                                .appPackageName
                                ?: (dataPoint.originalDataSource
                                    .device
                                    ?.model
                                    ?: "")),
                    "source_id" to
                            dataPoint.originalDataSource
                                .streamIdentifier,
                )
            }
        Handler(context!!.mainLooper).run { result.success(healthData) }
    }

    private fun errHandler(result: Result, addMessage: String) =
        OnFailureListener { exception ->
            Handler(context!!.mainLooper).run { result.success(null) }
            Log.w("FLUTTER_HEALTH::ERROR", addMessage)
            Log.w("FLUTTER_HEALTH::ERROR", exception.message ?: "unknown error")
            Log.w("FLUTTER_HEALTH::ERROR", exception.stackTrace.toString())
        }

    private fun sleepDataHandler(type: String, result: Result) =
        OnSuccessListener { response: SessionReadResponse ->
            val healthData: MutableList<Map<String, Any?>> = mutableListOf()
            for (session in response.sessions) {
                // Return sleep time in Minutes if requested ASLEEP data
                if (type == SLEEP_ASLEEP) {
                    healthData.add(
                        hashMapOf(
                            "value" to
                                    session.getEndTime(
                                        TimeUnit.MINUTES
                                    ) -
                                    session.getStartTime(
                                        TimeUnit.MINUTES,
                                    ),
                            "date_from" to
                                    session.getStartTime(
                                        TimeUnit.MILLISECONDS
                                    ),
                            "date_to" to
                                    session.getEndTime(
                                        TimeUnit.MILLISECONDS
                                    ),
                            "unit" to "MINUTES",
                            "source_name" to
                                    session.appPackageName,
                            "source_id" to
                                    session.identifier,
                        ),
                    )
                }

                if (type == SLEEP_IN_BED) {
                    val dataSets = response.getDataSet(session)

                    // If the sleep session has finer granularity
                    // sub-components, extract them:
                    if (dataSets.isNotEmpty()) {
                        for (dataSet in dataSets) {
                            for (dataPoint in
                            dataSet.dataPoints) {
                                // searching OUT OF BED data
                                if (dataPoint.getValue(
                                        Field.FIELD_SLEEP_SEGMENT_TYPE
                                    )
                                        .asInt() !=
                                    3
                                ) {
                                    healthData.add(
                                        hashMapOf(
                                            "value" to
                                                    dataPoint.getEndTime(
                                                        TimeUnit.MINUTES
                                                    ) -
                                                    dataPoint.getStartTime(
                                                        TimeUnit.MINUTES,
                                                    ),
                                            "date_from" to
                                                    dataPoint.getStartTime(
                                                        TimeUnit.MILLISECONDS
                                                    ),
                                            "date_to" to
                                                    dataPoint.getEndTime(
                                                        TimeUnit.MILLISECONDS
                                                    ),
                                            "unit" to
                                                    "MINUTES",
                                            "source_name" to
                                                    (dataPoint.originalDataSource
                                                        .appPackageName
                                                        ?: (dataPoint.originalDataSource
                                                            .device
                                                            ?.model
                                                            ?: "unknown")),
                                            "source_id" to
                                                    dataPoint.originalDataSource
                                                        .streamIdentifier,
                                        ),
                                    )
                                }
                            }
                        }
                    } else {
                        healthData.add(
                            hashMapOf(
                                "value" to
                                        session.getEndTime(
                                            TimeUnit.MINUTES
                                        ) -
                                        session.getStartTime(
                                            TimeUnit.MINUTES,
                                        ),
                                "date_from" to
                                        session.getStartTime(
                                            TimeUnit.MILLISECONDS
                                        ),
                                "date_to" to
                                        session.getEndTime(
                                            TimeUnit.MILLISECONDS
                                        ),
                                "unit" to
                                        "MINUTES",
                                "source_name" to
                                        session.appPackageName,
                                "source_id" to
                                        session.identifier,
                            ),
                        )
                    }
                }

                if (type == SLEEP_AWAKE) {
                    val dataSets = response.getDataSet(session)
                    for (dataSet in dataSets) {
                        for (dataPoint in dataSet.dataPoints) {
                            // searching SLEEP AWAKE data
                            if (dataPoint.getValue(
                                    Field.FIELD_SLEEP_SEGMENT_TYPE
                                )
                                    .asInt() ==
                                1
                            ) {
                                healthData.add(
                                    hashMapOf(
                                        "value" to
                                                dataPoint.getEndTime(
                                                    TimeUnit.MINUTES
                                                ) -
                                                dataPoint.getStartTime(
                                                    TimeUnit.MINUTES,
                                                ),
                                        "date_from" to
                                                dataPoint.getStartTime(
                                                    TimeUnit.MILLISECONDS
                                                ),
                                        "date_to" to
                                                dataPoint.getEndTime(
                                                    TimeUnit.MILLISECONDS
                                                ),
                                        "unit" to
                                                "MINUTES",
                                        "source_name" to
                                                (dataPoint.originalDataSource
                                                    .appPackageName
                                                    ?: (dataPoint.originalDataSource
                                                        .device
                                                        ?.model
                                                        ?: "unknown")),
                                        "source_id" to
                                                dataPoint.originalDataSource
                                                    .streamIdentifier,
                                    ),
                                )
                            }
                        }
                    }
                }
            }
            Handler(context!!.mainLooper).run { result.success(healthData) }
        }

    private fun intervalDataHandler(
        dataType: DataType,
        field: Field,
        includeManualEntry: Boolean,
        result: Result
    ) = OnSuccessListener { response: DataReadResponse ->
        val healthData = mutableListOf<HashMap<String, Any>>()
        for (bucket in response.buckets) {
            /// Fetch all data points for the specified DataType
            // val dataSet = response.getDataSet(dataType)
            for (dataSet in bucket.dataSets) {
                /// For each data point, extract the contents and send them to
                // Flutter, along with
                // date and unit.
                var dataPoints = dataSet.dataPoints
                if (!includeManualEntry) {
                    dataPoints =
                        dataPoints.filterIndexed { _, dataPoint ->
                            !dataPoint.originalDataSource
                                .streamName
                                .contains(
                                    "user_input"
                                )
                        }
                }
                for (dataPoint in dataPoints) {
                    for (field in dataPoint.dataType.fields) {
                        val healthDataItems =
                            dataPoints.mapIndexed { _, dataPoint
                                ->
                                return@mapIndexed hashMapOf(
                                    "value" to
                                            getHealthDataValue(
                                                dataPoint,
                                                field
                                            ),
                                    "date_from" to
                                            dataPoint.getStartTime(
                                                TimeUnit.MILLISECONDS
                                            ),
                                    "date_to" to
                                            dataPoint.getEndTime(
                                                TimeUnit.MILLISECONDS
                                            ),
                                    "source_name" to
                                            (dataPoint.originalDataSource
                                                .appPackageName
                                                ?: (dataPoint.originalDataSource
                                                    .device
                                                    ?.model
                                                    ?: "")),
                                    "source_id" to
                                            dataPoint.originalDataSource
                                                .streamIdentifier,
                                    "is_manual_entry" to
                                            dataPoint.originalDataSource
                                                .streamName
                                                .contains(
                                                    "user_input"
                                                )
                                )
                            }
                        healthData.addAll(healthDataItems)
                    }
                }
            }
        }
        Handler(context!!.mainLooper).run { result.success(healthData) }
    }

    private fun aggregateDataHandler(includeManualEntry: Boolean, result: Result) =
        OnSuccessListener { response: DataReadResponse ->
            val healthData = mutableListOf<HashMap<String, Any>>()
            for (bucket in response.buckets) {
                var sourceName: Any = ""
                var sourceId: Any = ""
                var isManualEntry: Any = false
                var totalSteps: Any = 0
                var totalDistance: Any = 0
                var totalEnergyBurned: Any = 0
                /// Fetch all data points for the specified DataType
                for (dataSet in bucket.dataSets) {
                    /// For each data point, extract the contents and
                    // send them to Flutter,
                    // along with date and unit.
                    var dataPoints = dataSet.dataPoints
                    if (!includeManualEntry) {
                        dataPoints =
                            dataPoints.filterIndexed { _,
                                                       dataPoint ->
                                !dataPoint.originalDataSource
                                    .streamName
                                    .contains(
                                        "user_input"
                                    )
                            }
                    }
                    for (dataPoint in dataPoints) {
                        sourceName =
                            (dataPoint.originalDataSource
                                .appPackageName
                                ?: (dataPoint.originalDataSource
                                    .device
                                    ?.model
                                    ?: ""))
                        sourceId =
                            dataPoint.originalDataSource
                                .streamIdentifier
                        isManualEntry =
                            dataPoint.originalDataSource
                                .streamName
                                .contains(
                                    "user_input"
                                )
                        for (field in dataPoint.dataType.fields) {
                            when (field) {
                                getField(STEPS) -> {
                                    totalSteps =
                                        getHealthDataValue(
                                            dataPoint,
                                            field
                                        )
                                }

                                getField(
                                    DISTANCE_DELTA
                                ) -> {
                                    totalDistance =
                                        getHealthDataValue(
                                            dataPoint,
                                            field
                                        )
                                }

                                getField(
                                    ACTIVE_ENERGY_BURNED
                                ) -> {
                                    totalEnergyBurned =
                                        getHealthDataValue(
                                            dataPoint,
                                            field
                                        )
                                }
                            }
                        }
                    }
                }
                val healthDataItems =
                    hashMapOf(
                        "value" to
                                bucket.getEndTime(
                                    TimeUnit.MINUTES
                                ) -
                                bucket.getStartTime(
                                    TimeUnit.MINUTES
                                ),
                        "date_from" to
                                bucket.getStartTime(
                                    TimeUnit.MILLISECONDS
                                ),
                        "date_to" to
                                bucket.getEndTime(
                                    TimeUnit.MILLISECONDS
                                ),
                        "source_name" to sourceName,
                        "source_id" to sourceId,
                        "is_manual_entry" to
                                isManualEntry,
                        "workout_type" to
                                bucket.activity
                                    .toLowerCase(),
                        "total_steps" to totalSteps,
                        "total_distance" to
                                totalDistance,
                        "total_energy_burned" to
                                totalEnergyBurned
                    )
                healthData.add(healthDataItems)
            }
            Handler(context!!.mainLooper).run { result.success(healthData) }
        }

    private fun workoutDataHandler(type: String, result: Result) =
        OnSuccessListener { response: SessionReadResponse ->
            val healthData: MutableList<Map<String, Any?>> = mutableListOf()
            for (session in response.sessions) {
                // Look for calories and distance if they
                var totalEnergyBurned = 0.0
                var totalDistance = 0.0
                for (dataSet in response.getDataSet(session)) {
                    if (dataSet.dataType ==
                        DataType.TYPE_CALORIES_EXPENDED
                    ) {
                        for (dataPoint in dataSet.dataPoints) {
                            totalEnergyBurned +=
                                dataPoint.getValue(
                                    Field.FIELD_CALORIES
                                )
                                    .toString()
                                    .toDouble()
                        }
                    }
                    if (dataSet.dataType == DataType.TYPE_DISTANCE_DELTA
                    ) {
                        for (dataPoint in dataSet.dataPoints) {
                            totalDistance +=
                                dataPoint.getValue(
                                    Field.FIELD_DISTANCE
                                )
                                    .toString()
                                    .toDouble()
                        }
                    }
                }
                healthData.add(
                    hashMapOf(
                        "workoutActivityType" to
                                (workoutTypeMap
                                    .filterValues {
                                        it ==
                                                session.activity
                                    }
                                    .keys
                                    .firstOrNull()
                                    ?: "OTHER"),
                        "totalEnergyBurned" to
                                if (totalEnergyBurned ==
                                    0.0
                                )
                                    null
                                else
                                    totalEnergyBurned,
                        "totalEnergyBurnedUnit" to
                                "KILOCALORIE",
                        "totalDistance" to
                                if (totalDistance ==
                                    0.0
                                )
                                    null
                                else
                                    totalDistance,
                        "totalDistanceUnit" to
                                "METER",
                        "date_from" to
                                session.getStartTime(
                                    TimeUnit.MILLISECONDS
                                ),
                        "date_to" to
                                session.getEndTime(
                                    TimeUnit.MILLISECONDS
                                ),
                        "unit" to "MINUTES",
                        "source_name" to
                                session.appPackageName,
                        "source_id" to
                                session.identifier,
                    ),
                )
            }
            Handler(context!!.mainLooper).run { result.success(healthData) }
        }

    private fun callToHealthTypes(call: MethodCall): FitnessOptions {
        val typesBuilder = FitnessOptions.builder()
        val args = call.arguments as HashMap<*, *>
        val types = (args["types"] as? ArrayList<*>)?.filterIsInstance<String>()
        val permissions = (args["permissions"] as? ArrayList<*>)?.filterIsInstance<Int>()

        assert(types != null)
        assert(permissions != null)
        assert(types!!.count() == permissions!!.count())

        for ((i, typeKey) in types.withIndex()) {
            val access = permissions[i]
            val dataType = keyToHealthDataType(typeKey)
            when (access) {
                0 -> typesBuilder.addDataType(dataType, FitnessOptions.ACCESS_READ)
                1 -> typesBuilder.addDataType(dataType, FitnessOptions.ACCESS_WRITE)
                2 -> {
                    typesBuilder.addDataType(
                        dataType,
                        FitnessOptions.ACCESS_READ
                    )
                    typesBuilder.addDataType(
                        dataType,
                        FitnessOptions.ACCESS_WRITE
                    )
                }

                else ->
                    throw IllegalArgumentException(
                        "Unknown access type $access"
                    )
            }
            if (typeKey == SLEEP_ASLEEP ||
                typeKey == SLEEP_AWAKE ||
                typeKey == SLEEP_IN_BED
            ) {
                typesBuilder.accessSleepSessions(FitnessOptions.ACCESS_READ)
                when (access) {
                    0 ->
                        typesBuilder.accessSleepSessions(
                            FitnessOptions.ACCESS_READ
                        )

                    1 ->
                        typesBuilder.accessSleepSessions(
                            FitnessOptions.ACCESS_WRITE
                        )

                    2 -> {
                        typesBuilder.accessSleepSessions(
                            FitnessOptions.ACCESS_READ
                        )
                        typesBuilder.accessSleepSessions(
                            FitnessOptions.ACCESS_WRITE
                        )
                    }

                    else ->
                        throw IllegalArgumentException(
                            "Unknown access type $access"
                        )
                }
            }
            if (typeKey == WORKOUT) {
                when (access) {
                    0 ->
                        typesBuilder.accessActivitySessions(
                            FitnessOptions.ACCESS_READ
                        )

                    1 ->
                        typesBuilder.accessActivitySessions(
                            FitnessOptions.ACCESS_WRITE
                        )

                    2 -> {
                        typesBuilder.accessActivitySessions(
                            FitnessOptions.ACCESS_READ
                        )
                        typesBuilder.accessActivitySessions(
                            FitnessOptions.ACCESS_WRITE
                        )
                    }

                    else ->
                        throw IllegalArgumentException(
                            "Unknown access type $access"
                        )
                }
            }
        }
        return typesBuilder.build()
    }

    private fun hasPermissions(call: MethodCall, result: Result) {
        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            hasPermissionsHC(call, result)
            return
        }
        if (context == null) {
            result.success(false)
            return
        }

        val optionsToRegister = callToHealthTypes(call)

        val isGranted =
            GoogleSignIn.hasPermissions(
                GoogleSignIn.getLastSignedInAccount(context!!),
                optionsToRegister,
            )

        result?.success(isGranted)
    }

    /**
     * Requests authorization for the HealthDataTypes with the the READ or READ_WRITE permission
     * type.
     */
    private fun requestAuthorization(call: MethodCall, result: Result) {
        if (context == null) {
            result.success(false)
            return
        }
        mResult = result

        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            requestAuthorizationHC(call, result)
            return
        }

        val optionsToRegister = callToHealthTypes(call)

        // Set to false due to bug described in
        // https://github.com/cph-cachet/flutter-plugins/issues/640#issuecomment-1366830132
        val isGranted = false

        // If not granted then ask for permission
        if (!isGranted && activity != null) {
            GoogleSignIn.requestPermissions(
                activity!!,
                GOOGLE_FIT_PERMISSIONS_REQUEST_CODE,
                GoogleSignIn.getLastSignedInAccount(context!!),
                optionsToRegister,
            )
        } else { // / Permission already granted
            result?.success(true)
        }
    }

    /**
     * Revokes access to Google Fit using the `disableFit`-method.
     *
     * Note: Using the `revokeAccess` creates a bug on android when trying to reapply for
     * permissions afterwards, hence `disableFit` was used.
     */
    private fun revokePermissions(call: MethodCall, result: Result) {
        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            result.notImplemented()
            return
        }
        if (context == null) {
            result.success(false)
            return
        }
        Fitness.getConfigClient(
            activity!!,
            GoogleSignIn.getLastSignedInAccount(context!!)!!
        )
            .disableFit()
            .addOnSuccessListener {
                Log.i("Health", "Disabled Google Fit")
                result.success(true)
            }
            .addOnFailureListener { e ->
                Log.w(
                    "Health",
                    "There was an error disabling Google Fit",
                    e
                )
                result.success(false)
            }
    }

    private fun getTotalStepsInInterval(call: MethodCall, result: Result) {
        val start = call.argument<Long>("startTime")!!
        val end = call.argument<Long>("endTime")!!

        if (useHealthConnectIfAvailable && healthConnectAvailable) {
            getStepsHealthConnect(start, end, result)
            return
        }

        val context = context ?: return

        val stepsDataType = keyToHealthDataType(STEPS)
        val aggregatedDataType = keyToHealthDataType(AGGREGATE_STEP_COUNT)

        val fitnessOptions =
            FitnessOptions.builder()
                .addDataType(stepsDataType)
                .addDataType(aggregatedDataType)
                .build()
        val gsa = GoogleSignIn.getAccountForExtension(context, fitnessOptions)

        val ds =
            DataSource.Builder()
                .setAppPackageName("com.google.android.gms")
                .setDataType(stepsDataType)
                .setType(DataSource.TYPE_DERIVED)
                .setStreamName("estimated_steps")
                .build()

        val duration = (end - start).toInt()

        val request =
            DataReadRequest.Builder()
                .aggregate(ds)
                .bucketByTime(duration, TimeUnit.MILLISECONDS)
                .setTimeRange(start, end, TimeUnit.MILLISECONDS)
                .build()

        Fitness.getHistoryClient(context, gsa)
            .readData(request)
            .addOnFailureListener(
                errHandler(
                    result,
                    "There was an error getting the total steps in the interval!",
                ),
            )
            .addOnSuccessListener(
                threadPoolExecutor!!,
                getStepsInRange(
                    start,
                    end,
                    aggregatedDataType,
                    result
                ),
            )
    }

    private fun getStepsHealthConnect(start: Long, end: Long, result: Result) =
        scope.launch {
            try {
                val startInstant = Instant.ofEpochMilli(start)
                val endInstant = Instant.ofEpochMilli(end)
                val response =
                    healthConnectClient.aggregate(
                        AggregateRequest(
                            metrics =
                            setOf(
                                StepsRecord.COUNT_TOTAL
                            ),
                            timeRangeFilter =
                            TimeRangeFilter.between(
                                startInstant,
                                endInstant
                            ),
                        ),
                    )
                // The result may be null if no data is available in the
                // time range.
                val stepsInInterval =
                    response[StepsRecord.COUNT_TOTAL] ?: 0L
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "returning $stepsInInterval steps"
                )
                result.success(stepsInInterval)
            } catch (e: Exception) {
                Log.i("FLUTTER_HEALTH::ERROR", "unable to return steps")
                result.success(null)
            }
        }

    private fun getStepsInRange(
        start: Long,
        end: Long,
        aggregatedDataType: DataType,
        result: Result,
    ) = OnSuccessListener { response: DataReadResponse ->
        val map = HashMap<Long, Int>() // need to return to Dart so can't use sparse array
        for (bucket in response.buckets) {
            val dp = bucket.dataSets.firstOrNull()?.dataPoints?.firstOrNull()
            if (dp != null) {
                val count = dp.getValue(aggregatedDataType.fields[0])

                val startTime = dp.getStartTime(TimeUnit.MILLISECONDS)
                val startDate = Date(startTime)
                val endDate = Date(dp.getEndTime(TimeUnit.MILLISECONDS))
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "returning $count steps for $startDate - $endDate",
                )
                map[startTime] = count.asInt()
            } else {
                val startDay = Date(start)
                val endDay = Date(end)
                Log.i("FLUTTER_HEALTH::ERROR", "no steps for $startDay - $endDay")
            }
        }

        assert(map.size <= 1) {
            "getTotalStepsInInterval should return only one interval. Found: ${map.size}"
        }
        Handler(context!!.mainLooper).run { result.success(map.values.firstOrNull()) }
    }

    /// Disconnect Google fit
    private fun disconnect(call: MethodCall, result: Result) {
        if (activity == null) {
            result.success(false)
            return
        }
        val context = activity!!.applicationContext

        val fitnessOptions = callToHealthTypes(call)
        val googleAccount = GoogleSignIn.getAccountForExtension(context, fitnessOptions)
        Fitness.getConfigClient(context, googleAccount).disableFit().continueWith {
            val signinOption =
                GoogleSignInOptions.Builder(
                    GoogleSignInOptions
                        .DEFAULT_SIGN_IN
                )
                    .requestId()
                    .requestEmail()
                    .build()
            val googleSignInClient = GoogleSignIn.getClient(context, signinOption)
            googleSignInClient.signOut()
            result.success(true)
        }
    }

    private fun getActivityType(type: String): String {
        return workoutTypeMap[type] ?: FitnessActivities.UNKNOWN
    }

    /** Handle calls from the MethodChannel */
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "installHealthConnect" -> installHealthConnect(call, result)
            "useHealthConnectIfAvailable" -> useHealthConnectIfAvailable(call, result)
            "getHealthConnectSdkStatus" -> getHealthConnectSdkStatus(call, result)
            "hasPermissions" -> hasPermissions(call, result)
            "requestAuthorization" -> requestAuthorization(call, result)
            "revokePermissions" -> revokePermissions(call, result)
            "getData" -> getData(call, result)
            "getIntervalData" -> getIntervalData(call, result)
            "writeData" -> writeData(call, result)
            "delete" -> delete(call, result)
            "getAggregateData" -> getAggregateData(call, result)
            "getTotalStepsInInterval" -> getTotalStepsInInterval(call, result)
            "writeWorkoutData" -> writeWorkoutData(call, result)
            "writeBloodPressure" -> writeBloodPressure(call, result)
            "writeBloodOxygen" -> writeBloodOxygen(call, result)
            "writeMeal" -> writeMeal(call, result)
            "disconnect" -> disconnect(call, result)
            "doseStepSensorIsAvailable" -> doseStepSensorIsAvailable(call, result)
            "isStepSensorRunning" -> isStepSensorRunning(call, result)
            "startStepSensorBackgroundService" -> startStepSensorBackgroundService(call, result)
            "stopStepSensorBackgroundService" -> stopStepSensorBackgroundService(call, result)
            else -> result.notImplemented()
        }
    }

    private fun isStepSensorRunning(call: MethodCall, result: Result) {
        result.success(StepCounterService.isRunning())
    }

    private fun stopStepSensorBackgroundService(call: MethodCall, result: Result) {
        val serviceIntent = Intent(activity!!, StepCounterService::class.java)
        activity!!.stopService(serviceIntent)
    }

    private fun startStepSensorBackgroundService(call: MethodCall, result: Result) {
        if (ContextCompat.checkSelfPermission(activity!!, Manifest.permission.ACTIVITY_RECOGNITION)
            != PackageManager.PERMISSION_GRANTED) {
            mResult = result
            activityRecognitionPermissionLauncher!!.launch(arrayOf(Manifest.permission.ACTIVITY_RECOGNITION,Manifest.permission.POST_NOTIFICATIONS))
            return
        }

        startStepSenor()
        result.success(true)
    }

    private fun startStepSenor() {
        val serviceIntent = Intent(activity!!, StepCounterService::class.java)
        activity!!.startForegroundService(serviceIntent)
    }

    private fun doseStepSensorIsAvailable(call: MethodCall, result: Result) {
        val sensorManager = context?.getSystemService(Service.SENSOR_SERVICE) as SensorManager
        result.success(sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        if (channel == null) {
            return
        }
        binding.addActivityResultListener(this)
        activity = binding.activity

        val requestPermissionActivityContract =
            PermissionController.createRequestPermissionResultContract()

        healthConnectRequestPermissionsLauncher =
            (activity as ComponentActivity).registerForActivityResult(
                requestPermissionActivityContract
            ) { granted -> onHealthConnectPermissionCallback(granted) }

        activityRecognitionPermissionLauncher =
            (activity as ComponentActivity).registerForActivityResult(
                ActivityResultContracts.RequestMultiplePermissions()
            ) { granted ->
                if(granted.size == 2) {
                    startStepSenor()
                }
                mResult?.success(granted)
            }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        if (channel == null) {
            return
        }
        activity = null
        healthConnectRequestPermissionsLauncher = null
    }

    /** HEALTH CONNECT BELOW */
    var healthConnectAvailable = false
    var healthConnectStatus = HealthConnectClient.SDK_UNAVAILABLE

    fun checkAvailability() {
        healthConnectStatus = HealthConnectClient.getSdkStatus(context!!)
        healthConnectAvailable = healthConnectStatus == HealthConnectClient.SDK_AVAILABLE
    }

    private fun installHealthConnect(call: MethodCall, result: Result) {
        val uriString =
            "market://details?id=com.google.android.apps.healthdata&url=healthconnect%3A%2F%2Fonboarding"
        context!!.startActivity(
            Intent(Intent.ACTION_VIEW).apply {
                setPackage("com.android.vending")
                data = Uri.parse(uriString)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("overlay", true)
                putExtra("callerId", context!!.packageName)
            }
        )
        result.success(null)
    }

    fun useHealthConnectIfAvailable(call: MethodCall, result: Result) {
        useHealthConnectIfAvailable = true
        result.success(null)
    }

    private fun getHealthConnectSdkStatus(call: MethodCall, result: Result) {
        checkAvailability()
        if (healthConnectAvailable) {
            healthConnectClient =
                HealthConnectClient.getOrCreate(
                    context!!
                )
        }
        result.success(healthConnectStatus)
    }

    private fun hasPermissionsHC(call: MethodCall, result: Result) {
        val args = call.arguments as HashMap<*, *>
        val types = (args["types"] as? ArrayList<*>)?.filterIsInstance<String>()!!
        val permissions = (args["permissions"] as? ArrayList<*>)?.filterIsInstance<Int>()!!

        var permList = mutableListOf<String>()
        for ((i, typeKey) in types.withIndex()) {
            if (!MapToHCType.containsKey(typeKey)) {
                Log.w(
                    "FLUTTER_HEALTH::ERROR",
                    "Datatype " + typeKey + " not found in HC"
                )
                result.success(false)
                return
            }
            val access = permissions[i]
            val dataType = MapToHCType[typeKey]!!
            if (access == 0) {
                permList.add(
                    HealthPermission.getReadPermission(dataType),
                )
            } else {
                permList.addAll(
                    listOf(
                        HealthPermission.getReadPermission(
                            dataType
                        ),
                        HealthPermission.getWritePermission(
                            dataType
                        ),
                    ),
                )
            }
            // Workout also needs distance and total energy burned too
            if (typeKey == WORKOUT) {
                if (access == 0) {
                    permList.addAll(
                        listOf(
                            HealthPermission.getReadPermission(
                                DistanceRecord::class
                            ),
                            HealthPermission.getReadPermission(
                                TotalCaloriesBurnedRecord::class
                            ),
                        ),
                    )
                } else {
                    permList.addAll(
                        listOf(
                            HealthPermission.getReadPermission(
                                DistanceRecord::class
                            ),
                            HealthPermission.getReadPermission(
                                TotalCaloriesBurnedRecord::class
                            ),
                            HealthPermission.getWritePermission(
                                DistanceRecord::class
                            ),
                            HealthPermission.getWritePermission(
                                TotalCaloriesBurnedRecord::class
                            ),
                        ),
                    )
                }
            }
        }
        scope.launch {
            result.success(
                healthConnectClient
                    .permissionController
                    .getGrantedPermissions()
                    .containsAll(permList),
            )
        }
    }

    private fun requestAuthorizationHC(call: MethodCall, result: Result) {
        val args = call.arguments as HashMap<*, *>
        val types = (args["types"] as? ArrayList<*>)?.filterIsInstance<String>()!!
        val permissions = (args["permissions"] as? ArrayList<*>)?.filterIsInstance<Int>()!!

        var permList = mutableListOf<String>()
        for ((i, typeKey) in types.withIndex()) {
            if (!MapToHCType.containsKey(typeKey)) {
                Log.w(
                    "FLUTTER_HEALTH::ERROR",
                    "Datatype " + typeKey + " not found in HC"
                )
                result.success(false)
                return
            }
            val access = permissions[i]!!
            val dataType = MapToHCType[typeKey]!!
            if (access == 0) {
                permList.add(
                    HealthPermission.getReadPermission(dataType),
                )
            } else {
                permList.addAll(
                    listOf(
                        HealthPermission.getReadPermission(
                            dataType
                        ),
                        HealthPermission.getWritePermission(
                            dataType
                        ),
                    ),
                )
            }
            // Workout also needs distance and total energy burned too
            if (typeKey == WORKOUT) {
                if (access == 0) {
                    permList.addAll(
                        listOf(
                            HealthPermission.getReadPermission(
                                DistanceRecord::class
                            ),
                            HealthPermission.getReadPermission(
                                TotalCaloriesBurnedRecord::class
                            ),
                        ),
                    )
                } else {
                    permList.addAll(
                        listOf(
                            HealthPermission.getReadPermission(
                                DistanceRecord::class
                            ),
                            HealthPermission.getReadPermission(
                                TotalCaloriesBurnedRecord::class
                            ),
                            HealthPermission.getWritePermission(
                                DistanceRecord::class
                            ),
                            HealthPermission.getWritePermission(
                                TotalCaloriesBurnedRecord::class
                            ),
                        ),
                    )
                }
            }
        }
        if (healthConnectRequestPermissionsLauncher == null) {
            result.success(false)
            Log.i("FLUTTER_HEALTH", "Permission launcher not found")
            return
        }

        healthConnectRequestPermissionsLauncher!!.launch(permList.toSet())
    }

    fun getHCData(call: MethodCall, result: Result) {
        val dataType = call.argument<String>("dataTypeKey")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        val healthConnectData = mutableListOf<Map<String, Any?>>()

        scope.launch {
            MapToHCType[dataType]?.let { classType ->
                val records = mutableListOf<Record>()

                val granted = healthConnectClient.permissionController.getGrantedPermissions()
                if(!granted.contains(HealthPermission.getReadPermission(classType))) {
                    Log.d("Health Plugin", "No Permission granted for $dataType")
                    return@let
                }

                // Set up the initial request to read health records with specified
                // parameters
                var request =
                    ReadRecordsRequest(
                        recordType = classType,
                        // Define the maximum amount of data
                        // that HealthConnect can return
                        // in a single request
                        timeRangeFilter =
                        TimeRangeFilter.between(
                            startTime,
                            endTime
                        ),
                    )

                var response = healthConnectClient.readRecords(request)
                var pageToken = response.pageToken

                // Add the records from the initial response to the records list
                records.addAll(response.records)

                // Continue making requests and fetching records while there is a
                // page token
                while (!pageToken.isNullOrEmpty()) {
                    request =
                        ReadRecordsRequest(
                            recordType = classType,
                            timeRangeFilter =
                            TimeRangeFilter.between(
                                startTime,
                                endTime
                            ),
                            pageToken = pageToken
                        )
                    response = healthConnectClient.readRecords(request)

                    pageToken = response.pageToken
                    records.addAll(response.records)
                }

                // Workout needs distance and total calories burned too
                if (dataType == WORKOUT) {
                    for (rec in records) {
                        val record = rec as ExerciseSessionRecord
                        val distanceRequest =
                            healthConnectClient.readRecords(
                                ReadRecordsRequest(
                                    recordType =
                                    DistanceRecord::class,
                                    timeRangeFilter =
                                    TimeRangeFilter.between(
                                        record.startTime,
                                        record.endTime,
                                    ),
                                ),
                            )
                        var totalDistance = 0.0
                        for (distanceRec in distanceRequest.records) {
                            totalDistance +=
                                distanceRec.distance
                                    .inMeters
                        }

                        val energyBurnedRequest =
                            healthConnectClient.readRecords(
                                ReadRecordsRequest(
                                    recordType =
                                    TotalCaloriesBurnedRecord::class,
                                    timeRangeFilter =
                                    TimeRangeFilter.between(
                                        record.startTime,
                                        record.endTime,
                                    ),
                                ),
                            )
                        var totalEnergyBurned = 0.0
                        for (energyBurnedRec in
                        energyBurnedRequest.records) {
                            totalEnergyBurned +=
                                energyBurnedRec.energy
                                    .inKilocalories
                        }

                        val stepRequest =
                            healthConnectClient.readRecords(
                                ReadRecordsRequest(
                                    recordType =
                                    StepsRecord::class,
                                    timeRangeFilter =
                                    TimeRangeFilter.between(
                                        record.startTime,
                                        record.endTime
                                    ),
                                ),
                            )
                        var totalSteps = 0.0
                        for (stepRec in stepRequest.records) {
                            totalSteps += stepRec.count
                        }

                        // val metadata = (rec as Record).metadata
                        // Add final datapoint
                        healthConnectData.add(
                            // mapOf(
                            mapOf<String, Any?>(
                                "workoutActivityType" to
                                        (workoutTypeMapHealthConnect
                                            .filterValues {
                                                it ==
                                                        record.exerciseType
                                            }
                                            .keys
                                            .firstOrNull()
                                            ?: "OTHER"),
                                "totalDistance" to
                                        if (totalDistance ==
                                            0.0
                                        )
                                            null
                                        else
                                            totalDistance,
                                "totalDistanceUnit" to
                                        "METER",
                                "totalEnergyBurned" to
                                        if (totalEnergyBurned ==
                                            0.0
                                        )
                                            null
                                        else
                                            totalEnergyBurned,
                                "totalEnergyBurnedUnit" to
                                        "KILOCALORIE",
                                "totalSteps" to
                                        if (totalSteps ==
                                            0.0
                                        )
                                            null
                                        else
                                            totalSteps,
                                "totalStepsUnit" to
                                        "COUNT",
                                "unit" to "MINUTES",
                                "date_from" to
                                        rec.startTime
                                            .toEpochMilli(),
                                "date_to" to
                                        rec.endTime.toEpochMilli(),
                                "source_id" to "",
                                "source_name" to
                                        record.metadata
                                            .dataOrigin
                                            .packageName,
                            ),
                        )
                    }
                    // Filter sleep stages for requested stage
                } else if (classType == SleepSessionRecord::class) {
                    for (rec in response.records) {
                        if (rec is SleepSessionRecord) {
                            if (dataType == SLEEP_SESSION) {
                                healthConnectData.addAll(
                                    convertRecord(
                                        rec,
                                        dataType
                                    )
                                )
                            } else {
                                for (recStage in rec.stages) {
                                    if (dataType ==
                                        MapSleepStageToType[
                                            recStage.stage]
                                    ) {
                                        healthConnectData
                                            .addAll(
                                                convertRecordStage(
                                                    recStage,
                                                    dataType,
                                                    rec.metadata.dataOrigin
                                                        .packageName
                                                )
                                            )
                                    }
                                }
                            }
                        }
                    }
                } else {
                    for (rec in records) {
                        healthConnectData.addAll(
                            convertRecord(rec, dataType)
                        )
                    }
                }
            }

            Handler(context!!.mainLooper).run { result.success(healthConnectData) }
        }
    }

    fun convertRecordStage(
        stage: SleepSessionRecord.Stage,
        dataType: String,
        sourceName: String
    ): List<Map<String, Any>> {
        return listOf(
            mapOf<String, Any>(
                "stage" to stage.stage,
                "value" to
                        ChronoUnit.MINUTES.between(
                            stage.startTime,
                            stage.endTime
                        ),
                "date_from" to stage.startTime.toEpochMilli(),
                "date_to" to stage.endTime.toEpochMilli(),
                "source_id" to "",
                "source_name" to sourceName,
            ),
        )
    }

    fun getAggregateHCData(call: MethodCall, result: Result) {
        val dataType = call.argument<String>("dataTypeKey")!!
        val interval = call.argument<Long>("interval")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        val healthConnectData = mutableListOf<Map<String, Any?>>()
        scope.launch {
            MapToHCAggregateMetric[dataType]?.let { metricClassType ->
                val request =
                    AggregateGroupByDurationRequest(
                        metrics = setOf(metricClassType),
                        timeRangeFilter =
                        TimeRangeFilter.between(
                            startTime,
                            endTime
                        ),
                        timeRangeSlicer =
                        Duration.ofSeconds(
                            interval
                        )
                    )
                val response = healthConnectClient.aggregateGroupByDuration(request)

                for (durationResult in response) {
                    // The result may be null if no data is available in the
                    // time range
                    var totalValue = durationResult.result[metricClassType]
                    if (totalValue is Length) {
                        totalValue = totalValue.inMeters
                    } else if (totalValue is Energy) {
                        totalValue = totalValue.inKilocalories
                    }

                    val packageNames =
                        durationResult.result.dataOrigins
                            .joinToString { origin ->
                                "${origin.packageName}"
                            }

                    val data =
                        mapOf<String, Any>(
                            "value" to
                                    (totalValue
                                        ?: 0),
                            "date_from" to
                                    durationResult.startTime
                                        .toEpochMilli(),
                            "date_to" to
                                    durationResult.endTime
                                        .toEpochMilli(),
                            "source_name" to
                                    packageNames,
                            "source_id" to "",
                            "is_manual_entry" to
                                    packageNames.contains(
                                        "user_input"
                                    )
                        )
                    healthConnectData.add(data)
                }
            }
            Handler(context!!.mainLooper).run { result.success(healthConnectData) }
        }
    }

    // TODO: Find alternative to SOURCE_ID or make it nullable?
    fun convertRecord(record: Any, dataType: String): List<Map<String, Any>> {
        val metadata = (record as Record).metadata
        when (record) {
            is WeightRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.weight
                                    .inKilograms,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is HeightRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.height
                                    .inMeters,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is BodyFatRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.percentage
                                    .value,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is StepsRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to record.count,
                        "date_from" to
                                record.startTime
                                    .toEpochMilli(),
                        "date_to" to
                                record.endTime
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is ActiveCaloriesBurnedRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.energy
                                    .inKilocalories,
                        "date_from" to
                                record.startTime
                                    .toEpochMilli(),
                        "date_to" to
                                record.endTime
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is HeartRateRecord ->
                return record.samples.map {
                    mapOf<String, Any>(
                        "value" to it.beatsPerMinute,
                        "date_from" to
                                it.time.toEpochMilli(),
                        "date_to" to it.time.toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    )
                }

            is BodyTemperatureRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.temperature
                                    .inCelsius,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is BodyWaterMassRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.mass
                                    .inKilograms,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is BloodPressureRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                if (dataType ==
                                    BLOOD_PRESSURE_DIASTOLIC
                                )
                                    record.diastolic
                                        .inMillimetersOfMercury
                                else
                                    record.systolic
                                        .inMillimetersOfMercury,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is OxygenSaturationRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.percentage
                                    .value,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is BloodGlucoseRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.level
                                    .inMilligramsPerDeciliter,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is DistanceRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.distance
                                    .inMeters,
                        "date_from" to
                                record.startTime
                                    .toEpochMilli(),
                        "date_to" to
                                record.endTime
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is HydrationRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.volume
                                    .inLiters,
                        "date_from" to
                                record.startTime
                                    .toEpochMilli(),
                        "date_to" to
                                record.endTime
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is TotalCaloriesBurnedRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.energy
                                    .inKilocalories,
                        "date_from" to
                                record.startTime
                                    .toEpochMilli(),
                        "date_to" to
                                record.endTime
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is BasalMetabolicRateRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.basalMetabolicRate
                                    .inKilocaloriesPerDay,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is SleepSessionRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "date_from" to
                                record.startTime
                                    .toEpochMilli(),
                        "date_to" to
                                record.endTime
                                    .toEpochMilli(),
                        "value" to
                                ChronoUnit.MINUTES
                                    .between(
                                        record.startTime,
                                        record.endTime
                                    ),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    ),
                )

            is RestingHeartRateRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.beatsPerMinute,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    )
                )

            is BasalMetabolicRateRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to
                                record.basalMetabolicRate
                                    .inKilocaloriesPerDay,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    )
                )

            is FloorsClimbedRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to record.floors,
                        "date_from" to
                                record.startTime
                                    .toEpochMilli(),
                        "date_to" to
                                record.endTime
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    )
                )

            is RespiratoryRateRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "value" to record.rate,
                        "date_from" to
                                record.time
                                    .toEpochMilli(),
                        "date_to" to
                                record.time
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    )
                )

            is NutritionRecord ->
                return listOf(
                    mapOf<String, Any>(
                        "calories" to
                                record.energy!!.inKilocalories,
                        "protein" to
                                record.protein!!.inGrams,
                        "carbs" to
                                record.totalCarbohydrate!!
                                    .inGrams,
                        "fat" to
                                record.totalFat!!
                                    .inGrams,
                        "name" to record.name!!,
                        "mealType" to
                                (MapTypeToMealTypeHC[
                                    record.mealType]
                                    ?: MEAL_TYPE_UNKNOWN),
                        "date_from" to
                                record.startTime
                                    .toEpochMilli(),
                        "date_to" to
                                record.endTime
                                    .toEpochMilli(),
                        "source_id" to "",
                        "source_name" to
                                metadata.dataOrigin
                                    .packageName,
                    )
                )
            // is ExerciseSessionRecord -> return listOf(mapOf<String, Any>("value" to ,
            //                                             "date_from" to ,
            //                                             "date_to" to ,
            //                                             "source_id" to "",
            //                                             "source_name" to
            // metadata.dataOrigin.packageName))
            else ->
                throw IllegalArgumentException(
                    "Health data type not supported"
                ) // TODO: Exception or error?
        }
    }

    // TODO rewrite sleep to fit new update better --> compare with Apple and see if we should
    // not
    // adopt a single type with attached stages approach
    fun writeHCData(call: MethodCall, result: Result) {
        val type = call.argument<String>("dataTypeKey")!!
        val startTime = call.argument<Long>("startTime")!!
        val endTime = call.argument<Long>("endTime")!!
        val value = call.argument<Double>("value")!!
        val record =
            when (type) {
                BODY_FAT_PERCENTAGE ->
                    BodyFatRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        percentage =
                        Percentage(
                            value
                        ),
                        zoneOffset = null,
                    )

                HEIGHT ->
                    HeightRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        height =
                        Length.meters(
                            value
                        ),
                        zoneOffset = null,
                    )

                WEIGHT ->
                    WeightRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        weight =
                        Mass.kilograms(
                            value
                        ),
                        zoneOffset = null,
                    )

                STEPS ->
                    StepsRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        count = value.toLong(),
                        startZoneOffset = null,
                        endZoneOffset = null,
                    )

                ACTIVE_ENERGY_BURNED ->
                    ActiveCaloriesBurnedRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        energy =
                        Energy.kilocalories(
                            value
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                    )

                HEART_RATE ->
                    HeartRateRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        samples =
                        listOf<
                                HeartRateRecord.Sample>(
                            HeartRateRecord.Sample(
                                time =
                                Instant.ofEpochMilli(
                                    startTime
                                ),
                                beatsPerMinute =
                                value.toLong(),
                            ),
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                    )

                BODY_TEMPERATURE ->
                    BodyTemperatureRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        temperature =
                        Temperature.celsius(
                            value
                        ),
                        zoneOffset = null,
                    )

                BODY_WATER_MASS ->
                    BodyWaterMassRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        mass =
                        Mass.kilograms(
                            value
                        ),
                        zoneOffset = null,
                    )

                BLOOD_OXYGEN ->
                    OxygenSaturationRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        percentage =
                        Percentage(
                            value
                        ),
                        zoneOffset = null,
                    )

                BLOOD_GLUCOSE ->
                    BloodGlucoseRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        level =
                        BloodGlucose.milligramsPerDeciliter(
                            value
                        ),
                        zoneOffset = null,
                    )

                DISTANCE_DELTA ->
                    DistanceRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        distance =
                        Length.meters(
                            value
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                    )

                WATER ->
                    HydrationRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        volume =
                        Volume.liters(
                            value
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                    )

                SLEEP_ASLEEP ->
                    SleepSessionRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                        stages =
                        listOf(
                            SleepSessionRecord
                                .Stage(
                                    Instant.ofEpochMilli(
                                        startTime
                                    ),
                                    Instant.ofEpochMilli(
                                        endTime
                                    ),
                                    SleepSessionRecord
                                        .STAGE_TYPE_SLEEPING
                                )
                        ),
                    )

                SLEEP_LIGHT ->
                    SleepSessionRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                        stages =
                        listOf(
                            SleepSessionRecord
                                .Stage(
                                    Instant.ofEpochMilli(
                                        startTime
                                    ),
                                    Instant.ofEpochMilli(
                                        endTime
                                    ),
                                    SleepSessionRecord
                                        .STAGE_TYPE_LIGHT
                                )
                        ),
                    )

                SLEEP_DEEP ->
                    SleepSessionRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                        stages =
                        listOf(
                            SleepSessionRecord
                                .Stage(
                                    Instant.ofEpochMilli(
                                        startTime
                                    ),
                                    Instant.ofEpochMilli(
                                        endTime
                                    ),
                                    SleepSessionRecord
                                        .STAGE_TYPE_DEEP
                                )
                        ),
                    )

                SLEEP_REM ->
                    SleepSessionRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                        stages =
                        listOf(
                            SleepSessionRecord
                                .Stage(
                                    Instant.ofEpochMilli(
                                        startTime
                                    ),
                                    Instant.ofEpochMilli(
                                        endTime
                                    ),
                                    SleepSessionRecord
                                        .STAGE_TYPE_REM
                                )
                        ),
                    )

                SLEEP_OUT_OF_BED ->
                    SleepSessionRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                        stages =
                        listOf(
                            SleepSessionRecord
                                .Stage(
                                    Instant.ofEpochMilli(
                                        startTime
                                    ),
                                    Instant.ofEpochMilli(
                                        endTime
                                    ),
                                    SleepSessionRecord
                                        .STAGE_TYPE_OUT_OF_BED
                                )
                        ),
                    )

                SLEEP_AWAKE ->
                    SleepSessionRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                        stages =
                        listOf(
                            SleepSessionRecord
                                .Stage(
                                    Instant.ofEpochMilli(
                                        startTime
                                    ),
                                    Instant.ofEpochMilli(
                                        endTime
                                    ),
                                    SleepSessionRecord
                                        .STAGE_TYPE_AWAKE
                                )
                        ),
                    )

                SLEEP_SESSION ->
                    SleepSessionRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                    )

                RESTING_HEART_RATE ->
                    RestingHeartRateRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        beatsPerMinute =
                        value.toLong(),
                        zoneOffset = null,
                    )

                BASAL_ENERGY_BURNED ->
                    BasalMetabolicRateRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        basalMetabolicRate =
                        Power.kilocaloriesPerDay(
                            value
                        ),
                        zoneOffset = null,
                    )

                FLIGHTS_CLIMBED ->
                    FloorsClimbedRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        floors = value,
                        startZoneOffset = null,
                        endZoneOffset = null,
                    )

                RESPIRATORY_RATE ->
                    RespiratoryRateRecord(
                        time =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        rate = value,
                        zoneOffset = null,
                    )
                // AGGREGATE_STEP_COUNT -> StepsRecord()
                TOTAL_CALORIES_BURNED ->
                    TotalCaloriesBurnedRecord(
                        startTime =
                        Instant.ofEpochMilli(
                            startTime
                        ),
                        endTime =
                        Instant.ofEpochMilli(
                            endTime
                        ),
                        energy =
                        Energy.kilocalories(
                            value
                        ),
                        startZoneOffset = null,
                        endZoneOffset = null,
                    )

                BLOOD_PRESSURE_SYSTOLIC ->
                    throw IllegalArgumentException(
                        "You must use the [writeBloodPressure] API "
                    )

                BLOOD_PRESSURE_DIASTOLIC ->
                    throw IllegalArgumentException(
                        "You must use the [writeBloodPressure] API "
                    )

                WORKOUT ->
                    throw IllegalArgumentException(
                        "You must use the [writeWorkoutData] API "
                    )

                NUTRITION ->
                    throw IllegalArgumentException(
                        "You must use the [writeMeal] API "
                    )

                else ->
                    throw IllegalArgumentException(
                        "The type $type was not supported by the Health plugin or you must use another API "
                    )
            }
        scope.launch {
            try {
                healthConnectClient.insertRecords(listOf(record))
                result.success(true)
            } catch (e: Exception) {
                result.success(false)
            }
        }
    }

    fun writeWorkoutHCData(call: MethodCall, result: Result) {
        val type = call.argument<String>("activityType")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        val totalEnergyBurned = call.argument<Int>("totalEnergyBurned")
        val totalDistance = call.argument<Int>("totalDistance")
        if (workoutTypeMapHealthConnect.containsKey(type) == false) {
            result.success(false)
            Log.w(
                "FLUTTER_HEALTH::ERROR",
                "[Health Connect] Workout type not supported"
            )
            return
        }
        val workoutType = workoutTypeMapHealthConnect[type]!!
        val title = call.argument<String>("title") ?: type

        scope.launch {
            try {
                val list = mutableListOf<Record>()
                list.add(
                    ExerciseSessionRecord(
                        startTime = startTime,
                        startZoneOffset = null,
                        endTime = endTime,
                        endZoneOffset = null,
                        exerciseType = workoutType,
                        title = title,
                    ),
                )
                if (totalDistance != null) {
                    list.add(
                        DistanceRecord(
                            startTime = startTime,
                            startZoneOffset = null,
                            endTime = endTime,
                            endZoneOffset = null,
                            distance =
                            Length.meters(
                                totalDistance.toDouble()
                            ),
                        ),
                    )
                }
                if (totalEnergyBurned != null) {
                    list.add(
                        TotalCaloriesBurnedRecord(
                            startTime = startTime,
                            startZoneOffset = null,
                            endTime = endTime,
                            endZoneOffset = null,
                            energy =
                            Energy.kilocalories(
                                totalEnergyBurned
                                    .toDouble()
                            ),
                        ),
                    )
                }
                healthConnectClient.insertRecords(
                    list,
                )
                result.success(true)
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "[Health Connect] Workout was successfully added!"
                )
            } catch (e: Exception) {
                Log.w(
                    "FLUTTER_HEALTH::ERROR",
                    "[Health Connect] There was an error adding the workout",
                )
                Log.w("FLUTTER_HEALTH::ERROR", e.message ?: "unknown error")
                Log.w("FLUTTER_HEALTH::ERROR", e.stackTrace.toString())
                result.success(false)
            }
        }
    }

    fun writeBloodPressureHC(call: MethodCall, result: Result) {
        val systolic = call.argument<Double>("systolic")!!
        val diastolic = call.argument<Double>("diastolic")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)

        scope.launch {
            try {
                healthConnectClient.insertRecords(
                    listOf(
                        BloodPressureRecord(
                            time = startTime,
                            systolic =
                            Pressure.millimetersOfMercury(
                                systolic
                            ),
                            diastolic =
                            Pressure.millimetersOfMercury(
                                diastolic
                            ),
                            zoneOffset = null,
                        ),
                    ),
                )
                result.success(true)
                Log.i(
                    "FLUTTER_HEALTH::SUCCESS",
                    "[Health Connect] Blood pressure was successfully added!",
                )
            } catch (e: Exception) {
                Log.w(
                    "FLUTTER_HEALTH::ERROR",
                    "[Health Connect] There was an error adding the blood pressure",
                )
                Log.w("FLUTTER_HEALTH::ERROR", e.message ?: "unknown error")
                Log.w("FLUTTER_HEALTH::ERROR", e.stackTrace.toString())
                result.success(false)
            }
        }
    }

    fun deleteHCData(call: MethodCall, result: Result) {
        val type = call.argument<String>("dataTypeKey")!!
        val startTime = Instant.ofEpochMilli(call.argument<Long>("startTime")!!)
        val endTime = Instant.ofEpochMilli(call.argument<Long>("endTime")!!)
        if (!MapToHCType.containsKey(type)) {
            Log.w("FLUTTER_HEALTH::ERROR", "Datatype " + type + " not found in HC")
            result.success(false)
            return
        }
        val classType = MapToHCType[type]!!

        scope.launch {
            try {
                healthConnectClient.deleteRecords(
                    recordType = classType,
                    timeRangeFilter =
                    TimeRangeFilter.between(
                        startTime,
                        endTime
                    ),
                )
                result.success(true)
            } catch (e: Exception) {
                result.success(false)
            }
        }
    }

    val MapSleepStageToType =
        hashMapOf<Int, String>(
            1 to SLEEP_AWAKE,
            2 to SLEEP_ASLEEP,
            3 to SLEEP_OUT_OF_BED,
            4 to SLEEP_LIGHT,
            5 to SLEEP_DEEP,
            6 to SLEEP_REM,
        )

    private val MapMealTypeToTypeHC =
        hashMapOf<String, Int>(
            BREAKFAST to MEAL_TYPE_BREAKFAST,
            LUNCH to MEAL_TYPE_LUNCH,
            DINNER to MEAL_TYPE_DINNER,
            SNACK to MEAL_TYPE_SNACK,
            MEAL_UNKNOWN to MEAL_TYPE_UNKNOWN,
        )

    private val MapTypeToMealTypeHC =
        hashMapOf<Int, String>(
            MEAL_TYPE_BREAKFAST to BREAKFAST,
            MEAL_TYPE_LUNCH to LUNCH,
            MEAL_TYPE_DINNER to DINNER,
            MEAL_TYPE_SNACK to SNACK,
            MEAL_TYPE_UNKNOWN to MEAL_UNKNOWN,
        )

    private val MapMealTypeToType =
        hashMapOf<String, Int>(
            BREAKFAST to Field.MEAL_TYPE_BREAKFAST,
            LUNCH to Field.MEAL_TYPE_LUNCH,
            DINNER to Field.MEAL_TYPE_DINNER,
            SNACK to Field.MEAL_TYPE_SNACK,
            MEAL_UNKNOWN to Field.MEAL_TYPE_UNKNOWN,
        )

    val MapToHCType =
        hashMapOf(
            BODY_FAT_PERCENTAGE to BodyFatRecord::class,
            HEIGHT to HeightRecord::class,
            WEIGHT to WeightRecord::class,
            STEPS to StepsRecord::class,
            AGGREGATE_STEP_COUNT to StepsRecord::class,
            ACTIVE_ENERGY_BURNED to ActiveCaloriesBurnedRecord::class,
            HEART_RATE to HeartRateRecord::class,
            BODY_TEMPERATURE to BodyTemperatureRecord::class,
            BODY_WATER_MASS to BodyWaterMassRecord::class,
            BLOOD_PRESSURE_SYSTOLIC to BloodPressureRecord::class,
            BLOOD_PRESSURE_DIASTOLIC to BloodPressureRecord::class,
            BLOOD_OXYGEN to OxygenSaturationRecord::class,
            BLOOD_GLUCOSE to BloodGlucoseRecord::class,
            DISTANCE_DELTA to DistanceRecord::class,
            WATER to HydrationRecord::class,
            SLEEP_ASLEEP to SleepSessionRecord::class,
            SLEEP_AWAKE to SleepSessionRecord::class,
            SLEEP_LIGHT to SleepSessionRecord::class,
            SLEEP_DEEP to SleepSessionRecord::class,
            SLEEP_REM to SleepSessionRecord::class,
            SLEEP_OUT_OF_BED to SleepSessionRecord::class,
            SLEEP_SESSION to SleepSessionRecord::class,
            WORKOUT to ExerciseSessionRecord::class,
            NUTRITION to NutritionRecord::class,
            RESTING_HEART_RATE to RestingHeartRateRecord::class,
            BASAL_ENERGY_BURNED to BasalMetabolicRateRecord::class,
            FLIGHTS_CLIMBED to FloorsClimbedRecord::class,
            RESPIRATORY_RATE to RespiratoryRateRecord::class,
            TOTAL_CALORIES_BURNED to TotalCaloriesBurnedRecord::class
            // MOVE_MINUTES to TODO: Find alternative?
            // TODO: Implement remaining types
            // "ActiveCaloriesBurned" to
            // ActiveCaloriesBurnedRecord::class,
            // "BasalBodyTemperature" to
            // BasalBodyTemperatureRecord::class,
            // "BasalMetabolicRate" to BasalMetabolicRateRecord::class,
            // "BloodGlucose" to BloodGlucoseRecord::class,
            // "BloodPressure" to BloodPressureRecord::class,
            // "BodyFat" to BodyFatRecord::class,
            // "BodyTemperature" to BodyTemperatureRecord::class,
            // "BoneMass" to BoneMassRecord::class,
            // "CervicalMucus" to CervicalMucusRecord::class,
            // "CyclingPedalingCadence" to
            // CyclingPedalingCadenceRecord::class,
            // "Distance" to DistanceRecord::class,
            // "ElevationGained" to ElevationGainedRecord::class,
            // "ExerciseSession" to ExerciseSessionRecord::class,
            // "FloorsClimbed" to FloorsClimbedRecord::class,
            // "HeartRate" to HeartRateRecord::class,
            // "Height" to HeightRecord::class,
            // "Hydration" to HydrationRecord::class,
            // "LeanBodyMass" to LeanBodyMassRecord::class,
            // "MenstruationFlow" to MenstruationFlowRecord::class,
            // "MenstruationPeriod" to MenstruationPeriodRecord::class,
            // "Nutrition" to NutritionRecord::class,
            // "OvulationTest" to OvulationTestRecord::class,
            // "OxygenSaturation" to OxygenSaturationRecord::class,
            // "Power" to PowerRecord::class,
            // "RespiratoryRate" to RespiratoryRateRecord::class,
            // "RestingHeartRate" to RestingHeartRateRecord::class,
            // "SexualActivity" to SexualActivityRecord::class,
            // "SleepSession" to SleepSessionRecord::class,
            // "SleepStage" to SleepStageRecord::class,
            // "Speed" to SpeedRecord::class,
            // "StepsCadence" to StepsCadenceRecord::class,
            // "Steps" to StepsRecord::class,
            // "TotalCaloriesBurned" to
            // TotalCaloriesBurnedRecord::class,
            // "Vo2Max" to Vo2MaxRecord::class,
            // "Weight" to WeightRecord::class,
            // "WheelchairPushes" to WheelchairPushesRecord::class,
        )

    val MapToHCAggregateMetric =
        hashMapOf(
            HEIGHT to HeightRecord.HEIGHT_AVG,
            WEIGHT to WeightRecord.WEIGHT_AVG,
            STEPS to StepsRecord.COUNT_TOTAL,
            AGGREGATE_STEP_COUNT to StepsRecord.COUNT_TOTAL,
            ACTIVE_ENERGY_BURNED to
                    ActiveCaloriesBurnedRecord
                        .ACTIVE_CALORIES_TOTAL,
            HEART_RATE to HeartRateRecord.MEASUREMENTS_COUNT,
            DISTANCE_DELTA to DistanceRecord.DISTANCE_TOTAL,
            WATER to HydrationRecord.VOLUME_TOTAL,
            SLEEP_ASLEEP to SleepSessionRecord.SLEEP_DURATION_TOTAL,
            SLEEP_AWAKE to SleepSessionRecord.SLEEP_DURATION_TOTAL,
            SLEEP_IN_BED to SleepSessionRecord.SLEEP_DURATION_TOTAL,
            TOTAL_CALORIES_BURNED to
                    TotalCaloriesBurnedRecord.ENERGY_TOTAL
        )
}
