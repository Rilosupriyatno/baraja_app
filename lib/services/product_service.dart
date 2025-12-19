import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductService {
  final String? baseUrl = dotenv.env['BASE_URL'];
  
  // ✅ CACHING: Static cache for products with TTL
  static List<Product>? _cachedProducts;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  ProductService();
  
  /// Clear the product cache (call on logout or when data changes)
  static void clearCache() {
    _cachedProducts = null;
    _cacheTime = null;
  }

  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    try {
      // ✅ Return cached products if valid and not forcing refresh
      if (!forceRefresh && _cachedProducts != null && _cacheTime != null) {
        final cacheAge = DateTime.now().difference(_cacheTime!);
        if (cacheAge < _cacheDuration) {
          debugPrint('📦 Using cached products (${_cachedProducts!.length} items, age: ${cacheAge.inSeconds}s)');
          return _cachedProducts!;
        }
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/menu/menu-items'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> productsJson = jsonData['data'];

          final List<Product> productsList = productsJson.map((productJson) {
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
                    isDefault: option['isdefault'] ??
                        option['isDefault'] ??
                        false,
                  ))
                      .toList();
                }

                return Addon(
                  id: addon['_id'] ?? addon['id'] ?? '',
                  name: addon['name'] ?? '',
                  options: options,
                  price: 0.0,
                );
              }).toList();
            }

            // Handle discount percentage
            String? discountPercentage;
            if (productJson['discountPercentage'] != null) {
              discountPercentage =
                  productJson['discountPercentage'].toString();
            }

            // Parse prices
            double originalPrice = 0.0;
            if (productJson['originalPrice'] != null) {
              originalPrice = productJson['originalPrice'] is int
                  ? productJson['originalPrice'].toDouble()
                  : double.tryParse(
                  productJson['originalPrice'].toString()) ??
                  0.0;
            }

            double discountPrice = originalPrice;
            if (productJson['discountedPrice'] != null) {
              discountPrice = productJson['discountedPrice'] is int
                  ? productJson['discountedPrice'].toDouble()
                  : double.tryParse(
                  productJson['discountedPrice'].toString()) ??
                  0.0;
            }

            // Extract mainCategory (makanan/minuman)
            String mainCategory = 'Makanan';
            if (productJson['mainCategory'] != null &&
                productJson['mainCategory'].toString().isNotEmpty) {
              String rawMainCat = productJson['mainCategory'].toString().toLowerCase();
              if (rawMainCat == 'minuman' || rawMainCat == 'drinks') {
                mainCategory = 'Minuman';
              } else {
                mainCategory = 'Makanan';
              }
            }

            // Extract category name (Pasta, Frappe, Mocktail, dll)
            String categoryName = 'Lainnya';
            if (productJson['category'] != null) {
              var cat = productJson['category'];
              if (cat is Map && cat['name'] != null && cat['name'].toString().isNotEmpty) {
                categoryName = cat['name'];
              } else if (cat is String && cat.isNotEmpty) {
                categoryName = cat;
              }
            }

            // Parse availableAt → ambil outletId & name
            List<Outlet> outlets = [];
            if (productJson['availableAt'] != null) {
              outlets = (productJson['availableAt'] as List)
                  .map((outlet) => Outlet(
                outletId: outlet['_id']?.toString() ?? '',
                name: outlet['name'] ?? '',
              ))
                  .toList();
            }

            return Product(
              id: productJson['id'] ?? productJson['_id'] ?? '',
              name: productJson['name'] ?? '',
              category: categoryName,
              mainCategory: mainCategory,
              subCategory: null,
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
              availableAt: outlets,
            );
          }).toList();
          
          // ✅ Cache the products
          _cachedProducts = productsList;
          _cacheTime = DateTime.now();
          debugPrint('📦 Cached ${productsList.length} products');
          
          return productsList;
        } else {
          debugPrint(
              'API returned error: ${jsonData['message'] ?? 'Unknown error'}');
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

  Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getProducts();
    return products
        .where((product) => product.category
        .toString()
        .toLowerCase()
        .contains(category.toLowerCase()))
        .toList();
  }

  Future<List<Product>> getProductsByMainCategory(String mainCategory) async {
    final products = await getProducts();
    return products
        .where((product) => product.mainCategory
        .toLowerCase()
        .contains(mainCategory.toLowerCase()))
        .toList();
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
    return products
        .where((product) => product.discountPercentage != null)
        .toList();
  }

  // ==================== SEARCH METHODS ====================

  /// Search products by query (name, category, description)
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final products = await getProducts();
    final lowercaseQuery = query.toLowerCase();

    return products.where((product) {
      final matchesName = product.name.toLowerCase().contains(lowercaseQuery);
      final matchesCategory = product.category?.toLowerCase().contains(lowercaseQuery) ?? false;
      final matchesDescription = product.description.toLowerCase().contains(lowercaseQuery);
      final matchesMainCategory = product.mainCategory.toLowerCase().contains(lowercaseQuery);

      return matchesName || matchesCategory || matchesDescription || matchesMainCategory;
    }).toList();
  }

  /// Search products with ranking/scoring
  Future<List<Product>> searchProductsWithRanking(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final products = await getProducts();
    final lowercaseQuery = query.toLowerCase();

    // Create a list with products and their relevance score
    final productsWithScore = products.map((product) {
      int score = 0;

      // Name match (highest priority)
      if (product.name.toLowerCase() == lowercaseQuery) {
        score += 100;
      } else if (product.name.toLowerCase().startsWith(lowercaseQuery)) {
        score += 50;
      } else if (product.name.toLowerCase().contains(lowercaseQuery)) {
        score += 25;
      }

      // Category match
      if (product.category?.toLowerCase() == lowercaseQuery) {
        score += 30;
      } else if (product.category?.toLowerCase().contains(lowercaseQuery) ?? false) {
        score += 15;
      }

      // Description match (lowest priority)
      if (product.description.toLowerCase().contains(lowercaseQuery)) {
        score += 5;
      }

      // Main category match
      if (product.mainCategory.toLowerCase().contains(lowercaseQuery)) {
        score += 10;
      }

      return {'product': product, 'score': score};
    }).where((item) => (item['score'] as int) > 0).toList();

    // Sort by score (descending)
    productsWithScore.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Return only products
    return productsWithScore.map((item) => item['product'] as Product).toList();
  }

  /// Get search suggestions based on query
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final products = await getProducts();
    final lowercaseQuery = query.toLowerCase();
    final suggestions = <String>{};

    for (var product in products) {
      // Add matching product names
      if (product.name.toLowerCase().contains(lowercaseQuery)) {
        suggestions.add(product.name);
      }

      // Add matching categories
      if (product.category?.toLowerCase().contains(lowercaseQuery) ?? false) {
        suggestions.add(product.category!);
      }
    }

    return suggestions.take(5).toList();
  }

  /// Search products by multiple filters
  Future<List<Product>> searchProductsAdvanced({
    String? query,
    String? mainCategory,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? hasDiscount,
  }) async {
    final products = await getProducts();

    return products.where((product) {
      // Query filter
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        final matchesQuery = product.name.toLowerCase().contains(lowercaseQuery) ||
            (product.category?.toLowerCase().contains(lowercaseQuery) ?? false) ||
            (product.description.toLowerCase().contains(lowercaseQuery));

        if (!matchesQuery) return false;
      }

      // Main category filter
      if (mainCategory != null && product.mainCategory != mainCategory) {
        return false;
      }

      // Category filter
      if (category != null && product.category != category) {
        return false;
      }

      // Price range filter
      if (minPrice != null && product.discountPrice! < minPrice) {
        return false;
      }

      if (maxPrice != null && product.discountPrice! > maxPrice) {
        return false;
      }

      // Discount filter
      if (hasDiscount != null && hasDiscount) {
        if (product.discountPercentage == null) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}