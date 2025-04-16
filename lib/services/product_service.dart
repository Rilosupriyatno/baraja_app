import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  ProductService();

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/menu-items'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['formattedData'] != null) {
          final List<dynamic> productsJson = jsonData['formattedData'];

          return productsJson.map((productJson) {
            // Parse toppings if available
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

            // Parse addons if available
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

            // Handle discount percentage value - could be String or double
            String? discountPercentage;
            if (productJson['discountPercentage'] != null) {
              discountPercentage = productJson['discountPercentage'].toString();
            }

            // Convert color string to Color object if provided
            Color? imageColor;
            if (productJson['imageColor'] != null && productJson['imageColor'] is String) {
              String colorHex = productJson['imageColor'].toString().replaceFirst('#', '');
              if (colorHex.length == 6) {
                imageColor = Color(int.parse('0xFF$colorHex'));
              }
            }

            return Product(
              id: productJson['id'],
              name: productJson['name'],
              category: productJson['category'],
              mainCategory: productJson['mainCategory'],
              imageUrl: productJson['imageUrl'],
              originalPrice: productJson['originalPrice'].toDouble(),
              discountPrice: productJson['discountPrice']?.toDouble() ?? productJson['originalPrice'].toDouble(),
              description: productJson['description'],
              discountPercentage: discountPercentage,
              toppings: toppings,
              addons: addons,
              imageColor: imageColor,
            );
          }).toList();
        } else {
          throw Exception('Failed to load products: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load products: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  // Method to get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getProducts();
    return products.where((product) => product.category == category).toList();
  }

  // Method to get products by main category (Makanan/Minuman)
  Future<List<Product>> getProductsByMainCategory(String mainCategory) async {
    final products = await getProducts();
    return products.where((product) => product.mainCategory == mainCategory).toList();
  }

  // Method to get product by id
  Future<Product?> getProductById(String id) async {
    final products = await getProducts();
    try {
      return products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Method to get products with discount
  Future<List<Product>> getDiscountedProducts() async {
    final products = await getProducts();
    return products.where((product) => product.discountPercentage != null).toList();
  }
}