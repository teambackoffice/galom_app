import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';

/// Salesperson filter options. Loaded once per manager session.
class SalesPersonController with ChangeNotifier {
  SalesPersonController({ManagerService? service})
    : _service = service ?? ManagerService();

  final ManagerService _service;

  List<SalesPerson> _salesPersons = const [];
  bool _isLoading = false;
  String? _error;
  bool _loaded = false;

  List<SalesPerson> get salesPersons => _salesPersons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> ensureLoaded() async {
    if (_loaded || _isLoading) return;
    await load();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _service.getSalesPersons();
      list.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      _salesPersons = list;
      _loaded = true;
    } on ManagerApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load salespersons.';
    }
    _isLoading = false;
    notifyListeners();
  }
}
