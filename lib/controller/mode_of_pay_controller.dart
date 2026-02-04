import 'package:flutter/widgets.dart';
import 'package:location_tracker_app/modal/mode_of_payment.dart';
import 'package:location_tracker_app/service/mode_of_pay_service.dart';

class ModeOfPayController extends ChangeNotifier {
  final ModeOfPayService _service = ModeOfPayService();
  bool _isLoading = false;
  String? _error;
  ModeOfPaymentModal? modeofpay;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchmodeofpay() async {
    setLoading(true);
    notifyListeners();
    try {
      modeofpay = await _service.getmodeofpay();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
