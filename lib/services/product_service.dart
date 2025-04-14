import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:baraja_app/models/product.dart';
import 'package:baraja_app/models/topping.dart';
import 'package:baraja_app/models/addon.dart';

class ProductService {
  static const String baseUrl = 'http://localhost:3000'; // Ganti sesuai IP server-mu

  static Future<Product?> getProductById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/menu'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded['data'];

        final productJson = data.firstWhere(
              (item) => item['id'] == id,
          orElse: () => null,
        );

        if (productJson != null) {
          return Product.fromJson(productJson);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch product by id: $e');
    }
  }

  static Future<List<Product>> fetchMenuItems() async {
    try {
      final url = Uri.parse('$baseUrl/api/menu');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['data'];
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load menu items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load menu items: $e');
    }
  }

  // Method baru untuk mendapatkan produk berdasarkan kategori
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final allProducts = await fetchMenuItems();
      return allProducts.where((product) =>
      product.category == category ||
          product.mainCategory == category
      ).toList();
    } catch (e) {
      throw Exception('Failed to filter products by category: $e');
    }
  }
}