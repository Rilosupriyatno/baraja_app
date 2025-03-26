import 'package:flutter/material.dart';
import 'package:baraja_app/models/product.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isActive;
  final String? bundleText;
  final NumberFormat currencyFormatter;

  const ProductCard({
    super.key,
    required this.product,
    this.isActive = false,
    this.bundleText,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: SizedBox(
        width: 210, // Set width to 210 for square shape
        height: 210, // Set height to 210 for square shape
        child: GestureDetector(
          onTap: () {
            context.push('/product/${product.id}');
          },

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 3,
                  spreadRadius: 1,
                  offset: const Offset(2, 0), // Bayangan ke kanan
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  spreadRadius: 1,
                  offset: const Offset(2, 0), // Bayangan ke kanan
                ),
              ],
            ),
            child: Column(
              children: [
                // Product image
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: product.imageColor ?? AppTheme.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Coffee cup image representation
                        Center(
                          child: Icon(
                            Icons.coffee,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 60,
                          ),
                        ),

                        // Bundle indicator if applicable
                        if (bundleText != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                bundleText!,
                                style: TextStyle(
                                  color: Colors.brown[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Product details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product name
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Original price
                        Text(
                          currencyFormatter.format(product.originalPrice),
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),

                        // Discount price
                        Text(
                          currencyFormatter.format(product.discountPrice),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),

                        // Description
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}