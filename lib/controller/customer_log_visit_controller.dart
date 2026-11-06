import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location_tracker_app/service/customer_log_visit_service.dart';

/// A first/last counter visit that is checked in but not yet checked out.
class OpenCounterVisit {
  final String name;
  final String customerName;

  /// `HH:MM:SS`, the visit's check-in time.
  final String checkinTime;
  final bool isFirstCounter;
  final bool isLastCounter;

  const OpenCounterVisit({
    required this.name,
    required this.customerName,
    required this.checkinTime,
    required this.isFirstCounter,
    required this.isLastCounter,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'customer_name': customerName,
    'checkin_time': checkinTime,
    'is_first_counter': isFirstCounter,
    'is_last_counter': isLastCounter,
  };

  factory OpenCounterVisit.fromJson(Map<String, dynamic> j) => OpenCounterVisit(
    name: j['name'].toString(),
    customerName: (j['customer_name'] ?? '').toString(),
    checkinTime: (j['checkin_time'] ?? '').toString(),
    isFirstCounter: j['is_first_counter'] == true,
    isLastCounter: j['is_last_counter'] == true,
  );

  String get counterLabel => isFirstCounter ? 'First Counter' : 'Last Counter';

  /// Check-in as a DateTime today, or null if the time can't be parsed.
  DateTime? get checkinAt {
    final parts = checkinTime.split('.').first.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final s = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    if (h == null || m == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m, s);
  }
}

/// A first/last counter meeting from today that has been checked out.
/// Only used to tell whether a locally saved open visit was checked out.
class ClosedCounterVisit {
  final String name;
  final String customerName;
  final String checkinTime;
  final String checkoutTime;
  final String meetingRemarks;
  final bool isFirstCounter;

  const ClosedCounterVisit({
    required this.name,
    required this.customerName,
    required this.checkinTime,
    required this.checkoutTime,
    required this.meetingRemarks,
    required this.isFirstCounter,
  });

