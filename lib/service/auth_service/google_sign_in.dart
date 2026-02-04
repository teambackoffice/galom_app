// import 'dart:convert';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;

// class AuthenticationService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final String _backendUrl = 'https://chundakadan.in/'; // Your ERP URL

//   // Sign in with username and password to your ERP backend
//   Future<User?> signInWithUsernamePassword(
//     String username,
//     String password,
//   ) async {
//     try {
//       // Step 1: Authenticate with your ERP backend
//       final response = await http.post(
//         Uri.parse('$_backendUrl/login'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'username': username, 'password': password}),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         // Get the custom token from your backend
//         // Your backend should generate a Firebase custom token
//         final String customToken = data['firebaseToken'];

//         // Step 2: Sign in to Firebase with the custom token
//         final UserCredential userCredential = await _auth.signInWithCustomToken(
//           customToken,
//         );

//         return userCredential.user;
//       } else {
//         throw Exception('Login failed: ${response.body}');
//       }
//     } catch (e) {
//       print('Error signing in: $e');
//       return null;
//     }
//   }

//   // Alternative: If you don't need Firebase at all
//   Future<Map<String, dynamic>?> signInERPOnly(
//     String username,
//     String password,
//   ) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$_backendUrl/login'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'username': username, 'password': password}),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         // Store the token locally for future API calls
//         // You might want to use flutter_secure_storage for this
//         final String erpToken = data['token'];
//         final Map<String, dynamic> userData = data['user'];

//         // Save token for later use
//         await _saveToken(erpToken);

//         return userData;
//       } else {
//         throw Exception('Login failed');
//       }
//     } catch (e) {
//       print('Error signing in: $e');
//       return null;
//     }
//   }

//   Future<void> _saveToken(String token) async {
//     // Use shared_preferences or flutter_secure_storage
//     // Example with shared_preferences:
//     // final prefs = await SharedPreferences.getInstance();
//     // await prefs.setString('erp_token', token);
//   }

//   Future<void> signOut() async {
//     // Clear local token
//     // final prefs = await SharedPreferences.getInstance();
//     // await prefs.remove('erp_token');

//     // If using Firebase
//     await _auth.signOut();
//   }
// }
