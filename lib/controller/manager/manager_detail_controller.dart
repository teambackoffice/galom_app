import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/service/manager_service.dart';

/// Loads a single detail object (attendance day, transaction) for one screen.
class ManagerDetailController<T> with ChangeNotifier {
  ManagerDetailController(this._loader);

  final Future<T> Function() _loader;

  T? _data;
  ManagerApiException? _error;
  bool _isLoading = false;
  bool _disposed = false;

  T? get data => _data;
  ManagerApiException? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _notify();
    try {
      _data = await _loader();
    } on ManagerApiException catch (e) {
      _error = e;
    } catch (e) {
      debugPrint('Manager detail parse error: $e');
      _error = const ManagerApiException(
        'Unexpected response from the server.',
      );
    }
    _isLoading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
