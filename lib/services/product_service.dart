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
      final response = await http.get(
        Uri.parse('$baseUrl/api/menu/menu-items'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      );

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
                id: topping['id'] ?? topping['_id'] ?? '',
                name: topping['name'] ?? '',
                price: topping['price'] is int
                    ? topping['price'].toDouble()
                    : (topping['price'] ?? 0).toDouble(),
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
                    id: option['_id'] ?? option['id'] ?? '',
                    label: option['label'] ?? '',
                    price: option['price'] is int
                        ? option['price'].toDouble()
                        : (option['price'] ?? 0).toDouble(),
                    isDefault: option['isdefault'] ?? option['isDefault'] ?? false,
                  ))
                      .toList();
                }

                return Addon(
                  id: addon['_id'] ?? addon['id'] ?? '',
                  name: addon['name'] ?? '',
                  options: options,
                  price: 0.0,
                );
              })
                  .toList();
            }

            // Handle discount percentage
            String? discountPercentage;
            if (productJson['discountPercentage'] != null) {
              discountPercentage = productJson['discountPercentage'].toString();
            }

            // print(discountPercentage);

            // Parse prices safely
            double originalPrice = 0.0;
            if (productJson['price'] != null) {
              originalPrice = productJson['price'] is int
                  ? productJson['price'].toDouble()
                  : double.tryParse(productJson['price'].toString()) ?? 0.0;
            } else if (productJson['originalPrice'] != null) {
              originalPrice = productJson['originalPrice'] is int
                  ? productJson['originalPrice'].toDouble()
                  : double.tryParse(productJson['originalPrice'].toString()) ?? 0.0;
            }

            double discountPrice = originalPrice;
            if (productJson['discountPrice'] != null) {
              discountPrice = productJson['discountPrice'] is int
                  ? productJson['discountPrice'].toDouble()
                  : double.tryParse(productJson['discountPrice'].toString()) ?? 0.0;
            }

            // Process category - IMPORTANT: Handle various types safely
            dynamic rawCategory = productJson['category'] ?? 'Uncategorized';

            // Keep the category in its original form (list or string)
            // We'll process it in the MenuScreen _extractCategories method

            // Default mainCategory to 'Makanan' for foods and 'Minuman' for drinks
            String mainCategory = 'Makanan';

            // Try to determine if this is a drink based on categories
            bool isDrink = false;

            if (rawCategory is List) {
              for (var cat in rawCategory) {
                if (cat is String &&
                    (cat.toLowerCase().contains('coffee') ||
                        cat.toLowerCase().contains('chocolate') ||
                        cat.toLowerCase().contains('tea') ||
                        cat.toLowerCase().contains('milk'))) {
                  isDrink = true;
                  break;
                }
              }
            } else if (rawCategory is String) {
              if (rawCategory.toLowerCase().contains('coffee') ||
                  rawCategory.toLowerCase().contains('chocolate') ||
                  rawCategory.toLowerCase().contains('tea') ||
                  rawCategory.toLowerCase().contains('milk')) {
                isDrink = true;
              }
            }

            mainCategory = isDrink ? 'Minuman' : 'Makanan';

            // Use explicit mainCategory if provided
            if (productJson['mainCategory'] != null) {
              if (productJson['mainCategory'] is String) {
                mainCategory = productJson['mainCategory'];
              } else if (productJson['mainCategory'] is List &&
                  (productJson['mainCategory'] as List).isNotEmpty) {
                mainCategory = productJson['mainCategory'][0].toString();
              }
            }

            return Product(
              id: productJson['_id'] ?? productJson['id'] ?? '',
              name: productJson['name'] ?? '',
              category: rawCategory, // Pass the raw category data
              mainCategory: mainCategory,
              imageUrl: productJson['imageURL'] ?? productJson['imageUrl'] ?? '',
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