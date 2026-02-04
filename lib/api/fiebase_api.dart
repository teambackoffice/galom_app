import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:location_tracker_app/view/mainscreen/sales_order/sales_return.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseApi {
  final firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    // Request permission
    final settings = await firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // iOS APNs token (optional)
      final apnsToken = await firebaseMessaging.getAPNSToken();
      if (apnsToken != null) {
        print("APNs Token: $apnsToken");
      }

      // Get FCM token
      final fcmToken = await firebaseMessaging.getToken();
      print("FCM Token: $fcmToken");

      // Listen for token refresh
      firebaseMessaging.onTokenRefresh.listen((newToken) {
        print("Refreshed FCM Token: $newToken");
      });

      // Handle notification when app is opened from terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleMessageClick(message);
        }
      });

      // Handle notification when app is in background and opened by tapping
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleMessageClick(message);
      });
    } else {
      print("Notifications are not allowed by the user");
    }
  }

  void _handleMessageClick(RemoteMessage message) {
    print("Notification clicked: ${message.data}");
    if (message.data.containsKey('sales_return')) {
      final context = navigatorKey.currentState?.overlay?.context;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SalesReturnListPage()),
        );
      }
    }
  }
}
