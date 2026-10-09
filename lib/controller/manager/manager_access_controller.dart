import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:location_tracker_app/service/manager_service.dart';

/// Decides whether the Manager experience is shown.
///
/// `get_manager_access` is the source of truth. If it cannot be reached
/// (offline, timeout) the `is_manager` flag saved at login is used instead,
/// so salespersons are never blocked from their own screens.
class ManagerAccessController with ChangeNotifier {
  ManagerAccessController({
    ManagerService? service,
    FlutterSecureStorage? storage,
  }) : _service = service ?? ManagerService(),
       _storage = storage ?? const FlutterSecureStorage();

  final ManagerService _service;
  final FlutterSecureStorage _storage;

  static const String storageKey = 'is_manager';

  bool _isManager = false;
  bool _isChecking = false;
  bool _checked = false;

  bool get isManager => _isManager;
  bool get isChecking => _isChecking;
  bool get hasChecked => _checked;

  Future<bool> refresh() async {
    _isChecking = true;
    notifyListeners();
    try {
      _isManager = await _service.getManagerAccess();
      await _storage.write(key: storageKey, value: _isManager ? '1' : '0');
    } on ManagerApiException catch (e) {
      if (e.isSessionExpired) {
        _isManager = false;
      } else {
        final cached = await _storage.read(key: storageKey);
        _isManager = cached == '1' || cached == 'true';
      }
    } catch (_) {
      _isManager = false;
    }
    _isChecking = false;
    _checked = true;
    notifyListeners();
    return _isManager;
  }

  /// Called on logout.
  void reset() {
    _isManager = false;
    _checked = false;
    _isChecking = false;
    notifyListeners();
  }
}