  String get counterLabel => isFirstCounter ? 'First Counter' : 'Last Counter';
}

bool _blank(dynamic v) => v == null || v.toString().trim().isEmpty;

bool _flag(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

class LogCustomerVisitController extends ChangeNotifier {
  final LogCustomerVisitService _service = LogCustomerVisitService();

  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic>? responseData;

  /// The counter meeting currently in progress, if any.
  OpenCounterVisit? openVisit;
  bool isLoadingOpenVisit = false;
  bool isFinishingMeeting = false;

  /// Today's checked-out counter meetings, newest first.
  List<ClosedCounterVisit> closedVisits = [];

  static const _prefsKey = 'open_counter_visit';

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// Keeps the open visit on the device so it survives an app restart.
  Future<void> _saveLocal(OpenCounterVisit? visit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (visit == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(
          _prefsKey,
          jsonEncode({'date': _todayKey(), 'visit': visit.toJson()}),
        );
      }
    } catch (_) {}
  }

  Future<OpenCounterVisit?> _readLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return null;
      final data = jsonDecode(raw);
      if (data is! Map || data['date'] != _todayKey()) {
        await prefs.remove(_prefsKey); // left over from an earlier day
        return null;
      }
      return OpenCounterVisit.fromJson(
        Map<String, dynamic>.from(data['visit']),
      );
    } catch (_) {
      return null;
    }
  }

  String _cleanError(Object e) =>
      e.toString().replaceAll('Exception: ', '').trim();

  Future<void> logCustomerVisit({
    required String date,
    required String time,
    required double longitude,
    required double latitude,
    required String customerName,
    required String description,
    File? photo,
    bool isFirstCounter = false,
    bool isLastCounter = false,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.logCustomerVisit(
        date: date,
        time: time,
        longitude: longitude,
        latitude: latitude,
        customerName: customerName,
        description: description,
        photo: photo,
        isFirstCounter: isFirstCounter,
        isLastCounter: isLastCounter,
      );

      responseData = result;
      debugPrint('[CounterMeeting] log_customer_visit -> $result');

      // First/last counter: the sent time is the check-in; keep the id so
      // the meeting can be finished with update_customer_visit.
      if (isFirstCounter || isLastCounter) {
        final name = _visitNameFrom(result);
        if (name == null) {
          // Response didn't carry the id: recover the open visit from the
          // server so the meeting can still be finished.
          await loadOpenVisit();
        } else {
          openVisit = OpenCounterVisit(
            name: name,
            customerName: customerName,
            checkinTime: time,
            isFirstCounter: isFirstCounter,
            isLastCounter: isLastCounter,
          );
          await _saveLocal(openVisit);
        }
      }
    } catch (e) {
      errorMessage = _cleanError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Pulls the new visit id out of a log_customer_visit response, tolerating
  /// `message.name`, `message.data.name` or `data.name`.
  static String? _visitNameFrom(Map<String, dynamic> result) {
    String? pick(dynamic m) {
      if (m is! Map) return null;
      final n = m['name'];
      if (n is String && n.isNotEmpty) return n;
      return pick(m['data']);
    }

    return pick(result['message']) ?? pick(result['data']);
  }

  /// Restores an open first/last counter visit from the server, for when the
  /// app was closed between check-in and check-out.
  Future<void> loadOpenVisit() async {
    isLoadingOpenVisit = true;
    // Show the locally saved visit straight away, then confirm with server.
    openVisit ??= await _readLocal();
    debugPrint('[CounterMeeting] local open visit: ${openVisit?.toJson()}');
    notifyListeners();
    try {
      final entries = await _service.getMyTodayVisits();
      debugPrint('[CounterMeeting] get_my_today_visits -> $entries');

      // Older servers don't return the counter / check-out fields, so they
      // can't tell us whether the meeting is still open. Keep the local copy.
      final serverKnowsCheckout = entries.any(
        (e) => e.containsKey('checkout_time'),
      );
      if (!serverKnowsCheckout) return;

      OpenCounterVisit? found;
      final closed = <ClosedCounterVisit>[];
      for (final e in entries) {
        final isFirst = _flag(e['is_first_counter']);
        final isLast = _flag(e['is_last_counter']);
        final checkout = e['checkout_time'];
        // A meeting is only finished once it has a remark (the remark is
        // required to check out). Don't trust checkout_time alone: some
        // servers fill it in at check-in time.
        final remarks = (e['meeting_remarks'] ?? '').toString().trim();
        final isOpen =
            (isFirst || isLast) && (_blank(checkout) || remarks.isEmpty);
        if ((isFirst || isLast) && !isOpen) {
          closed.add(
            ClosedCounterVisit(
              name: e['name'].toString(),
              customerName: (e['customer_name'] ?? '').toString(),
              checkinTime: (e['time'] ?? '').toString(),
              checkoutTime: checkout.toString(),
              meetingRemarks: (e['meeting_remarks'] ?? '').toString(),
              isFirstCounter: isFirst,
            ),
          );
        }
        if (isOpen && found == null) {
          found = OpenCounterVisit(
            name: e['name'].toString(),
            customerName: (e['customer_name'] ?? '').toString(),
            checkinTime: (e['time'] ?? '').toString(),
            isFirstCounter: isFirst,
            isLastCounter: isLast,
          );
        }
      }
      // Only drop the locally saved visit when the server shows that same
      // visit as checked out. If the server's list leaves it out or doesn't
      // flag it, keep the reminder: losing an open meeting is worse.
      final local = openVisit;
      if (found == null && local != null) {
        final checkedOut = closed.any((c) => c.name == local.name);
        if (!checkedOut) found = local;
      }
      openVisit = found;
      closedVisits = closed;
      await _saveLocal(found);
    } catch (e) {
      debugPrint('[CounterMeeting] get_my_today_visits failed: $e');
      // Leave any locally known open visit in place if the lookup fails.
    } finally {
      isLoadingOpenVisit = false;
      notifyListeners();
    }
  }

  /// Records the check-out and meeting remark. Returns null on success, or
  /// the error message to show.
  Future<String?> finishMeeting(String meetingRemarks) async {
    final visit = openVisit;
    if (visit == null) return 'No open counter visit';

    isFinishingMeeting = true;
    notifyListeners();
    try {
      final result = await _service.updateCustomerVisit(
        name: visit.name,
        meetingRemarks: meetingRemarks,
        // Send the real check-out time: if the server already stored one
        // (e.g. defaulted at check-in) it would otherwise keep that value.
        checkoutTime: DateFormat('HH:mm:ss').format(DateTime.now()),
      );
      closedVisits = [
        ClosedCounterVisit(
          name: visit.name,
          customerName: visit.customerName,
          checkinTime: (result['checkin_time'] ?? visit.checkinTime).toString(),
          checkoutTime: (result['checkout_time'] ?? '').toString(),
          meetingRemarks: (result['meeting_remarks'] ?? meetingRemarks)
              .toString(),
          isFirstCounter: visit.isFirstCounter,
        ),
        ...closedVisits.where((v) => v.name != visit.name),
      ];
      openVisit = null;
      await _saveLocal(null);
      return null;
    } catch (e) {
      debugPrint('[CounterMeeting] update_customer_visit failed: $e');
      return _cleanError(e);
    } finally {
      isFinishingMeeting = false;
      notifyListeners();
    }
  }
}
