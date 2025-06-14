import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final dynamic category;
  final String mainCategory; // Makanan atau Minuman
  final String imageUrl;
  final double? originalPrice;
  final double? discountPrice;
  final String description;
  final String? discountPercentage;
  final List<Topping>? toppings;
  final List<Addon>? addons;
  final Color? imageColor;
  final double averageRating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.mainCategory,
    required this.imageUrl,
    required this.originalPrice,
    required this.discountPrice,
    required this.description,
    this.discountPercentage,
    this.toppings,
    this.addons,
    this.imageColor,
    required this.averageRating,
    required this.reviewCount,
  });
  // You can add methods to help with category processing
  List<String> getCategories() {
    List<String> result = [];

    if (category is List) {
      for (var cat in category) {
        if (cat != null) {
          result.add(cat.toString());
        }
      }
    } else if (category is String) {
      result.add(category);
    } else if (category != null) {
      result.add(category.toString());
    }

    if (result.isEmpty) {
      result.add('Uncategorized');
    }

    return result;
  }

  // Getter to check if this product belongs to a specific category
  bool hasCategory(String categoryName) {
    if (category is List) {
      return (category as List).any((cat) =>
      cat != null && cat.toString().toLowerCase() == categoryName.toLowerCase());
    } else if (category is String) {
      return category.toLowerCase() == categoryName.toLowerCase();
    }
    return false;
  }
}

class Topping {
  final String id;
  final String name;
  final double price;

  Topping({
    required this.id,
    required this.name,
    required this.price,
  });
}

class Addon {
  final String id;
  final String name;
  final double price;
  final List<AddonOption> options;

  Addon({
    required this.id,
    required this.name,
    required this.price,
    required this.options,
  });
}

class AddonOption {
  final String id;
  final String label;
  final double price;
  final bool isDefault;

  AddonOption({
    required this.id,
    required this.label,
    required this.price,
    required this.isDefault,
  });
}



class PromoItem {
  // final String title;
  // final Color? color;
  final String imagePath;

  PromoItem( {
    required this.imagePath,
    // required this.title,
    // this.color,
  });
}
