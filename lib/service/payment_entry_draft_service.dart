import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/payment_entry_draft_status.dart';

class PaymentEntryDraftService {
  static const _storage = FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}payment_entry_status';

  Future<PaymentEntryDraftStatusModal> fetchPaymentEntryStatus({
    required String customerName,
  }) async {
    try {
      print("=========== PAYMENT ENTRY STATUS API ===========");

      // Retrieve SID and Sales Person ID
      String? sid = await _storage.read(key: 'sid');
      String? salesPersonId = await _storage.read(key: 'sales_person_id');

      print("SID: $sid");
      print("Sales Person ID: $salesPersonId");

      if (sid == null || salesPersonId == null) {
        throw Exception("Authentication required. Please login again.");
      }

      // Setup headers
      var headers = {
        'Cookie': 'sid=$sid; system_user=yes;',
        'Content-Type': 'application/json',
      };

      print("Headers: $headers");

      // Build URI
      final uri = Uri.parse(url).replace(
        queryParameters: {
          'customer_name': customerName,
          'sales_person': salesPersonId,
        },
      );

      print("Request URL: $uri");
      print("Request Method: GET");

      // API Call
      final response = await http.get(uri, headers: headers);

      print("Status Code: ${response.statusCode}");
      print("Reason Phrase: ${response.reasonPhrase}");
      print("Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("=========== SUCCESS RESPONSE ===========");
        return paymentEntryDraftStatusModalFromJson(response.body);
      } else {
        print("=========== ERROR RESPONSE ===========");
        throw Exception(
          "Failed to load payment entry status: "
          "${response.statusCode} - ${response.reasonPhrase} - ${response.body}",
        );
      }
    } catch (e, stackTrace) {
      print("=========== EXCEPTION OCCURRED ===========");
      print("Error: $e");
      print("StackTrace: $stackTrace");

      throw Exception(
        "An error occurred while fetching payment entry status: $e",
      );
    }
  }
}
