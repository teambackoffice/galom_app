class ApiConstants {
  static const String host = "https://uat-mettaapp.tbocloud.in/";
  static const String baseUrl = "$host/api/method/sales_pilot.Api.auth.";
  static const String galomBaseUrl = "$host/api/method/galom.galom.";
  static const String managerBaseUrl =
      "${host}api/method/sales_pilot.Api.manager.";
  static const String targetsBaseUrl =
      "$host/api/method/sales_pilot.Api.targets.";

  /// Stock inventory is served from a separate server.
  static const String stockHost = "https://metta.tbocloud.in/";
  static const String stockUrl =
      "${stockHost}api/method/sales_pilot.Api.auth.get_all_items_stock";
}
