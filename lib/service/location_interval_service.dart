import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/location_interval_modal.dart';

class LocationIntervalService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}get_location_update_interval';

  Future<LocationIntervalModal?> getLocationUpdateInterval() async {
    try {
      // Read sid from secure storage
      final sid = await _storage.read(key: 'sid');
      if (sid == null) {
        return null;
      }

      // Prepare headers
      var headers = {'Cookie': 'sid=$sid'};

      // Prepare and log request
      final uri = Uri.parse(url);

      final request = http.Request('GET', uri);
      request.headers.addAll(headers);

      // Send request
      final response = await request.send();


      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();

        return LocationIntervalModal.fromJson(jsonDecode(responseBody));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
