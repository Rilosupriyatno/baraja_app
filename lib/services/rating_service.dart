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
    required String orderId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/customer/$menuItemId/$orderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting existing rating: $e');
      return null;
    }
  }

  // Create new rating
  static Future<Map<String, dynamic>> createRating({
    required String menuItemId,
    required String orderId,
    required int rating,
    String? review,
    // List<String>? tags,
    // List<String>? imageUrls, // Ubah nama parameter
  }) async {
    try {
      // Format images sesuai ekspektasi backend
      // List<Map<String, dynamic>> formattedImages = [];
      // if (imageUrls != null) {
      //   formattedImages = imageUrls.map((url) => {
      //     'url': url,
      //     'caption': '' // atau null jika tidak ada caption
      //   }).toList();
      // }

      final body = {
        'menuItemId': menuItemId,
        'orderId': orderId,
        'rating': rating,
        'review': review ?? '',
        // 'tags': tags ?? [],
        // 'images': formattedImages, // Gunakan format yang benar
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
    // List<String>? tags,
    // List<String>? imageUrls,
  }) async {
    try {
      final body = {
        'rating': rating,
        'review': review ?? '',
        // 'tags': tags ?? [],
        // 'imageUrls': imageUrls ?? [],
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
    required String orderId,
    String? outletId,
    required int rating,
    String? review,
    // List<String>? tags,
    // List<String>? imageUrls,
    Map<String, dynamic>? existingRating,
  }) async {
    if (existingRating != null) {
      // Update existing rating
      return await updateRating(
        ratingId: existingRating['_id'],
        rating: rating,
        review: review,
        // tags: tags,
        // imageUrls: imageUrls,
      );
    } else {
      // Create new rating
      return await createRating(
        menuItemId: menuItemId,
        orderId: orderId,
        // outletId: outletId,
        rating: rating,
        review: review,
        // tags: tags,
        // imageUrls: imageUrls,
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