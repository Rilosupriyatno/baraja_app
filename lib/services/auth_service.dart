import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final String? baseUrl = dotenv.env['BASE_URL']; // Ganti dengan base URL-mu

  Map<String, dynamic>? _user;
  String? _jwtToken;

  Map<String, dynamic>? get user => _user;
  String? get jwtToken => _jwtToken;

  // ==============================
// REGISTER DENGAN EMAIL DAN PASSWORD
// ==============================
  Future<void> registerWithEmailAndPassword(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signup'), // pastikan endpoint ini benar
      headers: {'Content-Type': 'application/json'},
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
      await prefs.setString('token', _jwtToken!);

      notifyListeners();
    } else {
      throw Exception('Registrasi gagal: ${response.body}');
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': googleAuth.idToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _user = responseData['user'];
        _jwtToken = responseData['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _user?['_id']); // simpan userId
        await prefs.setString('username', _user?['name']); // simpan userName
        await prefs.setString('token', _jwtToken!);    // simpan token


        notifyListeners();
      } else {
        print('Gagal login ke backend: ${response.body}');
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
    }
  }

  // ==============================
  // REGISTER DENGAN EMAIL DAN PASSWORD
  // ==============================
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Login gagal: ${response.body}');
    }

    // Simpan token atau data jika diperlukan
  }


  // ==============================
  // RESET PASSWORD
  // ==============================
  Future<void> resetPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengirim email reset password');
    }
  }

  // ==============================
  // CEK STATUS LOGIN
  // ==============================
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token');

    if (storedToken != null) {
      // Coba validasi token dengan backend
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
        await logout(); // Token expired atau tidak valid
      }
    }
    return false;
  }

  // ==============================
  // FETCH USER PROFILE
  // ==============================
  Future<void> fetchUserProfile() async {
    if (_jwtToken == null) return;

    final response = await http.get(
      Uri.parse('$baseUrl/api/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = data['user'];
      notifyListeners();
    } else {
      print('Gagal ambil profil: ${response.body}');
    }
  }

  // ==============================
  // LOGOUT
  // ==============================
  Future<void> logout() async {
    _user = null;
    _jwtToken = null;

    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    notifyListeners();
  }
}

