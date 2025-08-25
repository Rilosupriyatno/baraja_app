import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FavoriteService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "ngrok-skip-browser-warning": "true",
    // kalau butuh token:
    // "Authorization": "Bearer $token",
  };

  Future<List<dynamic>> getFavorites(String userId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/favorites/$userId"),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["favorites"] ?? [];
      } else {
        print("Failed to load favorites: ${res.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error getting favorites: $e");
      return [];
    }
  }

  Future<bool> addFavorite(String userId, String menuItemId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/favorites/$userId/$menuItemId"),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return true;
      } else {
        print("Failed to add favorite: ${res.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error adding favorite: $e");
      return false;
    }
  }

  Future<bool> removeFavorite(String userId, String menuItemId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/api/favorites/$userId/$menuItemId"),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return true;
      } else {
        print("Failed to remove favorite: ${res.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error removing favorite: $e");
      return false;
    }
  }
}