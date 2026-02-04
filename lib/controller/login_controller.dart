// controllers/login_controller.dart
import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController with ChangeNotifier {
  final LoginService _authService = LoginService();

  bool isLoading = false;
  String? errorMessage;
  bool isLoggedIn = false;

  // Check if user is already logged in when app starts
  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    bool isSuccess = await _authService.login(username, password);

    isLoading = false;

    if (isSuccess) {
      isLoggedIn = true;

      // Save login status to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      notifyListeners();
      return true;
    } else {
      errorMessage = 'Invalid username or password';
      isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    // Clear login status from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    // Clear any user data if needed
    // You might want to clear other stored user data here

    isLoggedIn = false;
    isLoading = false;
    errorMessage = null;

    notifyListeners();
  }

  // Clear error message
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
