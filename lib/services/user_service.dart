import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // static const String baseUrl = 'YOUR_API_BASE_URL'; // Ganti dengan URL API Anda
  static final String? baseUrl = dotenv.env['BASE_URL'];

  // Model untuk User Data
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update User Profile
  static Future<bool> updateUserProfile({
    required String username,
    String? email,
    String? phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return false;

      final Map<String, dynamic> requestData = {
        'username': username,
      };

      if (email != null) requestData['email'] = email;
      if (phone != null && phone.isNotEmpty) requestData['phone'] = phone;

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Change Password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password berhasil diubah'};
      } else if (response.statusCode == 400) {
        return {'success': false, 'message': responseData['message'] ?? 'Password lama tidak sesuai'};
      } else {
        return {'success': false, 'message': 'Gagal mengubah password'};
      }
    } catch (e) {
      print('Error changing password: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // Check if user is Google user
  static Future<bool> isGoogleUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/user/auth-type'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['authType'] == 'google' || responseData['password'] == '-';
      }

      return false;
    } catch (e) {
      print('Error checking auth type: $e');
      return false;
    }
  }

  // Save user data to local storage
  static Future<void> saveUserDataLocally(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_id', userData['_id'] ?? '');
    await prefs.setString('username', userData['username'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('phone', userData['phone'] ?? '');
    await prefs.setString('profile_picture', userData['profilePicture'] ?? '');
    await prefs.setString('role', userData['role'] ?? 'customer');

    // Untuk mengetahui apakah user Google atau bukan
    await prefs.setBool('is_google_user', userData['password'] == '-' || userData['password'] == null);
  }

  // Get user data from local storage
  static Future<Map<String, dynamic>> getUserDataLocally() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'user_id': prefs.getString('user_id') ?? '',
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'phone': prefs.getString('phone') ?? '',
      'profile_picture': prefs.getString('profile_picture') ?? '',
      'role': prefs.getString('role') ?? 'customer',
      'is_google_user': prefs.getBool('is_google_user') ?? false,
    };
  }
}