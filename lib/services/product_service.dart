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
            debugPrint('Processing product: ${productJson['name']}');

            // Parse toppings
            List<Topping>? toppings;
            if (productJson['toppings'] != null) {
              toppings = (productJson['toppings'] as List)
                  .map((topping) => Topping(
                id: topping['id'],
                name: topping['name'],
                price: topping['price'] is int
                    ? topping['price'].toDouble()
                    : topping['price'],
              ))
                  .toList();
            }

            // Parse addons with their options
            List<Addon>? addons;
            if (productJson['addons'] != null) {
              addons = (productJson['addons'] as List)
                  .map((addon) {
                List<AddonOption> options = [];

                if (addon['options'] != null) {
                  options = (addon['options'] as List)
                      .map((option) => AddonOption(
                    id: option['id'],
                    label: option['label'],
                    price: option['price'] is int
                        ? option['price'].toDouble()
                        : option['price'],
                    isDefault: option['isDefault'] ?? false,
                  ))
                      .toList();
                }

                return Addon(
                  id: addon['id'],
                  name: addon['name'],
                  options: options,
                  price: 0.0, // jika memang tidak ada harga di level addon, atau sesuaikan dengan struktur data kamu
                );

              })
                  .toList();
            }

            // Handle discount percentage
            String? discountPercentage;
            if (productJson['discountPercentage'] != null) {
              discountPercentage = productJson['discountPercentage'].toString();
            }

            // Parse prices safely
            double originalPrice = 0.0;
            if (productJson['originalPrice'] != null) {
              originalPrice = productJson['originalPrice'] is int
                  ? productJson['originalPrice'].toDouble()
                  : productJson['originalPrice'];
            }

            double discountPrice = originalPrice;
            if (productJson['discountPrice'] != null) {
              discountPrice = productJson['discountPrice'] is int
                  ? productJson['discountPrice'].toDouble()
                  : productJson['discountPrice'];
            }

            // Handle category and mainCategory
            String category = 'Uncategorized';
            if (productJson['category'] != null) {
              category = productJson['category'] is List
                  ? (productJson['category'] as List).join(', ')
                  : productJson['category'].toString();
            }

            String mainCategory = 'Uncategorized';
            if (productJson['mainCategory'] != null) {
              mainCategory = productJson['mainCategory'] is List
                  ? (productJson['mainCategory'] as List).join(', ')
                  : productJson['mainCategory'].toString();
            }

            return Product(
              id: productJson['id'],
              name: productJson['name'],
              category: category,
              mainCategory: mainCategory,
              imageUrl: productJson['imageUrl'] ?? '',
              originalPrice: originalPrice,
              discountPrice: discountPrice,
              description: productJson['description'] ?? '',
              discountPercentage: discountPercentage,
              toppings: toppings ?? [],
              addons: addons ?? [],
              imageColor: generateImageColor(mainCategory),
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
    return products.where((product) =>
        product.category.toLowerCase().contains(category.toLowerCase())).toList();
  }

  Future<List<Product>> getProductsByMainCategory(String mainCategory) async {
    final products = await getProducts();
    return products.where((product) =>
        product.mainCategory.toLowerCase().contains(mainCategory.toLowerCase())).toList();
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