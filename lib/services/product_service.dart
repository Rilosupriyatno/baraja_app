import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  ProductService();

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/menu/menu-items'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['formattedData'] != null) {
          final List<dynamic> productsJson = jsonData['formattedData'];

          return productsJson.map((productJson) {
            // Parse toppings
            List<Topping>? toppings;
            if (productJson['toppings'] != null) {
              toppings = (productJson['toppings'] as List)
                  .map((topping) => Topping(
                id: topping['id'],
                name: topping['name'],
                price: topping['price'].toDouble(),
              ))
                  .toList();
            }

            // Parse addons
            List<Addon>? addons;
            if (productJson['addons'] != null) {
              addons = (productJson['addons'] as List)
                  .map((addon) => Addon(
                id: addon['id'],
                name: addon['name'],
                price: addon['price'].toDouble(),
              ))
                  .toList();
            }

            // Discount as String
            String? discountPercentage;
            if (productJson['discountPercentage'] != null) {
              discountPercentage = productJson['discountPercentage'].toString();
            }

            return Product(
              id: productJson['id'],
              name: productJson['name'],
              category: productJson['category'] is List
                  ? (productJson['category'] as List).join(', ')
                  : productJson['category'] ?? 'Uncategorized',

              mainCategory: productJson['mainCategory'] is List
                  ? (productJson['mainCategory'] as List).join(', ')
                  : productJson['mainCategory'] ?? 'Uncategorized',

              imageUrl: productJson['imageUrl'],
              originalPrice: productJson['originalPrice'].toDouble(),
              discountPrice: productJson['discountPrice']?.toDouble() ??
                  productJson['originalPrice'].toDouble(),
              description: productJson['description'],
              discountPercentage: discountPercentage,
              toppings: toppings,
              addons: addons,
              imageColor: generateImageColor(productJson['mainCategory']),
            );
          }).toList();
        } else {
          debugPrint('API returned error: ${jsonData['message'] ?? 'Unknown error'}');
          throw Exception('Failed to load products');
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        throw Exception('Failed to load products');
      }
    } catch (e) {
      debugPrint('Exception caught in getProducts(): $e');
      throw Exception('Failed to load products: $e');
    }
  }

  // Helper function to assign color locally
  Color generateImageColor(String mainCategory) {
    switch (mainCategory.toLowerCase()) {
      case 'makanan':
        return Colors.orange.shade300;
      case 'minuman':
        return Colors.blue.shade300;
      case 'snack':
        return Colors.purple.shade300;
      default:
        return Colors.grey.shade400;
    }
  }

  // Other filter functions
  Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getProducts();
    return products.where((product) => product.category == category).toList();
  }

  Future<List<Product>> getProductsByMainCategory(String mainCategory) async {
    final products = await getProducts();
    return products.where((product) => product.mainCategory == mainCategory).toList();
  }

  Future<Product?> getProductById(String id) async {
    final products = await getProducts();
    try {
      return products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Product>> getDiscountedProducts() async {
    final products = await getProducts();
    return products.where((product) => product.discountPercentage != null).toList();
  }
}
