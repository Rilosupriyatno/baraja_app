import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: dotenv.env['WEB_CLIENT_ID'], // Web Client ID
  );
  final String? baseUrl = dotenv.env['BASE_URL'];

  Map<String, dynamic>? _user;
  String? _jwtToken;

  Map<String, dynamic>? get user => _user;
  String? get jwtToken => _jwtToken;

  // ==============================
  // REGISTER DENGAN EMAIL DAN PASSWORD
  // ==============================
  Future<void> registerWithEmailAndPassword(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json','ngrok-skip-browser-warning': 'true',},
      body: jsonEncode({
        'username': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      _user = responseData['user'];
      _jwtToken = responseData['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _user?['_id'] ?? '');
      await prefs.setString('username', _user?['username'] ?? '');
      await prefs.setString('userRole', _user?['role'] ?? '');
      await prefs.setString('token', _jwtToken!);

      notifyListeners();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Registrasi gagal');
    }
  }

  // ==============================
  // LOGIN DENGAN GOOGLE
  // ==============================
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Login dibatalkan oleh pengguna');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('Token Google tidak lengkap');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json','ngrok-skip-browser-warning': 'true',},
        body: jsonEncode({'idToken': googleAuth.idToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _user = responseData['user'];
        _jwtToken = responseData['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _user?['_id'] ?? '');
        await prefs.setString('username', _user?['username'] ?? '');
        await prefs.setString('userRole', _user?['role'] ?? '');
        await prefs.setString('token', _jwtToken!);

        notifyListeners();
        _saveFcmToken();

      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Google login gagal');
      }
    } catch (e) {
      throw Exception('Google login gagal: $e');
    }
  }

  // ==============================
  // LOGIN DENGAN EMAIL DAN PASSWORD / USERNAME DAN PASSWORD
  // ==============================
  Future<void> loginWithEmailAndPassword(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signin'),
      headers: {'Content-Type': 'application/json','ngrok-skip-browser-warning': 'true',},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Extract user data and token
      _jwtToken = responseData['token'];

      // Remove token from user data if it exists
      final userData = Map<String, dynamic>.from(responseData);
      userData.remove('token');
      userData.remove('cashiers'); // Remove cashiers list if exists

      _user = userData;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _user?['_id'] ?? '');
      await prefs.setString('username', _user?['username'] ?? '');
      await prefs.setString('userRole', _user?['role'] ?? '');
      await prefs.setString('token', _jwtToken!);

      // If user is admin and has cashiers data, save it separately if needed
      if (responseData['cashiers'] != null) {
        await prefs.setString('cashiers', jsonEncode(responseData['cashiers']));
      }

      notifyListeners();
      _saveFcmToken();

    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Login gagal: ${response.body}');
    }
  }

  // Tambahkan method debugging ini ke auth_service.dart

  Future<void> _saveFcmToken() async {
    try {
      print("🔄 Starting FCM token save process...");

      // Check if user is logged in
      if (_jwtToken == null) {
        print("❌ No JWT token available");
        return;
      }

      // Request FCM permission first
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print("📱 FCM Permission status: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print("❌ FCM permission denied");
        return;
      }

      final fcmToken = await messaging.getToken();
      print("🔑 FCM Token: ${fcmToken?.substring(0, 20)}..."); // Print partial token for debugging

      if (fcmToken == null) {
        print("❌ FCM token is null");
        return;
      }

      if (_jwtToken == null) {
        print("❌ JWT token is null");
        return;
      }

      print("🌐 Sending request to: $baseUrl/api/fcm/save-fcm-token");
      print("🔐 Using JWT token: ${_jwtToken?.substring(0, 20)}...");

      final response = await http.post(
        Uri.parse('$baseUrl/api/fcm/save-fcm-token'),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'device_type': 'android',
        }),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📡 Response body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ FCM token saved successfully");
      } else {
        print("❌ Failed to save FCM token. Status: ${response.statusCode}");
        print("❌ Error response: ${response.body}");
      }
    } catch (e) {
      print("💥 Exception in _saveFcmToken: $e");
      print("💥 Exception type: ${e.runtimeType}");
    }
  }

  Future<void> _removeFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && _jwtToken != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/api/fcm/remove-fcm-token'),
          headers: {
            'Authorization': 'Bearer $_jwtToken',
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
          body: jsonEncode({'fcm_token': fcmToken}),
        );
        if (response.statusCode != 200) {
          print("Failed to remove FCM token: ${response.body}");
        }
      }
    } catch (e) {
      print("Error removing FCM token: $e");
    }
  }


  // ==============================
  // RESET PASSWORD
  // ==============================
  Future<void> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json','ngrok-skip-browser-warning': 'true',},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mengirim email reset password');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // ==============================
  // CEK STATUS LOGIN
  // ==============================
  Future<bool> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');

      if (storedToken != null) {
        // Validate token with backend
        final response = await http.get(
          Uri.parse('$baseUrl/api/user/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $storedToken',
            'ngrok-skip-browser-warning': 'true',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _user = data['user'];
          _jwtToken = storedToken;
          notifyListeners();

          return true;
        } else {
          // Token expired or invalid
          await logout();
          return false;
        }
      }
    } catch (e) {
      print('Error checking login status: $e');
      await logout();
    }
    return false;
  }

  // ==============================
  // FETCH USER PROFILE
  // ==============================
  Future<void> fetchUserProfile() async {
    if (_jwtToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_jwtToken',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        notifyListeners();
      } else {
        print('Failed to fetch profile: ${response.body}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  // ==============================
  // GET USER ROLE
  // ==============================
  String? getUserRole() {
    return _user?['role'];
  }

  // ==============================
  // CHECK IF USER IS ADMIN
  // ==============================
  bool isAdmin() {
    final role = getUserRole();
    return role != null && [
      'superadmin',
      'admin',
      'marketing',
      'akuntan',
      'inventory',
      'operational',
      'staff',
      'cashier junior',
      'cashier senior'
    ].contains(role);
  }

  // ==============================
  // CHECK IF USER IS CUSTOMER
  // ==============================
  bool isCustomer() {
    return getUserRole() == 'customer';
  }

  // ==============================
  // LOGOUT
  // ==============================
  Future<void> logout() async {
    try {
      _removeFcmToken();
      _user = null;
      _jwtToken = null;

      // Sign out from Google and Firebase
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('username');
      await prefs.remove('userRole');
      await prefs.remove('cashiers');

      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
      // Still clear local data even if there's an error
      _user = null;
      _jwtToken = null;
      notifyListeners();
    }
  }
}