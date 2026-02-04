import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/create_payment_entry_controller.dart';
import 'package:location_tracker_app/controller/create_sales_order_controller.dart';
import 'package:location_tracker_app/controller/create_sales_return_contoller.dart';
import 'package:location_tracker_app/controller/customer_list_controller.dart';
import 'package:location_tracker_app/controller/customer_log_visit_controller.dart';
import 'package:location_tracker_app/controller/employee_location_controller.dart';
import 'package:location_tracker_app/controller/invoice_list_controller.dart';
import 'package:location_tracker_app/controller/item_list_controller.dart';
import 'package:location_tracker_app/controller/item_stock_controller.dart';
import 'package:location_tracker_app/controller/item_tax_controller.dart';
import 'package:location_tracker_app/controller/login_controller.dart';
import 'package:location_tracker_app/controller/mode_of_pay_controller.dart';
import 'package:location_tracker_app/controller/pay_sales_invoice_controller.dart';
import 'package:location_tracker_app/controller/payment_entry_controller.dart';
import 'package:location_tracker_app/controller/payment_entry_draft_controller.dart';
import 'package:location_tracker_app/controller/remark_task_controller.dart';
import 'package:location_tracker_app/controller/sales_invoice_details_controller.dart';
import 'package:location_tracker_app/controller/sales_invoice_id_controller.dart';
import 'package:location_tracker_app/controller/sales_order_controller.dart';
import 'package:location_tracker_app/controller/sales_return_controller.dart';
import 'package:location_tracker_app/controller/specialOffer/get_special_offer_controller.dart';
import 'package:location_tracker_app/controller/specialOffer/post_special_offer_controller.dart';
import 'package:location_tracker_app/controller/task_controller.dart';
import 'package:location_tracker_app/controller/update_task_status_controller.dart';
import 'package:location_tracker_app/service/login_service.dart';
import 'package:location_tracker_app/view/spalsh_screen/splash_screen.dart';
import 'package:provider/provider.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final LoginService _authService = LoginService();

  MyApp({super.key});

  Future<bool> checkLogin() async {
    return await _authService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => GetCustomerListController()),
        ChangeNotifierProvider(create: (_) => SalesOrderController()),
        ChangeNotifierProvider(create: (_) => ItemListController()),
        ChangeNotifierProvider(create: (_) => CreateSalesOrderController()),
        ChangeNotifierProvider(create: (_) => InvoiceListController()),
        ChangeNotifierProvider(create: (_) => PaySalesInvoiceController()),
        ChangeNotifierProvider(create: (_) => PaymentEntryController()),
        ChangeNotifierProvider(create: (_) => ModeOfPayController()),
        ChangeNotifierProvider(create: (_) => CraetePaymentEntryController()),
        ChangeNotifierProvider(create: (_) => CreateSalesReturnController()),
        ChangeNotifierProvider(create: (_) => SalesReturnController()),
        ChangeNotifierProvider(create: (_) => PaymentEntryDraftController()),
        ChangeNotifierProvider(create: (_) => LocationController()),
        ChangeNotifierProvider(create: (_) => LogCustomerVisitController()),
        ChangeNotifierProvider(create: (_) => SalesInvoiceIdsController()),
        ChangeNotifierProvider(create: (_) => SalesInvoiceDetailController()),
        ChangeNotifierProvider(create: (_) => ItemTaxController()),
        ChangeNotifierProvider(create: (_) => GetSpecialOfferController()),
        ChangeNotifierProvider(create: (_) => SpecialOfferController()),
        ChangeNotifierProvider(create: (_) => EmployeeTaskController()),
        ChangeNotifierProvider(create: (_) => UpdateTaskStatusController()),
        ChangeNotifierProvider(create: (_) => RemarkTaskController()),
        ChangeNotifierProvider(create: (_) => ItemStockController()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Location Tracker',
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: SplashScreen(),
      ),
    );
  }
}
