import 'package:flutter/material.dart';
import 'package:baraja_app/widgets/menu_product_card.dart';

import '../models/product.dart';

/// Widget untuk menampilkan grid produk dengan 2 kolom
class ProductGrid extends StatelessWidget {
  final List<Product> products;

  const ProductGrid({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 kolom
        childAspectRatio: 0.75, // Rasio lebar:tinggi card
        crossAxisSpacing: 12, // Spasi horizontal antar card
        mainAxisSpacing: 12, // Spasi vertikal antar card
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return MenuProductCard(product: products[index]);
      },
    );
  }
}