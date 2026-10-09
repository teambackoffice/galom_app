class ApiConstants {
  static const String host = "http://127.0.0.1:8000/";
  static const String baseUrl = "$host/api/method/sales_pilot.Api.auth.";
  static const String galomBaseUrl = "$host/api/method/galom.galom.";
  static const String managerBaseUrl =
      "${host}api/method/sales_pilot.Api.manager.";

  /// Stock inventory is served from a separate server.
  static const String stockHost = "https://metta.tbocloud.in/";
  static const String stockUrl =
      "${stockHost}api/method/sales_pilot.Api.auth.get_all_items_stock";
}
