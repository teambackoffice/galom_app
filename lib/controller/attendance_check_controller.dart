// lib/controller/employee_location_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      print('[AttendanceCtrl] raw API response: $data');

      // Response shape:
      // { "message": { "status": "success", "data": { "current_status": "IN", "last_log_time": "..." } } }
      final rawMsg = data['message'];
      final Map<String, dynamic> msg =
          rawMsg is Map<String, dynamic> ? rawMsg : {};

      // The real status lives inside msg['data'], not msg['status']
      final nested = msg['data'];
      final Map<String, dynamic> innerData =
          nested is Map<String, dynamic> ? nested : {};

      final currentStatus =
          (innerData['current_status'] as String? ?? 'OUT').toUpperCase();
      isTracking = currentStatus == 'IN';

      final rawLogTime = innerData['last_log_time'] as String?;
      final logTime = rawLogTime != null ? DateTime.tryParse(rawLogTime) : null;

      if (isTracking) {
        // Currently checked in — last_log_time is the check-in time
        checkInTime = logTime;
        checkOutTime = null;
        // Keep local storage in sync
        await _saveCheckInTime(logTime);
      } else {
        // Currently checked out — last_log_time is the check-out time
        checkOutTime = logTime;
        // Restore today's check-in time from local storage (API doesn't return it)
        checkInTime = await _loadTodayCheckInTime();
      }

      error = null;

      print('[AttendanceCtrl] isTracking=$isTracking checkIn=$checkInTime checkOut=$checkOutTime');
    } catch (e) {
      print('[AttendanceCtrl] _fetchStatus error: $e');
      error = _clean(e);
    }

    isInitializing = false;
    notifyListeners();
  }

  // ── POST: Check In ──────────────────────────────────────────────────────────
  Future<void> startTracking() async {
    if (employeeId.isEmpty) {
      error = 'Employee ID is not set.';
      notifyListeners();
      return;
    }

    _setLoading(true);

    final result = await _service.addCheckIn(logType: 'IN');

    if (result['success'] == true) {
      isTracking = true;
      checkInTime = DateTime.now();
      checkOutTime = null;
      error = null;
      // Persist check-in time so it survives a restart
      await _saveCheckInTime(checkInTime);
    } else {
      error = result['message'] as String? ?? 'Check-in failed.';
    }

    _setLoading(false);
  }

  // ── POST: Check Out ─────────────────────────────────────────────────────────
  Future<void> stopTracking() async {
    if (employeeId.isEmpty) {
      error = 'Employee ID is not set.';
      notifyListeners();
      return;
    }

    _setLoading(true);

    final result = await _service.addCheckIn(logType: 'OUT');

    if (result['success'] == true) {
      isTracking = false;
      checkOutTime = DateTime.now();
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
