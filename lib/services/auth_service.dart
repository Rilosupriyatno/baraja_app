import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // Login dengan Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in aborted by user');
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Print out authentication details for debugging
      print('Access Token: ${googleAuth.accessToken}');
      print('ID Token: ${googleAuth.idToken}');

      // Validate tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google authentication tokens are missing');
      }

      // Create new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      throw Exception('Firebase Authentication Error: ${e.message}');
    } on PlatformException catch (e) {
      print('PlatformException: ${e.code} - ${e.message}');
      throw Exception('Platform Error during Google Sign-In: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error during Google sign-in: $e');
    }
  }
  // Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
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