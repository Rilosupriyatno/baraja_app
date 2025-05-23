import 'package:flutter/material.dart';
import 'package:baraja_app/models/topping.dart';

import 'addon.dart';

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



class PromoItem {
  final String title;
  final Color? color;

  PromoItem({
    required this.title,
    this.color,
  });
}
