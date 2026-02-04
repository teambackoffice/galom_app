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
      // Retrieve SID and Sales Person ID from secure storage
      String? sid = await _storage.read(key: 'sid');
      String? salesPersonId = await _storage.read(key: 'sales_person_id');

      if (sid == null || salesPersonId == null) {
        throw Exception("Authentication required. Please login again.");
      }

      // Setup headers
      var headers = {'Cookie': 'sid=$sid; system_user=yes;'};

      // Build URI with both customer and sales_person
      final uri = Uri.parse(url).replace(
        queryParameters: {
          'customer_name': customerName,
          'sales_person': salesPersonId,
        },
      );

      // Make request
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return paymentEntryDraftStatusModalFromJson(response.body);
      } else {
        throw Exception(
          "Failed to load payment entry status: "
          "${response.statusCode} - ${response.reasonPhrase} - ${response.body}",
        );
      }
    } catch (e, stackTrace) {
      throw Exception(
        "An error occurred while fetching payment entry status: $e",
      );
    }
  }
}
