package cachet.plugins.health

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

class HealthPermissionChecker(private val context: Context) {
    
    fun isLocationPermissionGranted(): Boolean {
        val fineLocationGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val coarseLocationGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        return fineLocationGranted || coarseLocationGranted
    }

    fun isHealthDistancePermissionGranted(): Boolean {
        val healthDistancePermission = "android.permission.health.READ_DISTANCE"
        return ContextCompat.checkSelfPermission(
            context,
            healthDistancePermission
        ) == PackageManager.PERMISSION_GRANTED
    }

    fun isHealthTotalCaloriesBurnedPermissionGranted(): Boolean {
        val healthCaloriesPermission = "android.permission.health.READ_TOTAL_CALORIES_BURNED"
        return ContextCompat.checkSelfPermission(
            context,
            healthCaloriesPermission
        ) == PackageManager.PERMISSION_GRANTED
    }
}