import 'package:flutter/material.dart';
import 'package:baraja_app/models/product.dart';

import '../models/category.dart';

// ProductData class that contains all data
class ProductData {
  // All coffee products
  static final List<Product> allProducts = [
    Product(
      id: '1',
      name: 'Kopi Arabica',
      category: 'Coffee',
      mainCategory: 'Minuman',
      imageUrl: 'https://static.promediateknologi.id/crop/0x0:0x0/0x0/webp/photo/p2/217/2024/10/07/kopi-americano-2500973096.jpg',
      originalPrice: 26000,
      discountPrice: 20000,
      description: 'Terbuat dari biji pilihan',
      imageColor: Colors.brown[700],
      toppings: [
        Topping(id: '1', name: 'Extra Espresso Shot', price: 5000),
        Topping(id: '2', name: 'Whipped Cream', price: 3000),
      ],
      addons: [
        Addon(id: '1', name: 'Cookies', price: 8000),
        Addon(id: '2', name: 'Chocolate Bar', price: 10000),
      ],
    ),
    Product(
      id: '2',
      name: 'Kopi Robusta',
      category: 'Coffee',
      mainCategory: 'Minuman',
      imageUrl: 'https://static.promediateknologi.id/crop/0x0:0x0/0x0/webp/photo/p2/217/2024/10/07/kopi-americano-2500973096.jpg',
      originalPrice: 24000,
      discountPrice: 19000,
      description: 'Kopi dengan rasa kuat',
      imageColor: Colors.brown[800],
      toppings: [
        Topping(id: '1', name: 'Extra Espresso Shot', price: 5000),
        Topping(id: '2', name: 'Whipped Cream', price: 3000),
      ],
      addons: [
        Addon(id: '1', name: 'Cookies', price: 8000),
        Addon(id: '2', name: 'Chocolate Bar', price: 10000),
      ],
    ),
    Product(
      id: '3',
      name: 'Kopi Luwak',
      category: 'Coffee',
      mainCategory: 'Minuman',
      imageUrl: 'https://static.promediateknologi.id/crop/0x0:0x0/0x0/webp/photo/p2/217/2024/10/07/kopi-americano-2500973096.jpg',
      originalPrice: 40000,
      discountPrice: 32000,
      description: 'Kopi premium pilihan',
      imageColor: Colors.brown[900],
      toppings: [
        Topping(id: '1', name: 'Extra Espresso Shot', price: 5000),
        Topping(id: '2', name: 'Whipped Cream', price: 3000),
      ],
      addons: [
        Addon(id: '1', name: 'Cookies', price: 8000),
        Addon(id: '2', name: 'Chocolate Bar', price: 10000),
      ],
    ),
    Product(
      id: '4',
      name: 'Espresso',
      category: 'Coffee',
      mainCategory: 'Minuman',
      imageUrl: 'https://static.promediateknologi.id/crop/0x0:0x0/0x0/webp/photo/p2/217/2024/10/07/kopi-americano-2500973096.jpg',
      originalPrice: 22000,
      discountPrice: 18000,
      description: 'Kopi hitam murni',
      imageColor: Colors.brown[600],
      toppings: [
        Topping(id: '1', name: 'Extra Espresso Shot', price: 5000),
        Topping(id: '2', name: 'Whipped Cream', price: 3000),
      ],
      addons: [
        Addon(id: '1', name: 'Cookies', price: 8000),
        Addon(id: '2', name: 'Chocolate Bar', price: 10000),
      ],
    ),
    Product(
      id: '5',
      name: 'Nasi Goreng',
      category: 'Main Course',
      mainCategory: 'Makanan',
      imageUrl: 'https://static.promediateknologi.id/crop/0x0:0x0/0x0/webp/photo/p2/217/2024/10/07/kopi-americano-2500973096.jpg',
      originalPrice: 28000,
      discountPrice: 23000,
      description: 'Dengan foam susu lembut',
      imageColor: Colors.brown[500],
      toppings: [
        Topping(id: '1', name: 'Extra Espresso Shot', price: 5000),
        Topping(id: '2', name: 'Whipped Cream', price: 3000),
      ],
      addons: [
        Addon(id: '1', name: 'Cookies', price: 8000),
        Addon(id: '2', name: 'Chocolate Bar', price: 10000),
      ],
    ),
  ];

  // Method to get products (now just returns the static list)
  static List<Product> getProducts() {
    return allProducts;
  }

  // Sample promo images
  static List<PromoItem> getPromoItems() {
    return [
      PromoItem(title: 'Diskon 30% Semua Kopi', color: Colors.red[700]),
      PromoItem(title: 'Gratis Ongkir', color: Colors.blue[700]),
      PromoItem(title: 'Beli 1 Gratis 1', color: Colors.green[700]),
    ];
  }

  // Subcategories
  static final Map<String, List<Category>> subMenus = {
    'Makanan': [
      Category(id: '1', name: 'Snack'),
      Category(id: '2', name: 'Main Course'),
      Category(id: '3', name: 'Dessert'),
      Category(id: '4', name: 'Pastry'),
      Category(id: '5', name: 'Breakfast'),
    ],
    'Minuman': [
      Category(id: '6', name: 'Coffee'),
      Category(id: '7', name: 'Non Coffee'),
      Category(id: '8', name: 'Tea'),
      Category(id: '9', name: 'Smoothies'),
      Category(id: '10', name: 'Juice'),
    ],
  };

  static Product? getProductById(String id) {
    try {
      return allProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
}
