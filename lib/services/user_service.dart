import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static final String? baseUrl = dotenv.env['BASE_URL'];

  // Get current user profile from API
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('DEBUG: Fetching user data from $baseUrl/api/user/profile');
      print('DEBUG: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final user = responseData['data'] ?? responseData['user'] ?? responseData;
        print('DEBUG: User data fetched: $user');
        await saveUserDataLocally(user);
        return user;
      } else if (response.statusCode == 401) {
        await _clearAuthData();
        return null;
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update User Profile with proper validation
  static Future<Map<String, dynamic>> updateUserProfile({
    required String username,
    String? email,
    String? phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final Map<String, dynamic> requestData = {
        'username': username.trim(),
      };

      if (email != null && email.trim().isNotEmpty) {
        requestData['email'] = email.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        requestData['phone'] = phone.trim();
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['data'] != null) {
          await saveUserDataLocally(responseData['data']);
        }
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profil berhasil diperbarui'
        };
      } else if (response.statusCode == 400) {
        final errors = responseData['errors'] as List?;
        final errorMessages = errors?.map((e) => e['msg']).join(', ') ??
            responseData['message'] ?? 'Data tidak valid';
        return {'success': false, 'message': errorMessages};
      } else if (response.statusCode == 401) {
        await _clearAuthData();
        return {'success': false, 'message': 'Sesi telah berakhir, silakan login ulang'};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memperbarui profil'
        };
      }
    } catch (e) {
      print('Error updating user profile: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // Change Password with proper validation
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/user/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password berhasil diubah'
        };
      } else if (response.statusCode == 400) {
        final errors = responseData['errors'] as List?;
        final errorMessages = errors?.map((e) => e['msg']).join(', ') ??
            responseData['message'] ?? 'Password tidak valid';
        return {'success': false, 'message': errorMessages};
      } else if (response.statusCode == 401) {
        await _clearAuthData();
        return {'success': false, 'message': 'Sesi telah berakhir, silakan login ulang'};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengubah password'
        };
      }
    } catch (e) {
      print('Error changing password: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // Check if user is Google user with improved error handling
  static Future<bool> isGoogleUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('DEBUG isGoogleUser(): BASE_URL = $baseUrl');
      print('DEBUG isGoogleUser(): token = $token');

      if (token == null) {
        print('DEBUG isGoogleUser(): No token, returning false');
        return false;
      }

      // First try to get from local data as fallback
      final localIsGoogle = prefs.getBool('is_google_user') ?? false;
      print('DEBUG isGoogleUser(): Local fallback = $localIsGoogle');

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/auth-type'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8)); // Shorter timeout for this call

      print('DEBUG isGoogleUser(): status = ${response.statusCode}');
      print('DEBUG isGoogleUser(): body = ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('DEBUG isGoogleUser(): responseData = $responseData');

        final authType = (responseData['authType'] ?? '').toString().toLowerCase();
        final bool isGoogle = authType == 'google';

        print('DEBUG isGoogleUser(): authType = $authType, isGoogle = $isGoogle');

        await prefs.setBool('is_google_user', isGoogle);
        return isGoogle;
      } else if (response.statusCode == 404) {
        // If endpoint doesn't exist, try to determine from user profile
        print('DEBUG isGoogleUser(): /auth-type endpoint not found, trying profile');
        return await _isGoogleUserFromProfile();
      }

      print('DEBUG isGoogleUser(): API failed, using local fallback = $localIsGoogle');
      return localIsGoogle;
    } catch (e) {
      print('ERROR isGoogleUser(): $e');
      final prefs = await SharedPreferences.getInstance();
      final fallback = prefs.getBool('is_google_user') ?? false;
      print('DEBUG isGoogleUser(): Exception fallback = $fallback');
      return fallback;
    }
  }

  // Alternative method to check Google user from profile data
  static Future<bool> _isGoogleUserFromProfile() async {
    try {
      final userProfile = await getCurrentUser();
      if (userProfile != null) {
        bool isGoogleUser = userProfile['authType'] == 'google' ||
            userProfile['authType'] == 'oauth' ||
            userProfile['password'] == null ||
            userProfile['password'] == '-' ||
            userProfile['googleId'] != null;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_google_user', isGoogleUser);

        print('DEBUG _isGoogleUserFromProfile(): result = $isGoogleUser');
        return isGoogleUser;
      }
    } catch (e) {
      print('ERROR _isGoogleUserFromProfile(): $e');
    }

    return false;
  }

  // Save user data to local storage
  static Future<void> saveUserDataLocally(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_id', userData['_id'] ?? userData['id'] ?? '');
    await prefs.setString('username', userData['username'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('phone', userData['phone'] ?? '');
    await prefs.setString('profile_picture', userData['profilePicture'] ?? userData['avatar'] ?? '');
    await prefs.setString('role', userData['role'] ?? 'user');

    // Determine if user is Google user
    bool isGoogleUser = userData['authType'] == 'google' ||
        userData['authType'] == 'oauth' ||
        userData['password'] == null ||
        userData['password'] == '-' ||
        userData['googleId'] != null;

    await prefs.setBool('is_google_user', isGoogleUser);
    print('DEBUG saveUserDataLocally(): saved is_google_user = $isGoogleUser');
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
      'role': prefs.getString('role') ?? 'user',
      'is_google_user': prefs.getBool('is_google_user') ?? false,
    };
  }

  // Clear auth data (for logout or token expiry)
  static Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('profile_picture');
    await prefs.remove('role');
    await prefs.remove('is_google_user');
  }

  // Check if token is still valid
  static Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('Fetching user data with token: $token');
      print('DEBUG: BASE_URL = $baseUrl');
      print('DEBUG: Token = $token');

      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('DEBUG isTokenValid(): Response status = ${response.statusCode}');

      if (response.statusCode == 401) {
        await _clearAuthData();
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      print('Error checking token validity: $e');
      return false;
    }
  }

  // Logout user
  static Future<void> logout() async {
    await _clearAuthData();
  }
}