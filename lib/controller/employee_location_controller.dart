import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/service/employee_location_service.dart';
import 'package:location_tracker_app/service/location_interval_service.dart';

class LocationController extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('location_tracking');
  final EmployeeLocationService _service = EmployeeLocationService();
  final LocationIntervalService _intervalService = LocationIntervalService();
  static const _storage = FlutterSecureStorage();

  bool isLoading = false;
  bool isTracking = false;
  bool _isInitializing = false;
  String? error;
  String? lastResult;
  int trackingInterval = 60; // Default fallback value (1 minute)
  bool _intervalLoaded = false;

  bool get isInitializing => _isInitializing;

  // Check-in / check-out timestamps shown in the UI
  DateTime? checkInTime;
  DateTime? checkOutTime;

  // Batch sending configuration
  bool enableBatchSending = false;
  int batchSize = 10;
  final List<LocationEntry> _pendingEntries = [];

  // Debouncing to prevent duplicate submissions
  DateTime? _lastLocationSentTime;
  double? _lastSentLatitude;
  double? _lastSentLongitude;
  static const int _minSecondsBetweenSends =
      5; // Minimum 5 seconds between sends

  LocationController() {
    _setupMethodCallHandler();
    _initialize();
    print("🚀 LocationController initialized");
  }

  // Public method to trigger initialization (useful for manual re-init from UI)
  Future<void> init(String kEmployeeId) async {
    await _initialize();
  }

  // Initialize controller with API interval fetch and state loading
  Future<void> _initialize() async {
    _isInitializing = true;
    notifyListeners();
    await _loadTrackingIntervalFromAPI();
    await _loadTrackingState();
    _isInitializing = false;
    notifyListeners();
  }

  // Fetch tracking interval from API
  Future<void> _loadTrackingIntervalFromAPI() async {
    try {
      print("📡 Fetching tracking interval from API...");
      final intervalData = await _intervalService.getLocationUpdateInterval();

      if (intervalData != null &&
          intervalData.message.data.locationUpdateInterval.isNotEmpty) {
        String intervalString =
            intervalData.message.data.locationUpdateInterval;
        print("📋 Raw interval from API: '$intervalString'");

        // Parse the interval string (e.g., "2 min", "30 sec", "1 hour")
        int apiInterval = _parseIntervalToSeconds(intervalString);
        trackingInterval = apiInterval;
        _intervalLoaded = true;
        print(
          "✅ Tracking interval loaded from API: ${trackingInterval}s (from '$intervalString')",
        );

        // Save the interval for offline use
        await _storage.write(
          key: 'tracking_interval',
          value: trackingInterval.toString(),
        );
      } else {
        print("⚠️ Failed to get interval from API, using default");
        await _loadSavedInterval();
      }
    } catch (e) {
      print("❌ Error loading interval from API: $e");
      await _loadSavedInterval();
    }
    notifyListeners();
  }

  // Parse interval string to seconds
  int _parseIntervalToSeconds(String intervalString) {
    try {
      // Clean the string and make it lowercase
      String cleaned = intervalString.trim().toLowerCase();
      print("🔧 Parsing interval: '$cleaned'");

      // Extract number and unit
      RegExp regExp = RegExp(
        r'(\d+)\s*(min|mins|minute|minutes|sec|secs|second|seconds|hour|hours|hr|hrs)',
      );
      RegExpMatch? match = regExp.firstMatch(cleaned);

      if (match != null) {
        int number = int.parse(match.group(1)!);
        String unit = match.group(2)!;

        print("🔧 Parsed: $number $unit");

        switch (unit) {
          case 'sec':
          case 'secs':
          case 'second':
          case 'seconds':
            return number;
          case 'min':
          case 'mins':
          case 'minute':
          case 'minutes':
            return number * 60;
          case 'hour':
          case 'hours':
          case 'hr':
          case 'hrs':
            return number * 3600;
          default:
            print("⚠️ Unknown unit '$unit', defaulting to seconds");
            return number;
        }
      } else {
        // Try to parse as just a number (assume seconds)
        int? directNumber = int.tryParse(cleaned);
        if (directNumber != null) {
          print("🔧 Parsed as direct number: $directNumber seconds");
          return directNumber;
        } else {
          print(
            "❌ Could not parse interval '$intervalString', using default 60s",
          );
          return 60;
        }
      }
    } catch (e) {
      print(
        "❌ Error parsing interval '$intervalString': $e, using default 60s",
      );
      return 60;
    }
  }

  // Load previously saved interval as fallback
  Future<void> _loadSavedInterval() async {
    try {
      String? savedInterval = await _storage.read(key: 'tracking_interval');
      if (savedInterval != null) {
        trackingInterval = int.tryParse(savedInterval) ?? 60;
        print("📱 Loaded saved interval: ${trackingInterval}s");
      }
    } catch (e) {
      print("❌ Failed to load saved interval: $e");
    }
  }

  // Public method to refresh interval from API
  Future<void> refreshTrackingInterval() async {
    print("🔄 Refreshing tracking interval from API...");
    await _loadTrackingIntervalFromAPI();

    // If tracking is active, update the native tracking with new interval
    if (isTracking && _intervalLoaded) {
      try {
        await _channel.invokeMethod('updateInterval', {
          'intervalSeconds': trackingInterval,
        });
        lastResult = 'Interval updated to ${trackingInterval}s from API';
        print(
          "✅ Updated active tracking with new interval: ${trackingInterval}s",
        );
        notifyListeners();
      } catch (e) {
        print("❌ Failed to update active tracking interval: $e");
      }
    }
  }

  // Save tracking state to persistent storage
  Future<void> _saveTrackingState() async {
    try {
      await _storage.write(key: 'is_tracking', value: isTracking.toString());
      print("💾 Tracking state saved: $isTracking");
    } catch (e) {
      print("❌ Failed to save tracking state: $e");
    }
  }

  // Load tracking state from persistent storage
  Future<void> _loadTrackingState() async {
    try {
      String? savedState = await _storage.read(key: 'is_tracking');
      if (savedState != null) {
        isTracking = savedState == 'true';
        print("📱 Loaded tracking state: $isTracking");

        // If the app was tracking when closed, resume tracking
        if (isTracking) {
          print("🔄 Resuming background tracking...");
          await _resumeTracking();
        }

        notifyListeners();
      }
    } catch (e) {
      print("❌ Failed to load tracking state: $e");
    }
  }

  // Resume tracking without user interaction
  Future<void> _resumeTracking() async {
    try {
      final bool started = await _channel.invokeMethod(
        'startLocationTracking',
        {'intervalSeconds': trackingInterval},
      );

      if (started) {
        lastResult =
            '🔄 Tracking resumed from background (${trackingInterval}s interval)';
        print(
          "✅ Background tracking resumed successfully with ${trackingInterval}s interval",
        );
      } else {
        print("❌ Failed to resume background tracking");
        isTracking = false;
        await _saveTrackingState();
      }
    } catch (e) {
      print("❌ Error resuming tracking: $e");
      isTracking = false;
      await _saveTrackingState();
    }
  }

  void _setupMethodCallHandler() {
    print("🔧 Setting up MethodChannel handler");
    _channel.setMethodCallHandler((MethodCall call) async {
      print("📱 Received method call: ${call.method}");
      print("📱 Call arguments: ${call.arguments}");

      switch (call.method) {
        case 'onLocationUpdate':
          print("📍 AUTOMATIC LOCATION UPDATE RECEIVED!");
          await _handleLocationUpdate(call.arguments);
          break;
        case 'onTrackingError':
          print("❌ Tracking error received: ${call.arguments}");
          _handleTrackingError(call.arguments);
          break;
        default:
          print("❓ Unknown method: ${call.method}");
      }
    });
  }

  Future<void> _handleLocationUpdate(Map<dynamic, dynamic> locationData) async {
    print("🎯 _handleLocationUpdate called with: $locationData");

    try {
      // Validate location data first
      if (!locationData.containsKey('latitude') ||
          !locationData.containsKey('longitude')) {
        throw Exception('Invalid location data: missing latitude or longitude');
      }

      double? latitude = locationData['latitude']?.toDouble();
      double? longitude = locationData['longitude']?.toDouble();

      if (latitude == null || longitude == null) {
        throw Exception('Invalid location data: latitude or longitude is null');
      }

      print("📍 Processing location: $latitude, $longitude");

      // DEBOUNCING: Check if we should send this location
      final now = DateTime.now();

      // Check if this is a duplicate location (same coordinates)
      bool isDuplicateLocation =
          _lastSentLatitude == latitude && _lastSentLongitude == longitude;

      // Check if enough time has passed since last send
      bool enoughTimePassed =
          _lastLocationSentTime == null ||
          now.difference(_lastLocationSentTime!).inSeconds >=
              _minSecondsBetweenSends;

      if (isDuplicateLocation && !enoughTimePassed) {
        print(
          "⏭️ SKIPPING: Duplicate location within ${_minSecondsBetweenSends}s window",
        );
        print(
          "   Last sent: $_lastSentLatitude, $_lastSentLongitude at $_lastLocationSentTime",
        );
        print(
          "   Time since last send: ${now.difference(_lastLocationSentTime!).inSeconds}s",
        );
        return; // Skip this update
      }

      final date = DateFormat('yyyy-MM-dd').format(now);
      final time = DateFormat('HH:mm:ss').format(now);

      print("📅 Date: $date, Time: $time");
      print("🚀 SENDING TO API AUTOMATICALLY with Track entry type...");

      // Send with "Track" entry type for automatic updates
      await _service.sendLocation(
        latitude: latitude,
        longitude: longitude,
        date: date,
        time: time,
        entryType: "Track", // Automatic tracking entry type
      );

      // Update last sent tracking
      _lastLocationSentTime = now;
      _lastSentLatitude = latitude;
      _lastSentLongitude = longitude;

      lastResult =
          '✅ AUTO-SENT: $latitude, $longitude at $time (${trackingInterval}s interval)';
      error = null;
      print("✅ SUCCESS: $lastResult");
      notifyListeners();
    } catch (e, stackTrace) {
      String errorMessage = e.toString();
      error = '❌ Auto-send failed: $errorMessage';
      print("❌ DETAILED ERROR: $e");
      print("📍 Stack trace: $stackTrace");
      notifyListeners();

      // Detailed error handling
      if (errorMessage.contains('credentials')) {
        error = '❌ Missing login credentials (sid/sales_person_id)';
      } else if (errorMessage.contains('Failed to send location: 401')) {
        error = '❌ Authentication failed - please login again';
      } else if (errorMessage.contains('Failed to send location: 403')) {
        error = '❌ Access denied - check permissions';
      } else if (errorMessage.contains('Failed to send location: 417')) {
        error = '❌ Duplicate request rejected by server';
      } else if (errorMessage.contains('Failed to send location: 500')) {
        error = '❌ Server error - try again later';
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('NetworkException')) {
        error = '❌ Network error - check internet connection';
      }
      notifyListeners();
    }
  }

  void _handleTrackingError(String errorMessage) {
    error = "📱 Tracking error: $errorMessage";
    print("❌ Tracking error: $errorMessage");
    notifyListeners();
  }

  Future<bool> requestPermissions() async {
    try {
      print("🔐 Requesting permissions using NATIVE iOS method...");

      // Call native iOS method directly to request permissions
      final bool permissionGranted = await _channel.invokeMethod(
        'requestLocationPermission',
      );

      print("📍 Native permission request result: $permissionGranted");

      // Trust the native iOS result - it directly checks CLAuthorizationStatus
      // which is the source of truth for iOS location permissions
      if (permissionGranted) {
        print("✅ Location permission granted by native iOS!");
        error = null;
        notifyListeners();
        return true;
      } else {
        print("❌ Location permission denied by native iOS");
        error =
            'Location permission denied.\n\n'
            'To enable:\n'
            '1. Open Settings\n'
            '2. Scroll to "Chundakadan App"\n'
            '3. Tap "Location"\n'
            '4. Select "While Using the App" or "Always"';
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = 'Permission error: $e';
      print("❌ Permission error: $e");
      notifyListeners();
      return false;
    }
  }

  Future<void> startTracking() async {
    if (isTracking) {
      print("⚠️ Already tracking, cannot start again");
      return;
    }

    print("🚀 Starting tracking with Check In...");
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Ensure we have the latest interval from API before starting
      if (!_intervalLoaded) {
        print("📡 Loading tracking interval before starting...");
        await _loadTrackingIntervalFromAPI();
      }

      final bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        print("❌ Permissions not granted, cannot start tracking");
        isLoading = false;
        notifyListeners();
        return;
      }

      // First send Check In entry
      print("📍 Getting current location for Check In...");
      final Map<dynamic, dynamic>? locationData = await _channel.invokeMethod(
        'getCurrentLocation',
      );

      if (locationData != null) {
        double latitude = locationData['latitude'];
        double longitude = locationData['longitude'];
        print("📍 Got location for Check In: $latitude, $longitude");

        final now = DateTime.now();
        final date = DateFormat('yyyy-MM-dd').format(now);
        final time = DateFormat('HH:mm:ss').format(now);
        print("⏰ Check In time: $date $time");

        // Send Check In entry first
        print("🚀 Sending Check In entry to API...");
        await _service.sendLocation(
          latitude: latitude,
          longitude: longitude,
          date: date,
          time: time,
          entryType: "Check In",
        );

        print("✅ Check In entry sent successfully");
        lastResult = '✅ Check In sent: $latitude, $longitude at $time';

        // Record check-in time and reset check-out
        checkInTime = now;
        checkOutTime = null;

        // Initialize debouncing with Check In location
        _lastLocationSentTime = now;
        _lastSentLatitude = latitude;
        _lastSentLongitude = longitude;
      } else {
        throw Exception('Failed to get current location for Check In');
      }

      // Then start continuous tracking with API interval
      print(
        "📡 Starting continuous tracking with ${trackingInterval}s interval...",
      );
      final bool started = await _channel.invokeMethod(
        'startLocationTracking',
        {'intervalSeconds': trackingInterval},
      );

      if (started) {
        isTracking = true;
        await _saveTrackingState(); // Save state persistently
        lastResult =
            '🟢 Auto-tracking started - will send every ${trackingInterval}s (from API)';
        _pendingEntries.clear();
        print(
          "✅ Tracking started successfully with ${trackingInterval}s interval",
        );
      } else {
        error = '❌ Failed to start native tracking';
        print("❌ Failed to start native tracking");
      }
    } catch (e, stackTrace) {
      error = '❌ Start tracking error: $e';
      print("❌ DETAILED Start tracking error: $e");
      print("📍 Stack trace: $stackTrace");

      // Detailed error handling for Check In
      String errorMessage = e.toString();
      if (errorMessage.contains('credentials')) {
        error = '❌ Missing login credentials for Check In';
      } else if (errorMessage.contains('Failed to send location: 401')) {
        error = '❌ Authentication failed during Check In';
      } else if (errorMessage.contains('Failed to send location: 403')) {
        error = '❌ Access denied during Check In';
      } else if (errorMessage.contains('Failed to send location: 500')) {
        error = '❌ Server error during Check In';
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('NetworkException')) {
        error = '❌ Network error during Check In';
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> stopTracking() async {
    if (!isTracking) {
      print("⚠️ Not currently tracking, cannot stop");
      return;
    }

    print("🛑 Stopping tracking with Check Out...");
    isLoading = true;
    error = null; // Clear any previous errors
    notifyListeners();

    try {
      // First send Check Out entry
      print("📍 Getting current location for Check Out...");
      final Map<dynamic, dynamic>? locationData = await _channel.invokeMethod(
        'getCurrentLocation',
      );

      if (locationData != null) {
        double latitude = locationData['latitude'];
        double longitude = locationData['longitude'];
        print("📍 Got location for Check Out: $latitude, $longitude");

        final now = DateTime.now();
        final date = DateFormat('yyyy-MM-dd').format(now);
        final time = DateFormat('HH:mm:ss').format(now);
        print("⏰ Check Out time: $date $time");

        // Send Check Out entry
        print("🚀 Sending Check Out entry to API...");
        await _service.sendLocation(
          latitude: latitude,
          longitude: longitude,
          date: date,
          time: time,
          entryType: "Check Out",
        );

        print("✅ Check Out entry sent successfully");
        lastResult = '✅ Check Out sent: $latitude, $longitude at $time';

        // Record check-out time
        checkOutTime = now;
      } else {
        print("❌ Failed to get location for Check Out");
        error = '❌ Failed to get location for Check Out';
        // Continue with stopping tracking even if location fails
      }

      // Then stop continuous tracking
      print("🛑 Stopping native location tracking...");
      final bool stopped = await _channel.invokeMethod('stopLocationTracking');

      if (stopped) {
        isTracking = false;
        await _saveTrackingState(); // Save state persistently
        if (error == null) {
          // Only update if no previous error
          lastResult = '🔴 Auto-tracking stopped with Check Out';
        }
        print("✅ Native tracking stopped successfully");
      } else {
        error = '❌ Failed to stop native tracking';
        print("❌ Failed to stop native tracking");
        // Force state change anyway
        isTracking = false;
        await _saveTrackingState();
      }
    } catch (e, stackTrace) {
      error = '❌ Stop tracking error: $e';
      print("❌ DETAILED Stop tracking error: $e");
      print("📍 Stack trace: $stackTrace");

      // Force stop tracking state even if there's an error
      isTracking = false;
      await _saveTrackingState();

      // Detailed error handling for Check Out
      String errorMessage = e.toString();
      if (errorMessage.contains('credentials')) {
        error = '❌ Missing login credentials for Check Out';
      } else if (errorMessage.contains('Failed to send location: 401')) {
        error = '❌ Authentication failed during Check Out';
      } else if (errorMessage.contains('Failed to send location: 403')) {
        error = '❌ Access denied during Check Out';
      } else if (errorMessage.contains('Failed to send location: 500')) {
        error = '❌ Server error during Check Out';
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('NetworkException')) {
        error = '❌ Network error during Check Out';
      }
    }

    isLoading = false;
    notifyListeners();
  }

  // Updated method to use API interval and refresh from API
  Future<void> updateTrackingInterval(int intervalSeconds) async {
    trackingInterval = intervalSeconds;
    print("⏱️ Updating interval to $intervalSeconds seconds");

    // Save the manually set interval
    await _storage.write(
      key: 'tracking_interval',
      value: intervalSeconds.toString(),
    );

    if (isTracking) {
      try {
        await _channel.invokeMethod('updateInterval', {
          'intervalSeconds': intervalSeconds,
        });
        lastResult = 'Interval updated to $intervalSeconds seconds';
        notifyListeners();
      } catch (e) {
        error = 'Failed to update interval: $e';
        notifyListeners();
      }
    }
  }

  // Manual location post (Send Now button) - KEPT FOR YOUR UI
  Future<void> postLocation() async {
    print("📍 Manual location request...");
    isLoading = true;
    error = null;
    lastResult = null;
    notifyListeners();

    try {
      final Map<dynamic, dynamic>? locationData = await _channel.invokeMethod(
        'getCurrentLocation',
      );

      if (locationData != null) {
        double latitude = locationData['latitude'];
        double longitude = locationData['longitude'];

        final now = DateTime.now();
        final date = DateFormat('yyyy-MM-dd').format(now);
        final time = DateFormat('HH:mm:ss').format(now);

        // Send with "Track" entry type for manual sends
        await _service.sendLocation(
          latitude: latitude,
          longitude: longitude,
          date: date,
          time: time,
          entryType: "Track", // Manual sends are also "Track" type
        );

        lastResult = '✅ MANUAL: Location sent successfully';
        print("✅ Manual location sent successfully");
      } else {
        error = '❌ Failed to get current location';
        print("❌ Failed to get current location");
      }
    } catch (e) {
      error = '❌ Manual location error: $e';
      print("❌ Manual location error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // Batch methods (KEPT FOR YOUR UI COMPATIBILITY)
  Future<void> sendPendingEntries() async {
    print("📦 Send pending entries (currently disabled)");
    lastResult = 'Batch sending disabled for debugging';
    notifyListeners();
  }

  void toggleBatchSending(bool enabled) {
    enableBatchSending = false;
    print("📦 Batch sending toggle attempted - keeping disabled for debugging");
    notifyListeners();
  }

  void updateBatchSize(int newSize) {
    batchSize = newSize.clamp(1, 50);
    print("📦 Batch size updated to $batchSize (currently disabled)");
    notifyListeners();
  }

  // Getters for UI (KEPT FOR YOUR UI)
  int get pendingEntriesCount => _pendingEntries.length;
  bool get hasPendingEntries => _pendingEntries.isNotEmpty;
  bool get intervalLoaded => _intervalLoaded;

  // KEPT FOR YOUR UI COMPATIBILITY
  Future<void> checkStoredCredentials() async {
    try {
      const storage = FlutterSecureStorage();
      String? sid = await storage.read(key: 'sid');
      String? salesPersonId = await storage.read(key: 'sales_person_id');

      print("🔐 CREDENTIAL CHECK:");
      print(
        "   SID: ${sid != null ? 'EXISTS (${sid.length} chars)' : 'MISSING'}",
      );
      print("   Sales Person ID: ${salesPersonId ?? 'MISSING'}");

      if (sid == null || salesPersonId == null) {
        throw Exception('Missing stored credentials - please login again');
      }
    } catch (e) {
      print("❌ Credential check failed: $e");
      rethrow;
    }
  }
  // Add to your LocationController class

  // Customer visit tracking - in memory
  Map<String, dynamic>? activeCustomerVisit;

  bool get hasActiveCustomerVisit => activeCustomerVisit != null;

  Future<bool> checkInToCustomer({
    required String customerName,
    String? purpose,
  }) async {
    try {
      // You can add location fetching here if needed

      activeCustomerVisit = {
        'customer_name': customerName,
        'purpose': purpose ?? '',
        'check_in_time': DateTime.now(),
      };

      notifyListeners();
      return true;
    } catch (e) {
      error = 'Failed to check in: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOutFromCustomer() async {
    if (activeCustomerVisit == null) return false;

    try {
      final checkInTime = activeCustomerVisit!['check_in_time'] as DateTime;
      final checkOutTime = DateTime.now();
      final duration = checkOutTime.difference(checkInTime);

      // You can send data to API here
      print('Visit completed:');
      print('Customer: ${activeCustomerVisit!['customer_name']}');
      print('Duration: ${duration.inMinutes} minutes');

      // Clear active visit
      activeCustomerVisit = null;
      notifyListeners();

      return true;
    } catch (e) {
      error = 'Failed to check out: $e';
      notifyListeners();
      return false;
    }
  }
}
