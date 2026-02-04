import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    // Firebase and notification properties (existing)
    
    // Location tracking properties (new)
    private var locationManager: CLLocationManager?
    private var methodChannel: FlutterMethodChannel?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var locationTimer: Timer?
    private var trackingInterval: TimeInterval = 60.0 // Default 1 minute
    private var isTracking = false
    private var currentLocationResult: FlutterResult?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Firebase setup (existing)
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // Firebase notifications setup (existing)
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        // Location tracking setup (new)
        setupLocationManager()
        
        // Setup method channel immediately after GeneratedPluginRegistrant
        // The Flutter engine is ready at this point
        setupMethodChannel()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Location Tracking Setup (NEW)
    
    private func setupMethodChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            print("❌ [NATIVE] Failed to get FlutterViewController - window: \(String(describing: window)), rootVC: \(String(describing: window?.rootViewController))")
            return
        }
        
        print("✅ [NATIVE] Setting up method channel with FlutterViewController")
        
        methodChannel = FlutterMethodChannel(
            name: "location_tracking",
            binaryMessenger: controller.binaryMessenger
        )
        
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call: call, result: result)
        }
        
        print("✅ [NATIVE] Method channel 'location_tracking' registered successfully")
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 10.0
    }
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestLocationPermission":
            requestLocationPermission(result: result)
        case "requestBackgroundPermission":
            requestBackgroundPermission(result: result)
        case "startLocationTracking":
            guard let args = call.arguments as? [String: Any],
                  let intervalSeconds = args["intervalSeconds"] as? Int else {
                result(false)
                return
            }
            startLocationTracking(intervalSeconds: intervalSeconds, result: result)
        case "stopLocationTracking":
            stopLocationTracking(result: result)
        case "updateInterval":
            guard let args = call.arguments as? [String: Any],
                  let intervalSeconds = args["intervalSeconds"] as? Int else {
                result(false)
                return
            }
            updateInterval(intervalSeconds: intervalSeconds, result: result)
        case "getCurrentLocation":
            getCurrentLocation(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestLocationPermission(result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            print("❌ Location manager not available")
            result(false)
            return
        }
        
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        print("📍 [NATIVE] Current authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            print("📍 [NATIVE] Requesting 'When In Use' permission...")
            locationManager.requestWhenInUseAuthorization()
            // Wait a bit then request Always
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("📍 [NATIVE] Requesting 'Always' permission...")
                locationManager.requestAlwaysAuthorization()
            }
            result(true)
        case .authorizedWhenInUse:
            print("📍 [NATIVE] Have 'When In Use', requesting 'Always'...")
            locationManager.requestAlwaysAuthorization()
            result(true)
        case .authorizedAlways:
            print("✅ [NATIVE] Already have 'Always' permission")
            result(true)
        case .denied:
            print("❌ [NATIVE] Permission denied")
            result(false)
        case .restricted:
            print("❌ [NATIVE] Permission restricted")
            result(false)
        @unknown default:
            print("⚠️ [NATIVE] Unknown status: \(status.rawValue)")
            result(false)
        }
    }
    
    private func requestBackgroundPermission(result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            result(false)
            return
        }
        
        // Use compatible authorization status check
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Will be handled in delegate method
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                locationManager.requestAlwaysAuthorization()
            }
            result(true)
        case .denied, .restricted:
            result(false)
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
            result(true)
        case .authorizedAlways:
            result(true)
        @unknown default:
            result(false)
        }
    }
    
    private func startLocationTracking(intervalSeconds: Int, result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            print("❌ Location manager not available")
            result(false)
            return
        }
        
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        print("📍 Current authorization status: \(status.rawValue)")
        
        // Request permission if not determined
        if status == .notDetermined {
            print("📍 Requesting 'When In Use' permission first...")
            locationManager.requestWhenInUseAuthorization()
            // Request 'Always' after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("📍 Requesting 'Always' permission...")
                locationManager.requestAlwaysAuthorization()
            }
            // Return false to indicate permissions need to be granted first
            result(false)
            return
        } else if status == .authorizedWhenInUse {
            print("📍 Have 'When In Use', requesting 'Always' for background tracking...")
            locationManager.requestAlwaysAuthorization()
        }
        
        // Allow tracking with both "Always" and "When In Use" permissions
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            print("❌ Location permission denied or restricted")
            result(false)
            return
        }
        
        print("✅ Starting location tracking with \(intervalSeconds)s interval")
        trackingInterval = TimeInterval(intervalSeconds)
        isTracking = true
        
        // Start location updates (compatible with older iOS)
        locationManager.startUpdatingLocation()
        
        // Start timer for regular updates
        startLocationTimer()
        
        // Enable background location updates (iOS 9.0+)
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        }
        
        print("✅ Location tracking started successfully")
        result(true)
    }
    
    private func stopLocationTracking(result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            result(false)
            return
        }
        
        isTracking = false
        
        // Stop location services
        locationManager.stopUpdatingLocation()
        
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = false
        }
        
        // Stop timer
        locationTimer?.invalidate()
        locationTimer = nil
        
        // End background task if running
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        result(true)
    }
    
    private func updateInterval(intervalSeconds: Int, result: @escaping FlutterResult) {
        trackingInterval = TimeInterval(intervalSeconds)
        
        if isTracking {
            // Restart timer with new interval
            locationTimer?.invalidate()
            startLocationTimer()
        }
        
        result(true)
    }
    
    private func startLocationTimer() {
        locationTimer = Timer.scheduledTimer(withTimeInterval: trackingInterval, repeats: true) { [weak self] _ in
            self?.requestCurrentLocation()
        }
        
        // Get initial location
        requestCurrentLocation()
    }
    
    private func requestCurrentLocation() {
        guard let locationManager = locationManager else { return }
        
        // Start background task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            if let bgTask = self?.backgroundTask {
                UIApplication.shared.endBackgroundTask(bgTask)
                self?.backgroundTask = .invalid
            }
        }
        
        locationManager.requestLocation()
    }
    
    private func getCurrentLocation(result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            result(FlutterError(code: "NO_LOCATION_MANAGER", message: "Location manager not available", details: nil))
            return
        }
        
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Location permission not granted", details: nil))
            return
        }
        
        // Start background task for single location request
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            if let bgTask = self?.backgroundTask {
                UIApplication.shared.endBackgroundTask(bgTask)
                self?.backgroundTask = .invalid
            }
        }
        
        // Store the result for the single location request
        currentLocationResult = result
        locationManager.requestLocation()
    }
    
    private func sendLocationToFlutter(latitude: Double, longitude: Double) {
        let arguments: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        methodChannel?.invokeMethod("onLocationUpdate", arguments: arguments)
    }
    
    private func sendErrorToFlutter(error: String) {
        methodChannel?.invokeMethod("onTrackingError", arguments: error)
    }

    // MARK: - Firebase Notifications (EXISTING - Keep as is)
    
    // Forward APNs token to Firebase
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // Show notifications in foreground
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

    // Handle when user taps a notification
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    // MARK: - CLLocationManagerDelegate (NEW)
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Handle single location request
        if let result = currentLocationResult {
            let locationData: [String: Any] = [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude
            ]
            result(locationData)
            currentLocationResult = nil
        } else {
            // Handle continuous tracking
            sendLocationToFlutter(latitude: location.coordinate.latitude, 
                                 longitude: location.coordinate.longitude)
        }
        
        // End background task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle single location request error
        if let result = currentLocationResult {
            result(FlutterError(code: "LOCATION_ERROR", message: error.localizedDescription, details: nil))
            currentLocationResult = nil
        } else {
            sendErrorToFlutter(error: "Location error: \(error.localizedDescription)")
        }
        
        // End background task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 Authorization status changed to: \(status.rawValue)")
        
        switch status {
        case .authorizedAlways:
            print("✅ Background location permission granted (Always)")
        case .authorizedWhenInUse:
            print("⚠️ Only 'When In Use' permission granted, requesting 'Always'...")
            // Request always authorization for background tracking
            manager.requestAlwaysAuthorization()
        case .denied:
            print("❌ Location permission denied by user")
            sendErrorToFlutter(error: "Location permission denied. Please enable in Settings.")
        case .restricted:
            print("❌ Location permission restricted (parental controls or MDM)")
            sendErrorToFlutter(error: "Location permission restricted")
        case .notDetermined:
            print("📍 Location permission not yet determined")
            break
        @unknown default:
            print("⚠️ Unknown authorization status: \(status.rawValue)")
            break
        }
    }
    
    // MARK: - App Lifecycle (NEW)
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        
        if isTracking {
            // Ensure background location continues
            if #available(iOS 9.0, *) {
                locationManager?.allowsBackgroundLocationUpdates = true
            }
        }
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        
        if isTracking && locationTimer == nil {
            // Restart timer when coming to foreground
            startLocationTimer()
        }
    }
}