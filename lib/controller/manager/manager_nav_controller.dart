import 'package:flutter/foundation.dart';

/// Tabs of the Manager shell (bottom navigation order).
enum ManagerTab { home, attendance, visits, sales, stock, leaves }

/// Sub-tabs of the Sales tab.
enum SalesTab { orders, returns, invoices, payments }

class ManagerNavController with ChangeNotifier {
  ManagerTab _tab = ManagerTab.home;
  SalesTab _salesTab = SalesTab.orders;

  ManagerTab get tab => _tab;
  SalesTab get salesTab => _salesTab;

  void goTo(ManagerTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  void goToSales(SalesTab salesTab) {
    _tab = ManagerTab.sales;
    _salesTab = salesTab;
    notifyListeners();
  }

  void setSalesTab(SalesTab salesTab) {
    if (_salesTab == salesTab) return;
    _salesTab = salesTab;
    notifyListeners();
  }
}
