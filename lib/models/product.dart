import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String mainCategory; // Makanan atau Minuman
  final String imageUrl;
  final double? originalPrice;
  final double? discountPrice;
  final String description;
  final String? discountPercentage;
  final List<Topping>? toppings;
  final List<Addon>? addons;
  final Color? imageColor;

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
  });
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
  final String title;
  final Color? color;

  PromoItem({
    required this.title,
    this.color,
  });
}
