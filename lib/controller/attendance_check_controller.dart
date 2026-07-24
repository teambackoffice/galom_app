// lib/controller/employee_location_controller.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_tracker_app/service/attendance_check.dart';

// Key used to persist today's check-in time across restarts
const _kCheckInKey = 'attendance_checkin_time';

class UpdatedAttendanceController extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Public State ────────────────────────────────────────────────────────────
  bool isTracking = false;
  bool isLoading = false;
  bool isInitializing = false; // true while fetching status on startup
  String? error;

  DateTime? checkInTime;
  DateTime? checkOutTime;

  // KM readings entered by the user at check-in / check-out.
  String? checkInKm;
  String? checkOutKm;

  // Local file path of the photo captured/picked at check-in / check-out
  // (kept only for the current session so the log card can preview it;
  // not restored from the server).
  String? checkInPhotoPath;
  String? checkOutPhotoPath;

  int pendingEntriesCount = 0;
  bool get hasPendingEntries => pendingEntriesCount > 0;

  String employeeId = '7f47632a-ac4f-11ef-ad49-8c1645f11e0b';

  // ── Bootstrap ───────────────────────────────────────────────────────────────
  /// Call from initState:
  ///   context.read<LocationController>().init('EMP-001');
  Future<void> init([String empId = '']) async {
    // employeeId from secure storage is used by the service directly;
    // empId param kept for backward-compat but not overriding storage.
    if (empId.isNotEmpty) employeeId = empId;
    await _fetchStatus();
  }

  // ── GET: Fetch current status from server ───────────────────────────────────
  Future<void> _fetchStatus() async {
    if (employeeId.isEmpty) return;

    isInitializing = true;
    error = null;
    notifyListeners();

    try {
      final data = await _service.getEmployeeStatus();

      // ── Debug: log full API response ──

      // Response shape:
      // { "message": { "status": "success", "data": { "current_status": "IN", "last_log_time": "..." } } }
      final rawMsg = data['message'];
      final Map<String, dynamic> msg = rawMsg is Map<String, dynamic>
          ? rawMsg
          : {};

      // The real status lives inside msg['data'], not msg['status']
      final nested = msg['data'];
      final Map<String, dynamic> innerData = nested is Map<String, dynamic>
          ? nested
          : {};

      final currentStatus = (innerData['current_status'] as String? ?? 'OUT')
          .toUpperCase();
      isTracking = currentStatus == 'IN';

      final rawLogTime = innerData['last_log_time'] as String?;
      final logTime = rawLogTime != null ? DateTime.tryParse(rawLogTime) : null;

      // If the server reports a KM reading for the last log, reflect it.
      final serverKm = innerData['custom_kilometer']?.toString();

      if (isTracking) {
        // Currently checked in — last_log_time is the check-in time
        checkInTime = logTime;
        checkOutTime = null;
        checkOutKm = null;
        checkOutPhotoPath = null;
        if (serverKm != null) checkInKm = serverKm;
        // Keep local storage in sync
        await _saveCheckInTime(logTime);
      } else {
        // Currently checked out — last_log_time is the check-out time
        checkOutTime = logTime;
        if (serverKm != null) checkOutKm = serverKm;
        // Restore today's check-in time from local storage (API doesn't return it)
        checkInTime = await _loadTodayCheckInTime();
      }

      error = null;

      print(
        '[AttendanceCtrl] isTracking=$isTracking checkIn=$checkInTime checkOut=$checkOutTime',
      );
    } catch (e) {
      print('[AttendanceCtrl] _fetchStatus error: $e');
      error = _clean(e);
    }

    isInitializing = false;
    notifyListeners();
  }

  // Helper to get current location coordinates
  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        error = 'Location services are disabled. Please enable GPS.';
        notifyListeners();
        await Geolocator.openLocationSettings();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          error = 'Location permissions are denied.';
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        error =
            'Location permissions are permanently denied. Please enable them in settings.';
        notifyListeners();
        await Geolocator.openAppSettings();
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      error = 'Error getting location: $e';
      notifyListeners();
      print('[AttendanceCtrl] Error getting position: $e');
      return null;
    }
  }

  /// Reads [photo] off disk and returns its base64 string, or null.
  Future<String?> _encodePhoto(File? photo) async {
    if (photo == null) return null;
    try {
      final bytes = await photo.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('[AttendanceCtrl] Error encoding photo: $e');
      return null;
    }
  }

  /// Builds a filename that preserves the original extension (defaults to png).
  String _photoFileName(File? photo, String prefix) {
    final ext = photo != null && photo.path.contains('.')
        ? photo.path.split('.').last
        : 'png';
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  // ── POST: Check In ──────────────────────────────────────────────────────────
  /// [km] is the odometer reading entered by the user.
  /// [photo] is an optional image captured via camera or picked from gallery.
  Future<void> startTracking({required String km, File? photo}) async {
    if (employeeId.isEmpty) {
      error = 'Employee ID is not set.';
      notifyListeners();
      return;
    }

    _setLoading(true);

    double? lat;
    double? lon;
    final position = await _getCurrentPosition();
    if (position != null) {
      lat = position.latitude;
      lon = position.longitude;
    }

    final imageBase64 = await _encodePhoto(photo);
    final imageFileName = photo != null
        ? _photoFileName(photo, 'checkin')
        : null;

    final result = await _service.addCheckIn(
      logType: 'IN',
      latitude: lat,
      longitude: lon,
      customKilometer: km,
      imageBase64: imageBase64,
      imageFileName: imageFileName,
    );

    if (result['success'] == true) {
      isTracking = true;
      checkInTime = DateTime.now();
      checkOutTime = null;
      // Fresh day / fresh session — clear out any previous check-out info.
      checkInKm = km;
      checkInPhotoPath = photo?.path;
      checkOutKm = null;
      checkOutPhotoPath = null;
      error = null;
      // Persist check-in time so it survives a restart
      await _saveCheckInTime(checkInTime);
    } else {
      error = result['message'] as String? ?? 'Check-in failed.';
    }

    _setLoading(false);
  }

  // ── POST: Check Out ─────────────────────────────────────────────────────────
  /// [km] is the odometer reading entered by the user.
  /// [photo] is an optional image captured via camera or picked from gallery.
  Future<void> stopTracking({required String km, File? photo}) async {
    if (employeeId.isEmpty) {
      error = 'Employee ID is not set.';
      notifyListeners();
      return;
    }

    _setLoading(true);

    double? lat;
    double? lon;

    final position = await _getCurrentPosition();
    if (position != null) {
      lat = position.latitude;
      lon = position.longitude;
    }

    final imageBase64 = await _encodePhoto(photo);
    final imageFileName = photo != null
        ? _photoFileName(photo, 'checkout')
        : null;

    final result = await _service.addCheckIn(
      logType: 'OUT',
      latitude: lat,
      longitude: lon,
      customKilometer: km,
      imageBase64: imageBase64,
      imageFileName: imageFileName,
    );

    if (result['success'] == true) {
      isTracking = false;
      checkOutTime = DateTime.now();
      checkOutKm = km;
      checkOutPhotoPath = photo?.path;
      error = null;
    } else {
      error = result['message'] as String? ?? 'Check-out failed.';
    }

    _setLoading(false);
  }

  // ── Pending offline entries ─────────────────────────────────────────────────
  Future<void> sendPendingEntries() async {
    // TODO: iterate local DB and call _service.addCheckIn for each record
    pendingEntriesCount = 0;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  // ── Local persistence for check-in time ────────────────────────────────────

  /// Saves [time] to secure storage as ISO-8601 string.
  Future<void> _saveCheckInTime(DateTime? time) async {
    if (time == null) {
      await _storage.delete(key: _kCheckInKey);
    } else {
      await _storage.write(key: _kCheckInKey, value: time.toIso8601String());
    }
  }

  /// Returns the stored check-in time only if it is from today; null otherwise.
  Future<DateTime?> _loadTodayCheckInTime() async {
    final raw = await _storage.read(key: _kCheckInKey);
    if (raw == null) return null;
    final stored = DateTime.tryParse(raw);
    if (stored == null) return null;
    final now = DateTime.now();
    // Discard if it was saved on a previous day
    if (stored.year != now.year ||
        stored.month != now.month ||
        stored.day != now.day) {
      await _storage.delete(key: _kCheckInKey);
      return null;
    }
    return stored;
  }
}
