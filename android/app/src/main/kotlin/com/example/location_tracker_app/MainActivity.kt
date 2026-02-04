package com.location_tracker_app

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        private const val CHANNEL = "location_tracking"
        private const val PERMISSION_REQUEST_CODE = 123
    }

    private var pendingResult: MethodChannel.Result? = null
    private var locationService: LocationTrackingService? = null
    private var isServiceBound = false
    private var methodChannel: MethodChannel? = null

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as LocationTrackingService.LocationBinder
            locationService = binder.getService()
            locationService?.setMethodChannel(methodChannel)
            isServiceBound = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            isServiceBound = false
            locationService = null
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            onMethodCall(call, result)
        }
        
        // Bind to the service
        val serviceIntent = Intent(this, LocationTrackingService::class.java)
        bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestLocationPermission" -> requestLocationPermission(result)
            "requestBackgroundPermission" -> requestBackgroundPermission(result)
            "startLocationTracking" -> {
                val intervalSeconds = call.argument<Int>("intervalSeconds") ?: 60
                startLocationTracking(intervalSeconds, result)
            }
            "stopLocationTracking" -> stopLocationTracking(result)
            "updateInterval" -> {
                val newInterval = call.argument<Int>("intervalSeconds") ?: 60
                updateInterval(newInterval, result)
            }
            "getCurrentLocation" -> getCurrentLocation(result)
            else -> result.notImplemented()
        }
    }

    private fun requestLocationPermission(result: MethodChannel.Result) {
        android.util.Log.d("LocationTracking", "📍 Requesting location permissions")
        pendingResult = result
        
        if (hasLocationPermissions()) {
            android.util.Log.d("LocationTracking", "✅ Location permissions already granted")
            result.success(true)
            return
        }

        val permissions = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )

        android.util.Log.d("LocationTracking", "📍 Showing permission dialog...")
        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
    }

    private fun requestBackgroundPermission(result: MethodChannel.Result) {
        android.util.Log.d("LocationTracking", "📍 Requesting background location permissions")
        pendingResult = result
        
        if (hasLocationPermissions()) {
            android.util.Log.d("LocationTracking", "✅ All location permissions already granted")
            result.success(true)
            return
        }

        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            android.util.Log.d("LocationTracking", "📍 Android 10+: Requesting fine, coarse, and background location")
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            )
        } else {
            android.util.Log.d("LocationTracking", "📍 Android 9-: Requesting fine and coarse location")
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        }

        android.util.Log.d("LocationTracking", "📍 Showing permission dialog...")
        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
    }

    private fun hasLocationPermissions(): Boolean {
        val fineLocation = ContextCompat.checkSelfPermission(this, 
            Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarseLocation = ContextCompat.checkSelfPermission(this, 
            Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        
        val backgroundLocation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(this, 
                Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        
        return fineLocation && coarseLocation && backgroundLocation
    }

    private fun startLocationTracking(intervalSeconds: Int, result: MethodChannel.Result) {
        android.util.Log.d("LocationTracking", "📍 Starting location tracking with ${intervalSeconds}s interval")
        
        // Check if permissions are granted
        if (!hasLocationPermissions()) {
            android.util.Log.w("LocationTracking", "⚠️ Location permissions not granted, requesting...")
            // Request permissions first
            pendingResult = result
            requestBackgroundPermission(result)
            return
        }

        if (!isServiceBound || locationService == null) {
            android.util.Log.e("LocationTracking", "❌ Location service not bound or unavailable")
            result.success(false)
            return
        }

        android.util.Log.d("LocationTracking", "✅ Permissions granted, starting tracking service")
        val started = locationService!!.startTracking((intervalSeconds * 1000).toLong())
        android.util.Log.d("LocationTracking", "📍 Tracking started: $started")
        result.success(started)
    }

    private fun stopLocationTracking(result: MethodChannel.Result) {
        if (!isServiceBound || locationService == null) {
            result.success(false)
            return
        }

        val stopped = locationService!!.stopTracking()
        result.success(stopped)
    }

    private fun updateInterval(intervalSeconds: Int, result: MethodChannel.Result) {
        if (!isServiceBound || locationService == null) {
            result.success(false)
            return
        }

        locationService!!.updateInterval((intervalSeconds * 1000).toLong())
        result.success(true)
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        // Only check for basic location permissions, not background
        val hasFineLocation = ContextCompat.checkSelfPermission(this, 
            Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarseLocation = ContextCompat.checkSelfPermission(this, 
            Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        
        if (!hasFineLocation && !hasCoarseLocation) {
            android.util.Log.e("LocationTracking", "❌ No location permissions for getCurrentLocation")
            result.error("PERMISSION_DENIED", "Location permissions not granted", null)
            return
        }

        if (!isServiceBound || locationService == null) {
            android.util.Log.e("LocationTracking", "❌ Service not available for getCurrentLocation")
            result.error("SERVICE_UNAVAILABLE", "Location service not available", null)
            return
        }

        android.util.Log.d("LocationTracking", "✅ Getting current location...")
        locationService!!.getCurrentLocation(result)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE && pendingResult != null) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            
            android.util.Log.d("LocationTracking", "📍 Permission result: allGranted=$allGranted")
            permissions.forEachIndexed { index, permission ->
                val granted = if (index < grantResults.size) grantResults[index] == PackageManager.PERMISSION_GRANTED else false
                android.util.Log.d("LocationTracking", "  - $permission: ${if (granted) "✅ GRANTED" else "❌ DENIED"}")
            }
            
            if (!allGranted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                android.util.Log.w("LocationTracking", "⚠️ Not all permissions granted, opening app settings")
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", packageName, null)
                }
                startActivity(intent)
            }
            
            pendingResult?.success(allGranted)
            pendingResult = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isServiceBound) {
            unbindService(serviceConnection)
            isServiceBound = false
        }
    }
}