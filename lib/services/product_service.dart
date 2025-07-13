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

        // Ubah dari 'formattedData' ke 'data'
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> productsJson = jsonData['data'];

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

            // Parse prices safely - sesuaikan dengan backend response
            double originalPrice = 0.0;
            if (productJson['originalPrice'] != null) {
              originalPrice = productJson['originalPrice'] is int
                  ? productJson['originalPrice'].toDouble()
                  : double.tryParse(productJson['originalPrice'].toString()) ?? 0.0;
            }

            double discountPrice = originalPrice;
            if (productJson['discountedPrice'] != null) {
              discountPrice = productJson['discountedPrice'] is int
                  ? productJson['discountedPrice'].toDouble()
                  : double.tryParse(productJson['discountedPrice'].toString()) ?? 0.0;
            }

            // Process category - sesuaikan dengan backend response
            dynamic rawCategory = productJson['category'] ?? {'name': 'Uncategorized'};

            // Process subCategory - ambil dari backend response
            String subCategoryName = 'Lainnya';
            if (productJson['subCategory'] != null) {
              var subCat = productJson['subCategory'];
              if (subCat is Map && subCat['name'] != null) {
                subCategoryName = subCat['name'];
              } else if (subCat is String) {
                subCategoryName = subCat;
              }
            }

            // Determine mainCategory berdasarkan category
            String mainCategory = 'Makanan';
            if (rawCategory is Map && rawCategory['name'] != null) {
              String categoryName = rawCategory['name'];
              if (categoryName.toLowerCase().contains('minuman') ||
                  categoryName.toLowerCase().contains('drink') ||
                  categoryName.toLowerCase().contains('coffee') ||
                  categoryName.toLowerCase().contains('tea')) {
                mainCategory = 'Minuman';
              }
            }

            return Product(
              id: productJson['id'] ?? productJson['_id'] ?? '',
              name: productJson['name'] ?? '',
              category: rawCategory, // Pass the full category object
              mainCategory: subCategoryName, // Use subCategory as mainCategory for filtering
              imageUrl: productJson['imageUrl'] ?? '',
              originalPrice: originalPrice,
              discountPrice: discountPrice,
              description: productJson['description'] ?? '',
              discountPercentage: discountPercentage,
              toppings: toppings ?? [],
              addons: addons ?? [],
              averageRating: productJson['averageRating'] is num
                  ? (productJson['averageRating'] as num).toDouble()
                  : 0.0,
              reviewCount: productJson['reviewCount'] is int
                  ? productJson['reviewCount']
                  : (productJson['reviewCount'] ?? 0),
              imageColor: generateImageColor(mainCategory),
            );
          }).toList();
        } else {
          debugPrint('API returned error: ${jsonData['message'] ?? 'Unknown error'}');
          debugPrint('Response body: ${response.body}'); // Debug tambahan
          throw Exception('Failed to load products');
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}'); // Debug tambahan
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