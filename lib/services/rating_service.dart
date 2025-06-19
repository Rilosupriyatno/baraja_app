import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RatingService {
  // Sesuaikan dengan base URL API Anda
  static final String? baseUrl = dotenv.env['BASE_URL'];

  // Common headers for all requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  // Get existing rating for a specific menu item and order
  static Future<Map<String, dynamic>?> getExistingRating({
    required String menuItemId,
    required String id,
  }) async {
    try {
      print('🌐 API Call - URL: $baseUrl/api/my-rating/$menuItemId/$id');

      final response = await http.get(
        Uri.parse('$baseUrl/api/rating/my-rating/$menuItemId/$id'),
        headers: _headers,
      );

      print('🌐 API Response Status: ${response.statusCode}');
      print('🌐 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🌐 Parsed API Response: $data');

        if (data['success'] == true) {
          print('✅ Rating found: ${data['data']}');
          return data['data'];
        } else {
          print('❌ API returned success: false');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('ℹ️ No rating found (404)');
        return null;
      } else {
        print('❌ API Error: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception in _getExistingRating: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  // Create new rating
  static Future<Map<String, dynamic>> createRating({
    required String menuItemId,
    required String id,
    required int rating,
    String? review,
    // List<String>? tags,
    // List<String>? imageUrls, // Ubah nama parameter
  }) async {
    try {

      final body = {
        'menuItemId': menuItemId,
        'id': id,
        'rating': rating,
        'review': review ?? '',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/rating/create'),
        headers: _headers,
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'Unknown error',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  // Update existing rating
  static Future<Map<String, dynamic>> updateRating({
    required String ratingId,
    required int rating,
    String? review,
  }) async {
    try {
      final body = {
        'rating': rating,
        'review': review ?? '',
      };

      final response = await http.put(
        Uri.parse('$baseUrl/ratings/$ratingId'),
        headers: _headers,
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'Unknown error',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  // Submit rating (create or update based on existing rating)
  static Future<Map<String, dynamic>> submitRating({
    required String menuItemId,
    required String id,
    String? outletId,
    required int rating,
    String? review,
    Map<String, dynamic>? existingRating,
  }) async {
    if (existingRating != null) {
      // Update existing rating
      return await updateRating(
        ratingId: existingRating['_id'],
        rating: rating,
        review: review,
      );
    } else {
      // Create new rating
      return await createRating(
        menuItemId: menuItemId,
        id: id,
        rating: rating,
        review: review,
      );
    }
  }

  // Get ratings for a specific menu item (optional feature)
  static Future<List<Map<String, dynamic>>> getMenuItemRatings({
    required String menuItemId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/menu/$menuItemId?page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting menu item ratings: $e');
      return [];
    }
  }

  // Get customer's all ratings (optional feature)
  static Future<List<Map<String, dynamic>>> getCustomerRatings({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/customer?page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting customer ratings: $e');
      return [];
    }
  }

  // Delete rating (optional feature)
  static Future<Map<String, dynamic>> deleteRating({
    required String ratingId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/ratings/$ratingId'),
        headers: _headers,
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'Unknown error',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'message': e.toString(),
        'data': null,
      };
    }
  }
}