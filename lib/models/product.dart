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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      mainCategory: json['mainCategory'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      originalPrice: (json['originalPrice'] != null) ? json['originalPrice'].toDouble() : null,
      discountPrice: (json['discountPrice'] != null) ? json['discountPrice'].toDouble() : null,
      description: json['description'] ?? '',
      discountPercentage: json['discountPercentage'],
      toppings: json['toppings'] != null
          ? (json['toppings'] as List).map((e) => Topping.fromJson(e)).toList()
          : null,
      addons: json['addons'] != null
          ? (json['addons'] as List).map((e) => Addon.fromJson(e)).toList()
          : null,
      imageColor: null, // Warna tidak bisa langsung diconvert dari JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'category': category,
      'mainCategory': mainCategory,
      'imageUrl': imageUrl,
      'originalPrice': originalPrice,
      'discountPrice': discountPrice,
      'description': description,
      'discountPercentage': discountPercentage,
      'toppings': toppings?.map((e) => e.toJson()).toList(),
      'addons': addons?.map((e) => e.toJson()).toList(),
      // imageColor tidak di-serialize
    };
  }
}
class PromoItem {
  final String title;
  final Color? color;

  PromoItem({
    required this.title,
    this.color,
  });
}
