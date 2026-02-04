package com.location_tracker_app

import android.app.*
import android.content.Intent
import android.location.Location
import android.os.*
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import io.flutter.plugin.common.MethodChannel

class LocationTrackingService : Service() {
    companion object {
        private const val CHANNEL_ID = "LocationTrackingChannel"
        private const val NOTIFICATION_ID = 1
    }
    
    private val binder = LocationBinder()
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var locationCallback: LocationCallback? = null
    private var isTracking = false
    private var intervalMs: Long = 60000 // Default 1 minute
    private var methodChannel: MethodChannel? = null

    inner class LocationBinder : Binder() {
        fun getService(): LocationTrackingService = this@LocationTrackingService
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
        setupLocationCallback()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder = binder

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracks employee location in background"
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun setupLocationCallback() {
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    sendLocationToFlutter(location.latitude, location.longitude)
                }
            }
        }
    }

    fun startTracking(intervalMs: Long): Boolean {
        if (isTracking) return true
        
        this.intervalMs = intervalMs
        
        return try {
            startForegroundService()
            
            val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, intervalMs)
                .setWaitForAccurateLocation(false)
                .setMinUpdateIntervalMillis(intervalMs / 2)
                .setMaxUpdateDelayMillis(intervalMs)
                .build()

            locationCallback?.let { callback ->
                fusedLocationClient.requestLocationUpdates(
                    locationRequest,
                    callback,
                    Looper.getMainLooper()
                )
            }
            
            isTracking = true
            true
        } catch (e: SecurityException) {
            e.printStackTrace()
            sendErrorToFlutter("Location permission denied: ${e.message}")
            false
        } catch (e: Exception) {
            e.printStackTrace()
            sendErrorToFlutter("Failed to start tracking: ${e.message}")
            false
        }
    }

    fun stopTracking(): Boolean {
        if (!isTracking) return true
        
        return try {
            locationCallback?.let { fusedLocationClient.removeLocationUpdates(it) }
            isTracking = false
            stopForeground(true)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            sendErrorToFlutter("Failed to stop tracking: ${e.message}")
            false
        }
    }

    fun updateInterval(intervalMs: Long) {
        this.intervalMs = intervalMs
        if (isTracking) {
            stopTracking()
            startTracking(intervalMs)
        }
    }

    fun getCurrentLocation(result: MethodChannel.Result) {
        try {
            val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 0)
                .setMaxUpdates(1)
                .build()

            val singleLocationCallback = object : LocationCallback() {
                override fun onLocationResult(locationResult: LocationResult) {
                    locationResult.lastLocation?.let { location ->
                        val locationData = mapOf(
                            "latitude" to location.latitude,
                            "longitude" to location.longitude
                        )
                        result.success(locationData)
                    } ?: result.error("NO_LOCATION", "Unable to get location", null)
                    
                    fusedLocationClient.removeLocationUpdates(this)
                }
            }

            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                singleLocationCallback,
                Looper.getMainLooper()
            )
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", "Location permission denied", e.message)
        } catch (e: Exception) {
            result.error("LOCATION_ERROR", "Failed to get location", e.message)
        }
    }

    private fun startForegroundService() {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) 
                PendingIntent.FLAG_IMMUTABLE else 0
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Employee Location Tracking")
            .setContentText("Tracking your location for attendance")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun sendLocationToFlutter(latitude: Double, longitude: Double) {
        try {
            methodChannel?.let { channel ->
                val arguments = mapOf(
                    "latitude" to latitude,
                    "longitude" to longitude
                )
                
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod("onLocationUpdate", arguments)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun sendErrorToFlutter(error: String) {
        try {
            methodChannel?.let { channel ->
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod("onTrackingError", error)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun setMethodChannel(channel: MethodChannel?) {
        this.methodChannel = channel
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isTracking) {
            stopTracking()
        }
    }
}