import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final String? baseUrl = dotenv.env['BASE_URL'];
  Map<String, dynamic>? _user;
  String? _jwtToken;

  Map<String, dynamic>? get user => _user;
  String? get jwtToken => _jwtToken;


  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login dengan email dan password
  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Add this method to your existing AuthService class
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  // Register dengan email dan password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Step 1: Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Login dibatalkan oleh pengguna');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('Token Google tidak lengkap');
      }

      // Step 2: Firebase Auth (Opsional, bisa dilewati kalau hanya pakai backend sendiri)
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Step 3: Kirim idToken ke backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': googleAuth.idToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Login sukses: ${responseData['user']['email']}');
        print('Token JWT dari backend: ${responseData['token']}');
        _user = responseData['user'];
        _jwtToken = responseData['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _jwtToken!);

        notifyListeners();
        // Simpan token jika perlu (misalnya ke SharedPreferences)
      } else {
        print('Gagal login ke backend: ${response.body}');
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        notifyListeners();
      } else {
        print('Gagal fetch user profile: ${response.body}');
      }
    } catch (e) {
      print('Error get profile: $e');
    }
  }

  // Add this method to your AuthService class
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return false;

      // Set the token in memory
      _jwtToken = token;

      // Try to fetch the user profile to validate the token
      await fetchUserProfile();

      // If we have user data, the token is valid
      return _user != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  Future<void> logoutFromGoogle() async {
    try {
      // Step 1: Logout dari Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        _user = null;
        _jwtToken = null;
        notifyListeners();

        print('Logout dari Google Sign-In berhasil');
      }

      // Step 2: Logout dari Firebase (jika kamu pakai FirebaseAuth)
      await FirebaseAuth.instance.signOut();
      print('Logout dari Firebase Auth berhasil');

      // Step 3: Hapus token JWT backend (jika kamu simpan ke SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      print('Token backend dihapus');

      // ✅ Tambahkan redirect atau navigasi ke halaman login jika perlu
      // Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Terjadi kesalahan saat logout: $e');
    }
  }

  // Handler untuk FirebaseAuthException
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'email-already-in-use':
        return Exception('The email address is already in use.');
      case 'weak-password':
        return Exception('The password is too weak.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}